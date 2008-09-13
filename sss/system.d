/**
 * System functions, tempered by conf.verboseMode.
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

module sss.system;

import hcf.process;

import sss.conf;

/** system + output */
int vSayAndSystem(char[] cmd)
{
    if (verboseMode)
        return sayAndSystem(cmd);
    else
        return system(cmd);
}

/** systemOrDie + output */
void vSaySystemDie(char[] cmd)
{
    if (verboseMode)
        saySystemDie(cmd);
    else
        systemOrDie(cmd);
}

/** systemResponse + output */
int vSayAndSystemR(char[] cmd, char[] rflag, char[] rfile, bool deleteRFile)
{
    if (verboseMode)
        return sayAndSystemR(cmd, rflag, rfile, deleteRFile);
    else
        return systemResponse(cmd, rflag, rfile, deleteRFile);
}

/** systemROrDie + output */
void vSaySystemRDie(char[] cmd, char[] rflag, char[] rfile, bool deleteRFile)
{
    if (verboseMode)
        saySystemRDie(cmd, rflag, rfile, deleteRFile);
    else
        systemROrDie(cmd, rflag, rfile, deleteRFile);
}
