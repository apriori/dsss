/**
 * DSSS commands "clean" an "distclean"
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

module sss.clean;

import std.file;
import std.path;
import std.stdio;
import std.string;

import sss.conf;

import hcf.path;

/** A utility function to attempt removal of a file but not fail on error */
void tryRemove(char[] fn)
{
    try {
        std.file.remove(fn);
    } catch (Exception e) {
        // ignored
    }
}

/** Clean a tree: Remove all empty directories in the tree */
void cleanTree(char[] dirn)
{
    try {
        rmdir(dirn);
        cleanTree(getDirName(dirn));
    } catch (Exception e) {
        // ignored
    }
}

/** The entry function to the DSSS "clean" command */
int clean(DSSSConf conf = null) {
    // fairly simple, get rid of easy things - dsss_objs and dsss_imports
    if (exists("dsss_objs"))
        rmRecursive("dsss_objs");
    if (exists("dsss_imports"))
        rmRecursive("dsss_imports");
    if (exists("dsss_docs"))
        rmRecursive("dsss_docs");
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
            dsssScriptedStep(conf, settings["preclean"]);
        }
        
        if (type == "library" || type == "sourcelibrary") {
            if (targetGNUOrPosix()) {
                // first remove the static library
                tryRemove("libS" ~ target ~ ".a");
                
                // then remove the shared libraries
                char[] shlibname = getShLibName(settings);
                char[][] shortshlibnames = getShortShLibNames(settings);
                
                tryRemove(shlibname);
                foreach (ssln; shortshlibnames) {
                    tryRemove(ssln);
                }
                
            } else if (targetVersion("Windows")) {
                // first remove the static library
                tryRemove("S" ~ target ~ ".lib");
                
                // then remove the shared libraries
                char[] shlibname = getShLibName(settings);
                char[][] shortshlibnames = getShortShLibNames(settings);
                
                tryRemove(shlibname);
                foreach (ssln; shortshlibnames) {
                    tryRemove(ssln);
                }
            } else {
                assert(0);
            }
            
        } else if (type == "binary") {
            if (targetVersion("Posix")) {
                tryRemove(target);
            } else if (targetVersion("Windows")) {
                tryRemove(target ~ ".exe");
            } else {
                assert(0);
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
            dsssScriptedStep(conf, settings["postclean"]);
        }
        
        writefln("");
    }
    
    // and the lastbuild file if it exists
    if (exists(configLBName)) {
        tryRemove(configLBName);
    }
    
    return 0;
}
