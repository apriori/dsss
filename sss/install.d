/**
 * DSSS command "install"
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

module sss.install;

import std.file;
import std.stdio;
import std.string;

import hcf.path;
import hcf.process;

import sss.conf;

/** Entry into the "install" command */
int install(char[][] buildElems, DSSSConf conf = null, char[] pname = null, char[][]* subManifest = null)
{
    // get the configuration
    if (conf is null)
        conf = readConfig(buildElems);
    
    // get the corresponding sources
    char[][] buildSources = sourcesByElems(buildElems, conf);
    
    // prepare to make a manifest
    if (pname.length == 0) {
        pname = conf.settings[""]["name"].dup;
    }
    char[][] manifest;
    char[] manifestFile;
    manifestFile = manifestPrefix ~ std.path.sep ~ conf.settings[""]["name"] ~ ".manifest";
    manifest ~= "share" ~ std.path.sep ~ "dsss" ~ std.path.sep ~ "manifest" ~ std.path.sep ~
        pname ~ ".manifest";
    
    /// Copy in the file and add it to the manifest
    void copyAndManifest(char[] file, char[] prefix, char[] from = "")
    {
        copyInFile(file, prefix, from);
        
        // if the prefix starts with the installation prefix, strip it
        if (prefix.length > forcePrefix.length &&
            prefix[0..forcePrefix.length] == forcePrefix)
            prefix = prefix[forcePrefix.length + 1 .. $];
        
        manifest ~= prefix ~ std.path.sep ~ file;
    }
    
    // now install the requested things
    foreach (build; buildSources) {
        char[][char[]] settings = conf.settings[build];
        
        // basic info
        char[] type = settings["type"];
        char[] target = settings["target"];

        // maybe we shouldn't install it
        if ("noinstall" in settings)
            continue;
        
        // say what we're doing
        writefln("Installing %s", target);
        
        // do preinstall
        if ("preinstall" in settings) {
            manifest ~= dsssScriptedStep(conf, settings["preinstall"]);
        }
        
        // figure out what it is
        if (type == "library" && libsSafe()) {
            // far more complicated
            
            // 1) copy in library files
            if (targetGNUOrPosix()) {
                // copy in the .a and .so/.dll files
                
                // 1) .a
                copyAndManifest("libS" ~ target ~ ".a", libPrefix);

                // and perhaps the debug version as well
                if (buildDebug)
                    copyAndManifest("libSdebug-" ~ target ~ ".a", libPrefix);
                
                char[] shlibname = getShLibName(settings);
                
                if (shLibSupport() &&
                    ("shared" in settings)) {
                    if (targetVersion("Posix")) {
                        // 2) .so
                        char[][] shortshlibnames = getShortShLibNames(settings);
                
                        // copy in
                        copyAndManifest(shlibname, libPrefix);
                
                        // make softlinks
                        foreach (ssln; shortshlibnames) {
                            // make it
                            saySystemDie("ln -sf " ~ shlibname ~ " " ~
                                         libPrefix ~ std.path.sep ~ ssln);
                            manifest ~= libPrefix ~ std.path.sep ~ ssln;
                        }
                    } else if (targetVersion("Windows")) {
                        // 2) .dll
                        copyAndManifest(shlibname, libPrefix);
                    } else {
                        assert(0);
                    }
                }
            } else if (targetVersion("Windows")) {
                // copy in the .lib and .dll files
                
                // 1) .lib
                copyAndManifest("S" ~ target ~ ".lib", libPrefix);
                
                char[] shlibname = getShLibName(settings);
                
                if (shLibSupport() &&
                    ("shared" in settings)) {
                    // 2) .dll
                    copyAndManifest(shlibname, libPrefix);
                }
            } else {
                assert(0);
            }
            
            // 2) install generated .di files
            char[][] srcFiles = targetToFiles(build, conf, true);
            foreach (file; srcFiles) {
                // if it's already a .di file, this is simpler
                if (std.string.tolower(getExt(file)) == "di") {
                    copyAndManifest(getBaseName(file),
                                    includePrefix ~ std.path.sep ~ getDirName(file),
                                    getDirName(file) ~ std.path.sep);

                } else {
                    // install the generated .di file
                    copyAndManifest(getBaseName(file ~ "i"),
                                    includePrefix ~ std.path.sep ~ getDirName(file),
                                    "dsss_imports" ~ std.path.sep ~ getDirName(file) ~ std.path.sep);
                }
            }
            
        } else if (type == "binary") {
            // fairly easy
            if (targetVersion("Posix")) {
                copyAndManifest(target, binPrefix);
            } else if (targetVersion("Windows")) {
                copyAndManifest(target ~ ".exe", binPrefix);
            } else {
                assert(0);
            }
            
        } else if (type == "sourcelibrary" ||
                   (type == "library" && !libsSafe())) {
            // also fairly easy
            char[][] srcFiles = targetToFiles(build, conf, true);
            foreach (file; srcFiles) {
                char[] fdir = getDirName(file);
                char[] pdir = fdir.dup;
                if (fdir != "") fdir ~= std.path.sep;
                if (pdir != "") pdir = std.path.sep ~ pdir;
                
                copyAndManifest(getBaseName(file),
                                includePrefix ~ pdir,
                                fdir);
            }
            
        } else if (type == "subdir") {
            // recurse
            char[] origcwd = getcwd();
            chdir(build);
            int installret = install(null, null, pname, &manifest);
            if (installret) return installret;
            chdir(origcwd);
        }
        
        // do postinstall
        if ("postinstall" in settings) {
            manifest ~= dsssScriptedStep(conf, settings["postinstall"]);
        }
        
        // install the manifest itself
        if (subManifest) {
            (*subManifest) ~= manifest;
        } else {
            mkdirP(manifestPrefix);
            std.file.write(manifestFile, std.string.join(manifest, "\n") ~ "\n");
        }
        
        // extra line for clarity
        writefln("");
    }
    
    // then install documentation
    if (doDocs && exists("dsss_docs")) {
        writefln("Installing documentation...");
        
        char[] docs = docPrefix ~ std.path.sep ~ pname;
        mkdirP(docs);
        
        chdir("dsss_docs");
        
        // copy in everything
        void copyDir(char[] cdir)
        {
            char[] subdocs = docs ~ std.path.sep ~ cdir;
            mkdirP(subdocs);
            
            foreach (file; listdir(cdir)) {
                char[] full = cdir ~ std.path.sep ~ file;
                if (isdir(full)) {
                    copyDir(full);
                } else {
                    copyInFile(file, subdocs, cdir ~ std.path.sep);
                }
            }
        }
        
        foreach (file; listdir(".")) {
            if (isdir(file)) {
                copyDir(file);
            } else {
                copyInFile(file, docs);
            }
        }
        
        chdir("..");
    }
    
    return 0;
}
