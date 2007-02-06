
// Compiler implementation of the D programming language
// Copyright (c) 1999-2007 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <assert.h>
#include <limits.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#if _WIN32
#include <windows.h>
long __cdecl __ehfilter(LPEXCEPTION_POINTERS ep);
#endif

#if __DMC__
#include <dos.h>
#endif

#if linux
#include <errno.h>
#endif

#include "mem.h"
#include "root.h"

#include "compile.h"
#include "mars.h"
#include "module.h"
#include "mtype.h"
#include "id.h"
#include "cond.h"
#include "expression.h"
#include "lexer.h"
#include "whereami.h"

#include "config.h"

void getenv_setargv(const char *envvar, int *pargc, char** *pargv);

Global global;

Global::Global()
{
    mars_ext = "d";
    sym_ext  = "d";
    hdr_ext  = "di";
    doc_ext  = "html";
    ddoc_ext = "ddoc";

    obj_ext  = "o";

    copyright = "Copyright (c) 1999-2007 by Digital Mars and Gregor Richards,";
    written = "written by Walter Bright and Gregor Richards";
    version = "version 0.2 (based on DMD 1.005)";
    global.structalign = 8;
    cmodules = NULL;

    memset(&params, 0, sizeof(Param));
}

char *Loc::toChars()
{
    OutBuffer buf;
    char *p;

    if (filename)
    {
	buf.printf("%s", filename);
    }

    if (linnum)
	buf.printf("(%d)", linnum);
    buf.writeByte(0);
    return (char *)buf.extractData();
}

Loc::Loc(Module *mod, unsigned linnum)
{
    this->linnum = linnum;
    this->filename = mod ? mod->srcfile->toChars() : NULL;
}

/**************************************
 * Print error message and exit.
 */

void error(Loc loc, const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    verror(loc, format, ap);
    va_end( ap );
}

void verror(Loc loc, const char *format, va_list ap)
{
    if (!global.gag)
    {
	char *p = loc.toChars();

	if (*p)
	    fprintf(stdmsg, "%s: ", p);
	mem.free(p);

	fprintf(stdmsg, "Error: ");
	vfprintf(stdmsg, format, ap);
	fprintf(stdmsg, "\n");
	fflush(stdmsg);
    }
    global.errors++;
}

/***************************************
 * Call this after printing out fatal error messages to clean up and exit
 * the compiler.
 */

void fatal()
{
#if 0
    halt();
#endif
    exit(EXIT_FAILURE);
}

/**************************************
 * Try to stop forgetting to remove the breakpoints from
 * release builds.
 */
void halt()
{
#ifdef DEBUG
    *(char*)0=0;
#endif
}

void usage()
{
    printf("ReBuild %s\n%s %s\n",
	global.version, global.copyright, global.written);
    printf("\
Documentation: www.digitalmars.com/d/index.html\n\
Usage:\n\
  rebuild files.d ... { -switch }\n\
\n\
  files.d        D source files\n%s\
  -dc=<compiler> use the specified compiler configuration\n\
  -p             do not compile (or link)\n\
  -c             do not link\n\
  -lib           link a static library\n\
  -shlib         link a dynamic library\n\
  -shlib-support exit failure or success for whether shared libraries are supported\n\
  -files         list files which would be compiled (but don't compile)\n\
  -full          compile all source files, regardless of their age\n\
  -explicit      only compile files explicitly named, not dependencies\n\
  --help         print help\n\
  -Ipath         where to look for imports\n\
  -Ccompileflag  pass compileflag to compilation\n\
  -Llinkerflag   pass linkerflag to link\n\
  -ll<lib>       link in the specified library\n\
                 Windows: Link to <lib>.lib\n\
                 Posix: Link to lib<lib>.{a,so}\n\
  -Spath         search path for libraries\n\
  -O             optimize\n\
  -oqobjdir      write object files to directory objdir with fully-qualified module names\n\
  -odobjdir      write object files to directory objdir\n\
  -offilename	 name output file to filename\n\
  -quiet         suppress unnecessary messages\n\
  -release	 compile release version\n\
  -exec          run resulting program\n\
  -v             verbose\n\
  -version=level compile in version code >= level\n\
  -version=ident compile in version code identified by ident\n\
  -circular      allow circular dependencies to work on some compilers (namely GDC) \n\
  -testversion=<version> exit failure or success for whether the specified version is defined\n\
  All other flags are passed to the compiler.\n\
",
#if WIN32
"  @cmdfile       read arguments from cmdfile\n"
#else
""
#endif
);
}

bool stringInArray(Array *arr, char *str)
{
    for (unsigned int i = 0; i < arr->dim; i++) {
        if (!strcmp((char *) arr->data[i], str)) return true;
    }
    return false;
}

int main(int argc, char *argv[])
{
    int i;
    Array files;
    char *p;
    Module *m;
    int status = EXIT_SUCCESS;
    int argcstart = argc;

    // Check for malformed input
    if (argc < 1 || !argv)
    {
      Largs:
	error("missing or null command line arguments");
	fatal();
    }
    for (i = 0; i < argc; i++)
    {
	if (!argv[i])
	    goto Largs;
    }

    // Initialization
    Type::init();
    Id::initialize();
    Module::init();
    initPrecedence();

    //backend_init();

#if __DMC__	// DMC unique support for response files
    if (response_expand(&argc,&argv))	// expand response files
	error("can't open response file");
#endif

    files.reserve(argc - 1);

    // Set default values
    global.params.argv0 = argv[0];
    global.params.link = 1;
    global.params.lib = 0;
    global.params.shlib = 0;
    global.params.fullbuild = 0;
    global.params.fullqobjs = 1;
    global.params.objdir = ".";
    global.params.useAssert = 1;
    global.params.useInvariants = 1;
    global.params.useIn = 1;
    global.params.useOut = 1;
    global.params.useArrayBounds = 1;
    global.params.useSwitchError = 1;
    global.params.useInline = 0;
    global.params.obj = 1;
    global.params.Dversion = 2;

    global.params.linkswitches = new Array();
    global.params.libfiles = new Array();
    global.params.objfiles = new Array();
    global.params.ddocfiles = new Array();

    // Predefine version identifiers
    VersionCondition::addPredefinedGlobalIdent("build");
    VersionCondition::addPredefinedGlobalIdent("rebuild");
    VersionCondition::addPredefinedGlobalIdent("all");
    
    // BEFORE reading configuration, check for a specified compiler
    char *chooseProfile = "default";
    for (i = 1; i < argc; i++)
    {
        p = argv[i];
        if (!strncmp(p, "-dc=", 4)) {
            chooseProfile = p + 4;
            break;
        }
    }
    
    readConfig(argv[0], chooseProfile);
    
    // get include paths
    if (masterConfig.find("") != masterConfig.end() &&
        masterConfig[""].find("compiler") != masterConfig[""].end()) {
        std::string compiler = masterConfig[""]["compiler"];
        
        if (compiler == "dmd") {
            // we have this built in
            char *inif;
            
            if (masterConfig[""].find("inifile") != masterConfig[""].end())
                inif = mem.strdup(masterConfig[""]["inifile"].c_str());
            else
                inif = mem.strdup("sc.ini");
            
            // trick whereami into giving us a path
            char *dir, *fil, *full;
            if (!whereAmI("dmd", &dir, &fil)) {
                error("dmd is not in $PATH");
                exit(1);
            }
            full = (char *) mem.malloc(strlen(dir) + 5);
            sprintf(full, "%s%cdmd", dir,
#if __WIN32
                    '\\'
#else
                    '/'
#endif
                   );
            inifile(full, inif);
            mem.free(full);
            
            mem.free(inif);
            
        } else if (compiler.substr(compiler.length() - 3) == "gdc") {
            // a bit more complicated
#define READBUFSIZ 1024
            char readBuf[READBUFSIZ + 1];
            readBuf[READBUFSIZ] = '\0';
            int nloc;
            
            // 1) read version
            if (readCommand(compiler + " -dumpversion", readBuf, READBUFSIZ) < 1) {
                error("Failed to detect GDC version");
            }
            std::string cversion = readBuf;
            nloc = cversion.find('\n', 0);
            if (nloc != std::string::npos) cversion = cversion.substr(0, nloc);
            
            // 2) read machine
            if (readCommand(compiler + " -dumpmachine", readBuf, READBUFSIZ) < 1) {
                error("Failed to detect GDC target");
            }
            std::string cmachine = readBuf;
            nloc = cmachine.find('\n', 0);
            if (nloc != std::string::npos) cmachine = cmachine.substr(0, nloc);
            
            // 3) get the prefix
            char *gdcdir, *gdcfil;
            if (!whereAmI("gdc", &gdcdir, &gdcfil)) {
                error("gdc is not in $PATH");
                exit(1);
            }
            
            // 4) make include paths
            if (!global.params.imppath)
                global.params.imppath = new Array();
            global.params.imppath->push(strdup(
                (std::string(gdcdir) + "/../include/d/" + cversion + "/").c_str()));
            global.params.imppath->push(strdup(
                (std::string(gdcdir) + "/../include/d/" + cversion + "/" + cmachine + "/").c_str()));
            global.params.imppath->push(strdup(
                (std::string(gdcdir) + "/../" + cmachine + "/include/d/" + cversion + "/").c_str()));
            global.params.imppath->push(strdup(
                (std::string(gdcdir) + "/../" + cmachine + "/include/d/" + cversion + "/" + cmachine + "/").c_str()));
        }
    }
    
    // special configuration options needed here
    if (masterConfig.find("") != masterConfig.end() &&
        masterConfig[""].find("objext") != masterConfig[""].end()) {
        global.obj_ext = strdup(masterConfig[""]["objext"].c_str());
    }
    
    getenv_setargv("DFLAGS", &argc, &argv);

#if 0
    for (i = 0; i < argc; i++)
    {
	printf("argv[%d] = '%s'\n", i, argv[i]);
    }
#endif

    for (i = 1; i < argc; i++)
    {
	p = argv[i];
	if (*p == '-')
	{
            if (strcmp(p + 1, "p") == 0)
            {
                global.params.obj = 0;
                global.params.link = 0;
            }
	    else if (strcmp(p + 1, "c") == 0 ||
                     strcmp(p + 1, "obj") == 0 /* compat with build */)
		global.params.link = 0;
            else if (strcmp(p + 1, "lib") == 0)
                global.params.lib = 1;
            else if (strcmp(p + 1, "shlib") == 0)
                global.params.shlib = 1;
            else if (strcmp(p + 1, "link") == 0) /* compat with build */
            {
                global.params.link = 1;
                global.params.lib = 0;
                global.params.shlib = 0;
            }
            else if (strcmp(p + 1, "nolib") == 0) /* compat with build */
            {
                global.params.lib = 0;
                global.params.shlib = 0;
            }
            else if (strcmp(p + 1, "nolink") == 0) /* compat with build */
                global.params.link = 0;
            else if (strcmp(p + 1, "shlib-support") == 0)
            {
                // just test for support
                if (masterConfig.find("shliblink") == masterConfig.end() ||
                    masterConfig["shliblink"].find("shlibs") == masterConfig["shliblink"].end() ||
                    masterConfig["shliblink"]["shlibs"] != "yes") {
                    exit(1);
                } else {
                    exit(0);
                }
            }
            else if (strcmp(p + 1, "files") == 0)
            {
                global.params.listfiles = 1;
                global.params.obj = 0;
                global.params.link = 0;
            }
            else if (strcmp(p + 1, "full") == 0)
                global.params.fullbuild = 1;
            else if (strcmp(p + 1, "explicit") == 0)
                global.params.expbuild = 1;
	    else if (strcmp(p + 1, "v") == 0 ||
                     strcmp(p + 1, "V") == 0 || /* compat with build */
                     strcmp(p + 1, "names") == 0 /* also build */)
            {
		global.params.verbose = 1;
                //addFlag(compileFlags, "compile", "verbose", "-v");
            }
	    else if (strcmp(p + 1, "O") == 0)
            {
		global.params.optimize = 1;
                addFlag(compileFlags, "compile", "optimize", "-O");
            }
	    else if (p[1] == 'o')
	    {
		switch (p[2])
		{
                    case 'q':
                        if (!p[3])
                            global.params.objdir = ".";
                        else
                            global.params.objdir = p + 3;
                        global.params.fullqobjs = 1;
                        break;
                    
		    case 'd':
			if (!p[3])
			    goto Lnoarg;
			global.params.objdir = p + 3;
                        global.params.fullqobjs = 0;
			break;

		    case 'f':
			if (!p[3])
			    goto Lnoarg;
			global.params.objname = p + 3;
			break;

		    case 'p':
                        error("Rebuild does not support -op. Use -oq instead.");
                        exit(1);
			/*if (p[3])
			    goto Lerror;
			global.params.preservePaths = 1;
                        addFlag(compileFlags, "compile", "op", "-op"); */
			break;

		    case 0:
			error("-o no longer supported, use -of or -od");
			break;

		    default:
			goto Lerror;
		}
	    }
	    else if (strcmp(p + 1, "quiet") == 0)
		global.params.quiet = 1;
	    else if (strcmp(p + 1, "release") == 0)
            {
		global.params.release = 1;
                addFlag(compileFlags, "compile", "release", "-release");
            }
	    else if (p[1] == 'I')
	    {
		if (!global.params.imppath)
		    global.params.imppath = new Array();
		global.params.imppath->push(p + 2);
                
                addFlag(compileFlags, "compile", "incdir", "-I$i", p + 2);
	    }
	    else if (memcmp(p + 1, "version", 5) == 0)
	    {
		// Parse:
		//	-version=number
		//	-version=identifier
		if (p[8] == '=')
		{
                    addFlag(compileFlags, "compile", "version", "-version=$i", p + 9);
                    
		    if (isdigit(p[9]))
		    {	long level;

			errno = 0;
			level = strtol(p + 9, &p, 10);
			if (*p || errno || level > INT_MAX)
			    goto Lerror;
			VersionCondition::setGlobalLevel((int)level);
		    }
		    else if (Lexer::isValidIdentifier(p + 9))
			VersionCondition::addGlobalIdent(p + 9);
		    else
			goto Lerror;
		}
		else
		    goto Lerror;
	    }
	    else if (strcmp(p + 1, "-help") == 0)
	    {	usage();
		exit(EXIT_SUCCESS);
	    }
	    else if (p[1] == 'L')
	    {
                addFlag(linkFlags, "link", "flag", "-L$i", p + 2);
                addFlag(liblinkFlags, "liblink", "flag", "-L$i", p + 2);
                addFlag(shliblinkFlags, "shliblink", "flag", "-L$i", p + 2);
	    }
            else if (!strncmp(p + 1, "ll", 2) == 0)
            {
                linkLibrary(p + 3);
            }
            else if (p[1] == 'C')
            {
                addFlag(compileFlags, "compile", "flag", "$i", p + 2);
            }
            else if (p[1] == 'S')
            {
                // add a flag both to compile and to link
                addFlag(compileFlags, "compile", "libdir", "-L-L$i", p + 2);

                addFlag(linkFlags, "link", "libdir", "-L-L$i", p + 2);
                addFlag(liblinkFlags, "liblink", "libdir", "-L-L$i", p + 2);
                addFlag(shliblinkFlags, "shliblink", "libdir", "-L-L$i", p + 2);
            }
	    else if (strcmp(p + 1, "exec") == 0)
            {
                global.params.run = 1;
		global.params.runargs_length = ((i >= argcstart) ? argc : argcstart) - i - 1;
		if (global.params.runargs_length)
		{
		    files.push(argv[i + 1]);
		    global.params.runargs = &argv[i + 2];
		    i += global.params.runargs_length;
		    global.params.runargs_length--;
		}
		else
		{   global.params.run = 0;
		    goto Lnoarg;
		}
	    }
            else if (strcmp(p + 1, "circular") == 0)
            {
                addFlag(compileFlags, "compile", "circular", "");
            }
            else if (strncmp(p + 1, "testversion=", 12) == 0)
            {
                if (!global.params.versionids) exit(1);
                
                if (findCondition(global.params.versionids,
                                  new Identifier(p + 13, 0))) exit(0);
                exit(1);
            }
            else if (strncmp(p + 1, "dc=", 3) == 0) {}
            else if (strncmp(p + 1, "CFPATH", 6) == 0 ||
                     strncmp(p + 1, "BCFPATH", 7) == 0 ||
                     strcmp(p + 1, "allobj") == 0 ||
                     strcmp(p + 1, "cleanup") == 0 ||
                     strcmp(p + 1, "clean") == 0 ||
                     strncmp(p + 1, "LIBOPT", 6) == 0 ||
                     strncmp(p + 1, "SHLIBOPT", 8) == 0 ||
                     strncmp(p + 1, "LIBPATH", 7) == 0 ||
                     strcmp(p + 1, "test") == 0) {} /* compat with build */
	    else
	    {
                compileFlags += " ";
                compileFlags += p;
                continue;
                
	     Lerror:
		error("unrecognized switch '%s'", argv[i]);
		continue;

	     Lnoarg:
		error("argument expected for switch '%s'", argv[i]);
		continue;
	    }
	}
	else
	    files.push(p);
    }
    if (global.errors)
    {
	fatal();
    }
    if (files.dim == 0)
    {	usage();
	return EXIT_FAILURE;
    }
    
    addFlag(compileFlags, "compile", "od", "-od$i", global.params.objdir);
    
    if (global.params.release)
    {	global.params.useInvariants = 0;
	global.params.useIn = 0;
	global.params.useOut = 0;
	global.params.useAssert = 0;
	global.params.useArrayBounds = 0;
	global.params.useSwitchError = 0;
    }

    if (global.params.run)
	global.params.quiet = 1;

    if (global.params.useUnitTests)
	global.params.useAssert = 1;

    if (!global.params.obj)
	global.params.link = 0;

    if (global.params.link)
    {
	global.params.exefile = global.params.objname;
	global.params.objname = NULL;
    }
    else if (global.params.run)
    {
	error("flags conflict with -run");
	fatal();
    }
    else
    {
	if (global.params.objname && files.dim > 1)
	{
	    error("multiple source files, but only one .obj name");
	    fatal();
	}
    }
    if (global.params.cov)
	VersionCondition::addPredefinedGlobalIdent("D_Coverage");


    //printf("%d source files\n",files.dim);

    // Build import search path
    if (global.params.imppath)
    {
	for (i = 0; i < global.params.imppath->dim; i++)
	{
	    char *path = (char *)global.params.imppath->data[i];
	    Array *a = FileName::splitPath(path);

	    if (a)
	    {
		if (!global.path)
		    global.path = new Array();
		global.path->append(a);
	    }
	}
    }

    // Create Modules
    if (!global.cmodules) {
        global.cmodules = new Array();
    }
    global.cmodules->reserve(files.dim);
    for (i = 0; i < files.dim; i++)
    {	Identifier *id;
	char *ext;
	char *name;

	p = (char *) files.data[i];

/*#if _WIN32
	// Convert / to \ so linker will work
	for (int j = 0; p[j]; j++)
	{
	    if (p[j] == '/')
		p[j] = '\\';
	}
#endif */

	p = FileName::name(p);		// strip path
	ext = FileName::ext(p);
	if (ext)
	{
	    if (strcmp(ext, global.obj_ext) == 0)
	    {
		global.params.objfiles->push(files.data[i]);
		continue;
	    }

	    if (strcmp(ext, global.ddoc_ext) == 0)
	    {
		global.params.ddocfiles->push(files.data[i]);
		continue;
	    }

	    if (stricmp(ext, global.mars_ext) == 0 ||
		stricmp(ext, "htm") == 0 ||
		stricmp(ext, "html") == 0 ||
		stricmp(ext, "xhtml") == 0)
	    {
		ext--;			// skip onto '.'
		assert(*ext == '.');
		name = (char *)mem.malloc((ext - p) + 1);
		memcpy(name, p, ext - p);
		name[ext - p] = 0;		// strip extension

		if (name[0] == 0 ||
		    strcmp(name, "..") == 0 ||
		    strcmp(name, ".") == 0)
		{
		Linvalid:
		    error("invalid file name '%s'", (char *)files.data[i]);
		    fatal();
		}
	    }
	    else
	    {	error("unrecognized file extension %s\n", ext);
		fatal();
	    }
	}
	else
	{   name = p;
	    if (!*name)
		goto Linvalid;
	}

	id = new Identifier(name, 0);
	m = new Module((char *) files.data[i], id, global.params.doDocComments, global.params.doHdrGeneration);
	global.cmodules->push(m);
    }

#if _WIN32 && __DMC__
  __try
  {
#endif
    // Read files, parse them
    for (i = 0; i < global.cmodules->dim; i++)
    {
	m = (Module *)global.cmodules->data[i];
	if (global.params.verbose)
	    printf("parse     %s\n", m->toChars());
	if (!Module::rootModule)
	    Module::rootModule = m;
	m->importedFrom = m;
	m->deleteObjFile();
	m->read(0);
	m->parse();
	if (m->isDocFile)
	{
	    m->gendocfile();

	    // Remove m from list of modules
	    global.cmodules->remove(i);
	    i--;

	    /* Remove m's object file from list of object files
	    for (int j = 0; j < global.params.objfiles->dim; j++)
	    {
		if (m->objfile->name->str == global.params.objfiles->data[j])
		{
		    global.params.objfiles->remove(j);
		    break;
		}
	    }

	    if (global.params.objfiles->dim == 0)
		global.params.link = 0;*/
	}
    }
    if (global.errors)
	fatal();
#ifdef _DH
    if (global.params.doHdrGeneration)
    {
	/* Generate 'header' import files.
	 * Since 'header' import files must be independent of command
	 * line switches and what else is imported, they are generated
	 * before any semantic analysis.
	 */
	for (i = 0; i < global.cmodules->dim; i++)
	{
	    m = (Module *)global.cmodules->data[i];
	    if (global.params.verbose)
		printf("import    %s\n", m->toChars());
	    m->genhdrfile();
	}
    }
    if (global.errors)
	fatal();
#endif

    // parse pragmas
    for (i = 0; i < global.cmodules->dim; i++)
    {
	m = (Module *)global.cmodules->data[i];
	if (global.params.verbose)
	    printf("meta      %s\n", m->toChars());
	m->parsepragmas();
    }
    if (global.errors)
	fatal();
    
    /* Do semantic analysis
    for (i = 0; i < global.cmodules->dim; i++)
    {
	m = (Module *)global.cmodules->data[i];
	if (global.params.verbose)
	    printf("semantic  %s\n", m->toChars());
	m->semantic();
    }
    if (global.errors)
	fatal();

    // Do pass 2 semantic analysis
    for (i = 0; i < global.cmodules->dim; i++)
    {
	m = (Module *)global.cmodules->data[i];
	if (global.params.verbose)
	    printf("semantic2 %s\n", m->toChars());
	m->semantic2();
    }
    if (global.errors)
	fatal();

    // Do pass 3 semantic analysis
    for (i = 0; i < global.cmodules->dim; i++)
    {
	m = (Module *)global.cmodules->data[i];
	if (global.params.verbose)
	    printf("semantic3 %s\n", m->toChars());
	m->semantic3();
    }
    if (global.errors)
	fatal();

    // Scan for functions to inline
    if (global.params.useInline)
    {
	/ * The problem with useArrayBounds and useAssert is that the
	 * module being linked to may not have generated them, so if
	 * we inline functions from those modules, the symbols for them will
	 * not be found at link time.
	 * /
	if (!global.params.useArrayBounds && !global.params.useAssert)
	{
	    // Do pass 3 semantic analysis on all imported modules,
	    // since otherwise functions in them cannot be inlined
	    for (i = 0; i < Module::amodules.dim; i++)
	    {
		m = (Module *)Module::amodules.data[i];
		if (global.params.verbose)
		    printf("semantic3 %s\n", m->toChars());
		m->semantic3();
	    }
	    if (global.errors)
		fatal();
	}

	for (i = 0; i < global.cmodules->dim; i++)
	{
	    m = (Module *)global.cmodules->data[i];
	    if (global.params.verbose)
		printf("inline scan %s\n", m->toChars());
	    m->inlineScan();
	}
    }
    if (global.errors)
	fatal();*/
    
    class GroupedCompile {
        public:
        Array imodules, ofiles;
        Array origonames, newonames;
    };
    Array GroupedCompiles;
    GroupedCompiles.push((void *) new GroupedCompile);
    
    // Generate compile commands
    for (i = 0; i < global.cmodules->dim; i++)
    {
	m = (Module *)global.cmodules->data[i];
        GroupedCompile *gc;
        
        if (global.params.fullqobjs)
        {
            // find the right compile to add this to
            unsigned int cmp;
            for (cmp = 0; cmp < GroupedCompiles.dim; cmp++) {
                gc = (GroupedCompile *) GroupedCompiles.data[cmp];
                
                if (!stringInArray(&(gc->ofiles), m->objfile->name->str)) {
                    // add it
                    gc->ofiles.push((void *) m->objfile->name->str);
                    break;
                }
            }
            if (cmp == GroupedCompiles.dim) {
                gc = new GroupedCompile;
                GroupedCompiles.push(gc);
                gc->ofiles.push((void *) m->objfile->name->str);
            }
            
            // the output file name is guessable now that we have the module name
            if (m->md) {
                const char *mname = m->md->id->string;
                
                // add the module name
                char *ofname = (char *) mem.malloc(strlen(mname) + strlen(global.obj_ext) + 2);
                sprintf(ofname, "%s.%s", mname, global.obj_ext);
                
                // figure out what we should really be using to combine them
                std::string sep = ".";
                if (masterConfig.find("") != masterConfig.end() &&
                    masterConfig[""].find("objmodsep") != masterConfig[""].end())
                    sep = masterConfig[""]["objmodsep"];
                
                // now add all the package names
                Array *packages = m->md->packages;
                if (packages) {
                    for (int j = packages->dim - 1; j >= 0; j--) {
                        Identifier *id = (Identifier *) packages->data[j];
                        
                        char *newfname = (char *) mem.malloc(strlen(id->string) + strlen(ofname) + 2);
                        sprintf(newfname, "%s%s%s", id->string, sep.c_str(), ofname);
                        mem.free(ofname);
                        ofname = newfname;
                    }
                }
                
                // then add the objdir
                char *newofname = FileName::combine(global.params.objdir, ofname);
                mem.free(ofname);
                ofname = newofname;
                
                // make sure the name gets changed later
                gc->origonames.push((void *) m->objfile->name->str);
                gc->newonames.push((void *) ofname);
                
                m->objfile = new File(ofname);
            }
        } else {
            // just add it
            gc = (GroupedCompile *) GroupedCompiles.data[0];
            gc->ofiles.push((void *) m->objfile->name->str);
        }
        
	if (global.params.obj) {
            // don't generate if we should ignore this module
            char ignore = 0;
            if (m->md) {
                std::string modname = m->md->id->string;
                if (m->md->packages) {
                    for (int j = m->md->packages->dim - 1; j >= 0; j--) {
                        modname = std::string(((Identifier *) m->md->packages->data[j])->string) +
                            "." + modname;
                    }
                }
                
                if (masterConfig.find("") != masterConfig.end() &&
                    masterConfig[""].find("ignore") != masterConfig[""].end()) {
                    std::string modIgnoreList = masterConfig[""]["ignore"];
                    
                    // split by ' '
                    while (modIgnoreList.length()) {
                        std::string modIgnore;
                        int loc = modIgnoreList.find(' ', 0);
                        
                        if (loc == std::string::npos) {
                            modIgnore = modIgnoreList;
                            modIgnoreList = "";
                        } else {
                            modIgnore = modIgnoreList.substr(0, loc);
                            modIgnoreList = modIgnoreList.substr(loc + 1);
                        }
                        
                        // check it
                        if (modname.substr(0, modIgnore.length()) == modIgnore) {
                            ignore = 1;
                        }
                    }
                }
            }
            
            if (!ignore) {
                if (!global.params.objfiles)
                    global.params.objfiles = new Array();
                global.params.objfiles->push(m->objfile->name->str);
            }
            
            // figure out the most recent dependency
            struct stat sbuf;
            time_t newest = 0;
            Array modsToTest;
            if (!global.params.fullbuild) {
                modsToTest.push((void *) m);
                for (unsigned int j = 0; j < modsToTest.dim; j++) {
                    Module *mtest = (Module *) modsToTest.data[j];
                    
                    // test this dependency
                    if (stat(mtest->srcfile->name->str, &sbuf) == 0) {
                        if (sbuf.st_mtime > newest)
                            newest = sbuf.st_mtime;
                    }
                    
                    // now add its dependencies
                    for (unsigned int k = 0; k < mtest->aimports.dim; k++) {
                        // check if it's already there
                        for (unsigned int l = 0; l < modsToTest.dim; l++) {
                            if (mtest->aimports.data[k] ==
                                modsToTest.data[l]) goto noAddDep;
                        }
                        modsToTest.push(mtest->aimports.data[k]);
                        noAddDep: 0;
                    }
                }
            }
            
            // now check if we should ignore it because of its age
            if (!global.params.fullbuild &&
                stat(m->objfile->name->str, &sbuf) == 0 &&
                newest < sbuf.st_mtime)
                ignore = 1;
            
            if (!ignore) {
                gc->imodules.push((void *) m);
            }
        }
	if (global.params.verbose)
	    printf("code      %s\n", m->toChars());
        
        if (global.params.doDocComments)
            m->gendocfile();
    }
    
    // Now do the actual compilation
    for (unsigned int j = 0; j < GroupedCompiles.dim; j++) {
        GroupedCompile *gc = (GroupedCompile *) GroupedCompiles.data[j];
        
        if (gc->imodules.dim == 0) continue;
        
        // make a string of the file names
        std::string infiles;
        for (unsigned int k = 0; k < gc->imodules.dim; k++) {
            Module *m = (Module *) gc->imodules.data[k];
            infiles += m->srcfile->name->str;
            infiles += " ";
        }
        
        // then compile
        runCompile(infiles);
        
        // and rename
        for (unsigned int k = 0; k < gc->origonames.dim; k++) {
            rename((char *) gc->origonames.data[k],
                   (char *) gc->newonames.data[k]); // ignore errors
        }
    }
    
#if _WIN32 && __DMC__
  }
  __except (__ehfilter(GetExceptionInformation()))
  {
    printf("Stack overflow\n");
    fatal();
  }
#endif
    //backend_term();
    if (global.errors)
	fatal();

    if (!global.params.objfiles->dim)
    {
	if (global.params.link)
	    error("no object files to link");
    }
    else
    {
	if (global.params.link)
	    status = runLINK();

	if (global.params.run)
	{
	    if (!status)
	    {
		status = runProgram();

		/* Delete .obj files and .exe file
		 */
		for (i = 0; i < global.cmodules->dim; i++)
		{
		    m = (Module *)global.cmodules->data[i];
		    m->deleteObjFile();
		}
		deleteExeFile();
	    }
	}
    }

    return status;
}



/***********************************
 * Parse and append contents of environment variable envvar
 * to argc and argv[].
 * The string is separated into arguments, processing \ and ".
 */

void getenv_setargv(const char *envvar, int *pargc, char** *pargv)
{
    char *env;
    char *p;
    Array *argv;
    int argc;

    int wildcard;		// do wildcard expansion
    int instring;
    int slash;
    char c;
    int j;

    env = getenv(envvar);
    if (!env)
	return;

    env = mem.strdup(env);	// create our own writable copy

    argc = *pargc;
    argv = new Array();
    argv->setDim(argc);

    for (int i = 0; i < argc; i++)
	argv->data[i] = (void *)(*pargv)[i];

    j = 1;			// leave argv[0] alone
    while (1)
    {
	wildcard = 1;
	switch (*env)
	{
	    case ' ':
	    case '\t':
		env++;
		break;

	    case 0:
		goto Ldone;

	    case '"':
		wildcard = 0;
	    default:
		argv->push(env);		// append
		//argv->insert(j, env);		// insert at position j
		j++;
		argc++;
		p = env;
		slash = 0;
		instring = 0;
		c = 0;

		while (1)
		{
		    c = *env++;
		    switch (c)
		    {
			case '"':
			    p -= (slash >> 1);
			    if (slash & 1)
			    {	p--;
				goto Laddc;
			    }
			    instring ^= 1;
			    slash = 0;
			    continue;

			case ' ':
			case '\t':
			    if (instring)
				goto Laddc;
			    *p = 0;
			    //if (wildcard)
				//wildcardexpand();	// not implemented
			    break;

			case '\\':
			    slash++;
			    *p++ = c;
			    continue;

			case 0:
			    *p = 0;
			    //if (wildcard)
				//wildcardexpand();	// not implemented
			    goto Ldone;

			default:
			Laddc:
			    slash = 0;
			    *p++ = c;
			    continue;
		    }
		    break;
		}
	}
    }

Ldone:
    *pargc = argc;
    *pargv = (char **)argv->data;
}

#if _WIN32

long __cdecl __ehfilter(LPEXCEPTION_POINTERS ep)
{
    //printf("%x\n", ep->ExceptionRecord->ExceptionCode);
    if (ep->ExceptionRecord->ExceptionCode == STATUS_STACK_OVERFLOW)
    {
#ifndef DEBUG
	return EXCEPTION_EXECUTE_HANDLER;
#endif
    }
    return EXCEPTION_CONTINUE_SEARCH;
}

#endif
