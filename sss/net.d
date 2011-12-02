/**
 * DSSS command "net"
 * 
 * Authors:
 *  Gregor Richards
 * 
 * License:
 *  Copyright (c) 2006, 2007  Gregor Richards
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
import std.conv;
import std.stdio;
import std.array;
import std.string;
alias std.string.split split;
import std.file;
alias std.file.write write;
import std.path;
import std.random;
import std.regex;

import sss.build;
import sss.clean;
import sss.conf;
import sss.install;
import sss.system;
import sss.uninstall;

import hcf.path;
import hcf.process;

/// If set, the given mirror will be used
string forceMirror;

/*import mango.http.client.HttpClient;
import mango.http.client.HttpGet;*/

/** Entry to the "net" command */
int net(string[] args)
{
    // cannot be used from the source dir
    if (inSourceDir) {
        writefln("The 'net' subcommand cannot be used with DSSS running from the source");
        writefln("directory. You must install DSSS.");
        return 1;
    }
    
    // make sure our sources list is up to date
    static bool srcListUpdated = false;
    if (!srcListUpdated) {
        srcListUpdated = true;
        
        // check for cruft from pre-0.3 DSSS
        if (exists(srcListPrefix ~ std.path.sep ~ ".svn")) {
            rmRecursive(srcListPrefix);
        }
        
        writefln("Synchronizing...");
        
        if (!exists(srcListPrefix ~ std.path.sep ~ "mirror")) {
            // find the full list.list file name
            string listlist = installPrefix ~ std.path.sep ~
                ".." ~ std.path.sep ~
                "etc" ~ std.path.sep ~
                "dsss" ~ std.path.sep ~
                "list.list";
            version (Posix) {
                if (!std.file.exists(listlist)) {
                    listlist = "/etc/dsss/list.list";
                }
            }
            
            // select a source list mirror
            string[] mirrorList = std.string.split(
                replace(
                    cast(string) std.file.read(listlist),
                    "\r", ""),
                "\n");
            while (mirrorList[$-1] == "") mirrorList = mirrorList[0..$-1];
            
            int sel = -1;
            
            if (forceMirror.length == 0) {
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
                    string csel;
                    while (sel < 0 || sel >= mirrorList.length) {
                        csel = to!string(din.readLine());
                        sel = to!int(csel) - 1;
                    }
                }
            }
            
            string mirror;
            if (sel == -1) {
                mirror = forceMirror;
            } else {
                mirror = mirrorList[sel];
            }
            
            // get it
            mkdirP(srcListPrefix);
            std.file.write(srcListPrefix ~ std.path.sep ~ "mirror",
                           mirror);
            sayAndSystem("curl -s -S -k " ~ mirror ~ "/source.list "
                        "-o " ~ srcListPrefix ~ std.path.sep ~ "source.list");
            sayAndSystem("curl -s -S -k " ~ mirror ~ "/pkgs.list "
                        "-o " ~ srcListPrefix ~ std.path.sep ~ "pkgs.list");
            sayAndSystem("curl -s -S -k " ~ mirror ~ "/mirrors.list "
                        "-o " ~ srcListPrefix ~ std.path.sep ~ "mirrors.list");
        } else {
            string mirror;
            if (forceMirror.length == 0) {
                mirror = cast(string) std.file.read(
                    srcListPrefix ~ std.path.sep ~ "mirror");
            } else {
                mirror = forceMirror;
            }
            
            string srcList = srcListPrefix ~ std.path.sep ~ "source.list";
            string pkgsList = srcListPrefix ~ std.path.sep ~ "pkgs.list";
            string mirrorsList = srcListPrefix ~ std.path.sep ~ "mirrors.list";
            
            sayAndSystem("curl -s -S -k " ~ mirror ~ "/source.list "
                        "-o " ~ srcList ~
                        " -z " ~ srcList);
            sayAndSystem("curl -s -S -k " ~ mirror ~ "/pkgs.list "
                        "-o " ~ pkgsList ~
                        " -z " ~ pkgsList);
            sayAndSystem("curl -s -S -k " ~ mirror ~ "/mirrors.list "
                        "-o " ~ mirrorsList ~
                        " -z " ~ mirrorsList);
        }
        
        writefln("");
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
        case "depslist":
        {
            DSSSConf dconf = readConfig(null);
            string[] deps;
            if (args[0] == "deps") {
                deps = sourceToDeps(true, conf, dconf);
            } else {
                deps = sourceToDeps(false, conf, dconf);
            }
            
            if (args[0] == "deps") {
                // install dependencies
                foreach (dep; deps) {
                    if (dep == "" || dep == dconf.settings[""]["name"]) continue;
                
                    string[] netcommand;
                    netcommand ~= "assert";
                    netcommand ~= dep;
                
                    writefln("\n\nInstalling %s\n", dep);
                    int netret = net(netcommand);
                    if (netret) return netret;
                }
                
            } else {
                // just list them
                deps = deps.dup.sort;
                string last = "";
                foreach (dep; deps) {
                    if (dep != last && dep != "" &&
                        dep != dconf.settings[""]["name"]) {
                        writefln("%s", dep);
                        last = dep;
                    }
                }
                
            }
            
            return 0;
        }
        
        case "assert":
        {
            // make sure that the tool is installed, install it if not
            
            // check for manifest files in every usedir
            bool found = false;
            string manifestFile = manifestPrefix ~ std.path.sep ~ args[1] ~ ".manifest";
            if (exists(manifestFile)) {
                found = true;
            } else {
                
                foreach (dir; useDirs) {
                    manifestFile = dir ~ std.path.sep ~
                        "share" ~ std.path.sep ~
                        "dsss" ~ std.path.sep ~
                        "manifest" ~ std.path.sep ~
                        args[1] ~ ".manifest";
                    if (exists(manifestFile)) {
                        found = true;
                        break;
                    }
                }
            }
            
            if (found) {
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
            string srcDir = scratchPrefix ~ std.path.sep ~ "DSSS_" ~ args[1];
            string tmpDir = srcDir;
            mkdirP(srcDir);
            writefln("Working in %s", srcDir);
            
            // 2) chdir
            string origcwd = getcwd();
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
                string archname = args[1] ~ ".tar.gz";
                
                // compress
                version (Windows) {
                    // CyberShadow 2007.02.21: this code actually works now
                    string[] files = listdir("");
                    auto regexp = RegExp(r"^[^\.]");
                    string cmdline = "bsdtar -zcf " ~ archname;
                    foreach(file;files)
                        if(regexp.test(file))
                            cmdline ~= " " ~ file;
                    vSaySystemDie(cmdline);
                } else {
                    vSaySystemDie("tar -cf - * | gzip -c > " ~ archname);
                }
                
                // move into place
                try {
                    std.file.rename(archname,
                                    origcwd ~ std.path.sep ~ archname);
                } catch (Exception x) {
                    // can't rename, copy
                    std.file.copy(archname,
                                  origcwd ~ std.path.sep ~ archname);
                    std.file.remove(archname);
                }
                
                writefln("Archive %s created.", archname);
                return 0;
            } else {
                // 4) make sure it's not installed
                if (args[1] != "dsss")
                    uninstall(args[1..2], true);
                
                // 5) install prerequisites
                string[] netcmd;
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
        
        case "list":
        {
            // Just list installable packages
            foreach (pkg; conf.srcURL.keys.sort) {
                writefln("%s", pkg);
            }
            return 0;
        }
        
        case "search":
        {
            // List matching packages
            if (args.length < 2) {
                writefln("Search for what?");
                return 1;
            }
            
            foreach (pkg; conf.srcURL.keys.sort) {
                if (!std.regex.match(pkg, regex(args[1])).empty()) {
                    writefln("%s", pkg);
                }
            }
            
            return 0;
        }
        
        default:
            writefln("Unrecognized command: %s", args[0]);
            return 1;
    }
}

/** Net config object */
class NetConfig {
    /** The mirror in use */
    string mirror;
    
    /** Versions of packages */
    string[string] vers;
    
    /** Dependencies of packages */
    string[][string] deps;
    
    /** Source formats of packages */
    string[string] srcFormat;
    
    /** Source URL of packages */
    string[string] srcURL;
    
    /** Patches */
    string[][string] srcPatches;
}

/** Read the net configuration info */
NetConfig ReadNetConfig()
{
    NetConfig conf = new NetConfig();
    
    // read in the mirror
    conf.mirror = cast(string) std.file.read(srcListPrefix ~ std.path.sep ~ "mirror");
    
    // read in the main tool/dep/version list
    string pkgslist = replace(
        cast(string) std.file.read(srcListPrefix ~ std.path.sep ~ "pkgs.list"),
        "\r", "");
    foreach (pkg; std.string.split(pkgslist, "\n")) {
        if (pkg.length == 0 || pkg[0] == '#') continue;
        
        string[] pkinfo = std.string.split(pkg, " ");
        
        // format: pkg ver deps
        if (pkinfo.length < 2) continue;
        conf.vers[pkinfo[0]] = pkinfo[1];
        conf.deps[pkinfo[0]] = pkinfo[2..$];
    }
    
    // then read in the source list
    string srclist = cast(string) std.file.read(srcListPrefix ~ std.path.sep ~ "source.list");
    foreach (pkg; std.string.split(srclist, "\n")) {
        if (pkg.length == 0 || pkg[0] == '#') continue;
        
        string[] pkinfo = std.string.split(pkg, " ");
        
        //format: pkg protocol/format URL [patches]
        if (pkinfo.length < 3) continue;
        conf.srcFormat[pkinfo[0]] = pkinfo[1];
        conf.srcURL[pkinfo[0]] = pkinfo[2];
        conf.srcPatches[pkinfo[0]] = pkinfo[3..$];
    }
    
    return conf;
}

/** Generate a list of dependencies for the current source */
string[] sourceToDeps(bool unresolvedOnly, NetConfig nconf = null, DSSSConf conf = null)
{
    if (nconf is null) {
        nconf = ReadNetConfig();
    }
    if (conf is null) {
        conf = readConfig(null);
    }
    
    // start with the requires setting
    string[] deps;
    if ("requires" in conf.settings[""]) {
        deps ~= std.string.split(conf.settings[""]["requires"]);
    }
    
    // then trace uses
    foreach (section; conf.sections) {
        string[] files;
        string type = conf.settings[section]["type"];
        if (type == "binary") {
            files ~= section;
        } else if (type == "library" || type == "sourcelibrary") {
            files ~= targetToFiles(section, conf);
        } else if (type == "subdir") {
            // recurse
            string origcwd = getcwd();
            chdir(section);
            deps ~= sourceToDeps(unresolvedOnly, nconf);
            chdir(origcwd);
            continue;
        } else {
            // ignore
            continue;
        }
        
        // use dsss_build -files or -notfound to get the list of files
        string filesFlag = "-files";
        if (unresolvedOnly)
            filesFlag = "-notfound";
        systemResponse(dsss_build ~ " " ~ filesFlag ~ " -offiles.tmp " ~
                       std.string.join(files, " "), "-rf", "temp.rf", true);
        
        // read the uses
        string[] uses = std.string.split(cast(string) std.file.read("files.tmp"),
                                         "\n");
        foreach (use; uses) {
            if (use.length == 0) break;

            // get rid of any trailing \r's or \n's
            while (use.length &&
                   (use[$-1] == '\n' ||
                    use[$-1] == '\r')) {
                use = use[0..$-1];
            }
            if (use.length == 0) break;
            
            // add the dep
            deps ~= canonicalSource(use, nconf);
        }
        
        tryRemove("files.tmp");
    }
    
    return deps;
}

/** Canonicalize a dependency (.d -> source) */
string canonicalSource(string origsrc, NetConfig nconf)
{
    string src = origsrc;
    version (Windows) {
        src = std.string.replace(src, "\\", "/");
    }
    
    if ((src.length > 2 &&
         std.string.tolower(src[$-2 .. $]) == ".d") ||
        (src.length > 3 &&
         std.string.tolower(src[$-3 .. $]) == ".di")) {
        // convert to a proper source
        if (src in nconf.deps &&
            nconf.deps[src].length == 1) {
            src = nconf.deps[src][0];
        } else {
            src = "";
        }
    }
    
    return src;
}

/** Get the source for a given package
 * Returns true on success, false on failure
 * NOTE: Your chdir can change! */
bool getSources(string pkg, NetConfig conf)
{
    /// get sources from upstream, return false on failure
    bool getUpstream() {
        // 1) get source
        string srcFormat = conf.srcFormat[pkg];
        int res;
        switch (srcFormat) {
            case "svn":
                // Subversion, check it out
                res = vSayAndSystem("svn export " ~ conf.srcURL[pkg]);
                break;
                
            default:
            {
                /* download ...
                HttpGet dlhttp = new HttpGet(conf.srcURL[pkg]);
                
                // save it to a source file
                write("src." ~ srcFormat, dlhttp.read());*/
                
                // mango doesn't work properly for me :(
                res = vSayAndSystem("curl -k " ~ conf.srcURL[pkg] ~ " -o src." ~ srcFormat);
                if (res != 0) return false;
                
                // extract it
                switch (srcFormat) {
                    case "tar.gz":
                    case "tgz":
                        version (Windows) {
                            // assume BsdTar
                            vSayAndSystem("bsdtar -xf src." ~ srcFormat);
                            res = 0;
                        } else {
                            res = vSayAndSystem("gunzip -c src." ~ srcFormat ~ " | tar -xf -");
                        }
                        break;
                        
                    case "tar.bz2":
                        version (Windows) {
                            // assume BsdTar
                            vSayAndSystem("bsdtar -xf src.tar.bz2");
                            res = 0;
                        } else {
                            res = vSayAndSystem("bunzip2 -c src.tar.bz2 | tar -xf -");
                        }
                        break;
                        
                    case "zip":
                        version (Windows) {
                            // assume BsdTar
                            vSayAndSystem("bsdtar -xf src.zip");
                            res = 0;
                        } else {
                            // assume InfoZip
                            res = vSayAndSystem("unzip src.zip");
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
        string srcDir = getcwd();
        foreach (patch; conf.srcPatches[pkg]) {
            string[] pinfo = split(patch, ":");
            string dir;
            string pfile;
            
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
            vSaySystemDie("curl -k " ~ conf.mirror ~ "/" ~ pfile ~
                         " -o " ~ pfile);
            
            // convert it to DOS line endings if necessary
            version (Windows) {
                vSaySystemDie("unix2dos " ~ pfile);
            }
            
            // install the patch
            system("patch -p0 -N -i " ~ pfile);    // CyberShadow 2007.02.21: added -N to prevent useless questions ("apply reverse patch?") when re-running "net install"
            
            chdir(srcDir);
        }
        
        return true;
    }
    
    if (!getUpstream()) {
        // failed to get from upstream, try a mirror
        string[] mirrorsList = std.string.split(
            cast(string) std.file.read(
                srcListPrefix ~ std.path.sep ~ "mirrors.list"
                ),
            "\n");
        while (mirrorsList[$-1] == "") mirrorsList = mirrorsList[0..$-1];
        
        // fail with zero mirrors
        if (mirrorsList.length > 0) {
            // choose a random one
            size_t sel = std.random.uniform(0, mirrorsList.length);
            string mirror = mirrorsList[sel];
            
            vSaySystemDie("curl -k " ~ mirror ~ "/" ~ pkg ~ ".tar.gz " ~
                         "-o " ~ pkg ~ ".tar.gz");
            
            // extract
            version (Windows) {
                vSayAndSystem("bsdtar -xf " ~ pkg ~ ".tar.gz");
            } else {
                vSaySystemDie("gunzip -c " ~ pkg ~ ".tar.gz | tar -xf -");
            }
        }
    }
    
    // 3) figure out where the source is and chdir
    if (!exists(configFName)) {
        string[] sub = listdir(".");
        foreach (entr; sub) {
            if (entr[0] == '.') continue;
                    
            // check if it's a source directory
            if (entr.isDir) {
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

