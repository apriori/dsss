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

import std.cstream;
import std.stdio;
import std.string;
alias std.string.split split;
import std.file;
alias std.file.write write;
import std.path;
import std.random;
import std.regexp;

import sss.build;
import sss.conf;
import sss.install;
import sss.uninstall;

import hcf.path;
import hcf.process;

/*import mango.http.client.HttpClient;
import mango.http.client.HttpGet;*/

/** Entry to the "net" command */
int net(char[][] args)
{
    // first, make sure our sources list is up to date
    static bool srcListUpdated = false;
    if (!srcListUpdated) {
        srcListUpdated = true;
        
        // check for cruft from pre-0.3 DSSS
        if (exists(srcListPrefix ~ std.path.sep ~ ".svn")) {
            rmRecursive(srcListPrefix);
        }
        
        if (!exists(srcListPrefix ~ std.path.sep ~ "mirror")) {
            // select a source list mirror
            char[][] mirrorList = std.string.split(
                std.string.replace(
                    cast(char[]) std.file.read(etcPrefix ~ std.path.sep ~
                                               "dsss" ~ std.path.sep ~
                                               "list.list"),
                    "\r", ""),
                "\n");
            while (mirrorList[$-1] == "") mirrorList = mirrorList[0..$-1];
            
            int sel = -1;
            
            if (mirrorList.length == 1) {
                // easy choice :)
                sel = 0;
            } else {
                writefln("Please choose a mirror for the source list:");
                writefln("(Note that you may choose another mirror at any time by removing the directory");
                writefln("%s)", srcListPrefix);
                writefln("");
                
                foreach (i, mirror; mirrorList) {
                    writefln("%d) %s", i + 1, mirror);
                }
                
                // choose
                char[] csel;
                while (sel < 0 || sel >= mirrorList.length) {
                    csel = din.readLine();
                    sel = atoi(csel) - 1;
                }
            }
            
            // get it
            mkdirP(srcListPrefix);
            std.file.write(srcListPrefix ~ std.path.sep ~ "mirror",
                           mirrorList[sel]);
            char[] mirror = cast(char[]) std.file.read(
                srcListPrefix ~ std.path.sep ~ "mirror");
            saySystemDie("curl " ~ mirror ~ "/source.list "
                         "-o " ~ srcListPrefix ~ std.path.sep ~ "source.list");
            saySystemDie("curl " ~ mirror ~ "/pkgs.list "
                         "-o " ~ srcListPrefix ~ std.path.sep ~ "pkgs.list");
        } else {
            char[] mirror = cast(char[]) std.file.read(
                srcListPrefix ~ std.path.sep ~ "mirror");
            char[] srcList = srcListPrefix ~ std.path.sep ~ "source.list";
            char[] pkgsList = srcListPrefix ~ std.path.sep ~ "pkgs.list";
            
            saySystemDie("curl " ~ mirror ~ "/source.list "
                         "-o " ~ srcList ~
                         " -z " ~ srcList);
            saySystemDie("curl " ~ mirror ~ "/pkgs.list "
                         "-o " ~ pkgsList ~
                         " -z " ~ pkgsList);
        }
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
        
        case "fetch":
        case "install":
        {
            // download and install the specified package and its dependencies
            if (args.length < 2) {
                writefln("No package name specified.");
                return 1;
            }
            
            // 0) sanity
            if (!(args[1] in conf.vers)) {
                writefln("That package does not appear to exist!");
                return 1;
            }
            
            // 1) make the source directory
            char[] srcDir = scratchPrefix ~ std.path.sep ~ "DSSS_" ~ args[1];
            char[] tmpDir = srcDir;
            mkdirP(srcDir);
            writefln("Working in %s", srcDir);
            
            // 2) chdir
            char[] origcwd = getcwd();
            chdir(srcDir);
            
            // make sure the directory gets removed
            scope(exit) {
                chdir(origcwd);
                rmRecursive(tmpDir);
            }
            
            // 3) get sources
            if (!getSources(args[1], conf)) return 1;
            srcDir = getcwd();
            
            // if we're just fetching, make the archive
            if (args[0] == "fetch") {
                char[] archname = args[1] ~ ".tar.gz";
                
                // compress
                version (Windows) {
                    system("bsdtar -zcf " ~ archname ~ " " ~ std.string.join(
                        listdir(".", RegExp(r"^[^\.]")),
                        " "));
                } else {
                    system("tar -cf - * | gzip -c > " ~ archname);
                }
                
                // move into place
                std.file.rename(archname,
                                origcwd ~ std.path.sep ~ archname);
                
                writefln("Archive %s created.", archname);
                return 0;
            } else {
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
        }
        
        default:
            writefln("Unrecognized command: %s", args[0]);
            return 1;
    }
}

/** Net config object */
class NetConfig {
    /** The mirror in use */
    char[] mirror;
    
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
    
    // read in the mirror
    conf.mirror = cast(char[]) std.file.read(srcListPrefix ~ std.path.sep ~ "mirror");
    
    // read in the main tool/dep/version list
    char[] pkgslist = std.string.replace(
        cast(char[]) std.file.read(srcListPrefix ~ std.path.sep ~ "pkgs.list"),
        "\r", "");
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
        char[] type = conf.settings[section]["type"];
        if (type == "binary") {
            files ~= section;
        } else if (type == "library") {
            files ~= targetToFiles(section, conf);
        } else if (type == "subdir") {
            // recurse
            char[] origcwd = getcwd();
            chdir(section);
            deps ~= sourceToDeps(nconf);
            chdir(origcwd);
            continue;
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
    /// get sources from upstream, return false on failure
    bool getUpstream() {
        // 1) get source
        char[] srcFormat = conf.srcFormat[pkg];
        int res;
        switch (srcFormat) {
            case "svn":
                // Subversion, check it out
                res = sayAndSystem("svn co " ~ conf.srcURL[pkg]);
                break;
                
            default:
            {
                /* download ...
                HttpGet dlhttp = new HttpGet(conf.srcURL[pkg]);
                
                // save it to a source file
                write("src." ~ srcFormat, dlhttp.read());*/
                
                // mango doesn't work properly for me :(
                systemOrDie("curl " ~ conf.srcURL[pkg] ~ " -o src." ~ srcFormat);
                
                // extract it
                switch (srcFormat) {
                    case "tar.gz":
                    case "tgz":
                        version (Windows) {
                            // assume BsdTar
                            res = sayAndSystem("bsdtar -xf src." ~ srcFormat);
                        } else {
                            res = sayAndSystem("gunzip -c src." ~ srcFormat ~ " | tar -xf -");
                        }
                        break;
                        
                    case "tar.bz2":
                        version (Windows) {
                            // assume BsdTar
                            res = sayAndSystem("bsdtar -xf src.tar.bz2");
                        } else {
                            res = sayAndSystem("bunzip2 -c src.tar.bz2 | tar -xf -");
                        }
                        break;
                        
                    case "zip":
                        version (Windows) {
                            // assume BsdTar
                            res = sayAndSystem("bsdtar -xf src.zip");
                        } else {
                            // assume InfoZip
                            res = sayAndSystem("unzip src.zip");
                        }
                        break;
                        
                    default:
                        writefln("Unrecognized source format: %s", srcFormat);
                        return false;
                }
            }
        }
        
        if (res != 0) return false;
        
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
            
            // download the patch file
            saySystemDie("curl " ~ conf.mirror ~ "/" ~ pfile ~
                         " -o " ~ pfile);
            
            // install the patch
            system("patch -p0 -i " ~ pfile);
            
            chdir(srcDir);
        }
        
        return true;
    }
    
    if (!getUpstream()) {
        // failed to get from upstream, try a mirror
        char[][] mirrorsList = std.string.split(
            cast(char[]) std.file.read(
                srcListPrefix ~ std.path.sep ~ "mirrors.list"
                ),
            "\n");
        while (mirrorsList[$-1] == "") mirrorsList = mirrorsList[0..$-1];
        
        // choose a random one
        uint sel = cast(uint) ((cast(double) mirrorsList.length) * (rand() / (uint.max + 1.0)));
        char[] mirror = mirrorsList[sel];
        
        saySystemDie("curl " ~ mirror ~ "/" ~ pkg ~ ".tar.gz " ~
                     "-o " ~ pkg ~ ".tar.gz");
        
        // extract
        version (Windows) {
            saySystemDie("bsdtar -xf " ~ pkg ~ ".tar.gz");
        } else {
            saySystemDie("gunzip -c " ~ pkg ~ ".tar.gz | tar -xf -");
        }
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

