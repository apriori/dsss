/**
 * DSSS command "uninstall"
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

module sss.uninstall;

import sss.clean;
import sss.conf;

import std.file;
import std.path;
import std.stdio;
import std.string;

/** Entry to the "uninstall" function */
int uninstall(char[][] toolList, bool quiet = false)
{
    if (toolList.length == 0) {
        writefln("Uninstall what?");
        return 1;
    }
    
    foreach (tool; toolList)
    {
        // uninstall this tool
        char[] manifestFile = manifestPrefix ~ std.path.sep ~ tool ~ ".manifest";
        if (!exists(manifestFile)) {
            if(!quiet)
            	writefln("Package " ~ tool ~ " is not installed.");
            return 1;
        }
        
        writefln("Uninstalling %s", tool);
        
        // get the list
        char[][] manifest = std.string.split(
            cast(char[]) std.file.read(manifestFile),
            "\n");
        
        // then delete them
        foreach (file; manifest) {
            if (file != "") {
                // if it's not absolute, infer the absolute path
                if (!isabs(file)) {
                    file = forcePrefix ~ std.path.sep ~ file;
                }
                
                writefln("Removing %s", file);
                tryRemove(file);
                cleanTree(getDirName(file));
            }
        }
        
        writefln("");
    }
    
    return 0;
}

/** Entry to the "installed" function */
int installed()
{
    foreach (pkg; listdir(manifestPrefix).sort)
    {
        if (pkg.length < 9 || pkg[$-9 .. $]  != ".manifest") continue;
        pkg = pkg[0 .. $-9];
        
        writefln("%s", pkg);
    }
    
    return 0;
}
