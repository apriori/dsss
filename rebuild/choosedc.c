/* choose a default D compiler
 * Copyright (C) 2007  Gregor Richards
 * You may do whatever you want with this code.
 * THERE IS NO WARRANTY, TO THE EXTENT PERMITTED BY APPLICABLE LAW.
 */

#include "stdio.h"
#include "whereami.h"

int main()
{
    char *compiler, *os, *dir, *fil;
    int haveDMD, haveGDC;
    FILE *fout;
    
#ifdef __WIN32
    os = "win";
#else
    os = "posix";
#endif
    
    // check for DMD
    if (whereAmI("dmd", &dir, &fil)) {
        haveDMD = 1;
    } else {
        haveDMD = 0;
    }
    
    // check for GDC
    if (whereAmI("gdmd", &dir, &fil)) {
        haveGDC = 1;
    } else {
        haveGDC = 0;
    }
    
    // choose the compiler
    if (haveDMD && haveGDC) {
        // some random choice ^^
#ifdef __WIN32
        compiler = "dmd";
#else
        compiler = "gdc";
#endif
    } else if (haveDMD) {
        compiler = "dmd";
    } else if (haveGDC) {
        compiler = "gdc";
    } else {
        printf("Neither DMD nor GDC found in $PATH. Not configuring a default.\n");
        return 0;
    }
    
    // output the default file
    fout = fopen("rebuild.conf/default", "w");
    if (!fout) { perror("fopen"); return 1; }
    fprintf(fout, "profile=%s-%s\n", compiler, os);
    fclose(fout);
    
    return 0;
}
