/**
 * DSSS commands "clean" an "distclean"
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
            
        } else if (type == "subdir") {
            // recurse
            char[] origcwd = getcwd();
            chdir(build);
            int cleanret = distclean();
            if (cleanret) return cleanret;
            chdir(origcwd);
            
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
