/**
 * DSSS stubbed DLLMain (used to build any library as a DLL)
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

version (DSSSDLL) {
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
    
    void DLL_Initialize(void* gc)
    {
        std.gc.setGCHandle(gc);
        _minit();
        _moduleCtor();
    }
    
    void DLL_Terminate()
    {
        _moduleDtor();
        std.gc.endGCHandle();
    }
    
    version (build) {
        pragma(link, "kernel32");
    }
}
