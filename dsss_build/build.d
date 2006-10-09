/* *******************************************************
   Build is a tool to assist building applications and libraries written
   using the D programming language.

 Copyright:
   (c) 2005 Derek Parnell
   (c) 2006 Gregor Richards
 Authors:
   Derek Parnell, Melbourne
   Gregor Richards
 Initial Creation: January 2005
 Version: 3.03+DSSS
 Date: September 2006
 License:
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        Permission is hereby granted to anyone to use this software for any
        purpose, including commercial applications, and to alter it and/or
        redistribute it freely, subject to the following restrictions:$(NL)
        1. The origin of this software must not be misrepresented; you must
           not claim that you wrote the original software. If you use this
           software in a product, an acknowledgment within documentation of
           said product would be appreciated but is not required.$(NL)
        2. Altered source versions must be plainly marked as such, and must
           not be misrepresented as being the original software.$(NL)
        3. This notice may not be removed or altered from any distribution
           of the source.$(NL)
        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.
******************************************************* */

module build;
private import build_bn;    // This module's build number

version(unix)   version = Unix;
version(Unix)   version = Posix;
version(linux)  version = Posix;
version(darwin) version = Posix;
version(DigitalMars) version(Windows) version = UseResponseFile;

version(build)
{
    version(Windows) {
        // OptLink Definition File
        pragma (build_def, "VERSION 3.03");
    }
}


private{
    // --------- imports ----------------
    static import source;          // Source File class

    static import util.str;        // non-standard string routines.
    static import util.fdt;        // File Date-Time class
    static import util.pathex;     // Extended Path routines.
    static import util.fileex;     // Extended File routines.
    static import util.macro;      // Macro processing routines.
    static import util.booltype;   // definition of True and False
    alias util.booltype.True True;
    alias util.booltype.False False;
    alias util.booltype.Bool Bool;

    static import std.c.stdio;
    static import std.file;
    static import std.outbuffer;
    static import std.path;
    static import std.stdio;
    static import std.stream;
    static import std.string;

    version(Windows)
    {
        static import std.c.windows.windows;
    }

    version(linux)
    {
        static import std.c.linux.linux;
    }

    version(darwin)
    {
        static import std.c.darwin.darwin;
    }

    // --------- C externals ----------------
    extern (C)
    {
        int     system  (char *);
    }

    class BuildException : Error
    {
        this(char[] pMsg)
        {
            super (vAppName ~ ":" ~ pMsg);
        }
    }

    // --------- enums ----------------
    enum LibOpt {Implicit, Build, Shared, DontBuild}

    // --------- internal strings ----------------
    version(Windows) {
        char[] vExeExtention=`exe`;
        char[] vLibExtention=`lib`;
        char[] vObjExtention=`obj`;
        char[] vShrLibExtention=`dll`;
        char[] vLinkerStdOut = ">nul";
    }

    version(Posix) {
        char[] vExeExtention=``;
        char[] vLibExtention=`a`;
        char[] vObjExtention=`o`;
        char[] vShrLibExtention=`so`;
        char[] vLinkerStdOut = ">/dev/null";
    }
    char[] vSrcExtention=`d`;
    char[] vSrcDInterfaceExt = `di`;
    char[] vMacroExtention=`mac`;
    char[] vDdocExtention=`ddoc`;

    // ---------- Module scoped globals -----------
    version(DigitalMars) {
        version(Windows) {
            char[] vCompilerExe=`dmd.exe`;
            char[] vCompileOnly = `-c`;
            char[] vLinkerExe=`link.exe`;
            bool   vPostSwitches = true;
            bool   vAppendLinkSwitches = true;
            char[] vArgDelim = ",";
            char[] vArgFileDelim = "+";
            char[] vConfigFile=`sc.ini`;
            char[] vCompilerPath=``;
            char[] vLinkerPath=``;
            char[] vLinkerDefs=`/noi/map`;
            char[] vConfigPath=``;
            char[] vLibPaths = ``;
            char[] vConfigSep = ";";
            char[] vLibrarian = `lib.exe`;
            char[] vLibrarianOpts = `-c -p256`;
            bool   vShLibraries = false;
            char[] vShLibrarian = "";
            char[] vShLibrarianOpts = "";
            char[] vShLibrarianOutFileSwitch = "";
            char[] vHomePathId = "HOME";
            char[] vEtcPath    = "";
            char[] vSymInfoSwitch = "/co";
            char[] vOutFileSwitch = "-of";
            char[]     vLinkLibSwitch = "";
        }

        version(Posix) {
            char[] vCompilerExe=`dmd`;
            char[] vCompileOnly= `-c`;
            char[] vLinkerExe=`gcc`;
            bool   vPostSwitches = false;
            bool   vAppendLinkSwitches = false;
            char[] vArgDelim = " ";
            char[] vArgFileDelim = " ";
            char[] vConfigFile=`dmd.conf`;
            char[] vCompilerPath=``;
            char[] vLinkerPath=``;
            char[] vLinkerDefs=``;
            char[] vConfigPath=`/etc/`;
            char[] vLibPaths = ``;
            char[] vConfigSep = ":";
            char[] vLibrarian = `ar`;
            char[] vLibrarianOpts = `-r`;
            bool   vShLibraries = false;
            char[] vShLibrarian = "";
            char[] vShLibrarianOpts = "";
            char[] vShLibrarianOutFileSwitch = "";
            char[] vHomePathId = "HOME";
            char[] vEtcPath    = "/etc/";
            char[] vSymInfoSwitch = "-g";
            char[] vOutFileSwitch = "-o ";
            char[]     vLinkLibSwitch = "-l";
        }

        char[]     vVersionSwitch = "-version";
        char[]     vDebugSwitch = "-debug";
        char[][]   vCompilerDefs;
        char[]     vImportPath = "-I";
        bool       vUseModBaseName = false;
    }

    version(GNU) {
        version(Windows) {
            char[] vCompilerExe=`gdc.exe`;
            char[] vCompileOnly= `-c`;
            char[] vLinkerExe=`gdc.exe`;
            bool   vPostSwitches = false;
            bool   vAppendLinkSwitches = false;
            char[] vArgDelim = " ";
            char[] vArgFileDelim = " ";
            char[] vConfigFile=null;
            char[] vCompilerPath=``;
            char[] vLinkerPath=``;
            char[] vLinkerDefs=``;
            char[] vConfigPath=null;
            char[] vLibPaths = ``;
            char[] vConfigSep = ";";
            char[] vLibrarian = `ar.exe`;
            char[] vLibrarianOpts = `-c`;
            bool   vShLibraries = false;
            char[] vShLibrarian = "";
            char[] vShLibrarianOpts = "";
            char[] vShLibrarianOutFileSwitch = "";
            char[] vLinkLibSwitch = "-l";
            char[] vHomePathId = "HOME";
            char[] vEtcPath    = "";
            char[] vOutFileSwitch = "-o ";
        }

        version(Posix) {
            char[] vCompilerExe=`gdc`;
            char[] vCompileOnly= `-c`;
            char[] vLinkerExe=`gdc`;
            bool   vPostSwitches = false;
            bool   vAppendLinkSwitches = false;
            char[] vArgDelim = " ";
            char[] vArgFileDelim = " ";
            char[] vConfigFile=null;
            char[] vCompilerPath=``;
            char[] vLinkerPath=``;
            char[] vLinkerDefs=``;
            char[] vConfigPath=null;
            char[] vLibPaths = ``;
            char[] vConfigSep = ":";
            char[] vLibrarian = `ar`;
            char[] vLibrarianOpts = `-r`;
            bool   vShLibraries = true;
            char[] vShLibrarian = `gcc`;
            char[] vShLibrarianOpts = `-shared`;
            char[] vShLibrarianOutFileSwitch = `-o `;
            char[] vLinkLibSwitch = "-l";
            char[] vHomePathId = "HOME";
            char[] vEtcPath    = "/etc/";
            char[] vOutFileSwitch = "-rdynamic -o ";
        }
        char[]     vVersionSwitch = "-fversion";
        char[]     vDebugSwitch = "-fdebug";
        char[][]   vCompilerDefs;
        char[]     vImportPath = "-I ";
        char[]     vSymInfoSwitch = "-g";
        /* GDC places object files in the directory from which it is called */
        bool       vUseModBaseName = true;
    }

    char[]       vOverrideConfigPath = "";
    char[]       vBuildImportPath = "-I";
    char[]       vImportPathDelim = ";";
    char[]       vOutputPath = "-od";
    char[]       vRunSwitch = "-exec";
    char[]       vLibrarianPath = "";
    char[]*      vDelayedValue = null;
    char[]       vTemporaryPath = "";
    char[]       vLibPathSwitch = "-L";
    char[]       vMapSwitch = "-M";
    char[]       vGenDebugInfo = "-g";
    char[]       vResponseExt = "brf";
    char[]       vDefResponseFile = "build.brf";
    char[]       vDefMacroDefFile = "build.mdf";
    char[]       vUtilsConfigFile = "build.cfg";
    char[]       vPathId = "PATH";   // Used to locate the environment symbol

    char[]       vModOutPrefix = "MODULES = \n";
    char[]       vModOutSuffix = "";
    char[]       vModOutBody   = "    $(MODULE {mod})\n";
    char[]       vModOutDelim  = "";
    char[]       vModOutFile   = "_modules.ddoc";

    char[][]     vFinalProc;

    Bool         vTestRun;
    Bool         vScanImports;
    Bool         vNoLink;
    Bool         vForceCompile;
    Bool         vSilent;
    Bool         vSymbols;
    Bool         vCleanup;
    version(BuildVerbose) Bool         vVerbose;
    Bool         vMacroInput;
    Bool         vCollectUses;
    Bool         vNames;
    Bool         vAllObjects;
    Bool         vNoDef;
    Bool         vAutoImports;
    Bool         vExecuteProgram;
    Bool         vUseResponseFile;
    Bool         vConsoleApp;

    char[]       vUsesOutput;
    char[]       vSymbolOutName;
    char[]       vRunParms;
    char[]       vTargetExe;
    char[][]     vImportRoots;
    char[][]     vModulesToIgnore;
    char[][]     vModulesToNotice;
    char[][]     vBuildDef;
    char[][]     vDefaultLibs;
    LibOpt       vLibraryAction = LibOpt.Implicit;
    char[]       vAppPath;
    char[]       vAppName;
    char[]       vAppVersion = "3.03";
    char[]       vTargetName;           // Output name from first file name.
    char[]       vPragmaTargetName;     // Output name from pragma.
    char[]       vCommandTargetName;    // Output name from switches.
    char[][]     vCmdLineSourceFiles;   // List of source files from command line
    bool[char[]] vLinkFiles;            // List of non-source files from command line
    char[][]     vCombinedArgs;         // All the args are gathered here prior to processing.
    char[][]     vBuildArgs;            // Arguments passed to build
    char[][]     vCompilerArgs;         // Arguments passed to compiler
    char[][]     vSourceScanList;       // The list of places to find source files.
    bool[char[]] vResourceFileTypes;
    char[][]     vUDResTypes;


    version(Windows)
    {
        char[]       vWinVer = "";
        ubyte        vWinVerNum;
        bool         vAutoWinLibs = true;
    }

}

// Module constructor.
//-------------------------------------------------------
static this()
//-------------------------------------------------------
{
    // Force the 'build' version to be active.
    source.ActivateVersion("build");

    vSourceScanList ~= "." ~ std.path.sep;
    vNoLink = False;
    vTestRun = False;
    vScanImports = False;
    vForceCompile = False;
    vSilent = False;
    vCleanup = False;
    version(BuildVerbose) vVerbose = False;
    vMacroInput = True;
    vCollectUses = False;
    vNames = False;
    vAllObjects = False;
    vNoDef = False;
    vAutoImports = True;
    vExecuteProgram = False;
    vUseResponseFile = False;
    vSymbols = False;
    vConsoleApp = True;

    version(Posix)
    {
        vCompilerDefs ~= vVersionSwitch ~ "=Posix"; // Until such time as this is standard in dmd.
    }

    version(Windows) {
        vWinVerNum = cast(ubyte)(std.c.windows.windows.GetVersion() & 0xFF);
        vWinVer = std.string.format("%d.0", vWinVerNum);
     }

    vUseResponseFile = False;
    version(UseResponseFile) vUseResponseFile = True;

    util.str.SetEnv("@P", std.path.getDirName(vConfigPath));
    util.str.SetEnv("@D", std.path.getDirName(vCompilerPath));

    source.Source.UseModBaseName(vUseModBaseName);

}

//-------------------------------------------------------
void DisplayUsage(bool pFull = true)
//-------------------------------------------------------
{

    std.stdio.writefln(
        "Path and Version : %s v%s(%d)\n  built on %s"
            ,vAppPath, vAppVersion, build_bn.auto_build_number,
            __TIMESTAMP__);
    if (pFull == false)
        return;
    else {

    std.stdio.writefln(
        "Usage: %s sourcefile [options objectfiles libraries]"
            , vAppName);
    std.stdio.writefln("  sourcefile D source file");
    std.stdio.writefln("  -v         Verbose (passed through to D)");
    std.stdio.writefln("  -V         Verbose (NOT passed through)");
    std.stdio.writefln("  -names     Displays the names of the files used in building the target.");
    std.stdio.writefln("  -DCPATH<path> <path> is where the compiler has been installed.");
    std.stdio.writefln("             Only needed if the compiler is not in the system's");
    std.stdio.writefln("             PATH list. Used if you are testing an alternate");
    std.stdio.writefln("             version of the compiler.");
    std.stdio.writefln("  -CFPATH<path> <path> is where the D config file has been installed.");
    std.stdio.writefln("  -full      Causes all source files, except ignored modules,");
    std.stdio.writefln("              to be compiled.");
    std.stdio.writefln("  -link      Forces the linker to be called instead of the librarian.");
    std.stdio.writefln("              (Only needed if the source files do not contain");
    std.stdio.writefln("               main/WinMain)");
    std.stdio.writefln("  -nolink    Ensures that the linker is not called.");
    std.stdio.writefln("              (Only needed if main/WinMain is found in the source");
    std.stdio.writefln("               files and you do NOT want an executable created.)");
    std.stdio.writefln("  -lib       Forces the object files to be placed in a library.");
    std.stdio.writefln("              (Only needed if main/WinMain is found in the source");
    std.stdio.writefln("               files AND you want it in a library instead of");
    std.stdio.writefln("               an executable.)");
    std.stdio.writefln("  -shlib     Forces the object files to be placed in a shared library.");
    std.stdio.writefln("  -shlib-support");
    std.stdio.writefln("             Output 'yes' and return a successful exit code if shared");
    std.stdio.writefln("             libraries are supported, otherwise output 'no' and return");
    std.stdio.writefln("             a failure exit code.");
    std.stdio.writefln("  -nolib     Ensures that the object files are not used to form");
    std.stdio.writefln("              a library.");
    std.stdio.writefln("              (Only needed if main/WinMain is not found in the source");
    std.stdio.writefln("               files and you do NOT want a library.");
    std.stdio.writefln("  -obj       This is the same as having both -nolib and -nolink switches.");
    std.stdio.writefln("  -allobj    Ensures that all object files are added to a");
    std.stdio.writefln("              library.");
    std.stdio.writefln("              (Normally only those in the same directory are added.)");
    std.stdio.writefln("  -cleanup   Ensures that all object files created during the run");
    std.stdio.writefln("              are removed at the end of the run, plus other work files.");
    std.stdio.writefln("  -clean     Same as -cleanup");
  version(Windows) {
    std.stdio.writefln("  -gui[:x.y] Forces a GUI application to be created. The optional");
    std.stdio.writefln("              :x.y can be used to build an application for a ");
    std.stdio.writefln("              specific version of Windows. eg. -gui:4.0");
    std.stdio.writefln("              (Only needed if WinMain is not found in the source files");
    std.stdio.writefln("               or if you wish to override the default Windows version)");
    std.stdio.writefln("  -dll       Forces a DLL library to be created.");
    std.stdio.writefln("              (Only needed if DllMain is not found in the source files.)");
   }

    std.stdio.writefln("  -LIBOPT<opt> Allows you to pass <opt> to the librarian.");
    std.stdio.writefln("  -SHLIBOPT<opt> Allows you to pass <opt> to the shared-librarian.");
    std.stdio.writefln("  -LIBPATH=<pathlist> Used to add a semi-colon delimited list");
    std.stdio.writefln("                of search paths for library files.");
    std.stdio.writefln("  -MDF<path> Overrides the default Macro Definition File");
    std.stdio.writefln("  -test      Does everything as normal except it displays the commands");
    std.stdio.writefln("              instead of running them.");
    std.stdio.writefln("  -RDF<path> Overrides the default Rule Definition File");
    std.stdio.writefln("  -R=<Yes|No> Indicates whether to use a response file or command line");
    std.stdio.writefln("              arguments with the compiler tools.");
    std.stdio.writefln("               -R=Yes will cause a response to be used.");
    std.stdio.writefln("               -R=No will cause command line arguments to be used.");
    std.stdio.writefln("               -R will reverse the current usage.");
    std.stdio.writefln("  -PP<path>  Add a path to the Source Search List");

  version(UseResponseFile)
    std.stdio.writefln("               ** The default is to use a response file");
  else
    std.stdio.writefln("               ** The default is to use command line arguments");

    std.stdio.writefln("  -exec<param> If the link is successful, this will cause the");
    std.stdio.writefln("               executable just created to run. You can give it ");
    std.stdio.writefln("               run time parameters. Anything after the '-exec' will");
    std.stdio.writefln("               placed in the program's command line. You will need");
    std.stdio.writefln("               to quote any embedded spaces.");
    std.stdio.writefln("  -od<path>  Nominate the directory where temporary (work) files");
    std.stdio.writefln("             are to be created. By default they are created in");
    std.stdio.writefln("             the same directory as the target file.");
    std.stdio.writefln("  -X<module> Modules/Packages to ignore (eg. -Xmylib)");
    std.stdio.writefln("  -M<module> Modules/Packages to notice (eg. -Mphobos)");
    std.stdio.writefln("  -T<targetname> The name of the target file to create. Normally");
    std.stdio.writefln("              the target name istaken from the first or only name");
    std.stdio.writefln("              of the command line.");
    std.stdio.writefln("  -help     Displays the full 'usage' help text. ");
    std.stdio.writefln("  -h        Same as -help, displays the full 'usage' help text.");
    std.stdio.writefln("  -?        Same as -help, displays the full 'usage' help text.");
    std.stdio.writefln("  -silent   Avoids unnecessary messages being displayed.");
    std.stdio.writefln("  -noautoimport Turns off the automatic addition of source paths");
    std.stdio.writefln("              to the list of Import Roots.");
    std.stdio.writefln("  -info      Displays the version and path of the Build application.");
    std.stdio.writefln("  -nodef    Prevents a Module Definition File from being created.");
    std.stdio.writefln("  -UMB=<Yes/No> If 'Yes' this forces the utility to expect");
    std.stdio.writefln("            the object file to be created or residing in the current");
    std.stdio.writefln("            directory.");
    version(Windows)
    {
    std.stdio.writefln("  -AutoWinLibs=<Yes/No> If 'No' this prevents the tool from");
    std.stdio.writefln("              passing the standard set of Windows libraries");
    std.stdio.writefln("              to the linker for GUI applications. 'Yes' is");
    std.stdio.writefln("              is the default.");
    }
    std.stdio.writefln("  [...]      All other options, objectfiles and libraries are");
    std.stdio.writefln("              passed to the compiler");
    std.stdio.writefln("*Note, you can specify all or any command line value in a ");
    std.stdio.writefln("   response file. Each value appears in its own line in the");
    std.stdio.writefln("   response file and you reference this file by prefixing");
    std.stdio.writefln("   its name with an '@' symbol on the command line.");
    std.stdio.writefln("   Example:  build @final");
    std.stdio.writefln("      where a file called 'final.brf' contains the command");
    std.stdio.writefln("      line values (including other response file references)");
    std.stdio.writefln("   If the response file reference is just a single '@' then");
    std.stdio.writefln("   build looks for a file called 'build.brf'");
}
}

// Scans all known source files and extacts any modules.
// It returns the time of the most recently modified file.
//-------------------------------------------------------
util.fdt.FileDateTime GetNewestDateTime()
//-------------------------------------------------------
{
    source.Source lSource;
    int i;

    util.fdt.FileDateTime lModsTime = new util.fdt.FileDateTime();

    source.Source.AllFiles(
        delegate int (inout int i, inout source.Source lSource)
        {
            // Get the next Source object to examine.
            if (lSource.Ignore)
                return 0;

            // Ensure that it has been processed.
            lSource.search();

            version(BuildVerbose)
            {
                if(vVerbose == True) {
                    std.stdio.writefln("source file[%d] %s", i,
                            util.pathex.AbbreviateFileName(lSource.FileName));
                }
                else if(vNames == True) {
                    std.stdio.writefln(" [ %s ]", util.pathex.AbbreviateFileName(lSource.FileName));
                }
            } else {
                if(vNames == True) {
                    std.stdio.writefln(" [ %s ]", util.pathex.AbbreviateFileName(lSource.FileName));
                }
            }

            if (lSource.DependantsTime > lModsTime)
            {
                version(BuildVerbose)
                {
                    if(vVerbose == True)
                        std.stdio.writefln("Newer time: from %s to %s",
                                    lModsTime.toString(),
                                    lSource.DependantsTime.toString()
                                );
                }

                lModsTime = lSource.DependantsTime;
            }

            return 0;
        }
    );

    // Examine any link file dependancies too.
    foreach(int idx, char[] lFileName; vLinkFiles.keys)
    {
        util.fdt.FileDateTime lLinkTime = new util.fdt.FileDateTime(lFileName);

        version(BuildVerbose)
        {
            if(vVerbose == True) {
                std.stdio.writefln("link file[%d] %s %s", idx,
                        util.pathex.AbbreviateFileName(lFileName), lLinkTime.toString());
            }
            else if(vNames == True) {
                std.stdio.writefln(" [ %s ]", util.pathex.AbbreviateFileName(lFileName));
            }
        } else {
            if(vNames == True) {
                std.stdio.writefln(" [ %s ]", util.pathex.AbbreviateFileName(lFileName));
            }
        }
        if (lLinkTime > lModsTime)
        {
            version(BuildVerbose)
            {
                if(vVerbose == True)
                    std.stdio.writefln("Newer time: from %s to %s",
                                lModsTime.toString(),
                                lLinkTime.toString()
                            );
            }

            lModsTime = lLinkTime;
        }
    }

    return lModsTime;
}


/* Build the target.  Return an error code if there
    was a problem, else return zero.
*/
//-------------------------------------------------------
int Build()
//-------------------------------------------------------
{
    Bool        lCompiling;
    Bool        lLinking;
    Bool        lBuildRequired;
    char[][]    lFilesToLink;
    char[][]    lFilesToCompile;
    int         lRunResult;
    char[]      lTargetName;
    char[]      lTargetDir;
    util.fdt.FileDateTime lTargetTime;
    util.fdt.FileDateTime lMostRecentTime;
    auto source.Source[]    lNonLinkingSources;
    char[]      lDResponseFileName;
    char[]      lLinkResponseFileName;
    char[]      lLResponseFileName;
    char[]      lDefName;
    char[]      lOutText;
    char[]      lCompilerOpts;
    char[]      lSourcesToCompile;
    char[]      lCommand;
    char[][]    lObjectFiles;
    char[][]    lLibraryFiles;


    lCompiling = False;
    lLinking = False;
    lBuildRequired = False;

    // Examine each supplied source file.
    foreach( char[] lFile; vCmdLineSourceFiles)
    {
        lFile = GetFullPathname(lFile, vSourceScanList);
        if (std.path.getExt(lFile) == vMacroExtention)
        {
            version(BuildVerbose)
            {
                if (vVerbose == True)
                    std.stdio.writefln("Macro file '%s' being processed.", lFile);
            }

            char[] lAltFile = std.path.addExt( lFile, vSrcExtention); // Make it a D source file.
            if (util.macro.ConvertFile(lFile, "build", lAltFile))
                lFile = lAltFile;
            else
            {
                version(BuildVerbose)
                {
                    if ((vSilent != True) || (vVerbose == True))
                        std.stdio.writefln("Macro file '%s' failed to generate output", lFile);
                } else {
                    if (vSilent != True)
                        std.stdio.writefln("Macro file '%s' failed to generate output", lFile);
                }
                lFile.length = 0;
            }
        }

        if (lFile.length > 0)
        {
            new source.Source(lFile);
        }
    }

    // I'm linking if I'm not building a library, and a 'main' was
    // found, and I was not explicitly told not to link.
    lLinking =  (vLibraryAction == LibOpt.Build) ||
                (vLibraryAction != LibOpt.Shared && source.Source.WasMainFound == false) ||
                (vNoLink == True)
               ? False : True;

    lMostRecentTime = GetNewestDateTime();

    // If not explictly known, set the library action
    // based on whether or not 'main' was found in the sources.
    if (vLibraryAction == LibOpt.Implicit) {
        if (source.Source.WasMainFound){
            vLibraryAction = LibOpt.DontBuild;
        }
        else {
            vLibraryAction = LibOpt.Build;
        }
    }

    // I'm either creating a library, an executable or neither.

    // If a target name was supplied in a pragma, use that as the
    // default target name.
    if (vPragmaTargetName.length != 0)
    {
        vTargetName = vPragmaTargetName;
        version(BuildVerbose)
        {
            if(vVerbose == True)
                std.stdio.writefln("Pragma target override is '%s'", std.path.getName(vTargetName));
        }

    }

    // If a target name was supplied on the command line, use that
    // instead of the default name.
    if (vCommandTargetName.length != 0)
    {
        vTargetName = util.str.Expand(vCommandTargetName, "Target=" ~
            util.pathex.GetBaseName(vTargetName));
        version(BuildVerbose)
        {
            if(vVerbose == True)
                std.stdio.writefln("Cmdline target override is '%s'", vTargetName);
        }
    }

    // Ensure that the path to the target's location will exist.
    util.pathex.MakePath(vTargetName);

    if (vLibraryAction == LibOpt.Build ||
        vLibraryAction == LibOpt.Shared)
        // CHANGE: don't mess around with the specified extension
        lTargetName = vTargetName;

    else if (vNoLink == False)
    {
        if (source.Source.WasMainFound)
            if (source.Source.WasMainDLL)
                // Target is a shared library.
                lTargetName = util.pathex.ReplaceExtention(vTargetName, vShrLibExtention);
            else
            {
                // Target is an executable
                lTargetName = util.pathex.ReplaceExtention(vTargetName, vExeExtention);
                vTargetExe = lTargetName;
            }
        else
        {
            // Possible error. The user wants to link but no 'main' detected
            // so assume they know what they are doing and also assume an
            // executable is required.
            lTargetName = util.pathex.ReplaceExtention(vTargetName, vExeExtention);
            vTargetExe = lTargetName;
        }
    }
    else
        // Not linking and not archiving, so no target is required.
        lTargetName = "";

    if (lTargetName.length > 0)
    {
        // Get the full name of the target's location.
        lTargetName = util.pathex.CanonicalPath(lTargetName, false);
        lTargetDir = std.path.getDirName(lTargetName);

        // Show user if required to.
        version(BuildVerbose)
        {
            if((vVerbose == True) || (vNames == True) )
                std.stdio.writefln("\nBuilding target '%s'", lTargetName);
        }

        // Shorten the target name for future usages.
        lTargetName = util.pathex.AbbreviateFileName(lTargetName);


        // If the target doesn't exist or it is older than
        // most recently modified dependant file, we need to
        // rebuild the target.
        lTargetTime = new util.fdt.FileDateTime (lTargetName);
        version(BuildVerbose)
        {
            if(vVerbose == True) {
                std.stdio.writefln("Time %s for %s (target)", lTargetTime.toString(), lTargetName);
                std.stdio.writefln("Time %s (most recent)", lMostRecentTime.toString());
            }
        }

        if(lTargetTime < lMostRecentTime) {
            lBuildRequired = True;
        }
    }
    else
    {
        version(BuildVerbose)
        {
            if((vVerbose == True) || (vNames == True) )
                std.stdio.writefln("\nCompiling only. No target will be built.");
        } else {
            if(vNames == True)
                std.stdio.writefln("\nCompiling only. No target will be built.");
        }
    }

    if (source.Source.FileCount == 0)
    {
        /* It is possible to only have object and library
           files on the command line, in which case we
           just need to link them rather than compile.
        */

        // No files to compile, just link files, so collect
        // all the object files to link in.
        foreach( char[] lFileName; vLinkFiles.keys)
        {
            // Only include OBJECT files.
            if (util.str.ends(lFileName , vObjExtention) == True)
                lFilesToLink ~= lFileName;
        }
    }
    else
    {
        int lInitCount;

        do
        {
            lInitCount = source.Source.FileCount;
            source.Source.AllFiles(
                delegate int (inout int i, inout source.Source lCurrentSource)
                {
                    if (lCurrentSource.HasBeenScanned == false)
                    {
                        lCurrentSource.search();
                    }
                    return 0;
                }
            );
        } while (lInitCount != source.Source.FileCount);

        source.Source.AllFiles(
            delegate int (inout int i, inout source.Source lCurrentSource)
            {
                // Check each source to see if we need to recompile it.
                Bool lNeedsCompiling;
                char[] lShortFileName;
                char[] lFileType;

                lNeedsCompiling = vForceCompile;

                if (lCurrentSource.Ignore)
                    return 0;

                lShortFileName = util.pathex.AbbreviateFileName(lCurrentSource.FileName);
                lFileType = std.path.getExt(lShortFileName);
                if (lFileType != vSrcExtention && lFileType != vDdocExtention)
                    return 0;

                // Only source files are examined from here on.
                if (lCurrentSource.NoLink || lFileType == vDdocExtention)
                {
                    lNonLinkingSources ~= lCurrentSource;
                }

                if(lCurrentSource.FilesTime > lCurrentSource.ObjectsTime)
                {
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("%s newer than its object file", lShortFileName);
                    }

                    lNeedsCompiling = True;

                } else if(lCurrentSource.DependantsTime > lCurrentSource.ObjectsTime) {
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("%s has newer dependants than its object file.",
                                        lShortFileName);
                    }

                    lNeedsCompiling = True;
                }

                if(lNeedsCompiling == True)
                {
                    lBuildRequired = True;
                    lCompiling = True;
                    lFilesToCompile ~= lShortFileName;

                    // Check to see if I'm allowed to link this file.
                    if (lCurrentSource.NoLink == false)
                        lFilesToLink ~= util.pathex.AbbreviateFileName(lCurrentSource.ObjectName);

                    if (vTestRun == False)
                    {
                        if (lCurrentSource.IncrementBuildNumber())
                        {
                            version(BuildVerbose)
                            {
                                if (vVerbose == True)
                                    std.stdio.writefln("New build number %d for %s",
                                               lCurrentSource.BuildNumber,
                                                lCurrentSource.ModuleName);
                            }
                        }
                    }
                }
                else if (lCurrentSource.NoLink == false)
                {
                    lFilesToLink ~= util.pathex.AbbreviateFileName(lCurrentSource.ObjectName);
                }

                return 0;
            }
        );
    }

    if( lBuildRequired == False )
    {
        if (vSilent == False)
            std.stdio.writefln ("Files are up to date, no build required.");
        return 0;
    }

    foreach(char[] lFileName; lFilesToCompile)
    {
        lSourcesToCompile ~= util.str.enquote(lFileName) ~ "\n";
    }

    // Construct a Optlink Definition file if requested to.
    version(Windows)
    {
        if (source.Source.WasMainGUI) {
            AddBuildDef("EXETYPE NT");
            if (vWinVer.length != 0)
                AddBuildDef("SUBSYSTEM WINDOWS," ~ vWinVer);
            else
                AddBuildDef("SUBSYSTEM WINDOWS");
            if (vAutoWinLibs == true)
            {
                vDefaultLibs ~= "gdi32.lib";
                vDefaultLibs ~= "advapi32.lib";
                vDefaultLibs ~= "COMCTL32.LIB";
                vDefaultLibs ~= "comdlg32.lib";
                vDefaultLibs ~= "CTL3D32.LIB";
                vDefaultLibs ~= "kernel32.lib";
                vDefaultLibs ~= "ODBC32.LIB";
                vDefaultLibs ~= "ole32.lib";
                vDefaultLibs ~= "OLEAUT32.LIB";
                vDefaultLibs ~= "shell32.lib";
                vDefaultLibs ~= "user32.lib";
                vDefaultLibs ~= "uuid.lib";
                vDefaultLibs ~= "winmm.lib";
                vDefaultLibs ~= "winspool.lib";
                vDefaultLibs ~= "wsock32.lib";
            }
        }
        else if (source.Source.WasMainDLL) {
            AddBuildDef(`LIBRARY "` ~ std.path.getBaseName(lTargetName) ~ `"`);
            AddBuildDef("EXETYPE NT");
            if (vWinVer.length != 0)
                AddBuildDef("SUBSYSTEM WINDOWS," ~ vWinVer);
            else
                AddBuildDef("SUBSYSTEM WINDOWS");
            AddBuildDef("CODE PRELOAD DISCARDABLE SHARED EXECUTE");
            AddBuildDef("DATA PRELOAD SINGLE WRITE");
        }
        else if (vConsoleApp == True) {
            AddBuildDef(`EXETYPE DOS`);
        }

        if ((vNoDef == False) && (vBuildDef.length > 0))
        {
            lDefName = util.pathex.ReplaceExtention(lTargetName, "def");
            if (vTemporaryPath.length != 0)
            {
                lDefName = vTemporaryPath ~ std.path.getBaseName(lDefName);
            }
            lDefName = util.pathex.AbbreviateFileName(lDefName);
            util.fileex.CreateTextFile(lDefName, vBuildDef);

        }
    }

    // Add any library and any external object files required.
    lLibraryFiles.length = 0;
    foreach (char[] lFileName; vLinkFiles.keys)
    {
        char[] lCmdItem;

        if (lFileName.length > 0)
        {
            lCmdItem = lFileName;
            if ( lCmdItem[0..2] == "-l")
            {
                lLibraryFiles ~= lCmdItem[2..$];
            }
            else if ( util.str.ends(lCmdItem, "." ~ vLibExtention) == True)
            {
                // Cut off extention.
                lCmdItem.length = lCmdItem.length - vLibExtention.length - 1;
                lLibraryFiles ~= lCmdItem;
            }
            else
            {
                lFilesToLink ~= lCmdItem;
            }
        }
    }

    if ((lLinking == True) || (lCompiling == True))
    {
        // COMPILE phase ...
        if (lSourcesToCompile.length > 0)
        {
            // Ok, I have some compiling to do!
            char[] lCommandLine;

            lCommandLine = GatherCompilerArgs(lLinking) ~ lSourcesToCompile;

            if (vUseResponseFile == True)
            {
                lDResponseFileName = util.pathex.ReplaceExtention(lTargetName, "rsp");
                if (vTemporaryPath.length != 0)
                {
                    lDResponseFileName = vTemporaryPath ~ std.path.getBaseName(lDResponseFileName);
                }
                lDResponseFileName = util.pathex.AbbreviateFileName(lDResponseFileName);
                util.fileex.CreateTextFile(lDResponseFileName,lCommandLine);
                lCommand = vCompileOnly ~ " @" ~ lDResponseFileName;
            }
            else
            {   // using commandline; may run into limits
                lCommandLine=std.string.replace(lCommandLine, "\n", " ");
                lCommand = vCompileOnly ~ " " ~ lCommandLine;
            }

            version(BuildVerbose)
            {
                if (vVerbose == True)
                    std.stdio.writefln("Compiling with ..........\n%s\n", lCommandLine);
            }

            // Run Compiler to compile the source files that need it.
            lRunResult = util.fileex.RunCommand(vCompilerPath ~ vCompilerExe, lCommand);
            if (lRunResult != 0)
                vExecuteProgram = False;
        }

        // LINK phase ...
        if ( (lRunResult == 0) && (lFilesToLink.length > 0) && (lLinking == True))
        {
            char[] lCommandLine;
            char[] lLinkerSwitches;
            Bool IsMapping = False;

            // Prepare list of known resource file types.
            if (vResourceFileTypes.length == 0)
            {
                if (vUDResTypes.length == 0)
                {
                    vUDResTypes ~= "res";
                }
                foreach( char[] lResType; vUDResTypes)
                {
                    vResourceFileTypes[lResType] = true;
                }
            }

            // Build the command line for the linker.
            lCommandLine = "";
            version(Windows)
            {
                // Transfer linker switches from Compiler switches.
                foreach (char[] lCompileArg; vCompilerArgs)
                {
                    if (util.str.begins(lCompileArg, "-L") == True)
                    {
                        lLinkerSwitches ~= lCompileArg[2..$] ~ vArgDelim;
                    }
                }
                foreach( char[] lSwitch; std.string.split(vLinkerDefs ~ lLinkerSwitches, "/"))
                {
                    if (lSwitch == "nomap")
                    {
                        IsMapping = False;
                    }
                    else if (lSwitch == "map")
                    {
                        IsMapping = True;
                    }
                }

                // (1) Gather the object file names
                foreach(char[] lFile; lFilesToLink)
                {
                    // Only include OBJECT files.
                    if (std.path.getExt(lFile) == vObjExtention)
                        lCommandLine ~= lFile ~ vArgFileDelim;
                }
                if (lCommandLine.length > 0)
                    lCommandLine[$-1] = '\n';

                // (2) Set the output file name
                lCommandLine ~= util.str.enquote(util.pathex.AbbreviateFileName(lTargetName)) ~ "\n";

                // (3) Set the map name
                if (IsMapping == True)
                    lCommandLine ~= util.pathex.ReplaceExtention(lTargetName, "map");

                lCommandLine ~= "\n";

                // (4) Gather the libraries names.
                // Include the default libraries first.
                if (vLibraryAction != LibOpt.Shared)
                    lLibraryFiles = vDefaultLibs ~ lLibraryFiles;
                if (lLibraryFiles.length > 0)
                {
                    foreach( char[] lLib; lLibraryFiles)
                    {
                        lLib =  std.path.addExt(lLib, vLibExtention);
                        lCommandLine ~= vLinkLibSwitch ~ util.str.enquote(lLib) ~ "\n";
                    }
                }
                else
                    lCommandLine ~= "\n";

                // Include the explictly named libraries.
                if (vLibPaths.length > 1)
                {
                    if (vLibPaths[0..1] == vConfigSep)
                        vLibPaths = vLibPaths[1..$];

                    // Include the paths to the libraries.
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("Setting LIB=%s", vLibPaths);
                    }
                    util.str.SetEnv("LIB",vLibPaths[1..$]);
                }

                // (5) Set the 'def' file name
                if (lDefName.length > 0)
                    lCommandLine ~= util.str.enquote(lDefName) ~ "\n";
                else
                    lCommandLine ~= "\n";

                // (6) Gather the resource file names
                {
                    int lCnt;

                    foreach(char[] lFile; lFilesToLink)
                    {
                        char[] lExt;

                        lExt = std.path.getExt(lFile);
                        lCnt = 0;
                        // Only include fiels with the correct extention type.
                        if (lExt in vResourceFileTypes)
                        {
                            lCommandLine ~= lFile;
                            lCnt++;
                        }
                        if (lCnt > 0)
                            lCommandLine ~= vArgFileDelim;
                    }
                    if (lCnt > 0)
                        lCommandLine[$-1] = '\n';
                    else
                        lCommandLine ~= "\n";
                }

                // (7) Gather then switches
                lLinkerSwitches = util.str.strip(vLinkerDefs ~ lLinkerSwitches);
            }

            version(Posix)
            {
                // Transfer linker switches from Compiler switches.
                foreach (char[] lCompileArg; vCompilerArgs)
                {
                    if (util.str.begins(lCompileArg, "-L") == True)
                    {
                        lLinkerSwitches ~= lCompileArg[2..$] ~ vArgDelim;
                    }
                }

                // (1) Gather the object and resource file names
                foreach(char[] lFile; lFilesToLink)
                {
                    lCommandLine ~= lFile ~ "\n";
                }

                // (2) Set the output file name
                if (vLibraryAction == LibOpt.Shared) {
                    lCommandLine ~= vShLibrarianOutFileSwitch;
                } else {
                    lCommandLine ~= vOutFileSwitch;
                }
                lCommandLine ~= util.str.enquote(util.pathex.AbbreviateFileName(lTargetName)) ~ "\n";

                // (3) Set the map name
                if (IsMapping == True)
                    lLinkerSwitches ~= vMapSwitch ~ vArgDelim;

                // (4) Gather the libraries names.
                // Include the default libraries first.
                if (vLibraryAction != LibOpt.Shared)
                    lLibraryFiles = vDefaultLibs ~ lLibraryFiles;
                foreach( char[] lLib; lLibraryFiles)
                {
                    lCommandLine ~= vLinkLibSwitch ~ util.str.enquote(lLib) ~ "\n";
                }

                if (vLibPaths.length > 1)
                {
                    if (vLibPaths[0..1] == vConfigSep)
                        vLibPaths = vLibPaths[1..$];

                    // Include the paths to the libraries.
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("Setting LIB=%s", vLibPaths);
                    }

                    char[][] lLibPaths;
                    lLibPaths = std.string.split(vLibPaths, vConfigSep);
                    foreach(char[] lLib; lLibPaths)
                    {
                        if (lLib.length > 0)
                            lCommandLine ~= vLibPathSwitch ~ util.str.enquote(lLib) ~ "\n";
                    }
                }

                // (5) Gather then switches
                lLinkerSwitches = util.str.strip(vLinkerDefs ~ lLinkerSwitches);
            }

            if (vUseResponseFile == True)
            {
                lLinkResponseFileName = util.pathex.ReplaceExtention(lTargetName, "ksp");
                if (vTemporaryPath.length != 0)
                {
                    lLinkResponseFileName = vTemporaryPath ~ std.path.getBaseName(lLinkResponseFileName);
                }
                lLinkResponseFileName = util.pathex.AbbreviateFileName(lLinkResponseFileName);

                if (vPostSwitches)
                {
                    if (vAppendLinkSwitches)
                    {
                        lCommandLine = util.str.stripr(lCommandLine);
                    }
                    lCommandLine ~= lLinkerSwitches ~ "\n";
                }
                else
                    lCommandLine = lLinkerSwitches ~ "\n" ~ lCommandLine;
                util.fileex.CreateTextFile(lLinkResponseFileName,lCommandLine);
                lCommand = "@" ~ lLinkResponseFileName;
            }
            else
            {   // using commandline; may run into limits
                if (vPostSwitches)
                    lCommandLine ~= lLinkerSwitches ~ "\n";
                else
                    lCommandLine = lLinkerSwitches ~ "\n" ~ lCommandLine;

                lCommandLine=std.string.replace(lCommandLine, "\n", vArgDelim);
                // Locate switches and change delim from a comma to a blank,
                // then remove any trailing comma too.
                if (lLinkerSwitches.length > 0)
                {
                    int lPos = std.string.find(lCommandLine, lLinkerSwitches[0]);
                    if (lPos > 0)
                        lCommandLine[lPos-1] = ' ';
                }

                if (util.str.ends(lCommandLine,vArgDelim) == True)
                    lCommandLine.length = lCommandLine.length - vArgDelim.length;
                lCommand = lCommandLine;
            }

            version(BuildVerbose)
            {
                if (vVerbose == True)
                    std.stdio.writefln("Linking with ..........\n%s\n", lCommandLine);
            }

            // Run Linker
            if (vSilent == True)
            {
                lCommand ~= " " ~ vLinkerStdOut;
            }

            if (vLibraryAction == LibOpt.Shared) {
                lCommand = " " ~ vShLibrarianOpts ~ " " ~ lCommand;
                lRunResult = util.fileex.RunCommand(vShLibrarian, lCommand);
            } else {
                lRunResult = util.fileex.RunCommand(vLinkerPath ~ vLinkerExe, lCommand);
            }
            if (lRunResult != 0)
                vExecuteProgram = False;
        }

    }
    else
    {
        if (vSilent == False)
            std.stdio.writefln("No build required.");
        lRunResult = 0;
    }

    // Now build a library if requested to.
    if ( (source.Source.WasMainDLL)  && (lRunResult == 0) )
    {
        char[] lTargetFileName;
        char[] lImpLibPath;
        char[] lImpLibArgs;
        ulong[] lImpManf;

        vExecuteProgram = False;

        lImpLibPath = util.pathex.LocateFile("implib.exe", util.str.GetEnv(vPathId));
        if (util.file2.FileExists(lImpLibPath))
        {
            lImpManf = util.fileex.FindInFile(lImpLibPath, "Borland");
            if (lImpManf.length != 0)
                lImpLibArgs ~= "-a";
            else
                lImpLibArgs ~= "/system";

            lTargetFileName = std.path.getBaseName(lTargetName);
            lRunResult = util.fileex.RunCommand(lImpLibPath, lImpLibArgs ~
                                       " " ~ std.path.addExt(lTargetFileName, "lib") ~
                                       " " ~ std.path.addExt(lTargetFileName, "dll") );
        }
    }
    else if ( (vLibraryAction == LibOpt.Build) && (lRunResult == 0))
    {
        int lFileCount;

        vExecuteProgram = False;

        if (vLibraryAction == LibOpt.Build) {
            lOutText = vLibrarianOpts ~ std.path.linesep;
        } else {
            lOutText = vShLibrarianOpts ~ std.path.linesep ~ vShLibrarianOutFileSwitch;
        }
        lOutText ~= lTargetName ~  std.path.linesep;  // Create a new library

        foreach( char[] lFileName; lFilesToLink)
        {
            char[] lFileDir;

            lFileDir = std.path.getDirName(lFileName);
            if ((vAllObjects == True) || lFileDir == "" || lFileDir == lTargetDir)
            {
                if (lFileName.length > 1 + vSrcExtention.length)
                {
                    if (lFileName[$-vSrcExtention.length .. $] == vSrcExtention)
                    {
                        lFileName = lFileName[0..$-vSrcExtention.length] ~ vObjExtention;
                    }
                }
                lFileCount++;
                lOutText ~= lFileName ~ std.path.linesep;
            }
        }
        
        if (lFileCount > 0)
        {
            if (vUseResponseFile == True) {
                lLResponseFileName = util.pathex.ReplaceExtention(lTargetName, "lsp");
                if (vTemporaryPath.length != 0)
                {
                    lLResponseFileName = vTemporaryPath ~ std.path.getBaseName(lLResponseFileName);
                }
                util.fileex.CreateTextFile(lLResponseFileName,lOutText);
                lCommand = "@" ~ lLResponseFileName;
            }
            else
            {   // using commandline, may run into limits
                lCommand  = std.string.replace(lOutText,std.path.linesep," ");
            }

            version(BuildVerbose)
            {
                // FIXME: this verbosity should include shared librarian
                if (vVerbose == True)
                    std.stdio.writefln("Librarian with ..........\n%s\n", lOutText);
            }

            if (vLibraryAction == LibOpt.Build) {
                lRunResult = util.fileex.RunCommand(vLibrarianPath ~ vLibrarian, lCommand);
            } else {
                lRunResult = util.fileex.RunCommand(vShLibrarian, lCommand);
            }
        }
    }

    // Optional clean up.
    if (vCleanup == True)
    {
        char[][] lHitList;

        version(BuildVerbose)
        {
            if (vVerbose == True)
                std.stdio.writefln("Cleaning up ...");
        }

        source.Source.AllFiles(
            delegate int (inout int i, inout source.Source lSource)
            {
                if (lSource.Ignore)
                    return 0;

                if (lSource.ObjectName.length > 0)
                {
                    lHitList ~= lSource.ObjectName;
                }
                return 0;
            }
        );
        // Build's own temprary files.
        lHitList ~= lDResponseFileName;
        lHitList ~= lLinkResponseFileName;
        lHitList ~= lLResponseFileName;
        lHitList ~= lDefName;

        // Possible ones created by compiler, linker, and librarian.
        lHitList ~= util.pathex.ReplaceExtention(lTargetName, "map");
        lHitList ~= util.pathex.ReplaceExtention(lTargetName, "bak");
        lHitList ~= util.pathex.ReplaceExtention(lTargetName, "lst");

        foreach(char[] lFilename; lHitList)
        {
            if (lFilename.length > 0)
            {
                if (util.file2.FileExists( lFilename ) )
                {
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("  removing %s", lFilename);
                    }
                    std.file.remove(lFilename);
                }
            }
        }

    }

    foreach(char[] lFinal; vFinalProc)
    {
        char[] lCommandLine;

        lCommandLine = util.str.Expand(lFinal, "Target=" ~ lTargetName ~
                                               ",TargetPath=" ~ std.path.getDirName(lTargetName) ~
                                               ",TargetBase=" ~ std.path.getBaseName(lTargetName)
                         );
        if (lCommandLine.length > 0)
        {
            util.fileex.RunCommand(lCommandLine);
        }
    }
    return lRunResult;

}

// -------------------------------------------
char [] GatherCompilerArgs(Bool pLinking)
// -------------------------------------------
{
    char[] lOutText;

    foreach(char [] lRoot; vImportRoots)
    {
        version(Posix)
            AddCompilerArg( vImportPath ~ "\"" ~ lRoot ~ "\"" );
        version(Windows)
            AddCompilerArg( vImportPath ~ lRoot );
    }

    // Build command files for compilation.
    foreach (char[] lCompileArg; vCompilerArgs)
    {
        // Ignore empty args
        if (lCompileArg.length > 0)
        {
            // Enclose in quotes if no quotes are currently present.
            if (std.string.find(lCompileArg, "\"") == -1)
                // Arguments containing a blank need to be quoted.
                if (std.string.find(lCompileArg, " ") != -1)
                {
                    // Strip off any trailing shell escape lead-in character.
                    if (lCompileArg[$-1] == '\\')
                        lCompileArg.length = lCompileArg.length - 1;
                    lOutText ~= std.string.format(`"%s"`, lCompileArg);
                }
                else
                    lOutText ~= lCompileArg;
            else
                lOutText ~= lCompileArg;

            // Terminate with a newline char.
            lOutText ~= "\n";
        }
    }

    if (pLinking == False)
    { // No linking allowed.
        if (vCompileOnly.length > 0)
        {
            if (std.string.find(vCompileOnly, " ") != -1)
                lOutText ~= std.string.format(`"%s"`,vCompileOnly);
            else
                lOutText ~= vCompileOnly;
            // Terminate with a newline char.
            lOutText ~= "\n";

            AddCompilerArg( vCompileOnly );
        }
    }

    return lOutText;
}


// -------------------------------------------
char[][] ModulesToIgnore()
// -------------------------------------------
{
    return vModulesToIgnore;
}


// -------------------------------------------
void AddLink(char[] pPath)
// -------------------------------------------
{
    if (pPath.length == 0)
        return;
    if ((pPath in vLinkFiles) is null)
        vLinkFiles[pPath] = true;
}

// -------------------------------------------
void AddTarget(char[] pPath)
// -------------------------------------------
{
    if (pPath.length == 0)
        return;

    if (vPragmaTargetName.length == 0)
        vPragmaTargetName = pPath;
    else
    {
        version(BuildVerbose)
        {
            if (vPragmaTargetName != pPath)
            {
                if (vVerbose == True)
                    std.stdio.writefln("Multiple pragma(target,...) detected. '%s' will be used and '%s' rejected.",
                                    vPragmaTargetName, pPath );
            }
        }
    }

}

// -------------------------------------------
void AddBuildDef(char[] pText, bool pReplace = false)
// -------------------------------------------
{
    int lPos;
    char[] lLowerText;
    static uint[ char[] ] lElementIdx;

    if (vNoDef == True)
        return;

    lLowerText = std.string.tolower(pText);

    lPos = std.string.find(lLowerText, ' ');
    if (lPos == -1)
        lPos = lLowerText.length;
    lLowerText.length = lPos;

    if (lLowerText in lElementIdx)
    {
        if (pReplace)
            vBuildDef[ lElementIdx[lLowerText] ] = pText;
    }
    else {
        vBuildDef ~= pText;
        lElementIdx[ lLowerText ] = vBuildDef.length-1;
    }
}

// -------------------------------------------
void AddCompilerArg(char[] pArg)
// -------------------------------------------
{
    bool lFound;

    if (pArg.length > 0)
    {
        // Translate exported version pragmas.
        if (pArg.length > 3)
        {
            if (pArg[0..3] == `+v+`)
                pArg = vVersionSwitch ~ "=" ~ pArg[3..$];
        }

        lFound = false;
        foreach(char[] lArg; vCompilerArgs)
        {
            if (lArg == pArg)
            {
                lFound = true;
                break;
            }
        }
        if (! lFound )
            vCompilerArgs ~= pArg;
    }
}

// -------------------------------------------
char[] AddRoot(char[] pRootName)
// -------------------------------------------
{
    static bool [char[]] lRootHash;
    char[] lFullName;
    char[] lSearchName;

    if(pRootName.length == 0)
        return pRootName;

    lFullName = util.pathex.CanonicalPath(pRootName);
    version(Windows) lSearchName = std.string.tolower(lFullName);
    version(Posix)   lSearchName = lFullName;
    if( !(lSearchName in lRootHash) )
    {
        vImportRoots ~= lFullName;
        lRootHash[lSearchName] = true;
        return lFullName;
    }
    else
        return "";

}

Bool AutoImports()
{
    return vAutoImports;
}

char[][] GetImportRoots()
{
    return vImportRoots;
}

void Process_DFLAGS(char[] pText)
{
    int      lPos;
    int      lEndPos;
    char[]   lRootName;
    char[][] lRoots;
    char[][] lArgs;
    int      lArg;
    bool     lInArg;
    char     lQuote;

    lInArg = false;
    lArg = -1;
    lQuote = 0;
    foreach (char lArgChar; pText)
    {
        if ( (lArgChar == '"') || (lArgChar == '\'') )
        {
            if (lQuote == lArgChar)
            {
                lQuote = 0;
                continue;
            }

            if (lQuote == 0)
            {
                lQuote = lArgChar;
                continue;
            }
        }

        if (lArgChar == ' ')
        {
            if (lQuote == 0)
            {
                lInArg = false;
                continue;
            }
        }

        if (lInArg == false)
        {
            lArg++;
            lArgs.length = lArg+1;
            lInArg = true;
        }
        lArgs[lArg] ~= lArgChar;

    }

    foreach(char[] lSwitch; lArgs)
    {
        if ((lSwitch.length > 0) && (lSwitch[0] == '-'))
        {
            if (vDelayedValue != null)
            {
                // Used when an switch needs the subsequent arg to
                // be its value.
                *vDelayedValue = lSwitch;
                vDelayedValue = null;
                vReceivedArgs[$-1].ArgText ~= " " ~ lSwitch;
                continue;
            }

            vReceivedArgs.length = vReceivedArgs.length + 1;
            vReceivedArgs[$-1].ArgText = lSwitch.dup;
            vReceivedArgs[$-1].CompilerArg = False;
            vReceivedArgs[$-1].DFlag = True;

            if (lSwitch[1] == 'I')
            {
                lRoots = std.string.split(lSwitch[2..length], vConfigSep);
                foreach(char[] lRoot; lRoots)
                {
                    lRootName = AddRoot(lRoot);
                    version(BuildVerbose)
                    {
                        if(vVerbose == True && lRootName.length > 0)
                                std.stdio.writefln(" added root from config file %s", lRootName);
                    }
                }
            }
            else
            {
                version(DigitalMars)
                {
                    if (util.str.IsLike(lSwitch,  (vOutFileSwitch ~ "*")) == True)
                    {
                        // Target name (eg. -oftestapp)
                        vCommandTargetName = lSwitch[vOutFileSwitch.length .. $];
                        continue;
                    }
                }

                version(GNU)
                {
                    if (lSwitch == vOutFileSwitch)
                    {
                        // Target name (eg. -o testapp)
                        vDelayedValue = &vCommandTargetName;
                        continue;
                    }
                }

                if (util.str.IsLike(lSwitch,  std.utf.toUTF32(vOutputPath ~ "*")) == True)
                {
                    char[] lbRoot;

                    vTemporaryPath = lSwitch[vOutputPath.length .. $];

                    if (vTemporaryPath.length == 0)
                    {
                        vTemporaryPath = std.path.curdir;
                    }
                    if (util.str.ends(vTemporaryPath, std.path.sep) == False)
                        vTemporaryPath ~= std.path.sep;

                    vTemporaryPath = AddRoot(vTemporaryPath);
                    // The path was added to the list of import roots.
                    version(BuildVerbose)
                    {
                        if(vVerbose == True)
                            std.stdio.writefln("Added root from config file Object Write Path = %s",vTemporaryPath);
                    }
                    util.pathex.MakePath(vTemporaryPath);

                    // This one actually *is* passed thru.
                    version(DigitalMars)
                    {
                        // Ensure we don't have both -op and -od when using dmd.
                        RemoveRecdArg("-op");
                    }
                }
                vReceivedArgs[$-1].CompilerArg = True;
            }
        }
    }
}

// -------------------------------------------
void ReadEnviron()
// -------------------------------------------
{
    char[]   lSymValue;

    // Check for a environment flag before config file.
    lSymValue = util.str.GetEnv("DFLAGS");
    if (lSymValue.length > 0 )
    {
        version(BuildVerbose)
        {
            if (vVerbose == True)
                std.stdio.writefln("Analyzing environment symbol DFLAGS=%s", lSymValue);
        }

        Process_DFLAGS( lSymValue );
    }
}

// -------------------------------------------
void ReadCompilerConfigFile()
// -------------------------------------------
{
    char[]   lConfigPath;
    char[][] lTextLines;
    int      lPos;

    if (vConfigFile.length == 0)
    {
        // There is no configuration file to process
      return;
    }

    if (vOverrideConfigPath.length > 0)
        lConfigPath = vOverrideConfigPath ~ vConfigFile ;
    else
        lConfigPath = vConfigPath ~ vConfigFile ;
    version(BuildVerbose)
    {
        if (vVerbose == True)
            std.stdio.writefln("Reading from config: %s", lConfigPath);
    }
    util.fileex.GetTextLines(lConfigPath, lTextLines, util.fileex.GetOpt.Exists);


    foreach(int i, char[] lLine; lTextLines)
    {
        // Strip off trailing whitespace.
        lLine = util.str.stripr(lLine);

        // Replace any environment symbols with their value.
        version(BuildVerbose)
        {
            if (vVerbose == True)
                std.stdio.writefln(" Line %d: %s", i+1, lLine);
        }

        lLine = util.str.ExpandEnvVar(lLine);

        // Examine DFLAGS
        lPos = std.string.find(lLine, "DFLAGS=");
        if(lPos == 0)
        {
            Process_DFLAGS(lLine[lPos+7..length]);
        } // end of DFLAGS processing.

        // Examine LIB
        lPos = std.string.find(lLine, "LIB=");
        if(lPos == 0)
        {
            char[][] lPaths;
            lLine = lLine[lPos+4 .. length];
            lPaths.length = 1;
            foreach(char lChar; lLine)
            {
                if (lChar == '"') {}
                else if (lChar == ';')
                {
                    lPaths.length = lPaths.length + 1;
                }
                else
                    lPaths[$-1] ~= lChar;

            }
            for(int j = 0; j < lPaths.length; j++)
            {
                lPaths[j] = std.string.strip(lPaths[j]);
            }

            foreach( char[] lPath; lPaths)
            {
                if (lPath.length > 0)
                {
                    if (lPath[0] == '"' && lPath[length-1] == '"') {
                        lPath = lPath[1..length-1];
                    }
                    vLibPaths ~= vConfigSep ~ `"` ~ util.pathex.CanonicalPath(lPath) ~ `"`;
                }
            }
            version(BuildVerbose)
            {
                if(vVerbose == True)
                    std.stdio.writefln(" use %s",vLibPaths);
            }
            continue;
        }

        // Examine LINKCMD
        lPos = std.string.find(lLine, "LINKCMD=");
        if(lPos == 0)
        {
            SetFileLocation(lLine[8..$], vLinkerPath, vLinkerExe, "linker");
            continue;
        }

        lPos = std.string.find(lLine, "LIBCMD=");
        if(lPos == 0) {
            SetFileLocation(lLine[7..$], vLibrarianPath, vLibrarian, "librarian");
            continue;
        }

    }

    if (vLinkerPath.length == 0)
        SetFileLocation(vLinkerExe.dup, vLinkerPath, vLinkerExe, "linker");

    if (vLibrarianPath.length == 0)
        SetFileLocation(vLibrarian.dup, vLibrarianPath, vLibrarian, "librarian");
}


void SetFileLocation(char[] pCmdValue, inout char[] pFilePath, inout char[] pFileExe, char[] pType)
{
    char[] lCmdValue;
    int lPos;

    lCmdValue = pCmdValue.dup;

    // Strip out any quotes
    while( (lPos = std.string.find(lCmdValue, "\"")) != -1)
    {
        lCmdValue = lCmdValue[0..lPos] ~ lCmdValue[lPos+1 .. $];
    }

    if (vExeExtention.length > 0)
    {
        if (std.path.getExt(lCmdValue).length == 0)
            lCmdValue ~= "." ~ vExeExtention;
    }

    if (util.pathex.IsRelativePath(lCmdValue) == True)
    {
        pFilePath = util.pathex.FindFileInPathList(vPathId,lCmdValue);
        if (util.str.ends(pFilePath, std.path.sep) == False)
            pFilePath ~= std.path.sep;

        pFilePath = util.pathex.CanonicalPath(pFilePath ~ lCmdValue, false);
    }
    else
    {
        pFilePath = util.pathex.CanonicalPath(lCmdValue, false);
    }
    pFileExe = std.path.getBaseName(pFilePath).dup;
    pFilePath = std.path.getDirName(pFilePath) ~ std.path.sep;

    version(BuildVerbose)
    {
        if(vVerbose == True)
        {
            std.stdio.writefln(" %s path '%s'",pType, pFilePath);
            std.stdio.writefln(" %s is '%s'",pType, pFileExe);
        }
    }
}

// Display each entry in the supplied list.
// -------------------------------------------
void DisplayItems(char[][] pList, char[] pTitle = "")
// -------------------------------------------
{
    if (pList.length > 0) {
        if (pTitle.length > 0)
            std.stdio.writefln("\n%s",pTitle);

        foreach(int lIndex, char[] lListEntry; pList) {
            std.stdio.writefln(" [%2d]: %s",lIndex,lListEntry);
        }
    }
}

// -------------------------------------------
void DisplayItems(source.ExternRef[] pList, char[] pTitle = "")
// -------------------------------------------
{
    if (pList.length > 0) {
        if (pTitle.length > 0)
            std.stdio.writefln("\n%s",pTitle);

        foreach(int lIndex, source.ExternRef lListEntry; pList)
        {
            std.stdio.writef(" [%2d]: %s",lIndex,lListEntry.FilePath);
            if (lListEntry.ToolOpts.length > 0)
                foreach(char[] lOpt; lListEntry.ToolOpts)
                    std.stdio.writef(" [%s]",lOpt);
            std.stdio.writefln("");
        }
    }
}

// -------------------------------------------
void DisplayItems(CmdLineArg[] pList, char[] pTitle = "")
// -------------------------------------------
{
    if (pList.length > 0) {
        if (pTitle.length > 0)
            std.stdio.writefln("\n%s",pTitle);

        foreach(int lIndex, CmdLineArg lListEntry; pList)
        {
            if (lListEntry.ArgText.length > 0)
            {
                std.stdio.writef(" [%2d]: %s",lIndex,lListEntry.ArgText);
                if (lListEntry.DFlag == True)
                    std.stdio.writef(" (DFLAG)");
                if (lListEntry.CompilerArg == True)
                    std.stdio.writef(" (COMPILER)");
                std.stdio.writefln("");
            }
        }
    }
}

// ------------------------------------------------
char[] GetAppPath()
{
    return vAppPath.dup;
}

// ------------------------------------------------
char[] GetFullPathnameScan(char[] pFileName, int pScanList)
// -------------------------------------------
{
    if (pScanList == 0)
        return GetFullPathname(pFileName);
    else
        return GetFullPathname(pFileName, vSourceScanList);
}

// ------------------------------------------------
char[] GetFullPathname(char[] pFileName, char[][] pScanList = null)
// -------------------------------------------
{
    char[] lPossiblePath;
    char[] lLocalPath;
    char[] lFileBase;
    char[][] lFileExtList;

    lFileExtList ~= std.file.getExt(pFileName);
    if (lFileExtList[0] == vSrcExtention)
    {
        lFileExtList ~= lFileExtList[0];
        lFileExtList[0] = vSrcDInterfaceExt;
    }
    lFileBase = std.path.getName(pFileName);
    foreach (char[] lExt; lFileExtList)
    {
        char[] lTestFileName;

        lTestFileName = lFileBase ~ "." ~ lExt;
        if (util.pathex.IsRelativePath(lTestFileName) == True && pScanList.length > 0)
        {
            // Do explicit scanning of supplied paths.
            foreach(char[] lNextRoot; pScanList) {
                lPossiblePath = ( lNextRoot ~ lTestFileName );
                if(util.file2.FileExists(lPossiblePath)) {
                    return util.pathex.AbbreviateFileName(lPossiblePath);
                }
            }

            // If not found in scan list, drop through to standard scan.
        }

        // Look for file in current folder first.
        lLocalPath = util.pathex.CanonicalPath(lTestFileName, false);
        if(util.file2.FileExists(lLocalPath))
        {
            return util.pathex.AbbreviateFileName(lLocalPath);
        }

        // Examine each known import root to see if the file lives there.
        foreach(char[] lNextRoot; vImportRoots)
        {
            lPossiblePath = ( lNextRoot ~ lTestFileName );
            if(util.file2.FileExists(lPossiblePath))
            {
                return util.pathex.AbbreviateFileName(lPossiblePath);
            }
        }

    }
    return util.pathex.AbbreviateFileName(lLocalPath);
}

void RemoveRecdArg(char[] pArg)
{
    // Remove all matching received args.
    for(int i = vReceivedArgs.length - 1; i >= 0; i--)
    {
        if (pArg[$-1] == '*')
        {
            if (util.str.begins(vReceivedArgs[i].ArgText, pArg[0..$-1]) == True)
            {
                vReceivedArgs[i].ArgText = "";
                vReceivedArgs[i].CompilerArg = False;
            }
        }
        else if (vReceivedArgs[i].ArgText == pArg)
        {
            vReceivedArgs[i].ArgText = "";
            vReceivedArgs[i].CompilerArg = False;
        }
    }
}

// -------------------------------
void ExamineArgs(char[][] pArgGroup)
// -------------------------------
{
    // Remove any explicitly-requested args.
    for(int j = pArgGroup.length-1; j >= 0; j--)
    {
        if (pArgGroup[j].length > 2 &&
            pArgGroup[j][0..2] == "--")
        {
            char[] lArg;
            lArg = pArgGroup[j][1..$];
            for(int i = j-1; i >= 0; i--)
            {
                if (lArg[$-1] == '*')
                {
                    if (util.str.begins(pArgGroup[i], lArg[0..$-1]) == True)
                    {
                        pArgGroup[i] = "";
                        break;
                    }
                }
                else if (pArgGroup[i] == lArg)
                {
                    pArgGroup[i] = "";
                    break;
                }
            }
            pArgGroup[j] = "";
        }
    }

    foreach(char[] lArg; pArgGroup)
    {
        if (lArg.length > 0)
            ProcessCmdLineArg( lArg );
    }

    // Collect out the args that are to be passed to the compiler.
    foreach(CmdLineArg lArg; vReceivedArgs)
    {
        if (lArg.CompilerArg == True)
            AddCompilerArg(lArg.ArgText);
    }
}


// -------------------------------------------
int main(char[][] pArgs)
// -------------------------------------------
{
    int lBuildResult;
    char[] lCompPath;
    bool lSetPath = false;

    /* Set routine addresses in the Source module. This allows
       the methods and functions in Source to access the optional
       functionality provided by this module.
    */
    source.AddRoot          = &AddRoot;
    source.GetImportRoots   = &GetImportRoots;
    source.ModulesToIgnore  = &ModulesToIgnore;
    source.AutoImports      = &AutoImports;
    source.AddTarget        = &AddTarget;
    source.AddLink          = &AddLink;
    source.AddBuildDef      = &AddBuildDef;
    source.GetFullPathname  = &GetFullPathname;
    source.GetFullPathnameScan = &GetFullPathnameScan;
    source.AddCompilerArg   = &AddCompilerArg;
    source.GetAppPath       = &GetAppPath;
    source.vPathId          = vPathId;
    util.fileex.vPathId     = vPathId;
    util.fileex.vExeExtention = vExeExtention;


    // Scan the PATH env symbol to locate the D compiler.
    lCompPath = util.pathex.FindFileInPathList(vPathId, vCompilerExe);
    if (lCompPath.length > 0){
        if (lCompPath[length-1] != std.path.sep[0])
            lCompPath ~= std.path.sep;
        vCompilerPath = lCompPath.dup;
        util.str.SetEnv("@D", std.path.getDirName(vCompilerPath));
    }

    if (vCompilerPath.length == 0)
    {
        vCompilerPath = util.pathex.GetInitCurDir;
        util.str.SetEnv("@D", std.path.getDirName(vCompilerPath));
        lSetPath = true;
    }

    // Strip off application's path from arglist.
    vAppPath = pArgs[0];
    vAppName = std.path.getBaseName(vAppPath);
    version (Windows)
    {
        int DotPos;
        DotPos = std.string.rfind(vAppName, '.');
        if (DotPos != -1)
        {
            vAppName.length = DotPos;
        }
    }
    util.str.SetEnv("@S", std.path.getDirName(vAppPath));

    pArgs=pArgs[1..pArgs.length];
    if (pArgs.length == 0) {
        if (util.file2.FileExists(vDefResponseFile) == false)
        {
            // No other arguments so show usage message.
            DisplayUsage ();
            return 0;
        }
        else
        {
            pArgs ~= "@" ~ vDefResponseFile;
        }
    }


    GatherArgs( pArgs );
    version(BuildVerbose)
    {
        source.vVerboseMode = vVerbose;

        util.fileex.vVerbose = vVerbose;

        if (vVerbose == True)
            std.stdio.writefln("*** build v%s (build %d)***", vAppVersion, build_bn.auto_build_number);
    }

    ExamineArgs( vCombinedArgs );

    util.fileex.vTestRun = vTestRun;
    source.mCollectUses  = vCollectUses;
    source.vForceCompile = vForceCompile;
    source.ObjWritePath  = vTemporaryPath;

    // Grab the external macro definitions unless otherwise told not to.
    source.mMacroInput = vMacroInput;
    if (vMacroInput == True)
        version(BuildVerbose)
        {
            ProcessMacroDefs(vVerbose);
        } else {
            ProcessMacroDefs(False);
        }

    if( (vTargetName.length == 0) && (vCommandTargetName.length == 0) ){
        throw new BuildException("No target name supplied.");
    }

    version(BuildVerbose)
    {
        if ((vVerbose == True) || (vNames == True) )
            std.stdio.writefln("Current Dir '%s'", util.pathex.GetInitCurDir());
    } else {
        if (vNames == True)
            std.stdio.writefln("Current Dir '%s'", util.pathex.GetInitCurDir());
    }

    if (lSetPath)
    {
        version(BuildVerbose)
        {
            if (vVerbose == True)
                std.stdio.writefln("%s not found in PATH symbol, so assuming current directory",
                        vCompilerExe);
        }
    }

    if (vCompilerPath[length-1] != std.path.sep[0])
    {
        vCompilerPath ~= std.path.sep;
        util.str.SetEnv("@D", std.path.getDirName(vCompilerPath));
    }


    if (vConfigFile.length > 0)
    {
        char[][] lPotentialPaths;

        lPotentialPaths ~= "." ~ std.path.sep;
        lPotentialPaths ~= util.str.GetEnv(vHomePathId);
        version(Windows)
        {
            char[] lTemp;
            lTemp = util.str.GetEnv("HOMEDRIVE");
            if (lTemp.length > 0)
            {
                lPotentialPaths ~= lTemp ~ util.str.GetEnv("HOMEPATH");
            }
        }
        lPotentialPaths ~= vCompilerPath;
        if (vEtcPath.length > 0)
            lPotentialPaths ~= vEtcPath;

        foreach( char[] p; lPotentialPaths)
        {
            if (p.length > 0)
            {
                if (util.str.ends(p, std.path.sep) is False)
                    p ~= std.path.sep;
                if (util.file2.FileExists(p ~ vConfigFile) == true)
                {
                    vConfigPath = p.dup;
                    util.str.SetEnv("@P", std.path.getDirName(vConfigPath));
                    break;
                }
            }
        }
    }

    if (vExeExtention.length > 0)
    {
        if (std.path.getExt(vCompilerExe).length == 0)
            vCompilerExe ~= "." ~ vExeExtention;
    }
    if (util.file2.FileExists(vCompilerPath ~ vCompilerExe) == false)
    {
        throw new BuildException(std.string.format("The compiler '%s' was not found.",
                vCompilerPath ~ vCompilerExe));
    }

    version(BuildVerbose)
    {
        if (vVerbose == True)
            std.stdio.writefln("Compiler installed in %s",vCompilerPath);
    }

    source.SetKnownVersions();

    ReadEnviron();

    ReadCompilerConfigFile();

    version(Posix)
    {
        // Unless supplied by the config file, these are the default
        // libraries to use for linking.
        if (vDefaultLibs.length == 0)
        {
            vDefaultLibs ~= "c";
            version(DigitalMars)
            {
                vDefaultLibs ~= "phobos";
            }
            version(GNU)
            {
                vDefaultLibs ~= "gphobos";
            }
            vDefaultLibs ~= "pthread";
            vDefaultLibs ~= "m";
        }
    }

    // Assume phobos will be ignored unless user has specified another set.
    if (vModulesToIgnore.length == 0)
        vModulesToIgnore ~= "phobos";

    // Rationalize the ignored modules list.
    foreach(char[] m; vModulesToNotice) {
        for (int i=0; i < vModulesToIgnore.length; i++) {
            if (vModulesToIgnore[i] == m) {
                // Must remove from ignored list.
                vModulesToIgnore = vModulesToIgnore[0..i] ~ vModulesToIgnore[i+1..length];
                i--;
            }
        }
    }


    // Process the D Source files that were on the command line.
    // Each file must already exist. If any does not exist, then
    // the application will abort.
    bool lAllExist = true;

    // List all missing files (if any).
    foreach( char[] lFile; vCmdLineSourceFiles)
    {
        if (! util.file2.FileExists( GetFullPathname(lFile, vSourceScanList)) )
        {
            if (vSilent == False)
                std.stdio.writefln("** File '%s' not found.", lFile);
            lAllExist = false;
        }
    }
    if ( lAllExist == false)
    {
        throw new BuildException ("Not all supplied files exist.");
    }

    // Process the files
    lBuildResult = Build();

    // After processing analysis.
    version(BuildVerbose)
    {
        if(vVerbose == True)
        {
            std.stdio.writefln("");
            DisplayItems(vReceivedArgs,   "build args: ...............");
            DisplayItems(vCompilerArgs,   "compiler args: ................");
            DisplayItems(vCmdLineSourceFiles,   "command line files: ...............");
            DisplayItems(source.Source.AllFiles,
                                          "source files: ...............");
            DisplayItems(vLinkFiles.keys, "link files: ...............");
            DisplayItems(source.Externals,"externally built files: ...............");
            DisplayItems(vImportRoots,    "import roots: .................");
            DisplayItems(vModulesToIgnore,"ignored packages: .................");
            DisplayItems(vModulesToNotice,"noticed package: .................");
        }
    }

    // Output list of modules if it was requested.
    if(vSymbols == True)
    {
        char[] lSymbolData;
        int lModuleCount;
        char[] lSymbolOutName;

        source.Source.AllFiles(
            delegate int (inout int i, inout source.Source lSource)
            {
                if (lSource.Ignore)
                    return 0;
                if (lSource.NoLink)
                    return 0;
                if (lSource.ModuleName.length == 0)
                    return 0;

                if (lModuleCount == 0)
                {
                    lSymbolData ~= vModOutPrefix;
                }
                lModuleCount++;

                if (lModuleCount > 1)
                {
                    lSymbolData ~= vModOutDelim;
                }

                lSymbolData ~= util.str.Expand(vModOutBody, "mod=" ~ lSource.ModuleName
                                                    ~ "," ~ "src=" ~ lSource.FileName
                                               );
            return 0;
            }
        );
        if (lModuleCount != 0)
        {
            lSymbolData ~= vModOutSuffix;
        }

        if (vSymbolOutName.length == 0)
            vSymbolOutName = util.pathex.GetBaseName(vTargetName) ~ vModOutFile;

        if (vTestRun == False)
        {
            // ensure requested path exists.
            util.pathex.MakePath(vSymbolOutName);

            // write out the data buffer to disk.
            std.file.write(vSymbolOutName, lSymbolData);
        }
        else
        {
            std.stdio.writefln("Modules: %s", vSymbolOutName);
        }
    }

    if (vCollectUses == True)
    {
        char[] lPrevLine;
        char[] lFile;

        lPrevLine.length = 0;
        lFile ~= "[USES]\n";
        foreach(char[] lLine; source.Source.Uses.sort)
        {
            if (lLine != lPrevLine)
            {
                lFile ~= lLine ~ "\n";
                lPrevLine = lLine.dup;
            }
        }

        lPrevLine.length = 0;
        lFile ~= "[USEDBY]\n";
        foreach(char[] lLine; source.Source.UsedBy.sort)
        {
            if (lLine != lPrevLine)
            {
                lFile ~= lLine ~ "\n";
                lPrevLine = lLine.dup;
            }
        }

        if (vUsesOutput.length == 0)
            vUsesOutput = util.pathex.GetBaseName(vTargetName) ~ ".use";

        if (vTestRun == False)
        {
            // ensure requested path exists.
            util.pathex.MakePath(vUsesOutput);
            std.file.write(vUsesOutput, lFile);
        }
        else
        {
            std.stdio.writefln("Uses: %s", vUsesOutput);
        }


    }


    // Run the resulting program if it was requested.
    if ((vExecuteProgram == True) && (vTargetExe.length > 0))
    {
        // Put at one blank line out first to separate it
        // from compiler console output.
        std.stdio.writefln("");

        util.fileex.RunCommand( util.pathex.CanonicalPath(vTargetExe, false),
                     std.string.strip(vRunParms));
    }

    return lBuildResult;


}

void ProcessResponseFile(char[] pArg, Bool pVerbose)
{
    // A response file is being used.
    char[] lRespFileName;
    char[][] lRespLines;

    if (pArg.length == 0)
        return;
    if (pArg == "@")
        lRespFileName = vDefResponseFile;
    else if (pArg[0] == '@')
        lRespFileName = pArg[1..length].dup;
    else
        lRespFileName = pArg;

    if (std.path.getExt(lRespFileName).length == 0)
    {
        lRespFileName ~= "." ~ vResponseExt;
    }

    version(BuildVerbose)
    {
        if (pVerbose == True)
            std.stdio.writefln("Response file %s", lRespFileName);
    }

    lRespLines = util.fileex.GetTextLines(lRespFileName, util.fileex.GetOpt.Exists);
    foreach(char[] lArg; lRespLines)
    {
        // Locate any comment text in the line.
        int lPos = std.string.find(lArg, "#");
        if (lPos != -1)
        {
            // Truncate the line at the '#' character.
            lArg.length = lPos;
        }

        lArg = std.string.strip(lArg);
        if (lArg.length > 1)
        {
            version(BuildVerbose)
            {
                if (pVerbose == True)
                    std.stdio.writefln("Response file arg: %s", lArg);
            }
            GatherOneArg( lArg, vCombinedArgs );
        }
    }
}

struct CmdLineArg
{
    char[] ArgText;
    Bool   CompilerArg;
    Bool   DFlag;
}
CmdLineArg[] vReceivedArgs;

void ProcessCmdLineArg( char[] pArg )
{
    static char[] lImportSwitch;

    // Handle a version switch on the command line by
    if(util.str.begins(pArg, vVersionSwitch) == True)
    {
        char[] lVersionString;

        lVersionString=pArg [vVersionSwitch.length .. $];
        if (lVersionString.length > 0 && lVersionString[0] == '=')
            lVersionString = lVersionString[1..$];
        if (lVersionString.length > 0)
        {
            source.ActivateVersion(lVersionString);
        }
    }
    else if(pArg == vDebugSwitch)
    {
        source.ActivateDebug("1");
    }
    else if(util.str.begins(pArg, vDebugSwitch) == True)
    {
        char[] lDebugString;

        lDebugString = pArg [vDebugSwitch.length .. $];
        if (lDebugString.length > 0 && lDebugString[0] == '=')
            lDebugString = lDebugString[1..$];
        if (lDebugString.length > 0)
        {
            source.ActivateDebug(lDebugString);
        }
    }

    if (pArg[0] == '-')
    {
        vReceivedArgs.length = vReceivedArgs.length + 1;
        vReceivedArgs[$-1].ArgText = pArg.dup;
        vReceivedArgs[$-1].CompilerArg = False;
        vReceivedArgs[$-1].DFlag = False;
    }

    switch(pArg) {
        case "-full":
            vForceCompile = True;
            // Not passed thru.
            break;

        case "-link":
            source.Source.WasMainFound = true;
            // Not passed thru.
            break;

        case "-nolink":
            vNoLink = True;
            // Not passed thru.
            break;

        case "-lib":
            vLibraryAction = LibOpt.Build;
            // Not passed thru.
            break;
            
        case "-shlib":
            vLibraryAction = LibOpt.Shared;
            // Not passed thru.
            break;
            
        case "-shlib-support":
            if (vShLibraries) {
                std.stdio.writefln("yes");
                std.c.stdlib.exit(0);
            } else {
                std.stdio.writefln("no");
                std.c.stdlib.exit(1);
            }
            // Not passed thru.
            break;

        case "-nolib":
            vLibraryAction = LibOpt.DontBuild;
            // Not passed thru.
            break;

        case "-obj":
            vLibraryAction = LibOpt.DontBuild;
            vNoLink = True;
            // Not passed thru.
            break;

        case "-nounittest":
            // Not passed thru. Deprecated switch is now ignored.
            if (vSilent == False)
                std.stdio.writefln("Note: '-nounittest' ignored. This switch is no longer used.");
            break;

        case "-info":
            DisplayUsage(false);
            // Not passed thru.
            break;

        case "-silent":
            vSilent = True;
            // Not passed thru.
            break;

        case "-noautoimport":
            vAutoImports = False;
            // Not passed thru
            break;

        case "-nodef":
            vNoDef = True;
            // Not passed thru.
            break;

        case "-nomacro":
            vMacroInput = False;
            // Not passed thru.
            break;

        case "-usage":
        case "-help":
        case "-h":
        case "-?":
            DisplayUsage();
            // Not passed thru.
            break;

        case "-allobj":
            vAllObjects = True;
            // Not passed thru.
            break;

        case "-test":
            vTestRun = True;
            // Not passed thru.
            break;

        case "-cleanup":
            // drop through ...
        case "-clean":
            vCleanup = True;
            // Not passed thru.
            break;

        case "-V": /* we need verbose status earlier */
            // Not passed thru.
            break;

        case "-names":
            vNames = True;
            // Not passed thru.
            break;

        default:
            if (pArg.length > 0)
            {
            if (pArg[0] == '-') {
                if (pArg == vGenDebugInfo)
                {
                    // Requires symbolic debug info.
                    vLinkerDefs ~= vSymInfoSwitch;
                    vReceivedArgs[$-1].CompilerArg = True;
                    break;
                }

                // Test for Librarian options.
                if (util.str.IsLike(pArg, "-LIBOPT*"d) == True)
                {
                    vLibrarianOpts ~= " " ~ pArg[7..$].dup;
                    break;

                }
                if (util.str.IsLike(pArg, "-SHLIBOPT*"d) == True)
                {
                    vShLibrarianOpts ~= " " ~ pArg[9..$].dup;
                    break;

                }

                if (util.str.begins(pArg, "-LIBPATH=") == True)
                {
                    vLibPaths ~= vConfigSep ~ pArg[9..$].dup;
                    break;
                }

                if (util.str.begins(pArg, "-CFG=") == True)
                {
                    char[] lFile;
                    char[] lSubSection;
                    char[][] lLocalArgs;
                    lFile = pArg[5..$];
                    lSubSection = "";
                    if (auto m = std.regexp.search(lFile, "(.*)\\[(.*)\\]") )
                    {
                        lSubSection = m.match(2);
                        lFile = m.match(1);
                    }
                    version(BuildVerbose)
                    {
                        ProcessOneBuildConfig("+" ~ lSubSection, vVerbose, lFile, lLocalArgs);
                    } else {
                        ProcessOneBuildConfig("+" ~ lSubSection, False, lFile, lLocalArgs);
                    }
                    ExamineArgs(lLocalArgs);
                    break;
                }

                // Check if a list of modules has been requested.
                if (util.str.IsLike(pArg, "-modules*"d) == True)
                {
                    vSymbols = True;
                    if (pArg.length > 8)
                    {
                        if (pArg[8] == '=' || pArg[8] == ':')
                            // drop off leading delimiter.
                            vSymbolOutName = pArg[9..$];
                        else
                            vSymbolOutName = pArg[8..$];
                    }
                    else
                    {
                        vSymbolOutName = pArg[8..$];
                    }
                    // Not passed thru.
                    break;
                }

                // Test for alternate install locations.
                if (util.str.IsLike(pArg, "-DCPATH?*"d) == True)
                {
                    char[] lNewPath = pArg[7..length].dup;
                    if (util.str.ends(lNewPath, std.path.sep) == False)
                        lNewPath ~= std.path.sep;
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("DCPATH was %s now %s", vCompilerPath, lNewPath);
                    }
                    vCompilerPath = lNewPath;
                    util.str.SetEnv("@D", std.path.getDirName(vCompilerPath));
                    break;

                }

                if (util.str.IsLike(pArg,  "-CFPATH?*"d) == True)
                {
                    char[] lNewPath = pArg[7..length].dup;
                    if (util.str.ends(lNewPath, std.path.sep) == False)
                        lNewPath ~= std.path.sep;
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("CFPATH was %s now %s", vConfigPath, lNewPath);
                    }
                    vOverrideConfigPath = lNewPath;
                    util.str.SetEnv("@P", std.path.getDirName(vOverrideConfigPath));
                    break;

                }

                if (util.str.IsLike(pArg,  "-PP?*"d) == True)
                {
                    char[] lNewPath = pArg[3..length].dup;
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("Added %s to Source Scan List", lNewPath);
                    }

                    if ( util.str.ends(lNewPath, std.path.sep) == False)
                        lNewPath ~= std.path.sep;
                    vSourceScanList ~= lNewPath;
                    break;

                }

                if (util.str.IsLike(pArg,  "-RDF?*"d) == True)
                {
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("RDF was %s now %s", source.vRDFName, pArg[4..$]);
                    }

                    source.vRDFName = pArg[4..$].dup;
                    break;

                }

                if (util.str.IsLike(pArg,  "-MDF?*"d) == True)
                {
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("MDF was %s now %s", vDefMacroDefFile, pArg[4..$]);
                    }

                    vDefMacroDefFile = pArg[4..$].dup;
                    break;

                }

                if (pArg == vBuildImportPath)
                {
                    vDelayedValue = &lImportSwitch;
                    break;
                }
                else if ( util.str.begins(pArg, vBuildImportPath) == True)
                {
                    char [] lRoot;
                    foreach(char[] lCmdRoot; std.string.split(pArg[vBuildImportPath.length .. $],
                                                        vImportPathDelim))
                    {
                        lRoot = AddRoot(lCmdRoot);
                        if (lRoot.length > 0)
                        {
                            version(BuildVerbose)
                            {
                                if(vVerbose == True)
                                    std.stdio.writefln("Added root from command line = %s",lRoot);
                            }
                        }
                    }
                    break;
                }

                if (util.str.IsLike(pArg,  std.utf.toUTF32(vRunSwitch ~ "*")) == True)
                {
                    vRunParms ~= pArg[vRunSwitch.length .. $] ~ " ";
                    vExecuteProgram = True;
                    break;
                }

                if (util.str.IsLike(pArg, "-uses*"d) == True)
                {

                    vCollectUses = True;
                    if (pArg.length > 5)
                    {
                        if (pArg[5] == '=' || pArg[5] == ':')
                            vUsesOutput = pArg[6..$];
                        else
                            vUsesOutput = pArg[5..$];
                    }
                    break;
                }

                if (util.str.IsLike(pArg, "-UMB*"d) == True)
                {

                    vUseModBaseName = util.str.YesNo(pArg, true);
                    source.Source.UseModBaseName(vUseModBaseName);
                    break;
                }
                version(Windows)
                {
                if (util.str.IsLike(pArg, "-AutoWinLibs*"d) == True)
                {

                    vAutoWinLibs = util.str.YesNo(pArg, true);
                    break;
                }
                }
                // Special check for Object Write Path
                version(DigitalMars)
                {
                if (util.str.IsLike(pArg,  std.utf.toUTF32(vOutputPath ~ "*")) == True)
                {
                    char[] lRoot;

                    vTemporaryPath = pArg[vOutputPath.length .. $];
                    if (vTemporaryPath.length > 0 && vTemporaryPath[$-1..$] != std.path.sep)
                        vTemporaryPath ~= std.path.sep;

                    lRoot = AddRoot(vTemporaryPath);
                    if (lRoot.length > 0){
                        version(BuildVerbose)
                        {
                            if(vVerbose == True)
                                std.stdio.writefln("Added root from Object Write Path = %s",lRoot);
                        }
                        util.pathex.MakePath(lRoot);
                    }


                    // This one actually *is* passed thru.
                    version(DigitalMars)
                    {
                        // Ensure we don't have both -op and -od when using dmd.
                        RemoveRecdArg("-op");
                    }
                }
                }

                if (util.str.IsLike(pArg,  "-X?*"d) == True)
                {
                    // Modules to ignore (eg. -Xmylib)
                    vModulesToIgnore ~= pArg[2..$];
                    break;
                }

                if (util.str.IsLike(pArg,  "-M?*"d) == True)
                {
                    // Modules to notice (eg. -Mphobos)
                    vModulesToNotice ~= pArg[2..$];
                    break;
                }

                if (util.str.IsLike(pArg,  "-T?*"d) == True)
                {
                    // Target name (eg. -Ttestapp)

                    vCommandTargetName = util.str.Expand(pArg[2..$],
                                                         "Target=" ~
                                                 util.pathex.GetBaseName(vCommandTargetName));
                    break;
                }

                version(DigitalMars)
                {
                if (util.str.IsLike(pArg,  (vOutFileSwitch ~ "*")) == True)
                {
                    // Target name (eg. -oftestapp)
                    vCommandTargetName = pArg[vOutFileSwitch.length .. $];
                    break;
                }
                }

                version(GNU)
                {
                if (pArg == vOutFileSwitch)
                {
                    // Target name (eg. -o testapp)
                    vDelayedValue = &vCommandTargetName;
                    break;
                }
                }

                if (util.str.IsLike(pArg,  "-R*"d) == True)
                {
                    char lValue;
                    // Response file usage (eg. -R=Yes)
                    if (pArg.length == 2)
                        vUseResponseFile = ~vUseResponseFile;
                    else
                        util.str.YesNo(pArg, vUseResponseFile, False);
                    break;
                }

                version(Windows) {
                    if (util.str.IsLike(pArg,  "-gui*"d) == True)
                    {
                        source.Source.WasMainGUI = true;
                        if (pArg.length == 4)
                            break;
                        if (pArg[4] == ':')
                            vWinVer = pArg[5..length];
                        else
                            vWinVer = pArg[4..length];
                        break;
                    }

                    if (pArg == "-dll")
                    {
                        source.Source.WasMainDLL = true;
                        break;
                    }
                }

                vReceivedArgs[$-1].CompilerArg = True;

            } else {

                if (vDelayedValue != null)
                {
                    // Used when an switch needs the subsequent arg to
                    // be its value.
                    if ( vDelayedValue == &lImportSwitch)
                    {
                        char [] lRoot;
                        foreach(char[] lCmdRoot; std.string.split(pArg, ";"))
                        {
                            lRoot = AddRoot(lCmdRoot);
                            if (lRoot.length > 0){
                                version(BuildVerbose)
                                {
                                    if(vVerbose == True)
                                        std.stdio.writefln("Added root from command line = %s",lRoot);
                                }
                            }
                        }
                    }
                    else
                    {
                        *vDelayedValue = pArg;
                        vReceivedArgs[$-1].ArgText ~= " " ~ pArg;
                    }
                    vDelayedValue = null;
                    break;
                }

                version(Windows)
                {
                    // Convert non-standard but sometimes used unix seps
                    // with standard Windows seps.
                    pArg = std.string.replace(pArg, "/", std.path.sep);
                }
                pArg = util.pathex.AbbreviateFileName(util.pathex.CanonicalPath(pArg, false));
                auto lArgExt = std.path.getExt(pArg);
                if (lArgExt == "")
                {
                       pArg ~= "." ~ vSrcExtention;
                       vCmdLineSourceFiles ~= pArg;
                }
                else if (lArgExt == vSrcExtention ||
                           lArgExt == vMacroExtention ||
                           lArgExt == vDdocExtention)
                {
                       vCmdLineSourceFiles ~= pArg;
                }
                else if (lArgExt == vResponseExt)
                {
                }
                else
                {
                       AddLink(GetFullPathname(pArg));
                }

                if(vTargetName is null &&
                    ((std.path.getExt(pArg) == vSrcExtention) ||
                     (std.path.getExt(pArg) == vMacroExtention)
                    )
                  )
                {
                   vTargetName = pArg;
                    version(BuildVerbose)
                    {
                        if(vVerbose == True)
                            std.stdio.writefln("Default target is '%s'", std.path.getName(vTargetName));
                    }
                }
            }
            break;
        }
    }
}

void GatherOneArg( char[] pArg, inout char[][] pArgGroup )
{
    static bool[char[]] lKnownArgs;

    pArg = std.string.strip(pArg);
    if (pArg.length == 0)
        return;

    version(BuildVerbose)
    {
        if ((pArg == "-V") || (pArg == "-v"))
            vVerbose = True;
    }

    if ( pArg.length >= 2 && pArg[0..2] == "--")
    {   // Need to remove an earlier matching argument.
        version(BuildVerbose)
        {
            if ((pArg == "--V") || (pArg == "--v"))
                vVerbose = False;
        }
        // Defer removing the earlier arg until I've examined all args.
        pArgGroup ~= pArg;
        return;
    }


    if ( (pArg[0] == '@') ||
              (util.str.ends(pArg, "." ~ vResponseExt) is True)
             )
    {
        version(BuildVerbose)
        {
            ProcessResponseFile(pArg, vVerbose);
        } else {
            ProcessResponseFile(pArg, False);
        }
    }
    else if (pArg[0] == '+')
        version(BuildVerbose)
        {
            ProcessBuildConfig(pArg, vVerbose, pArgGroup);
        } else {
            ProcessBuildConfig(pArg, False, pArgGroup);
        }
    else
    {   // Only add an argument if it is not already been added.
        if ( !(pArg in lKnownArgs) )
        {
            pArgGroup ~= pArg;
            lKnownArgs[pArg] = true;
        }
    }

}

void GatherArgs( char[][] pArgs )
{
    /* This collects together all the original command line arguments,
       any command line arguments in any configuration files, and
       the contents of any response files.
    */
    Bool lVerbose;
    version(BuildVerbose)
    {
        lVerbose = vVerbose;
    } else {
        lVerbose = False;
    }
    // Collect from configuration file(s).
    ProcessBuildConfig("+", lVerbose, vCombinedArgs);
    version(Windows)
    {
        ProcessBuildConfig("+Windows", lVerbose, vCombinedArgs);
    }
    version(Posix)
    {
        ProcessBuildConfig("+Posix", lVerbose, vCombinedArgs);
    }
    version(DigitalMars)
    {
        ProcessBuildConfig("+DigitalMars", lVerbose, vCombinedArgs);
    }
    version(GNU)
    {
        ProcessBuildConfig("+GNU", lVerbose, vCombinedArgs);
    }

    version(darwin)
    {
        ProcessBuildConfig("+darwin", lVerbose, vCombinedArgs);
    }

    version(Windows)
    {
        version(DigitalMars)
        {
            ProcessBuildConfig("+Windows:DigitalMars", lVerbose, vCombinedArgs);
        }
        version(GNU)
        {
            ProcessBuildConfig("+Windows:GNU", lVerbose, vCombinedArgs);
        }
    }
    version(Posix)
    {
        version(DigitalMars)
        {
            ProcessBuildConfig("+Posix:DigitalMars", lVerbose, vCombinedArgs);
        }
        version(GNU)
        {
            ProcessBuildConfig("+Posix:GNU", lVerbose, vCombinedArgs);
        }

    }

    version(DigitalMars)
    {
        if (vCompilerDefs.length == 0) vCompilerDefs  ~= "-op";
    }

    // Collect from original command line.
    foreach( char[] lArg; vCompilerDefs ~ pArgs)
    {
        GatherOneArg( lArg, vCombinedArgs );
    }


}

void ProcessMacroDefs(Bool pVerbose)
{
    // From build.exe location
    ProcessOneMacroDef(pVerbose, std.path.getDirName(vAppPath));

    // From compiler location
    ProcessOneMacroDef(pVerbose, vCompilerPath);

    // From current folder location
    ProcessOneMacroDef(pVerbose, util.pathex.GetInitCurDir());
}

void ProcessOneMacroDef(Bool pVerbose, char[] pPath)
{
    char[] lMacroDefFileName;
    char[][] lMacroDefLines;
    char[][] lMessages;

    static bool[ char[] ] lUsedPaths;

    lMacroDefFileName = pPath.dup;

    if ((lMacroDefFileName.length > 0) &&
        (lMacroDefFileName[$-std.path.sep.length..$] != std.path.sep) )
            lMacroDefFileName ~= std.path.sep;

    lMacroDefFileName ~= vDefMacroDefFile;

    if (lMacroDefFileName in lUsedPaths)
        return;
    lUsedPaths[lMacroDefFileName] = true;

    version(BuildVerbose)
    {
        if ((pVerbose == True) && util.file2.FileExists(lMacroDefFileName) )
            std.stdio.writefln("Build Macro Definition file %s", lMacroDefFileName);
    }

    lMacroDefLines = util.fileex.GetTextLines(lMacroDefFileName, util.fileex.GetOpt.Always);

    util.macro.AddMacros( "build", lMacroDefLines, lMessages);
    version(BuildVerbose)
    {
        if (pVerbose == True)
        {
            foreach(char[] lMsg; lMessages)
            {
                std.stdio.writefln("%s", lMsg);
            }
        }
    }

}

void ProcessBuildConfig(char[] pArg, Bool pVerbose, inout char[][] pArgGroup)
{
    // From build.exe location
    ProcessOneBuildConfig(pArg, pVerbose, std.path.getDirName(vAppPath), pArgGroup);

    // From compiler location
    ProcessOneBuildConfig(pArg, pVerbose, vCompilerPath, pArgGroup);

    // From current location
    ProcessOneBuildConfig(pArg, pVerbose, util.pathex.GetInitCurDir(), pArgGroup );

}

void ProcessOneBuildConfig(char[] pArg, Bool pVerbose, char[] pPath, inout char[][] pArgGroup)
{
    char[] lConfigFileName;
    char[][] lConfigLines;
    bool lFoundGroup;
    static bool[ char[] ] lUsedPaths;

    version(BuildVerbose)
    {
        if (pVerbose == True)
            std.stdio.writefln("Build Configuration file %s [%s]", pPath, pArg[1..$]);
    }

    lConfigFileName = pPath.dup;
    if (util.file2.FileExists(lConfigFileName) == false)
    {
        // Assume a path was supplied.
        if ((lConfigFileName.length > 0) &&
            (lConfigFileName[$-std.path.sep.length..$] != std.path.sep) )
                lConfigFileName ~= std.path.sep;

        lConfigFileName ~= vUtilsConfigFile;
    }

    if (pArg.length == 0)
        pArg = "+";

    if (lConfigFileName~pArg in lUsedPaths)
    {
        return;
    }
    lUsedPaths[lConfigFileName~pArg] = true;


    lConfigLines = util.fileex.GetTextLines(lConfigFileName, util.fileex.GetOpt.Always);
    if (pArg.length == 1)
        lFoundGroup = true;
    else
    {
        lFoundGroup = false;
        pArg = util.str.ExpandEnvVar(pArg[1..$]);
    }

    foreach(char[] lArg; lConfigLines)
    {
        if (lArg.length == 0)
            continue;
        lArg = util.str.ExpandEnvVar(lArg);
        if (!lFoundGroup)
        {
            if (std.regexp.find(lArg, `^\[\W*` ~ pArg ~ `\W*\]$`) != -1)
            {
                lFoundGroup = true;
                continue;
            }
        }

        if (lFoundGroup)
        {
            // Locate any comment text in the line.
            int lPos = std.string.find(lArg, "#");
            if (lPos != -1)
            {
                // Truncate the line at the '#' character.
                lArg.length = lPos;
            }

            lArg = std.string.strip(lArg);
            if (lArg.length > 1)
            {
                if ((lArg[0] == '[') && (lArg[$-1] == ']'))
                {
                    break; // Don't process any more lines.
                }

                version(BuildVerbose)
                {
                    if (pVerbose == True)
                        std.stdio.writefln("Build Configuration file arg: %s", lArg);
                }

                while ((lPos = std.string.find(lArg, "{Group}")) != -1)
                {
                    lArg = lArg[0..lPos] ~ pArg ~ lArg[lPos + 7 .. $];
                }

                if (util.str.begins(lArg, "CMDLINE=") == True)
                {
                    int lStartPos;
                    int lEndPos;
                    bool lEndFound;
                    lArg = std.string.strip(lArg[8..$]);
                    lStartPos = 0;
                    lEndPos = 0;
                    lEndFound = false;
                    while(lEndPos < lArg.length)
                    {
                        if (!lEndFound)
                        {
                            if (lArg[lEndPos] == ' ')
                            {
                                lEndFound = true;
                            }
                        }
                        else
                        {
                            if (std.string.find("-+@", lArg[lEndPos..lEndPos+1]) != -1)
                            {
                                GatherOneArg( lArg[lStartPos..lEndPos], pArgGroup );
                                lStartPos = lEndPos;
                                lEndFound = false;
                            }
                        }
                        lEndPos++;
                    }
                    if (lStartPos != lEndPos)
                    {
                        GatherOneArg( lArg[lStartPos..lEndPos], pArgGroup );
                    }

                }
                else if (util.str.begins(lArg, "FINAL=") == True)
                {
                    vFinalProc ~= lArg[6..$];
                }
                else if (util.str.begins(lArg, "LIBCMD=") == True)
                {
                    SetFileLocation(lArg[7..$], vLibrarianPath, vLibrarian, "librarian");
                }
                else if (util.str.begins(lArg, "COMPCMD=") == True)
                {
                    SetFileLocation(lArg[8..$], vCompilerPath, vCompilerExe, "compiler");
                }
                else if (util.str.begins(lArg, "LINKCMD=") == True)
                {
                    SetFileLocation(lArg[8..$], vLinkerPath, vLinkerExe, "linker");
                }
                else if (util.str.begins(lArg, "LINKSWITCH=") == True)
                {
                    vLinkerDefs = lArg[11..$].dup;
                }
                else if (util.str.begins(lArg, "INIT:") == True)
                {
                    SetInternalString( lArg[5..$] );
                }
                else {
                    version(BuildVerbose)
                    {
                        if (vVerbose == True)
                            std.stdio.writefln("Bad configuration command '%s' ignored.", lArg);
                    }
                }
            }
        }
    }
}

void SetInternalString(char[] pCommand)
{
    char[] lName;
    char[] lValue;
    int lPos;

    lPos = std.string.find(pCommand, "=");
    if (lPos == -1)
    {
        std.stdio.writefln("Internal String Set '%s' ignored ... '=' not found.", pCommand);
        return;
    }

    lName = std.string.strip(pCommand[0..lPos]);
    lValue = std.string.strip(pCommand[lPos+1..$]);

    // Strip off any enclosing quotes.
    if (lValue.length >= 2 &&
        std.string.find("\"'`", lValue[0]) != -1 &&
        lValue[$-1] == lValue[0])
    {
        lValue = lValue[1..$-1];
    }

    // Resolve any environment symbols and translate any escape sequences.
    lValue = util.str.TranslateEscapes(util.str.ExpandEnvVar(lValue));

    switch(lName)
    {
        case "ExeExtention"    : { vExeExtention     = lValue.dup;
                                   util.fileex.vExeExtention = vExeExtention;
                                   break;
                                 }
        case "LibExtention"    : { vLibExtention     = lValue.dup; break; }
        case "ObjExtention"    : { vObjExtention     = lValue.dup; break; }
        case "ShrLibExtention" : { vShrLibExtention  = lValue.dup; break; }
        case "SrcExtention"    : { vSrcExtention     = lValue.dup; break; }
        case "MacroExtention"  : { vMacroExtention   = lValue.dup; break; }
        case "DdocExtention"   : { vDdocExtention    = lValue.dup; break; }
        case "CompilerExe"     : { vCompilerExe      = lValue.dup; break; }
        case "CompileOnly"     : { vCompileOnly      = lValue.dup; break; }
        case "LinkerExe"       : { vLinkerExe        = lValue.dup; break; }
        case "ConfigFile"      : { vConfigFile       = lValue.dup; break; }
        case "CompilerPath"    : { vCompilerPath     = lValue.dup;
                                   util.str.SetEnv("@D", std.path.getDirName(vCompilerPath));
                                   break; }
        case "LinkerPath"      : { vLinkerPath       = lValue.dup; break; }
        case "LinkerDefs"      : { vLinkerDefs       = lValue.dup; break; }
        case "ConfigPath"      : { vOverrideConfigPath       = lValue.dup;
                                   util.str.SetEnv("@P", std.path.getDirName(vOverrideConfigPath));
                                   break; }
        case "LibPaths"        : { vLibPaths         = lValue.dup; break; }
        case "ConfigSep"       : { vConfigSep        = lValue.dup; break; }
        case "Librarian"       : { vLibrarian        = lValue.dup; break; }
        case "LibrarianOpts"   : { vLibrarianOpts    = lValue.dup; break; }
        case "ShLibraries"     : { util.str.YesNo(lValue, vShLibraries, false); break; }
        case "ShLibrarian"     : { vShLibrarian      = lValue.dup; break; }
        case "ShLibrarianOpts" : { vShLibrarianOpts  = lValue.dup; break; }
        case "ShLibrarianOutFileSwitch" : { vShLibrarianOutFileSwitch = lValue.dup; break; }
        case "VersionSwitch"   : { vVersionSwitch    = lValue.dup; break; }
        case "DebugSwitch"     : { vDebugSwitch      = lValue.dup; break; }
        case "OutFileSwitch"   : { vOutFileSwitch    = lValue.dup; break; }
        case "ImportPath"      : { vImportPath       = lValue.dup; break; }
        case "LinkLibSwitch"   : { vLinkLibSwitch    = lValue.dup; break; }
        case "LibPathSwitch"   : { vLibPathSwitch    = lValue.dup; break; }
        case "MapSwitch"       : { vMapSwitch        = lValue.dup; break; }
        case "SymInfoSwitch"   : { vSymInfoSwitch    = lValue.dup; break; }
        case "BuildImportPath" : { vBuildImportPath  = lValue.dup; break; }
        case "ImportPathDelim" : { vImportPathDelim  = lValue.dup; break; }
        case "OutputPath"      : { vOutputPath       = lValue.dup; break; }
        case "RunSwitch"       : { vRunSwitch        = lValue.dup; break; }
        case "LibrarianPath"   : { vLibrarianPath    = lValue.dup; break; }
        case "ResponseExt"     : { vResponseExt      = lValue.dup; break; }
        case "DefResponseFile" : { vDefResponseFile  = lValue.dup; break; }
        case "RDFName"         : { source.vRDFName          = lValue.dup; break; }
        case "DefMacroDefFile" : { vDefMacroDefFile  = lValue.dup; break; }
        case "LinkerStdOut"    : { vLinkerStdOut     = lValue.dup; break; }
        case "IgnoredModules"  : { vModulesToIgnore ~= std.string.split(lValue, ","); break; }
        case "AssumedLibs"     : { vDefaultLibs     ~= std.string.split(lValue, ","); break; }
        case "PathId"          : { vPathId           = lValue.dup;
                                   util.fileex.vPathId = vPathId;
                                   source.vPathId      = vPathId;
                                   break;
                                 }
        case "ModOutPrefix"    : { vModOutPrefix     = lValue.dup; break; }
        case "ModOutSuffix"    : { vModOutSuffix     = lValue.dup; break; }
        case "ModOutBody"      : { vModOutBody       = lValue.dup; break; }
        case "ModOutDelim"     : { vModOutDelim      = lValue.dup; break; }
        case "ModOutFile"      : { vModOutFile       = lValue.dup; break; }
        case "GenDebugInfo"    : { vGenDebugInfo     = lValue.dup; break; }
        case "CompilerDefs"    : { vCompilerDefs     ~= std.string.split(lValue, ","); break; }
        case "HomePathId"      : { vHomePathId       = lValue.dup; break; }
        case "EtcPath"         : { vEtcPath          = lValue.dup; break; }
        case "UDResTypes"      : { vUDResTypes       ~= std.string.split(lValue, ","); break; }
        case "PostSwitches"    : { util.str.YesNo(lValue, vPostSwitches, false); break; }
        case "AppendLinkSwitches" : { util.str.YesNo(lValue, vAppendLinkSwitches, false); break; }
        case "ArgDelim"        : { vArgDelim         = lValue.dup; break; }
        case "ArgFileDelim"    : { vArgFileDelim     = lValue.dup; break; }
        default:
            std.stdio.writefln("Set Internal String '%s' ignored ... unknown name.", pCommand);
    }
}
