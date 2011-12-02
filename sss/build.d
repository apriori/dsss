/**
 * DSSS command "build"
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

module sss.build;

import std.file;
import std.process;
import std.stdio;
import std.array;
import std.string;

import std.c.stdlib;

import hcf.path;
import hcf.process;

import sss.conf;
import sss.system;

/** The entry function to the DSSS "build" command */
int build(string[] buildElems, DSSSConf conf = null, string forceFlags = "") {
    // get the configuration
    if (conf is null)
        conf = readConfig(buildElems);
    
    // buildElems are by either soure or target, so we need one by source only
    string[] buildSources;
    
    // get the sources
    buildSources = sourcesByElems(buildElems, conf);
    
    // also get a complete list, since some steps need it
    string[] allSources = sourcesByElems(null, conf);
    
    /* building is fairly complicated, involves these steps:
     * 1) Make .di files
     *    (so that you link against your own libraries)
     * 2) Make fake shared libraries
     *    (they need to exist so that other libraries can link against them)
     * 3) Make real shared libraries
     * 4) Make binaries
     */
    
    // make the basic build line
    string bl = dsss_build ~ forceFlags ~ " ";
    
    // add -oq if we don't have such a setting
    if (indexOf(forceFlags, "-o") == -1) {
        mkdirP("dsss_objs" ~ std.path.sep ~ compilerShort());
        bl ~= "-oqdsss_objs" ~ std.path.sep ~ compilerShort() ~ " ";
    }
    
    // 1) Make .di files for everything
    foreach (build; allSources) {
        string[string] settings = conf.settings[build];
        
        // basic info
        string type = settings["type"];
        string target = settings["target"];
        
        if (type == "library" && libsSafe()) {
            writefln("Creating imports for %s", target);
            
            // do the predigen
            if ("predigen" in settings) {
                dsssScriptedStep(conf, settings["predigen"]);
            }
            
            // this is a library, so make .di files
            string[] srcFiles = targetToFiles(build, conf);
            
            // generate .di files
            foreach (file; srcFiles) {
                string ifile = "dsss_imports" ~ std.path.sep ~ file ~ "i";
                if (!exists(ifile) ||
                    fileNewer(file, ifile)) {
                    /* BIG FAT NOTE slash FIXME:
                     * .di files do NOT include interfaces! So, we need to just
                     * cast .d files as .di until that's fixed */
                    mkdirP(getDirName(ifile));
                    
                    // now edit the .di file to reference the appropriate library
                    
                    // usname = name_with_underscores
                    string usname = replace(build, std.path.sep, "_");

                    // if we aren't building a debug library, the debug conditional will fall through
                    string debugPrefix = null;
                    if (buildDebug)
                        debugPrefix = "debug-";
                    
                    /* generate the pragmas (FIXME: this should be done in a
                     * nicer way) */
                    string defaultLibName = libraryName(build);
                    if (defaultLibName == target) {
                        std.file.write(ifile, std.file.read(file) ~ `
version (build) {
    debug {
        version (GNU) {
            pragma(link, "` ~ debugPrefix ~ `DG` ~ target[2..$] ~ `");
        } else version (DigitalMars) {
            pragma(link, "` ~ debugPrefix ~ `DD` ~ target[2..$] ~ `");
        } else {
            pragma(link, "` ~ debugPrefix ~ `DO` ~ target[2..$] ~ `");
        }
    } else {
        version (GNU) {
            pragma(link, "DG` ~ target[2..$] ~ `");
        } else version (DigitalMars) {
            pragma(link, "DD` ~ target[2..$] ~ `");
        } else {
            pragma(link, "DO` ~ target[2..$] ~ `");
        }
    }
}
`);
                    } else {
                        std.file.write(ifile, std.file.read(file) ~ `
version (build) {
    debug {
        pragma(link, "` ~ debugPrefix ~ target ~ `");
    } else {
        pragma(link, "` ~ target ~ `");
    }
}
`);
                    }
                }
            }
            
            // do the postdigen
            if ("postdigen" in settings) {
                dsssScriptedStep(conf, settings["postdigen"]);
            }
            
            writefln("");
            
        }
    }
    
    // 2) Make fake shared libraries
    writeln("shared libs");
    if (shLibSupport()) {
        foreach (build; allSources) {
            string[string] settings = conf.settings[build];
            
            // ignore this if we're not building a shared library
            if (!("shared" in settings)) continue;
        
            // basic info
            string type = settings["type"];
            string target = settings["target"];
        
            if (type == "library" && libsSafe()) {
                string shlibname = getShLibName(settings);
                string[] shortshlibnames = getShortShLibNames(settings);
                string shlibflag = getShLibFlag(settings);

                if (exists(shlibname)) continue;
                
                writefln("Building stub shared library for %s", target);
                
                // make the stub
                if (targetGNUOrPosix()) {
                    string stubbl = bl ~ "-fPIC -shlib " ~ stubDLoc ~ " -of" ~ shlibname ~
                        " " ~ shlibflag;
                    vSaySystemRDie(stubbl, "-rf", shlibname ~ "_stub.rf", deleteRFiles);
                    if (targetVersion("Posix")) {
                        foreach (ssln; shortshlibnames) {
                            vSaySystemDie("ln -sf " ~ shlibname ~ " " ~ ssln);
                        }
                    }
                } else {
                    assert(0);
                }
                
                writefln("");
            }
        }
    }

    string docbl = "";
    /// A function to prepare for creating documentation for this build
    void prepareDocs(string build, bool doc) {
        // prepare for documentation
        docbl = "";
        if (doc) {
            string docdir = "dsss_docs" ~ std.path.sep ~ build;
            mkdirP(docdir);
            docbl ~= "-full -Dq" ~ docdir ~ " -candydoc ";
        
            // now extract candydoc there
            string origcwd = getcwd();
            chdir(docdir);
        
            version (Windows) {
                vSayAndSystem("bsdtar -xf " ~ candyDocPrefix);
            } else {
                vSayAndSystem("gunzip -c " ~ candyDocPrefix ~ " | tar -xf -");
            }
        
            chdir(origcwd);
        }
    }

    // 3) Make real libraries and do special steps and subdirs
    writeln("make real libraries");
    foreach (build; buildSources) {
        string[string] settings = conf.settings[build];
        
        // basic info
        string type = settings["type"];
        string target = settings["target"];
        
        if (type == "library" || type == "sourcelibrary") {
            string dotname = replace(build, std.path.sep, ".");
            
            // get the list of files
            string[] files = targetToFiles(build, conf);
            
            // and other necessary data
            string bflags, debugflags, releaseflags;
            if ("buildflags" in settings) {
                bflags = settings["buildflags"] ~ " ";
            }
            if ("debugflags" in settings) {
                debugflags = settings["debugflags"] ~ " ";
            } else {
                debugflags = "-debug -gc ";
            }
            if ("releaseflags" in settings) {
                releaseflags = settings["releaseflags"] ~ " ";
            }
            
            // output what we're building
            writefln("%s => %s", build, target);
            if (files.length == 0) {
                writefln("WARNING: Section %s has no files.", build);
                continue;
            }

            // prepare to do documentation
            prepareDocs(build, doDocs);
        
            // do the prebuild
            if ("prebuild" in settings) {
                dsssScriptedStep(conf, settings["prebuild"]);
            }
            
            // get the file list
            string fileList = std.string.join(targetToFiles(build, conf), " ");
            
            // if we should, build the library
            if ((type == "library" && libsSafe()) ||
                doDocs /* need to build the library to get docs */ ||
                testLibs /* need to build the ilbrary to test it */) {

                writeln("buildlibrary called");
                
                if (buildDebug)
                {
                    buildLibrary("debug-" ~ target, bl, bflags ~ debugflags, docbl, fileList, settings);
                }
                buildLibrary(target, bl, bflags ~ releaseflags, docbl, fileList, settings);
            }
        
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
            
        } else if (type == "subdir") {
            // recurse
            string origcwd = getcwd();
            chdir(build);
            
            // the one thing that's passed in is build flags
            string orig_dsss_build = dsss_build;
            if ("buildflags" in settings) {
                dsss_build ~= settings["buildflags"] ~ " ";
            }
            
            int buildret = sss.build.build(null);
            chdir(origcwd);
            
            dsss_build = orig_dsss_build;
            
        }         
    }
    
    // 4) Binaries
    writeln("binaries");
    foreach (build; buildSources) {
        string[string] settings = conf.settings[build];
        
        // basic info
        string bfile = build;
        string type = settings["type"];
        string target = settings["target"];
        sizediff_t bfileplus = indexOf(bfile, '+');
        if (bfileplus != -1) {
            bfile = bfile[0..bfileplus];
        }
        
        if (type == "binary") {
            // our binary build line
            string bflags;
            if ("buildflags" in settings) {
                bflags = settings["buildflags"];
            }
            if (buildDebug) {
                if ("debugflags" in settings) {
                    bflags ~= " " ~ settings["debugflags"];
                } else {
                    bflags ~= " -debug -gc";
                }
            } else {
                if ("releaseflags" in settings) {
                    bflags ~= " " ~ settings["releaseflags"];
                }
            }
            
            string bbl = bl ~ bflags ~ " ";
            
            // output what we're building
            writefln("%s => %s", bfile, target);

            // prepare for documentation
            prepareDocs(build, doDocs && doDocBinaries);
            bbl ~= docbl;
            
            // do the prebuild
            if ("prebuild" in settings) {
                dsssScriptedStep(conf, settings["prebuild"]);
            }
            
            // build a build line
            string ext = std.string.tolower(getExt(bfile));
            if (ext == "d") {
                bbl ~= bfile ~ " -of" ~ target ~ " ";
            } else if (ext == "brf") {
                bbl ~= "@" ~ getName(bfile) ~ " ";
            } else {
                writefln("ERROR: I don't know how to build something with extension %s", ext);
                return 1;
            }
            
            // then do it
            vSaySystemRDie(bbl, "-rf", target ~ ".rf", deleteRFiles);
            
            // do the postbuild
            if ("postbuild" in settings) {
                dsssScriptedStep(conf, settings["postbuild"]);
            }
            
            // an extra line for clarity
            writefln("");
            
        }
        writeln("binaries done");
    }
    
    return 0;
}

/**
 * Helper function to build libraries
 *
 * Params:
 *  target   = target file name (minus platform-specific parts)
 *  bl       = the base build line
 *  bflags   = build flags
 *  docbl    = build flags for documentation ("" for no docs)
 *  fileList = list of files to be compiled into the library
 *  settings = settings for this section from DSSSConf
 */
void buildLibrary(string target, string bl, string bflags, string docbl,
                 string fileList, string[string] settings)
{
    string shlibname = getShLibName(settings);
    string[] shortshlibnames = getShortShLibNames(settings);
    string shlibflag = getShLibFlag(settings);

    if (targetGNUOrPosix()) {
        // first do a static library
        if (exists("lib" ~ target ~ ".a")) std.file.remove("lib" ~ target ~ ".a");
        string stbl = bl ~ docbl ~ bflags ~ " -explicit -lib " ~ fileList ~ " -oflib" ~ target ~ ".a";
        if (testLibs || (shLibSupport() && ("shared" in settings)))
            stbl ~= " -full";
        vSaySystemRDie(stbl, "-rf", target ~ "_static.rf", deleteRFiles);

        // perhaps test the static library
        if (testLibs) {
            writefln("Testing %s", target);
            string tbl = bl ~ bflags ~ " -unittest -full " ~ fileList ~ " " ~ dsssLibTestDPrefix ~ " -oftest_" ~ target;
            vSaySystemRDie(tbl, "-rf", target ~ "_test.rf", deleteRFiles);
            vSaySystemDie("./test_" ~ target);
        }
        
        if (shLibSupport() &&
            ("shared" in settings)) {
            // then make the shared library
            if (exists(shlibname)) std.file.remove(shlibname);
            string shbl = bl ~ bflags ~ " -fPIC -explicit -shlib -full " ~ fileList ~ " -of" ~ shlibname ~
            " " ~ shlibflag;
            
            // finally, the shared compile
            vSaySystemRDie(shbl, "-rf", target ~ "_shared.rf", deleteRFiles);
        }
        
    } else if (targetVersion("Windows")) {
        // for the moment, only do a static library
        if (exists(target ~ ".lib")) std.file.remove(target ~ ".lib");
        string stbl = bl ~ docbl ~ bflags ~ " -explicit -lib " ~ fileList ~ " -of" ~ target ~ ".lib";
        if (testLibs)
            stbl ~= " -full";
        vSaySystemRDie(stbl, "-rf", target ~ "_static.rf", deleteRFiles);

        // perhaps test the static library
        if (testLibs) {
            writefln("Testing %s", target);
            string tbl = bl ~ bflags ~ " -unittest -full " ~ fileList ~ " " ~ dsssLibTestDPrefix ~ " -oftest_" ~ target ~ ".exe";
            vSaySystemRDie(tbl, "-rf", target ~ "_test.rf", deleteRFiles);
            vSaySystemDie("test_" ~ target ~ ".exe");
        }

    } else {
        assert(0);
    }
}
