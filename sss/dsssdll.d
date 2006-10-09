/**
 * DSSS stubbed DLLMain (used to build any library as a DLL)
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

import std.c.stdio;
import std.c.stdlib;
import std.string;
import std.c.windows.windows;
import std.gc;

HINSTANCE   g_hInst;

extern (C)
{
	void _minit();
	void _moduleCtor();
	void _moduleDtor();
}

extern (Windows) BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
    switch (ulReason)
    {
        case DLL_PROCESS_DETACH:
	    std.c.stdio._fcloseallp = null;
	    break;
    }
    g_hInst = hInstance;
    return true;
}

export void DLL_Initialize(void* gc)
{
    std.gc.setGCHandle(gc);
    _minit();
    _moduleCtor();
}

export void DLL_Terminate()
{
    _moduleDtor();
    std.gc.endGCHandle();
}
