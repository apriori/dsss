/**
 * DSSS command "uninstall"
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

module sss.uninstall;

import sss.clean;
import sss.conf;

import std.file;
import std.stdio;
import std.string;

/** Entry to the "uninstall" function */
int uninstall(char[][] toolList)
{
    foreach (tool; toolList)
    {
        // uninstall this tool
        char[] manifestFile = manifestPrefix ~ std.path.sep ~ tool ~ ".manifest";
        if (!exists(manifestFile)) {
            writefln("Tool " ~ tool ~ " is not installed.");
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
                writefln("Removing %s", file);
                tryRemove(file);
            }
        }
        
        writefln("");
    }
    
    return 0;
}
