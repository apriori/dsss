
// Component to call the compilation phase
// Copyright (c) 2007  Gregor Richards
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt
// or any later version.
// See the included readme.txt for details.

#include <iostream>
#include <string>
using namespace std;

extern "C" {
#include <stdlib.h>
}

#include "config.h"
#include "mars.h"
#include "module.h"
#include "response.h"

string compileCommand(const string &i, string &response, bool &useresponse)
{
    int varLoc;
    
    // compile a source file into an object file
    if (masterConfig.find("compile") == masterConfig.end() ||
        masterConfig["compile"].find("cmd") == masterConfig["compile"].end()) {
        cerr << "No 'compile.cmd' setting configured." << endl;
        global.errors++;
        return "";
    }
    
    // check if we need to use a response file
    useresponse = false;
    if (masterConfig["compile"].find("response") != masterConfig["compile"].end()) {
        useresponse = true;
        response = masterConfig["compile"]["response"];
    }
    
    // config: compile=[g]dmd -c $i -o $o
    string cline = masterConfig["compile"]["cmd"];
    
    // replace $i
    while ((varLoc = cline.find("$i", 0)) != string::npos) {
        cline = cline.substr(0, varLoc) +
            i +
            cline.substr(varLoc + 2);
    }
    
    // add flags
    cline += compileFlags;
    
    return cline;
}

void runCompile(const std::string &files)
{
    string response;
    bool useresponse;
    string cline = compileCommand(files, response, useresponse);
    
    if (global.params.verbose)
        printf("compile   %s\n", cline.c_str());
    
    // run it
    int res = 0;
    if (cline == "") {
        res = 1;
    } else {
        if (useresponse)
            res = systemResponse(cline.c_str(), response.c_str(), "rsp");
        else
            res = system(cline.c_str());
    }
    if (res) {
        global.errors++;
    }
}
