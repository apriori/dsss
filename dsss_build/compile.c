
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

string compileCommand(const string &i, const string &o)
{
    int varLoc;
    
    // compile a source file into an object file
    if (masterConfig.find("compile") == masterConfig.end() ||
        masterConfig["compile"].find("cmd") == masterConfig["compile"].end()) {
        cerr << "No 'compile.cmd' setting configured." << endl;
        global.errors++;
        return "";
    }
    
    // config: compile=[g]dmd -c $i -o $o
    string cline = masterConfig["compile"]["cmd"];
    
    // replace $i
    while ((varLoc = cline.find("$i", 0)) != string::npos) {
        cline = cline.substr(0, varLoc) +
            i +
            cline.substr(varLoc + 2);
    }
    
    // replace $o
    while ((varLoc = cline.find("$o", 0)) != string::npos) {
        cline = cline.substr(0, varLoc) +
            o +
            cline.substr(varLoc + 2);
    }
    
    // add flags
    cline += compileFlags;
    
    return cline;
}

void Module::genobjfile()
{
    string cline = compileCommand(
        srcfile->name->str,
        objfile->name->str);
    
    if (global.params.verbose)
        printf("compile   %s\n", cline.c_str());
    
    // run it
    if (cline == "" ||
        system(cline.c_str()))
        global.errors++;
}
