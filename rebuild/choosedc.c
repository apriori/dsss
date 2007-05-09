/* choose a default D compiler
 * Copyright (C) 2007  Gregor Richards
 * You may do whatever you want with this code.
 * THERE IS NO WARRANTY, TO THE EXTENT PERMITTED BY APPLICABLE LAW.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "whereami.h"

int main(int argc, char **argv)
{
    char *compiler, *os, *corelib, *testfile, *cmd, *defaultfname, *dmddir,
        *gdcdir, *dir, *fil;
    int haveDMD, haveGDC, inSourceDir, res;
    FILE *fout;
    
#ifdef __WIN32
    os = "win";
#else
    os = "posix";
#endif
    
    // figure out our own path
    if (!whereAmI(argv[0], &dir, &fil)) {
        // assume "."
        dir = ".";
    }
    
    // check if we're running out of the sourcedir
    testfile = (char *) malloc(strlen(dir) + 8);
    sprintf(testfile, "%s/mars.c", dir);
    if (access(testfile, F_OK) == 0) {
        inSourceDir = 1;
    } else {
        inSourceDir = 0;
    }
    free(testfile);
    
    // check for DMD
    if (whereAmI("dmd", &dmddir, &fil)) {
        haveDMD = 1;
    } else {
        haveDMD = 0;
    }
    
    // check for GDC
    if (whereAmI("gdmd", &gdcdir, &fil)) {
        haveGDC = 1;
    } else {
        haveGDC = 0;
    }
    
    // choose the compiler
    if (haveDMD && haveGDC) {
        // some random choice ^^
#ifdef __WIN32
        compiler = "dmd";
        haveGDC = 0;
#else
        compiler = "gdc";
        haveDMD = 0;
#endif
    } else if (haveDMD) {
        compiler = "dmd";
    } else if (haveGDC) {
        compiler = "gdc";
    } else {
        printf("Neither DMD nor GDC found in $PATH. Not configuring a default.\n"
               "Please add ONE of the following lines to your rebuild.conf/default file:\n"
               "profile=gdc-posix\n"
               "profile=gdc-posix-tango\n"
               "profile=gdc-win\n"
               "profile=gdc-win-tango\n"
               "profile=dmd-posix\n"
               "profile=dmd-posix-tango\n"
               "profile=dmd-win\n"
               "profile=dmd-win-tango\n");
        return 0;
    }
    
    // check which corelib is available
    if (inSourceDir) {
        testfile = (char *) malloc(strlen(dir) + 13);
        sprintf(testfile, "%s/testtango.d", dir);
    } else {
        testfile = (char *) malloc(strlen(dir) + 30);
        sprintf(testfile, "%s/../share/rebuild/testtango.d", dir);
    }
    printf("Ignore any error from GDC or DMD in the following lines.\n");
    if (haveGDC) {
        cmd = (char *) malloc(strlen(testfile) + 22);
        sprintf(cmd, "gdc -c -fsyntax-only %s", testfile);
        res = system(cmd);
    } else if (haveDMD) {
        cmd = (char *) malloc(strlen(testfile) + 12);
        sprintf(cmd, "dmd -c -o- %s", testfile);
        res = system(cmd);
    }
    if (res == 0) {
        corelib = "-tango";
    } else {
        corelib = "";
    }
    
    // output the default file
    if (inSourceDir) {
        defaultfname = (char *) malloc(strlen(dir) + 22);
        sprintf(defaultfname, "%s/rebuild.conf/default", dir);
    } else {
        defaultfname = (char *) malloc(strlen(dir) + 24);
        sprintf(defaultfname, "%s/../etc/rebuild/default", dir);
    }
    
    fout = fopen(defaultfname, "w");
    if (!fout) { perror("fopen"); return 1; }
    fprintf(fout, "profile=%s-%s%s\n", compiler, os, corelib);
    fclose(fout);
    
    return 0;
}
