/**
 * DSSS command "install"
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

module sss.install;

import std.file;
import std.stdio;
import std.string;

import hcf.path;
import hcf.process;

import sss.conf;

/** Entry into the "install" command */
int install(char[][] buildElems)
{
    // get the configuration
    DSSSConf conf = readConfig(buildElems);
    
    // get the corresponding sources
    char[][] buildSources = sourcesByElems(buildElems, conf);
    
    // prepare to make a manifest
    char[][] manifest;
    char[] manifestFile;
    manifestFile = manifestPrefix ~ std.path.sep ~ conf.settings[""]["name"] ~ ".manifest";
    manifest ~= manifestFile;
    
    /// Copy in the file and add it to the manifest
    void copyAndManifest(char[] file, char[] prefix, char[] from = "")
    {
        copyInFile(file, prefix, from);
        manifest ~= prefix ~ std.path.sep ~ file;
    }
    
    // now install the requested things
    foreach (build; buildSources) {
        char[][char[]] settings = conf.settings[build];
        
        // basic info
        char[] type = settings["type"];
        char[] target = settings["target"];

        // say what we're doing
        writefln("Installing %s", target);
        
        // do preinstall
        if ("preinstall" in settings) {
            dsssScriptedStep(settings["preinstall"]);
        }
        
        // figure out what it is
        if (type == "library") {
            // far more complicated
            
            // 1) copy in library files
            version (GNU_or_Posix) {
                // copy in the .a and .so/.dll files
                
                // 1) .a
                copyAndManifest("libS" ~ target ~ ".a", libPrefix);
                
                char[] shlibname = getShLibName(settings);
                
                if (shLibSupport() &&
                    ("shared" in settings)) {
                    version (Posix) {
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
                    } else version (Windows) {
                        // 2) .dll
                        copyAndManifest(shlibname, libPrefix);
                    } else {
                        static assert(0);
                    }
                }
            } else version (Windows) {
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
                static assert(0);
            }
            
            // 2) generate .di files
            char[][] srcFiles = targetToFiles(build, conf);
            foreach (file; srcFiles) {
                // install the .di file
                copyAndManifest(getBaseName(file ~ "i"),
                                includePrefix ~ std.path.sep ~ getDirName(file),
                                getDirName(file) ~ std.path.sep);
            }
            
        } else if (type == "binary") {
            // fairly easy
            version (Posix) {
                copyAndManifest(target, binPrefix);
            } else {
                copyAndManifest(target ~ ".exe", binPrefix);
            }
        }
        
        // do postinstall
        if ("postinstall" in settings) {
            dsssScriptedStep(settings["postinstall"]);
        }
        
        // install the manifest itself
        mkdirP(manifestPrefix);
        std.file.write(manifestFile, std.string.join(manifest, "\n") ~ "\n");
        
        // extra line for clarity
        writefln("");
    }
    
    return 0;
}
