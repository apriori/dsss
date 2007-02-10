
// Component to parse response files
// Copyright (c) 2007  Gregor Richards
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt
// or any later version.
// See the included readme.txt for details.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mem.h"
#include "response.h"

void dupArgs(int *argc, char ***argv)
{
    int oargc, i;
    char **oargv, **nargv;
    oargc = *argc;
    oargv = *argv;
    
    // allocate the new space
    nargv = (char **) mem.malloc((oargc + 1) * sizeof(char *));
    for (i = 0; i < oargc; i++) {
        nargv[i] = oargv[i];
    }
    nargv[i] = NULL;
    
    *argv = nargv;
}

void parseResponseFile(int *argc, char ***argv, char *rf, int argnum)
{
    int oargc, nargc, i, l;
    char **oargv, **nargv;
    oargc = *argc;
    oargv = *argv;
#define RDBUFSZ 1024
    char rdbuf[RDBUFSZ + 1];
    rdbuf[RDBUFSZ] = '\0';
    
    // First, dup up to the arg specified
    nargc = argnum + 1;
    if (argnum > -1)
        nargv = (char **) mem.malloc((argnum + 2) * sizeof(char *));
    else
        nargv = NULL;
    for (i = 0; i <= argnum; i++) {
        nargv[i] = oargv[i];
    }
    
    // Now, read the response file and add as necessary
    FILE *rff = fopen(rf, "r");
    if (!rff) { perror(rf); exit(1); }
    while (fgets(rdbuf, RDBUFSZ, rff)) {
        // remove any \n's or \r's
        l = strlen(rdbuf) - 1;
        while (l > 0 &&
               (rdbuf[l] == '\n' ||
                rdbuf[l] == '\r')) {
            rdbuf[l] = '\0';
            l--;
        }
        if (l <= 0) continue;
        
        // now add the argument
        nargc++;
        nargv = (char **) mem.realloc(nargv, (nargc+1) * sizeof(char *));
        nargv[nargc-1] = mem.strdup(rdbuf);
    }
    
    // Add remaining arguments
    for (i = argnum + 1; i < oargc; i++) {
        nargc++;
        nargv = (char **) mem.realloc(nargv, (nargc+1) * sizeof(char *));
        nargv[nargc-1] = oargv[i];
    }
    
    nargv[nargc] = NULL;
    
    // Free old memory
    mem.free(oargv);
    
    // Assign new memory
    *argc = nargc;
    *argv = nargv;
}
