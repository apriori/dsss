/**
 * DSSS command "net"
 * 
 * Authors:
 *  Gregor Richards
 * 
 * License:
 *  Copyright (c) 2006  Gregor Richards
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a
 *  copy of this software and associated documentation files (the "Software"),
 *  to deal in the Software without restriction, including without limitation
 *  the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *  and/or sell copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 */

module sss.net;

import std.stdio;
import std.string;
import std.file;
alias std.file.write write;
import std.path;

import sss.build;
import sss.conf;
import sss.install;
import sss.uninstall;

import hcf.path;
import hcf.process;

import mango.http.client.HttpClient;
import mango.http.client.HttpGet;

/** The source of the sources list is defaulted here */
private char[] srcSrc = "http://svn.dsource.org/projects/dsss/sources";

/** Entry to the "net" command */
int net(char[][] args)
{
    // first, make sure our sources list is up to date
    if (!exists(srcListPrefix)) {
        // check it out
        saySystemDie("svn co " ~ srcSrc ~ " " ~ srcListPrefix);
    } else {
        // update it
        // FIXME: this should not run every time
        saySystemDie("svn up " ~ srcListPrefix);
    }
    
    // load it
    NetConfig conf = ReadNetConfig();
    
    // now switch on the command
    if (args.length < 1) {
        writefln("The net command requires a second command as a parameter.");
        return 1;
    }
    switch (args[0]) {
        case "deps":
        {
            // install dependencies
            DSSSConf dconf = readConfig(null);
            char[][] deps = sourceToDeps(conf, dconf);
            foreach (dep; deps) {
                if (dep == "" || dep == dconf.settings[""]["name"]) continue;
                
                char[][] netcommand;
                netcommand ~= "assert";
                netcommand ~= dep;
                
                writefln("\n\nInstalling %s\n", dep);
                int netret = net(netcommand);
                if (netret) return netret;
            }
            
            return 0;
        }
        
        case "assert":
        {
            // make sure that the tool is installed, install it if not
            char[] manifestFile = manifestPrefix ~ std.path.sep ~ args[1] ~ ".manifest";
            if (exists(manifestFile)) {
                writefln("%s is already installed.\n", args[1]);
                return 0;
            }
            
            // fall through
        }
        
        case "install":
        {
            // download and install the specified package and its dependencies
            if (args.length < 2) {
                writefln("The install command requires a package name as an argument.");
                return 1;
            }
            
            // 0) sanity
            if (!(args[1] in conf.vers)) {
                writefln("That package does not appear to exist!");
                return 1;
            }
            
            // 1) make the source directory
            char[] srcDir = scratchPrefix ~ std.path.sep ~ "DSSS_" ~ args[1];
            mkdirP(srcDir);
            writefln("Building in %s", srcDir);
            
            // 2) chdir
            char[] origcwd = getcwd();
            chdir(srcDir);
            
            // 3) get sources
            if (!getSources(args[1], conf)) return 1;
            srcDir = getcwd();
            
            // 4) make sure it's not installed
            uninstall(args[1..2]);
            
            // 5) install prerequisites
            char[][] netcmd;
            netcmd ~= "deps";
            int netret = net(netcmd);
            if (netret) return netret;
            chdir(srcDir);
            
            // 6) build
            DSSSConf dconf = readConfig(null);
            int buildret = build(args[2..$], dconf);
            if (buildret) return buildret;
            
            // 7) install
            return install(args[2..$]);
        }
        
        default:
            writefln("Unrecognized command: %s", args[0]);
            return 1;
    }
}

/** Net config object */
class NetConfig {
    /** Versions of packages */
    char[][char[]] vers;
    
    /** Dependencies of packages */
    char[][][char[]] deps;
    
    /** Source formats of packages */
    char[][char[]] srcFormat;
    
    /** Source URL of packages */
    char[][char[]] srcURL;
    
    /** Patches */
    char[][][char[]] srcPatches;
}

/** Read the net configuration info */
NetConfig ReadNetConfig()
{
    NetConfig conf = new NetConfig();
    
    // read in the main tool/dep/version list
    char[] pkgslist = cast(char[]) std.file.read(srcListPrefix ~ std.path.sep ~ "pkgs.list");
    foreach (pkg; std.string.split(pkgslist, "\n")) {
        if (pkg.length == 0 || pkg[0] == '#') continue;
        
        char[][] pkinfo = std.string.split(pkg, " ");
        
        // format: pkg ver deps
        if (pkinfo.length < 2) continue;
        conf.vers[pkinfo[0]] = pkinfo[1];
        conf.deps[pkinfo[0]] = pkinfo[2..$];
    }
    
    // then read in the source list
    char[] srclist = cast(char[]) std.file.read(srcListPrefix ~ std.path.sep ~ "source.list");
    foreach (pkg; std.string.split(srclist, "\n")) {
        if (pkg.length == 0 || pkg[0] == '#') continue;
        
        char[][] pkinfo = std.string.split(pkg, " ");
        
        //format: pkg protocol/format URL [patches]
        if (pkinfo.length < 3) continue;
        conf.srcFormat[pkinfo[0]] = pkinfo[1];
        conf.srcURL[pkinfo[0]] = pkinfo[2];
        conf.srcPatches[pkinfo[0]] = pkinfo[3..$];
    }
    
    return conf;
}

/** Generate a list of dependencies for the current source */
char[][] sourceToDeps(NetConfig nconf = null, DSSSConf conf = null)
{
    if (nconf is null) {
        nconf = ReadNetConfig();
    }
    if (conf is null) {
        conf = readConfig(null);
    }
    
    // start with the requires setting
    char[][] deps;
    if ("requires" in conf.settings[""]) {
        deps ~= std.string.split(conf.settings[""]["requires"]);
    }
    
    // then trace uses
    foreach (section; conf.sections) {
        char[][] files;
        if (conf.settings[section]["type"] == "binary") {
            files ~= section;
        } else {
            files ~= targetToFiles(section, conf);
        }
        
        // make a uses file
        char[] usesLine = dsss_build ~ " -test -uses=temp.uses " ~
            std.string.join(files, " ");
        saySystemDie(usesLine);
        
        // then read the uses
        char[] uses = cast(char[]) std.file.read("temp.uses");
        foreach (use; std.string.split(uses, "\n")) {
            if (use.length == 0) continue;
            if (use[$-1] == '\r') use = use[0 .. $-1];
            if (use.length == 0) continue;
            
            if (use == "[USEDBY]") break;
            if (use[0] == '[') continue;
            
            // OK, we're definitely reading a use - split by " <> "
            char[][] useinfo = std.string.split(use, " <> ");
            if (useinfo.length < 2) continue;
            
            // add the dep
            deps ~= canonicalSource(useinfo[1], nconf);
        }
        
        // delete the uses file
        std.file.remove("temp.uses");
    }
    
    return deps;
}

/** Canonicalize a dependency (.d -> source) */
char[] canonicalSource(char[] origsrc, NetConfig nconf)
{
    char[] src = origsrc.dup;
    
    if ((src.length > 2 &&
         std.string.tolower(src[$-2 .. $]) == ".d") ||
        (src.length > 3 &&
         std.string.tolower(src[$-3 .. $]) == ".di")) {
        // convert to a proper source
        if (src in nconf.deps &&
            nconf.deps[src].length == 1) {
            src = nconf.deps[src][0].dup;
        } else {
            src = "";
        }
    }
    
    return src;
}

/** Get the source for a given package
 * Returns true on success, false on failure
 * NOTE: Your chdir can change! */
bool getSources(char[] pkg, NetConfig conf)
{
    // 1) get source
    char[] srcFormat = conf.srcFormat[pkg];
    switch (srcFormat) {
        case "svn":
            // Subversion, check it out
            saySystemDie("svn co " ~ conf.srcURL[pkg]);
            break;
                    
        default:
        {
            /* download ...
            HttpGet dlhttp = new HttpGet(conf.srcURL[pkg]);
                    
            // save it to a source file
            write("src." ~ srcFormat, dlhttp.read());*/
                    
            // mango doesn't work properly (?)
            systemOrDie("wget -c '" ~ conf.srcURL[pkg] ~ "' -O src." ~ srcFormat);
            
            // extract it
            switch (srcFormat) {
                case "tar.gz":
                case "tgz":
                    version (Windows) {
                        // assume BsdTar
                        systemOrDie("bsdtar -xf src." ~ srcFormat);
                    } else {
                        systemOrDie("gunzip -c src." ~ srcFormat ~ " | tar -xf -");
                    }
                    break;
                            
                case "tar.bz2":
                    version (Windows) {
                        // assume BsdTar
                        systemOrDie("bsdtar -xf src.tar.bz2");
                    } else {
                        systemOrDie("bunzip2 -c src.tar.bz2 | tar -xf -");
                    }
                    break;
                            
                case "zip":
                    version (Windows) {
                        // assume BsdTar
                        systemOrDie("bsdtar -xf src.zip");
                    } else {
                        // assume InfoZip
                        systemOrDie("unzip src.zip");
                    }
                    break;
                            
                default:
                    writefln("Unrecognized source format: %s", srcFormat);
                    return false;
            }
        }
    }
            
    // 2) apply patches
    char[] srcDir = getcwd();
    foreach (patch; conf.srcPatches[pkg]) {
        char[][] pinfo = split(patch, ":");
        char[] dir;
        char[] pfile;
        
        // split into dir:file or just file
        if (pinfo.length < 2) {
            dir = srcDir;
            pfile = pinfo[0];
        } else {
            dir = pinfo[0];
            pfile = pinfo[1];
        }
        
        chdir(dir);
        systemOrDie("patch -p0 -i " ~ srcListPrefix ~ std.path.sep ~ pfile);
        chdir(srcDir);
    }
    
    // 3) figure out where the source is and chdir
    if (!exists(configFName)) {
        char[][] sub = listdir(".");
        foreach (entr; sub) {
            if (entr[0] == '.') continue;
                    
            // check if it's a source directory
            if (isdir(entr)) {
                if (exists(entr ~ std.path.sep ~ configFName)) {
                    // found
                    chdir(entr);
                    break;
                }
            }
        }
    }
    
    return true;
}

version (build) {
    version (Windows) {
        pragma(link, "wsock32");
    }
}

