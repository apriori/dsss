/**
 * DSSS helper script to check out mango
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

module getmango;

import std.file;
import std.process;

int main()
{
    if (exists("mango")) return 0;
    
    int svnret = system("svn co http://svn.dsource.org/projects/mango/trunk/mango");
    if (svnret) return svnret;
    
    return system("patch -p0 -i mango.diff -f");
}
