/**
 * Helpful environment functions
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

module hcf.env;

import std.string;

import std.c.stdlib;

version (Windows) {
    import bcd.windows.windows;
}

/** Get an environment variable D-ly */
char[] getEnvVar(char[] var)
{
    version (Posix) {
        return toString(
            getenv(toStringz(var)));
    } else version (Windows) {
        char[1024] buffer;
        buffer[0] = '\0';
        GetEnvironmentVariableA(
                toStringz(var),
                buffer,
                1024);
        return toString(buffer);
    } else {
        static assert(0);
    }
}

/** Set an environment variable D-ly */
void setEnvVar(char[] var, char[] val)
{
    version (Posix) {
        setenv(toStringz(var),
               toStringz(val),
               1);
    } else version(Windows) {
        SetEnvironmentVariableA(
            toStringz(var),
            toStringz(val));
    } else {
        static assert(0);
    }
}
