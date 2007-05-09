
// Component to read configuration
// Copyright (c) 2007  Gregor Richards
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt
// or any later version.
// See the included readme.txt for details.

#include <iostream>
#include <set>
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

#include "compile.h"
#include "config.h"
#include "mars.h"
#include "mem.h"
#include "root.h"
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
std::string liblinkFlags;
std::string shliblinkFlags;

void readConfigFile(const string &dir, const string &fname, string &versionFile);

void readConfig(char *argvz, const string &profile, bool generate)
{
    // find where we're installed
    char *dir, *file;
    if (!whereAmI(argvz, &dir, &file)) {
        cerr << "Could not determine installed location!" << endl;
        exit(1);
    }
    
    // while we have this data, set our libpath
    global.libpath = (char *) mem.malloc(strlen(dir) + 8);
    sprintf(global.libpath, "%s/.." DIRSEP "lib", dir);
    
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
        // perhaps generate it
        if (generate) {
            system("rebuild_choosedc");
            readConfig(argvz, profile, false);
            return;
        } else {
            cerr << "Profile '" << profile << "' does not exist." << endl;
            if (profile == "default") {
                cerr << "You may generate it by running rebuild_choosedc";
#ifndef __WIN32
                cerr << ", as root, if necessary" << endl;
#else
                cerr << ".exe" << endl;
#endif
            }
            exit(1);
        }
    }
    
    // OK, read it
    string versionFile;
    readConfigFile(confdir, conffile, versionFile);
    
    // now run the version tests
    if (versionFile.length() <= 0) return;

    // check with the target compiler by writing a test file
    // FIXME: test file should be better named
    FILE *tmpfile = fopen("rebuild_tmp.d", "w");
    if (!tmpfile) {
        perror("rebuild_tmp.d");
        exit(1);
    }
                
    // write the test file
    fprintf(tmpfile, "%s", versionFile.c_str());
    fclose(tmpfile);
    
    // get the compile line
    string response;
    bool useresponse;
    string cline = compileCommand("rebuild_tmp.d", response, useresponse);
    
    // test it
#define VERTESTBUF 1024
    char result[VERTESTBUF + 1];
    result[VERTESTBUF] = '\0';
    int i;
    char *lastResult;
    
    if (readCommand(cline, result, VERTESTBUF) < 1) {
        std::cerr << "Could not detect versions." << std::endl;
        exit(1);
    }
    
    // remove temporary files
    remove("rebuild_tmp.d");
    remove("rebuild_tmp.o");
    remove("rebuild_tmp.obj");
    
    // then go result-by-result
    lastResult = result;
    int len = strlen(result);
    for (i = 0; i <= len; i++) {
        if (result[i] == '\r') {
            result[i] = '\0';
            
        } else if (result[i] == '\n' ||
                   result[i] == '\0') {
            result[i] = '\0';
            
            // add a version
            if (!global.params.versionids)
                global.params.versionids = new Array();
            global.params.versionids->push(mem.strdup(lastResult));
            
            lastResult = result + i + 1;
            
        }
    }
}

// read in a configuration file
void readConfigFile(const string &dir, const string &fname, string &versionFile)
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
                
                    readConfigFile(dir, subprof, versionFile);
                    
                } else if (section == "" &&
                           !strcmp(readBuf, "version")) {
                    // predefined version set
                    if (!global.params.versionids)
                        global.params.versionids = new Array();
                    global.params.versionids->push(mem.strdup(val));
                    
                } else if (section == "" &&
                           !strcmp(readBuf, "noversion")) {
                    if (!global.params.versionidsNot)
                        global.params.versionidsNot = new Array();
                    global.params.versionidsNot->push(mem.strdup(val));
                    
                } else if (section == "" &&
                           !strcmp(readBuf, "testversion")) {
                    // add to the test
                    versionFile += "version(";
                    versionFile += val;
                    versionFile += ") { pragma(msg, \"";
                    versionFile += val;
                    versionFile += "\"); }\n";
                    
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
    int rd = -1;

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
    
    // read repeatedly until there's no data left
    int cl = 0;
    while ((rd = read(op[0], buf + cl, len - cl)) > 0)
    {
        cl += rd;
    }
    rd = cl;
    
    buf[rd] = '\0';
                
    close(ip[1]);
    close(op[0]);
                
#else
    // WIN32 version
    HANDLE ip[2], op[2];
                
    SECURITY_ATTRIBUTES sa;
    memset(&sa, 0, sizeof(sa));
    sa.nLength = sizeof(SECURITY_ATTRIBUTES);
    sa.bInheritHandle = 1;
    CreatePipe(ip, ip + 1, &sa, 0);
    CreatePipe(op, op + 1, &sa, 0);
                
    STARTUPINFOA si;
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(STARTUPINFOA);
    si.hStdInput = ip[0];
    si.hStdOutput = op[1];
    si.hStdError = op[1];
    si.dwFlags = STARTF_USESTDHANDLES;
                
    PROCESS_INFORMATION pi;
    memset(&pi, 0, sizeof(pi));
                
    // start the sub process
    CreateProcess(NULL, (CHAR *) cmd.c_str(), NULL, NULL,
                  1, 0, NULL, NULL, &si, &pi);
    CloseHandle(ip[0]);
    CloseHandle(op[1]);
    CloseHandle(pi.hThread);
                
    // read repeatedly until there's no data left
    int cl = 0;
    do {
        ReadFile(op[0], buf + cl, len - cl, (DWORD *) &rd, NULL);
        if (rd > 0) cl += rd;
    } while (rd > 0);
    rd = cl;
    
    buf[rd] = '\0';
    
    CloseHandle(ip[1]);
    CloseHandle(ip[0]);
#endif
    
    return rd;
}

// Add a flag, with a default
void addFlag(std::string &to, const std::string &section, const std::string &flag,
             const std::string &def, const std::string &inp, const std::string &out,
             bool pre)
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
    
    if (pre) {
        to = " " + setfl + to;
    } else {
        to += " " + setfl;
    }
}

// Add a library to linkFlags
void linkLibrary(const std::string &name)
{
    static string last = "";
    
    // don't add the same one more than once in a row ...
    if (last == name) return;
    last = name;
    
    addFlag(linkFlags, "link", "lib", "$i", name, "", true);
    addFlag(liblinkFlags, "liblink", "lib", "$i", name, "", true);
    addFlag(shliblinkFlags, "shliblink", "lib", "$i", name, "", true);
}
