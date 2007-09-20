/**
 * Helpful process functions
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

module hcf.process;

public import std.process;
alias std.process.system system;

import std.stdio;
import std.string;
import std.stream;

import std.c.stdio;
import std.c.stdlib;

private {
    version (Windows) {
        import bcd.windows.windows;
    } else {
        extern (C) int dup2(int, int);
        extern (C) int fork();
        extern (C) int pipe(int[2]);
        extern (C) int read(int, void*, size_t);
        extern (C) int write(int, void*, size_t);
        extern (C) int close(int);
        extern (C) size_t waitpid(size_t, int*, int);
    }
}

class PStream : Stream {
    /** First init step: this, then start the process based on its result */
    void init1()
    {
        readable = true;
        writeable = true;
        seekable = false;
        
        version (Posix) {
            // get our pipes
            pipe(ip);
            pipe(op);
        
            // fork
            pid = fork();
            if (pid == 0) {
                // dup2 in our stdin/out
                dup2(ip[0], 0);
                hcf.process.close(ip[1]);
                dup2(op[1], 1);
                dup2(op[1], 2);
                hcf.process.close(op[0]);
            } else if (pid == -1) {
                // boom!
                throw new StreamException("Failed to fork");
            } else {
                hcf.process.close(ip[0]);
                hcf.process.close(op[1]);
            }
        } else version (Windows) {
            // get our pipes
            _SECURITY_ATTRIBUTES sa;
            sa.nLength = _SECURITY_ATTRIBUTES.sizeof;
            sa.bInheritHandle = 1;
            CreatePipe(&ipr, &ipw, &sa, 0);
            CreatePipe(&opr, &opw, &sa, 0);
            
            // don't fork yet - it'll have to be done by the next step
        }
    }
    
    /** Use system */
    this(char[] command)
    {
        init1();
        
        version (Posix) {
            if (pid == 0) {
                exit(std.process.system(command));
            }
        } else version (Windows) {
            _STARTUPINFOA si;
            si.cb = _STARTUPINFOA.sizeof;
            si.hStdInput = ipr;
            si.hStdOutput = opw;
            si.hStdError = opw;
            si.dwFlags = STARTF_USESTDHANDLES;
            
            _PROCESS_INFORMATION pi;
            
            CreateProcessA(null, toStringz(command), null, null,
                           1, 0, null, null, &si, &pi);
            CloseHandle(ipr);
            CloseHandle(opw);
            CloseHandle(pi.hThread);
            phnd = pi.hProcess;
        }
        
        init2();
    }
    
    /** Use execvp */
    this(char[] pathname, char[][] argv)
    {
        init1();
        
        version (Posix) {
            if (pid == 0) {
                execvp(pathname, argv);
                exit(1);
            }
        } else version(Windows) {
            assert(0);
        }
        
        init2();
    }
    
    /** The second init part */
    void init2()
    {
        isopen = true;
    }
    
    override size_t readBlock(void* buffer, size_t size)
    {
        version (Posix) {
            int rd = hcf.process.read(op[0], buffer, size);
            if (rd == -1) {
                readEOF = true;
                return 0;
            } else {
                readEOF = false;
            }
            return rd;
        } else version (Windows) {
            uint rd;
            if (!ReadFile(opr, buffer, size, &rd, null)) {
                readEOF = true;
                return 0;
            } else {
                readEOF = false;
            }
            return rd;
        }
    }
    
    override size_t writeBlock(void* buffer, size_t size)
    {
        version (Posix) {
            int wt = hcf.process.write(ip[1], buffer, size);
            if (wt == -1) {
                throw new StreamException("Process closed");
            }
            return wt;
        } else version (Windows) {
            uint wt;
            if (!WriteFile(opr, buffer, size, &wt, null)) {
                readEOF = true;
                return 0;
            } else {
                readEOF = false;
            }
            return wt;
        }
    }
    
    override ulong seek(long offset, SeekPos whence)
    {
        throw new StreamException("Cannot seek in PStreams");
    }
    
    /** Close the process, return the result */
    void close()
    {
        if (isopen) {
            isopen = false;
            version (Posix) {
                waitpid(pid, &eval, 0);
                hcf.process.close(ip[1]);
                hcf.process.close(op[0]);
            } else version (Windows) {
                GetExitCodeProcess(phnd, &eval);
                CloseHandle(phnd);
                CloseHandle(ipw);
                CloseHandle(opr);
            }
        }
    }
    
    version (Posix) {
        /** Get the exit value */
        int exitValue()
        {
            return eval;
        }
    } else version (Windows) {
        /** Get the exit value */
        uint exitValue()
        {
            return eval;
        }
    }
    
    private:
    
    version (Posix) {
        /** The pid */
        int pid;
    
        /** The exit value */
        int eval;
    
        /** The input pipe */
        int[2] ip;
    
        /** The output pipe */
        int[2] op;
    } else version (Windows) {
        /** The process handle */
        HANDLE phnd;
        
        /** The exit value */
        uint eval;
    
        /** The input pipe */
        HANDLE ipr, ipw;
        
        /** The output pipe */
        HANDLE opr, opw;
    }
}

/** Exception to be thrown when a command called dies */
class ProcessDeathException : Exception {
    this(char[] smsg)
    {
        super(smsg);
    }
}

/** system + guarantee success */
void systemOrDie(char[] cmd)
{
    int res;
    fflush(stdout); fflush(stderr);
    res = system(cmd);
    if (res)  // CyberShadow 2007.02.22: Display a message before exiting
    {
        int p = cmd.find(' ');
        if(p!=-1) cmd=cmd[0..p];
        writefln("Command " ~ cmd ~ " returned with code ", res, ", aborting.");
        throw new ProcessDeathException("Command failed, aborting.");
    }
}

/** system + output */
int sayAndSystem(char[] cmd)
{
    writefln("+ %s", cmd);
    fflush(stdout); fflush(stderr);
    return system(cmd);
}

/** systemOrDie + output */
void saySystemDie(char[] cmd)
{
    writefln("+ %s", cmd);
    systemOrDie(cmd);
}

/** system + use a response file */
int systemResponse(char[] cmd, char[] rflag, char[] rfile, bool deleteRFile)
{
    int ret;
    char[][] elems = std.string.split(cmd, " ");
    
    /* the output is elems past 1 joined with \n */
    char[] resp = std.string.join(elems[1..$], "\n");
    std.file.write(rfile, resp);
    
    fflush(stdout); fflush(stderr);
    ret = system(elems[0] ~ " " ~ rflag ~ rfile);
    
    if (deleteRFile) std.file.remove(rfile);
    
    return ret;
}

/** systemResponse + guarantee success */
void systemROrDie(char[] cmd, char[] rflag, char[] rfile, bool deleteRFile)
{
    int res;
    res = systemResponse(cmd, rflag, rfile, deleteRFile);
    if (res)  // CyberShadow 2007.02.22: Display a message before exiting
    {
        int p = cmd.find(' ');
        if(p!=-1) cmd=cmd[0..p];
        writefln("Command " ~ cmd ~ " returned with code ", res, ", aborting.");
        throw new ProcessDeathException("Command failed, aborting.");
    }
}

/** systemResponse + output */
int sayAndSystemR(char[] cmd, char[] rflag, char[] rfile, bool deleteRFile)
{
    writefln("+ %s", cmd);
    return systemResponse(cmd, rflag, rfile, deleteRFile);
}

/** systemROrDie + output */
void saySystemRDie(char[] cmd, char[] rflag, char[] rfile, bool deleteRFile)
{
    writefln("+ %s", cmd);
    systemROrDie(cmd, rflag, rfile, deleteRFile);
}
