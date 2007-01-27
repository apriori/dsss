
// Component to read configuration
// Copyright (c) 2007  Gregor Richards
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt
// or any later version.
// See the included readme.txt for details.

#include <iostream>
using namespace std;

extern "C" {
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
}

#if __WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <unistd.h>
#endif

#include "config.h"
#include "mars.h"
#include "whereami.h"

#define exists(x) (!access((x), F_OK))
#if __WIN32
#define DIRSEP "\\"
#else
#define DIRSEP "/"
#endif

Config masterConfig;

std::string compileFlags;
std::string linkFlags;

void readConfigFile(const string &dir, const string &fname);

void readConfig(char *argvz, const string &profile)
{
    // find where we're installed
    char *dir, *file;
    if (!whereAmI(argvz, &dir, &file)) {
        cerr << "Could not determine installed location!" << endl;
        exit(1);
    }
    
    // then look for appropriate directories
    string confdir;
#ifndef __WIN32
    confdir = string(getenv("HOME")) + DIRSEP ".rebuild";
    if (exists(confdir.c_str())) goto founddir;
#endif
    
    confdir = string(dir) + DIRSEP "rebuild.conf";
    if (exists(confdir.c_str())) goto founddir;
    
    confdir = string(dir) + DIRSEP ".." DIRSEP "etc" DIRSEP "rebuild";
    if (exists(confdir.c_str())) goto founddir;
    
#ifndef __WIN32
    confdir = "/etc/rebuild";
    if (exists(confdir.c_str())) goto founddir;
#else
    confdir = "C:\\rebuild.conf";
    if (exists(confdir.c_str())) goto founddir;
#endif
    
    cerr << "Cannot find a rebuild configuration directory." << endl;
    exit(1);
    
    
founddir:
    // OK, now look for the profile
    string conffile = confdir + DIRSEP + profile;
    if (!exists(conffile.c_str())) {
        cerr << "Profile '" << profile << "' does not exist." << endl;
        exit(1);
    }
    
    // OK, read it
    readConfigFile(confdir, conffile);
}

// read in a configuration file
void readConfigFile(const string &dir, const string &fname)
{
    string section = "";
    
    FILE *cfile = fopen(fname.c_str(), "r");
    if (!cfile) {
        cerr << "Failed to open " << fname << endl;
        exit(1);
    }
    
    // the read buffer
#define READBUFSIZ 1024
    char readBuf[READBUFSIZ + 1];
    readBuf[READBUFSIZ] = '\0';
    int readLen;
    
    // read lines
    while (!feof(cfile) && !ferror(cfile)) {
        if (!fgets(readBuf, READBUFSIZ, cfile)) break;
        
        // strip off line ending
        readLen = strlen(readBuf);
        while (readLen > 0 &&
               (readBuf[readLen - 1] == '\n' ||
                readBuf[readLen - 1] == '\r')) {
            readLen--;
            readBuf[readLen] = '\0';
        }
        
        if (readLen == 0 ||
            readBuf[0] == '#') continue;
        
        // if it's [...], it's a section
        if (readBuf[0] == '[' &&
            readBuf[readLen - 1] == ']') {
            readBuf[readLen - 1] = '\0';
            section = readBuf + 1;
            
        } else {
            // separate it into setting=value
            char *val;
            if (val = strchr(readBuf, '=')) {
                *val = '\0';
                val++;
            
                // set it or possibly recurse
                if (section == "" &&
                    !strcmp(readBuf, "profile")) {
                    // recurse into another profile
                    string subprof = dir + DIRSEP + string(val);
                    if (!exists(subprof.c_str())) {
                        cerr << "Profile " << subprof << ", required by " << fname << " not found." << endl;
                        exit(1);
                    }
                
                    readConfigFile(dir, subprof);
                
                } else {
                    // set a value
                    masterConfig[section][readBuf] = val;
                
                }
            }
        }
    }
    
    fclose(cfile);
}

// Read from a command
int readCommand(string cmd, char *buf, int len)
{
    int rd;

#ifndef __WIN32
    int ip[2], op[2];
    if (pipe(ip) == -1 ||
        pipe(op) == -1) {
        perror("pipe");
        return -1;
    }
    
    int pid = fork();
    if (pid == 0) {
        // child, fork the process
        dup2(ip[0], 0);
        close(ip[1]);
        dup2(op[1], 1);
        dup2(op[1], 2);
        close(op[0]);
        system(cmd.c_str());
        return -1;
                    
    } else if (pid == -1) {
        // uh oh! Assume no
        write(op[1], "n", 1);
    }
                
    close(ip[0]);
    close(op[1]);
                
    if ((rd = read(op[0], buf, len)) < 1) {
        return -1;
    }
    
    buf[rd] = '\0';
                
    close(ip[1]);
    close(op[0]);
                
#else
    // WIN32 version
    HANDLE ip[2], op[2];
                
    SECURITY_ATTRIBUTES sa;
    sa.nLength = sizeof(SECURITY_ATTRIBUTES);
    sa.bInheritHandle = 1;
    CreatePipe(ip, ip + 1, &sa, 0);
    CreatePipe(op, op + 1, &sa, 0);
                
    STARTUPINFOA si;
    si.cb = sizeof(STARTUPINFOA);
    si.hStdInput = ip[0];
    si.hStdOutput = op[1];
    si.hStdError = op[1];
    si.dwFlags = STARTF_USESTDHANDLES;
                
    PROCESS_INFORMATION pi;
                
    // start the sub process
    CreateProcess(NULL, (CHAR *) cmd.c_str(), NULL, NULL,
                  1, 0, NULL, NULL, &si, &pi);
    CloseHandle(ip[0]);
    CloseHandle(op[1]);
    CloseHandle(pi.hThread);
                
    // now read it
    if (!ReadFile(op[0], buf, len, (DWORD *) &rd, NULL) ||
        rd < 1) {
        return -1;
    }
    
    buf[rd] = '\0';
                
    CloseHandle(ip[1]);
    CloseHandle(ip[0]);
#endif
    
    return rd;
}

// Add a flag, with a default
void addFlag(std::string &to, const std::string &section, const std::string &flag,
             const std::string &def, const std::string &inp, const std::string &out)
{
    std::string setfl;
    int varLoc;
    
    if (masterConfig.find(section) != masterConfig.end() &&
        masterConfig[section].find(flag) != masterConfig[section].end())
        setfl = masterConfig[section][flag] + " ";
    else
        setfl = def + " ";
    
    // now parse $i and $o
    
    // replace $i
    while ((varLoc = setfl.find("$i", 0)) != string::npos) {
        setfl = setfl.substr(0, varLoc) +
            inp +
            setfl.substr(varLoc + 2);
    }
    
    // replace $o
    while ((varLoc = setfl.find("$o", 0)) != string::npos) {
        setfl = setfl.substr(0, varLoc) +
            out +
            setfl.substr(varLoc + 2);
    }
    
    to += " " + setfl;
}

// Add a library to linkFlags
void linkLibrary(const std::string &name)
{
    string useflag;
    if (global.params.lib) {
        useflag = "liblink";
    } else if (global.params.shlib) {
        useflag = "shliblink";
    } else {
        useflag = "link";
    }
    
    // add the flag
    addFlag(linkFlags, useflag, "lib", "$i", name);
}
