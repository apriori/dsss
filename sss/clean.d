/**
 * DSSS commands "clean" an "distclean"
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

module sss.clean;

import std.file;
import std.path;
import std.stdio;
import std.string;

import sss.build;
import sss.conf;

/** A utility function to attempt removal of a file but not fail on error */
void tryRemove(char[] fn)
{
    try {
        std.file.remove(fn);
    } catch (Exception e) {
        // ignored
    }
}

/** The entry function to the DSSS "clean" command */
int clean(DSSSConf conf = null) {
    // fairly simple
    foreach (dire; listdir(".")) {
        char[] ext = std.string.tolower(getExt(dire));
        if (ext == "o" ||
            ext == "obj") {
            writefln("Removing %s", dire);
            std.file.remove(dire);
        }
    }
    
    return 0;
}

/** The entry function to the DSSS "distclean" command */
int distclean(DSSSConf conf = null)
{
    // get the configuration
    if (conf is null)
        conf = readConfig(null);
    
    // distclean implies clean
    int res = clean(conf);
    if (res) return res;
    writefln("");
    
    // get the sources
    char[][] buildSources = sourcesByElems(null, conf);
    
    // then go through and delete actual files
    foreach (build; buildSources) {
        char[][char[]] settings = conf.settings[build];
        
        // basic info
        char[] type = settings["type"];
        char[] target = settings["target"];
        
        // tell what we're doing
        writefln("Removing %s", target);
        
        // do the preclean step
        if ("preclean" in settings) {
            dsssScriptedStep(settings["preclean"]);
        }
        
        if (type == "library") {
            // remove the .di files ...
            char[][] files = targetToFiles(build, conf);
            foreach (file; files) {
                tryRemove(file ~ "i");
                tryRemove(file ~ "i0");
            }
            
            version (GNU_or_Posix) {
                // first remove the static library
                tryRemove("libS" ~ target ~ ".a");
                
                // then remove the shared libraries
                char[] shlibname = getShLibName(settings);
                char[][] shortshlibnames = getShortShLibNames(settings);
                
                tryRemove(shlibname);
                foreach (ssln; shortshlibnames) {
                    tryRemove(ssln);
                }
                
            } else version (Windows) {
                // first remove
                tryRemove("S" ~ target ~ ".lib");
                
                // then remove the shared libraries
                char[] shlibname = getShLibName(settings);
                char[][] shortshlibnames = getShortShLibNames(settings);
                
                tryRemove(shlibname);
                foreach (ssln; shortshlibnames) {
                    tryRemove(ssln);
                }
            } else {
                static assert(0);
            }
            
        } else if (type == "binary") {
            version (Posix) {
                tryRemove(target);
            } else version (Windows) {
                tryRemove(target ~ ".exe");
            } else {
                static assert(0);
            }
        }
        
        // do the postclean step
        if ("postclean" in settings) {
            dsssScriptedStep(settings["postclean"]);
        }
        
        writefln("");
    }
    
    // and the lastbuild file if it exists
    if (exists(configLBName)) {
        tryRemove(configLBName);
    }
    
    return 0;
}
