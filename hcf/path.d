/**
 * Helpful path functions
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

module hcf.path;

public import std.path;

import std.stdio;
import std.file;
import std.string;

import std.c.stdlib;

version (Windows) {
    import bcd.windows.windows;
}

/** Get the system PATH */
char[][] getPath()
{
    return split(toString(getenv("PATH")), std.path.pathsep);
}

/** From args[0], figure out our path.  Returns 'false' on failure */
bool whereAmI(char[] argvz, inout char[] dir, inout char[] bname)
{
    // split it
    bname = getBaseName(argvz);
    dir = getDirName(argvz);
    
    // on Windows, this is a .exe
    version (Windows) {
        bname = defaultExt(bname, "exe");
    }
    
    // is this a directory?
    if (dir != "") {
        if (!std.path.isabs(dir)) {
            // make it absolute
            dir = getcwd() ~ std.path.sep ~ dir;
        }
        return true;
    }
    
    version (Windows) {
        // is it in cwd?
        char[] cwd = getcwd();
        if (exists(cwd ~ std.path.sep ~ bname)) {
            dir = cwd;
            return true;
        }
    }
    
    // rifle through the path
    char[][] path = getPath();
    foreach (pe; path) {
        char[] fullname = pe ~ std.path.sep ~ bname;
        if (exists(fullname)) {
            version (Windows) {
                dir = pe;
                return true;
            } else {
                if (getAttributes(fullname) & 0100) {
                    dir = pe;
                    return true;
                }
            }
        }
    }
    
    // bad
    return false;
}

/// Return a canonical pathname
char[] canonPath(char[] origpath)
{
    char[] ret;
    
    // replace any altsep with sep
    if (altsep.length) {
        ret = replace(origpath, altsep, sep);
    } else {
        ret = origpath.dup;
    }
    
    // expand tildes
    ret = expandTilde(ret);
    
    // get rid of any duplicate separators
    for (int i = 0; i < ret.length; i++) {
        if (ret[i .. (i + 1)] == sep) {
            // drop the duplicate separator
            i++;
            while (i < ret.length &&
                   ret[i .. (i + 1)] == sep) {
                ret = ret[0 .. i] ~ ret[(i + 1) .. $];
            }
        }
    }
    
    // make sure we don't miss a .. element
    if (ret.length > 3 && ret[($-3) .. $] == std.path.sep ~ "..") {
        ret ~= std.path.sep;
    }
    
    // or a . element
    if (ret.length > 2 && ret[($-2) .. $] == std.path.sep ~ ".") {
        ret ~= std.path.sep;
    }
    
    // search for .. elements
    for (int i = 0; ret.length > 4 && i <= ret.length - 4; i++) {
        if (ret[i .. (i + 4)] == std.path.sep ~ ".." ~ std.path.sep) {
            // drop the previous path element
            int j;
            for (j = i - 1; j > 0 && ret[j..(j+1)] != std.path.sep; j--) {}
            if (j > 0) {
                // cut
                ret = ret[0..j] ~ ret[(i + 3) .. $];
            } else {
                // sort of ridiculous, but cut as best we can
                ret = std.path.sep ~ ret[(i + 3) .. $];
            }
            i = j - 1;
        }
    }
    
    // search for . elements
    for (int i = 0; ret.length > 2 && i <= ret.length - 3; i++) {
        if (ret[i .. (i + 3)] == std.path.sep ~ "." ~ std.path.sep) {
            // drop this path element
            ret = ret[0..i] ~ ret[(i + 2) .. $];
            i--;
        }
    }
    
    // finally, get rid of any trailing separators
    while (ret.length &&
           ret[($ - 1) .. $] == sep) {
        ret = ret[0 .. ($ - 1)];
    }
    
    return ret;
}

/** Make a directory and all parent directories */
void mkdirP(char[] dir)
{
    dir = canonPath(dir);
    version (Windows) {
        dir = std.string.replace(dir, "/", "\\");
    }
    
    // split it into elements
    char[][] dires = split(dir, sep);
    
    char[] curdir;
    
    // check for root dir
    if (dires.length &&
        dires[0] == "") {
        curdir = std.path.sep;
        dires = dires[1..$];
    }
    
    // then go piece-by-piece, making directories
    foreach (dire; dires) {
        if (curdir.length) {
            curdir ~= sep ~ dire;
        } else {
            curdir ~= dire;
        }
        
        if (!exists(curdir)) {
            mkdir(curdir);
        }
    }
}

/** Remove a file or directory and all of its children */
void rmRecursive(char[] name)
{
    // can only delete writable files on Windows
    version (Windows) {
        SetFileAttributesA(toStringz(name),
                           GetFileAttributesA(toStringz(name)) &
                           ~FILE_ATTRIBUTE_READONLY);
    }
    
    if (isdir(name)) {
        foreach (elem; listdir(name)) {
            // don't delete . or ..
            if (elem == "." ||
                elem == "..") continue;
            rmRecursive(name ~ std.path.sep ~ elem);
        }
        
        // remove the directory itself
        rmdir(name);
    } else {
        std.file.remove(name);
    }
}
