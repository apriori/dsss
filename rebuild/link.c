
// Copyright (c) 1999-2008 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.
  
#include <iostream>
#include <string>

#include	<stdio.h>
#include	<ctype.h>
#include	<assert.h>
#include	<stdarg.h>
#include	<string.h>
#include	<stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#if __WIN32
#include <malloc.h>
#endif

#if _WIN32
#include	<process.h>
#else

#include	<sys/types.h>
#include	<sys/wait.h>
#include	<unistd.h>
#endif

#include        "mtype.h"
#include        "cond.h"
#include        "config.h"
#include        "identifier.h"
#include	"mars.h"
#include	"mem.h"
#include        "module.h"
#include        "response.h"
#include	"root.h"

using namespace std;

int executecmd(char *cmd, char *args, int useenv);
int executearg0(char *cmd, char *args);

/****************************************
 * Write filename to cmdbuf, quoting if necessary.
 */

void writeFilename(OutBuffer *buf, char *filename, size_t len)
{
    /* Loop and see if we need to quote
     */
    for (size_t i = 0; i < len; i++)
    {	char c = filename[i];

	if (isalnum(c) || c == '_')
	    continue;

	/* Need to quote
	 */
	buf->writeByte('"');
	buf->write(filename, len);
	buf->writeByte('"');
	return;
    }

    /* No quoting necessary
     */
    buf->write(filename, len);
}

void writeFilename(OutBuffer *buf, char *filename)
{
    writeFilename(buf, filename, strlen(filename));
}

/*****************************
 * Run the linker.  Return status of execution.
 */

string linkCommand(const string &i, const string &o, string &response, bool &useresponse, char post)
{
    int varLoc;
    
    // which link to choose
    string linkset = "link";
    
    if (global.params.lib) {
        linkset = "liblink";
    } else if (global.params.shlib) {
        linkset = "shliblink";
    } else if (global.params.dylib) {
        linkset = "dyliblink";
    }
    else
    {	/* Generate exe file name from first obj name.
	 * No need to add it to cmdbuf because the linker will default to it.
	 */
	char *n = (char *)global.params.objfiles->data[0];
	n = FileName::name(n);
	FileName *fn = FileName::forceExt(n, "exe");
	global.params.exefile = fn->toChars();
    }
    
    // check if we need to use a response file
    useresponse = false;
    if (masterConfig.find(linkset) != masterConfig.end() &&
        masterConfig[linkset].find("response") != masterConfig[linkset].end()) {
        useresponse = true;
        response = masterConfig[linkset]["response"];
    }
    
    // config: compile=[g]dmd -c $i -o $o
    string cline = masterConfig[linkset]["cmd"];
    
    // export_dynamic is used on all POSIXes except Darwin, where that's default
    if (global.params.exportDynamic) {
        if (!findCondition(global.params.versionids, new Identifier("darwin", 0))) {
            if (masterConfig[linkset].find("export_dynamic") !=
                masterConfig[linkset].end()) {
                cline += " " + masterConfig[linkset]["export_dynamic"];
            }
        }
    }
    
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
    
    // replace $l (lib directory)
    while ((varLoc = cline.find("$l", 0)) != string::npos) {
        cline = cline.substr(0, varLoc) + 
            global.libpath +
            cline.substr(varLoc + 2);
    }
    
    // add flags
    if (global.params.lib) {
        cline += liblinkFlags;
    } else if (global.params.shlib) {
        cline += shliblinkFlags;
    } else {
        cline += linkFlags;
    }
    
    return cline;
}
  
int runLINK()
{
    // get the list of input files, as well as the age if they're necessary
    string inp, out, response;
    bool useresponse;
    time_t mtime = 0;
    struct stat sbuf, osbuf;
    
    for (unsigned int i = 0; i < global.params.objfiles->dim; i++) {
        char *s = (char *) global.params.objfiles->data[i];
        
        inp += s;
        inp += " ";
        
        // now check the age
        if (!global.params.fullbuild &&
            stat(s, &sbuf) == 0 &&
            sbuf.st_mtime > mtime)
            mtime = sbuf.st_mtime;
    }
    
    if (global.params.exefile)
    {
	out = global.params.exefile;
    }
    else
    {	/* Generate exe file name from first sourcefile name, or object file
    * name if that fails */
        char *n;
        if (global.cmodules &&
            global.cmodules->dim > 0) {
            Module *m = (Module*)global.cmodules->data[0];
            if (m->srcfile)
                n = m->srcfile->name->str;
        }
        
        if (!n)
            n = (char *)global.params.objfiles->data[0];
        
        char *e;
        char *ex;
        
        n = FileName::name(n);
        e = FileName::ext(n);
        if (e)
        {
            e--;			// back up over '.'
            out = string(n).substr(0, e - n);
        }
        else
        {
            out = "a.out";
        }
        
        // add exeext
        if (masterConfig.find("") != masterConfig.end() &&
            masterConfig[""].find("exeext") != masterConfig[""].end()) {
            out += masterConfig[""]["exeext"];
        }
        
	global.params.exefile = strdup(out.c_str());
    }
    
    // do we even need to do the build?
    if (global.params.fullbuild ||
        mtime == 0 ||
        stat(global.params.exefile, &osbuf) != 0 ||
        osbuf.st_mtime <= mtime) {
        string cline = linkCommand(
            inp, out, response, useresponse, 0);
        
        if (global.params.verbose)
            printf("link      %s\n", cline.c_str());
        
        // run it
        int res = 0;
        if (cline == "") {
            res = 1;
        } else {
            if (global.params.listonly) {
                printf("%s\n", cline.c_str());
                res = 0;
            } else {
                if (useresponse)
                    res = systemResponse(cline.c_str(), response.c_str(), "link.rf", !(global.params.keeprfiles));
                else
                    res = system(cline.c_str());
            }
        }
        if (res) {
            global.errors++;
            return -1;
        }
        
        if (global.params.lib) {
            // do postlib link
            cline = linkCommand(out, "", response, useresponse, 1);
            if (global.params.verbose)
                printf("postlink  %s\n", cline.c_str());
            
            res = 0;
            if (cline == "") {
                res = 1;
            } else {
                if (global.params.listonly) {
                    printf("%s\n", cline.c_str());
                    res = 0;
                } else {
                    if (useresponse)
                        res = systemResponse(cline.c_str(), response.c_str(), "postlink.rf", !(global.params.keeprfiles));
                    else
                        res = system(cline.c_str());
                }
            }
            if (res) {
                global.errors++;
                return -1;
            }
        }
        
    } else {
        if (global.params.verbose)
            printf("no link necessary\n");
    }
    
    return 0;
}
  
void runClean()
{
    for (unsigned int i = 0; i < global.params.genobjfiles->dim; i++) {
        char *s = (char *) global.params.genobjfiles->data[i];
        
        if (global.params.listonly) {
            printf("rm -f %s\n", s);
        } else {
            if (global.params.verbose)
                printf("remove    %s\n", s);
            remove(s); // ignore errors
        }
    }
}

/**********************************
 * Delete generated EXE file.
 */

void deleteExeFile()
{
    if (global.params.exefile)
    {
	//printf("deleteExeFile() %s\n", global.params.exefile);
	remove(global.params.exefile);
    }
}

/******************************
 * Execute a rule.  Return the status.
 *	cmd	program to run
 *	args	arguments to cmd, as a string
 *	useenv	if cmd knows about _CMDLINE environment variable
 */

#if _WIN32
int executecmd(char *cmd, char *args, int useenv)
{
    int status;
    char *buff;
    size_t len;

    if (!global.params.quiet || global.params.verbose)
    {
	printf("%s %s\n", cmd, args);
	fflush(stdout);
    }

    if ((len = strlen(args)) > 255)
    {   char *q;
	static char envname[] = "@_CMDLINE";

	envname[0] = '@';
	switch (useenv)
	{   case 0:	goto L1;
	    case 2: envname[0] = '%';	break;
	}
	q = (char *) alloca(sizeof(envname) + len + 1);
	sprintf(q,"%s=%s", envname + 1, args);
	status = putenv(q);
	if (status == 0)
	    args = envname;
	else
	{
        L1: 0;
	    //error("command line length of %d is too long",len);
	}
    }

    status = executearg0(cmd,args);
#if _WIN32
    if (status == -1)
	status = spawnlp(0,cmd,cmd,args,NULL);
#endif
//    if (global.params.verbose)
//	printf("\n");
    if (status)
    {
	if (status == -1)
	    printf("Can't run '%s', check PATH\n", cmd);
	else
	    printf("--- errorlevel %d\n", status);
    }
    return status;
}
#endif

/**************************************
 * Attempt to find command to execute by first looking in the directory
 * where DMD was run from.
 * Returns:
 *	-1	did not find command there
 *	!=-1	exit status from command
 */

#if _WIN32
int executearg0(char *cmd, char *args)
{
    char *file;
    char *argv0 = global.params.argv0;

    //printf("argv0='%s', cmd='%s', args='%s'\n",argv0,cmd,args);

    // If cmd is fully qualified, we don't do this
    if (FileName::absolute(cmd))
	return -1;

    file = FileName::replaceName(argv0, cmd);

    //printf("spawning '%s'\n",file);
#if _WIN32
    return spawnl(0,file,file,args,NULL);
#else
    char *full;
    int cmdl = strlen(cmd);

    full = (char*) mem.malloc(cmdl + strlen(args) + 2);
    if (full == NULL)
	return 1;
    strcpy(full, cmd);
    full [cmdl] = ' ';
    strcpy(full + cmdl + 1, args);

    int result = system(full);

    mem.free(full);
    return result;
#endif
}
#endif

/***************************************
 * Run the compiled program.
 * Return exit status.
 */

int runProgram()
{
    //printf("runProgram()\n");
    if (global.params.verbose || global.params.listonly)
    {
	printf("%s", global.params.exefile);
	for (size_t i = 0; i < global.params.runargs_length; i++)
	    printf(" %s", (char *)global.params.runargs[i]);
	printf("\n");
    }
    if (global.params.listonly) {
        return 0;
    }

    // Build argv[]
    Array argv;

    argv.push((void *)global.params.exefile);
    for (size_t i = 0; i < global.params.runargs_length; i++)
    {	char *a = global.params.runargs[i];

#if _WIN32
	// BUG: what about " appearing in the string?
	if (strchr(a, ' '))
	{   char *b = (char *)mem.malloc(3 + strlen(a));
	    sprintf(b, "\"%s\"", a);
	    a = b;
	}
#endif
	argv.push((void *)a);
    }
    argv.push(NULL);

#if _WIN32
    char *ex = FileName::name(global.params.exefile);
    if (ex == global.params.exefile)
	ex = FileName::combine(".", ex);
    else
	ex = global.params.exefile;
    return spawnv(0,ex,(char **)argv.data);
#else
    pid_t childpid;
    int status;

    childpid = fork();
    if (childpid == 0)
    {
	const char *fn = (const char *)argv.data[0];
	if (!FileName::absolute(fn))
	{   // Make it "./fn"
	    fn = FileName::combine(".", fn);
	}
	execv(fn, (char **)argv.data);
	perror(fn);		// failed to execute
	return -1;
    }

    waitpid(childpid, &status, 0);

    status = WEXITSTATUS(status);
    return status;
#endif
}
