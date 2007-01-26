/**
 * DSSS command "build"
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

module sss.build;

import std.file;
import std.process;
import std.stdio;
import std.string;

import std.c.stdlib;

import hcf.path;
import hcf.process;

import sss.conf;

/** The entry function to the DSSS "build" command */
int build(char[][] buildElems, DSSSConf conf = null, char[] forceFlags = "") {
    // get the configuration
    if (conf is null)
        conf = readConfig(buildElems);
    
    // buildElems are by either soure or target, so we need one by source only
    char[][] buildSources;
    
    // get the sources
    buildSources = sourcesByElems(buildElems, conf);
    
    // also get a complete list, since some steps need it
    char[][] allSources = sourcesByElems(null, conf);
    
    /* building is fairly complicated, involves these steps:
     * 1) Make .di files
     *    (so that you link against your own libraries)
     * 2) Make fake shared libraries
     *    (they need to exist so that other libraries can link against them)
     * 3) Make real shared libraries
     * 4) Make binaries
     */
    
    // make the basic build line
    char[] bl = dsss_build ~ forceFlags;
    
    // for DMD, force output files to be generated in this directory
    version (DigitalMars) {
        bl ~= "-od. ";
    }
    
    // 1) Make .di files for everything
    foreach (build; allSources) {
        char[][char[]] settings = conf.settings[build];
        
        // basic info
        char[] type = settings["type"];
        char[] target = settings["target"];
        
        if (type == "library") {
            writefln("Creating imports for %s", target);
            
            // this is a library, so make .di files
            char[][] srcFiles = targetToFiles(build, conf);
            
            // generate .di files
            foreach (file; srcFiles) {
                if (!exists(file ~ "i") ||
                    fileNewer(file, file ~ "i")) {
                    
                    /+
                    // FIXME: this should not assume by version()
                    int res;
                    version (GNU) {
                        res = system(dsss_build ~
                                     "-obj -full -fintfc -fintfc-file=" ~
                                     file ~ "i " ~ file);
                    } else version (DigitalMars) {
                        res = system(dsss_build ~
                                     "-obj -full -H -Hf" ~
                                     file ~ "i " ~ file);
                    } else {
                        static assert(0);
                    }
                    
                    if (res) {
                        // make sure the .i file is removed
                        std.file.remove(file ~ "i");
                        return res;
                    }
                    +/
                    
                    /* BIG FAT NOTE slash FIXME:
                     * .di files do NOT include interfaces! So, we need to just
                     * cast .d files as .di until that's fixed */
                    std.file.copy(file, file ~ "i");
                    
                    // now edit the .di file to reference the appropriate library
                    
                    // usname = name_with_underscores
                    char[] usname = replace(build, std.path.sep, "_");
                    
                    if (shLibSupport() &&
                        ("shared" in settings)) {
                          std.file.write(file ~ "i", std.file.read(file ~ "i") ~ `
version (build) {
    version (DSSS_Static_` ~ usname ~ `) {
        pragma(link, "S` ~ target ~ `");
    } else {
        pragma(link, "` ~ target ~ `");
    }
}
`);
                    } else {
                        std.file.write(file ~ "i", std.file.read(file ~ "i") ~ `
version (build) {
    pragma(link, "S` ~ target ~ `");
}
`);
                    }
                }
            }
            
            writefln("");
            
        } else if (type == "subdir") {
            // recurse
            char[] origcwd = getcwd();
            chdir(build);
            
            // the one thing that's passed in is build flags
            char[] orig_dsss_build = dsss_build.dup;
            if ("buildflags" in settings) {
                dsss_build ~= " " ~ settings["buildflags"];
            }
            
            int buildret = sss.build.build(null);
            chdir(origcwd);
            
            dsss_build = orig_dsss_build;
        }
    }
    
    // 2) Make fake shared libraries
    if (shLibSupport()) {
        foreach (build; allSources) {
            char[][char[]] settings = conf.settings[build];
            
            // ignore this if we're not building a shared library
            if (!("shared" in settings)) continue;
        
            // basic info
            char[] type = settings["type"];
            char[] target = settings["target"];
        
            if (type == "library") {
                char[] shlibname = getShLibName(settings);
                char[][] shortshlibnames = getShortShLibNames(settings);
                char[] shlibflag = getShLibFlag(settings);
                
                if (exists(shlibname)) continue;
                
                writefln("Building stub shared library for %s", target);
                
                // make the stub
                version (GNU_or_Posix) {
                    char[] stubbl = bl ~ "-fPIC -shlib " ~ stubDLoc ~ " -T" ~ shlibname ~
                    " " ~ shlibflag;
                    saySystemDie(stubbl);
                    version (Posix) {
                        foreach (ssln; shortshlibnames) {
                            saySystemDie("ln -sf " ~ shlibname ~ " " ~ ssln);
                        }
                    }
                } else version (Windows) {
                    assert(0);
                } else {
                    static assert(0);
                }
                
                writefln("");
            }
        }
    }
    
    // 3) Make real libraries
    foreach (build; buildSources) {
        char[][char[]] settings = conf.settings[build];
        
        // basic info
        char[] type = settings["type"];
        char[] target = settings["target"];
        
        if (type == "library") {
            char[] dotname = std.string.replace(build, std.path.sep, ".");
            
            // get the list of files
            char[][] files = targetToFiles(build, conf);
            
            // unfortunately, at each step we need to move the .di files out of the way, then back
            // I'd like a switch in build to avoid this, but there isn't one
            foreach (file; files) {
                std.file.rename(file ~ "i", file ~ "i0");
            }
            
            // and other necessary data
            char[] shlibname = getShLibName(settings);
            char[] shlibflag = getShLibFlag(settings);
            char[] bflags;
            if ("buildflags" in settings) {
                bflags = settings["buildflags"];
            }
            
            // output what we're building
            writefln("%s => %s", build, target);
        
            // do the prebuild
            if ("prebuild" in settings) {
                dsssScriptedStep(conf, settings["prebuild"]);
            }
            
            // get the file list
            char[] fileList = std.string.join(targetToFiles(build, conf), " ");
            
            version (GNU_or_Posix) {
                // first do a static library
                if (exists("libS" ~ target ~ ".a")) std.file.remove("libS" ~ target ~ ".a");
                char[] stbl = bl ~ bflags ~ " -explicit -lib -full " ~ fileList ~ " -TlibS" ~ target ~ ".a";
                saySystemDie(stbl);
                
                if (shLibSupport() &&
                    ("shared" in settings)) {
                    // then make the shared library
                    if (exists(shlibname)) std.file.remove(shlibname);
                    char[] shbl = bl ~ bflags ~ " -fPIC -explicit -shlib -full " ~ fileList ~ " -T" ~ shlibname ~
                        " " ~ shlibflag;
                    
                    // finally, the shared compile
                    saySystemDie(shbl);
                }
                
            } else version (Windows) {
                // for the moment, only do a static library
                if (exists("S" ~ target ~ ".lib")) std.file.remove("S" ~ target ~ ".lib");
                char[] stbl = bl ~ bflags ~ " -explicit -lib -full " ~ fileList ~ " -TS" ~ target ~ ".lib";
                saySystemDie(stbl);
            } else {
                static assert(0);
            }
        
            // do the postbuild
            if ("postbuild" in settings) {
                dsssScriptedStep(conf, settings["postbuild"]);
            }
            
            // unfortunately, at each step we need to move the .di files out of the way, then back
            foreach (file; files) {
                std.file.rename(file ~ "i0", file ~ "i");
            }
            
            // an extra line for clarity
            writefln("");
        }
    }
    
    // 4) Binaries and specials
    foreach (build; buildSources) {
        char[][char[]] settings = conf.settings[build];
        
        // basic info
        char[] type = settings["type"];
        char[] target = settings["target"];
        
        if (type == "binary") {
            // our binary build line
            char[] bflags;
            if ("buildflags" in settings) {
                bflags = settings["buildflags"];
            }
            
            char[] bbl = bl ~ bflags ~ " ";
            
            // output what we're building
            writefln("%s => %s", build, target);
            
            // do the prebuild
            if ("prebuild" in settings) {
                dsssScriptedStep(conf, settings["prebuild"]);
            }
            
            // build a build line
            char[] ext = std.string.tolower(getExt(build));
            if (ext == "d") {
                bbl ~= build ~ " -T" ~ target ~ " ";
            } else if (ext == "brf") {
                bbl ~= "@" ~ getName(build) ~ " ";
            } else {
                writefln("ERROR: I don't know how to build something with extension %s", ext);
                return 1;
            }
            
            // then do it
            saySystemDie(bbl);
            
            // do the postbuild
            if ("postbuild" in settings) {
                dsssScriptedStep(conf, settings["postbuild"]);
            }
            
            // an extra line for clarity
            writefln("");
            
        } else if (type == "special") {
            // special type, do pre/post
            writefln("%s", target);
            if ("prebuild" in settings) {
                dsssScriptedStep(conf, settings["prebuild"]);
            }
            
            if ("postbuild" in settings) {
                dsssScriptedStep(conf, settings["postbuild"]);
            }
            writefln("");
            
        }
    }
    
    return 0;
}
