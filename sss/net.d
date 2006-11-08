/**
 * DSSS command "net"
 * 
 * Authors:
 *  Gregor Richards
 * 
 * License:
 *  Copyright (C) 2006  Gregor Richards
 *  
 *  This file is part of DSSS.
 *  
 *  DSSS is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *  
 *  DSSS is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with DSSS; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
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
            DSSSConf dsssconf = readConfig(args[2..$]);
            char[][] prereqs;
            if ("requires" in dsssconf.settings[""]) {
                prereqs = split(dsssconf.settings[""]["requires"]);
            }
            foreach (prereq; prereqs) {
                // assert that it's installed
                char[][] netcmd;
                netcmd ~= "assert";
                netcmd ~= prereq;
                int netret = net(netcmd);
                chdir(srcDir);
                if (netret) return netret;
            }
            
            // 6) build
            int buildret = build(args[2..$], dsssconf);
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

/** Get the source for a given package
 * Returns true on success, false on failure
 * NOTE: Your chdir can change! */
bool getSources(char[] pkg, NetConfig conf) {
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
            systemOrDie("wget '" ~ conf.srcURL[pkg] ~ "' -O src." ~ srcFormat);
                    
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