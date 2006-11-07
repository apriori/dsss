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
import std.file;
alias std.file.write write;
import std.path;

import sss.build;
import sss.conf;
import sss.install;

import hcf.path;
import hcf.process;

import mango.http.client.HttpClient;
import mango.http.server.HttpHeaders;

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
        //saySystemDie("svn up " ~ srcListPrefix);
    }
    
    // load it
    NetConfig conf = ReadNetConfig();
    
    // now switch on the command
    if (args.length < 1) {
        writefln("The net command requires a second command as a parameter.");
        return 1;
    }
    switch (args[0]) {
        case "install":
        {
            // FIXME: dependencies
            
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
            
            // 3) get source
            char[] srcFormat = conf.srcFormat[args[1]];
            switch (srcFormat) {
                case "svn":
                    // Subversion, check it out
                    saySystemDie("svn co " ~ conf.srcURL[args[1]]);
                    break;
                    
                default:
                {
                    // download ...
                    HttpClient dlhttp = new HttpClient(
                        HttpClient.Get,
                        conf.srcURL[args[1]]
                        );
                    
                    dlhttp.open();
                    
                    char[] outFile;
                    void sink(char[] cont)
                    {
                        outFile ~= cont;
                    }
                    
                    if (dlhttp.isResponseOK) {
                        int length = dlhttp.getResponseHeaders.getInt(
                            HttpHeader.ContentLength, int.max);
                        dlhttp.read(&sink, length);
                    } else {
                        writefln("Failed to download sources!");
                        return 1;
                    }
                    
                    dlhttp.close();
                    
                    // save it to a source file
                    write("src." ~ srcFormat, cast(void[]) outFile);
                    
                    // extract it
                    switch (srcFormat) {
                        case "tar.gz":
                            systemOrDie("gunzip -c src.tar.gz | tar -xf -");
                            break;
                            
                        case "tar.bz2":
                            systemOrDie("bunzip2 -c src.tar.bz2 | tar -xf -");
                            break;
                            
                        case "zip":
                            systemOrDie("unzip src.zip");
                            break;
                            
                        default:
                            writefln("Unrecognized source format: %s", srcFormat);
                            return 1;
                    }
                }
            }
            
            // FIXME: apply patches
            
            // 4) figure out where the source is
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
            
            // 5) build
            int buildret = build(args[2..$]);
            if (buildret) return buildret;
            
            // 6) install
            return install(args[2..$]);
            
            // FIXME: incomplete (delete sources)
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
        
        //format: pkg protocol/format URL
        if (pkinfo.length < 3) continue;
        conf.srcFormat[pkinfo[0]] = pkinfo[1];
        conf.srcURL[pkinfo[0]] = pkinfo[2];
    }
    
    return conf;
}
