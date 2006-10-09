/**************************************************************************

        @file source.d

        Copyright (c) 2005 Derek Parnell

        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.

        Permission is hereby granted to anyone to use this software for any
        purpose, including commercial applications, and to alter it and/or
        redistribute it freely, subject to the following restrictions:

        1. The origin of this software must not be misrepresented; you must
           not claim that you wrote the original software. If you use this
           software in a product, an acknowledgment within documentation of
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, January 2005
        @author         Derek Parnell


**************************************************************************/

module source;
private import source_bn;    // Build number for this module
//version(build) pragma(include, "build");
version(unix)  version = Unix;
version(Unix)  version = Posix;
version(linux)  version = Posix;
version(darwin) version = Posix;

private
{
    static import util.str;
    static import util.fdt;
    static import util.pathex;
    static import util.fileex;
    static import util.macro;
    static import util.booltype;   // definition of True and False
    alias util.booltype.True True;
    alias util.booltype.False False;
    alias util.booltype.Bool Bool;

    static import std.stdio;
    static import std.path;
    static import std.ctype;
    static import std.file;
    static import std.string;
}

public
{
    enum eRuleUsage
    {
        Ignore,
        Compile,
        Link
    }
    char[] function(char[] pPath) AddRoot;
    void function(char[] pArg) AddCompilerArg;
    char[][] function () GetImportRoots;
    Bool function() AutoImports;
    void function(char[] pPath) AddTarget;
    void function(char[] pPath) AddLink;
    void function(char[] pText, bool pReplace=false) AddBuildDef;
    char[][] function( ) ModulesToIgnore;
    char[] function(char[] pFile, char[][] pScanList = null) GetFullPathname;
    char[] function(char[] pFile, int pScanList) GetFullPathnameScan;
    char[] function() GetAppPath;

    version(BuildVerbose) Bool vVerboseMode;
    Bool    mMacroInput;
    Bool    mCollectUses;
    Bool    vForceCompile;
    char[]  ObjWritePath;
    char[]  vRDFName = "default.rdf";
    char[]  vPathId;

}

private
{
    import util.str;
    import util.fdt;
    import util.pathex;
    import util.fileex;
    import util.macro;
    import util.booltype;

    import std.stdio;
    import std.path;
    import std.ctype;
    import std.file;
    import std.string;

    const {
        version(Windows) {
            char[] ExeExt=`exe`;
            char[] LibExt=`lib`;
            char[] ObjExt=`obj`;
        }

        version(Posix) {
            char[] ExeExt=``;
            char[] LibExt=`a`;
            char[] ObjExt=`o`;
        }

        // Using these as the literals confuse my text editor's
        // 'bracket matching' algorithm.
        static char[] kOpenBrace = "\x7B";
        static char[] kCloseBrace = "\x7D";
        static char[] kOpenParen = "\x28";
        static char[] kCloseParen = "\x29";

    }

    bool [char[]] AttributeBlocks;
    bool mainFound;
    bool mainGUI;
    bool mainDLL;
    bool[char[]] vActiveVersions;
    long         vVersionLevel = 0;
    bool[char[]] vActiveDebugs;
    long         vDebugLevel = 0;
    char[][eRuleUsage] vUseNames;


    class SourceException : Error
    {
        this(char[] pMsg)
        {
            super (Source.classinfo.name ~ ":" ~ pMsg);
        }
    }

}

    debug(1)
    {
        private import std.stdio;
    }

// Module Constructor -----------------
static this()
{
    AttributeBlocks["private"] = true;
    AttributeBlocks["package"] = true;
    AttributeBlocks["protected"] = true;
    AttributeBlocks["public"] = true;
    AttributeBlocks["export"] = true;
    version(BuildVerbose) vVerboseMode = False;
    mMacroInput = False;
    vForceCompile = False;
    vUseNames[eRuleUsage.Ignore] = "ignore";
    vUseNames[eRuleUsage.Compile] = "compile";
    vUseNames[eRuleUsage.Link] = "link";
    debug(1)
    {
    writefln(__FILE__ ~ " build #%d", source_bn.auto_build_number);
    }
}

// Module Destructor -----------------
static ~this()
{
    // Clean up any resources held by the source files.
    Source.Finalize();
}

// Class -----------------
public class Source {
    static {
        private
        {
            Source[char[]] smSourceIndex;
            char[][] smScanOrder;
            bool smUseModBaseName;
            bool[char[]] smUses;
            bool[char[]] smUsedBy;
        }
        public
        {
            enum EMode
            {
                New,            // Must be a new source file
                Update          // Must update an existing record
            }
            int FileCount() { return smSourceIndex.length; }

            Source opIndex(char[] pFileName)
            {
                Source* lObject;
                if ((lObject = (pFileName in smSourceIndex)) !is null)
                    return *lObject;
                if ((lObject = (util.pathex.AbbreviateFileName(pFileName) in smSourceIndex)) !is null)
                    return *lObject;
                return null;
            }

            int AllFiles(int delegate(inout int lCnt, inout Source) dg)
            {
                int result = 0;
                int lCnt = 0;

                foreach (char[] lFileName; smScanOrder)
                {
                    result = dg(lCnt, smSourceIndex[lFileName]);
                    if (result != 0)
                        break;
                    lCnt++;
                }
                return result;
            }

            /* int AllFiles(int delegate(inout Source) dg)
            {
                int result = 0;

                foreach (char[] lFileName; smScanOrder)
                {
                    result = dg(smSourceIndex[lFileName]);
                    if (result != 0)
                        break;
                }
                return result;
            }
*/
            char[][] AllFiles()
            {
                return smScanOrder;
            }

            bool UseModBaseName() { return smUseModBaseName; }
            void UseModBaseName(bool pNewValue) { smUseModBaseName = pNewValue; }
            char[][] Uses() { return smUses.keys; }
            char[][] UsedBy() { return smUsedBy.keys; }

        }
    }

    private {
    char[] mFileName;
    char[] mModuleName;
    char[] mObjectName;
    FileDateTime mObjectTime;     /* time of object file, must be newest, otherwise compile */
    FileDateTime mDependantsTime;   /* time of newest of all dependencies */
    FileDateTime mFileTime;
    bool mHasBeenSearched;
    bool mNoLink;
    bool mIgnore;
    int mBuildNumber;
    char[][] mReferencedImports;
    bool[char[]] mActiveVersions;
    long         mVersionLevel = 0;
    bool[char[]] mActiveDebugs;
    long         mDebugLevel = 0;
    char[]  mLocalArgs;
    }

    public {
    // FileName (read only)
    char[] FileName () { return mFileName.dup; }

    // DependantsTime (read only)
    FileDateTime DependantsTime() { return mDependantsTime; }

    // ObjectsTime (read only)
    FileDateTime ObjectsTime() { return mObjectTime; }

    // FilesTime (read only)
    FileDateTime FilesTime() { return mFileTime; }

    // ModuleName (read only)
    char[] ModuleName() { return mModuleName.dup; }

    // ObjectName (read only)
    char[] ObjectName() { return mObjectName.dup; }

    // NoLink (read only)
    bool NoLink() { return mNoLink; }

    // Ignore
    bool Ignore() { return mIgnore; }
    bool Ignore(bool pNew) { mIgnore = pNew; return pNew;}

    // BuildNumber (read only)
    int BuildNumber() { return mBuildNumber; }

    // LocalArgs (read only)
    char[] LocalArgs () { return mLocalArgs.dup; }

    // HasBeenScanned (read only)
    bool HasBeenScanned () { return mHasBeenSearched; }

// --------------------------------------------------------------------
    static void Finalize()
// --------------------------------------------------------------------
    {
        for(int i = smScanOrder.length-1; i >= 0; i--)
        {
            Source x;
            x = smSourceIndex[smScanOrder[i]];
            delete x;
        }
    }
// --------------------------------------------------------------------
    this(char[] pFileName, EMode pMode = Source.EMode.New)
// --------------------------------------------------------------------
    {
        if (pFileName in Source.smSourceIndex)
        {
            if (pMode == Source.EMode.Update)
            {
                Source.smSourceIndex[pFileName].create("");
            }
            else
            {
                mIgnore = true;
                mHasBeenSearched = true;
                mNoLink = true;
            }

        }
        else
        {
            create(pFileName);
        }
    }

// --------------------------------------------------------------------
    void create(char[] pFileName)
// --------------------------------------------------------------------
    {
        char[] lObjectName;

        mReferencedImports.length = 0;
        mHasBeenSearched = false;
        mIgnore = false;
        if (pFileName.length > 0)
        {
            mFileName = pFileName;
            // Store this instantiation in the list of known files.
            smSourceIndex[pFileName] = this;
        }
        else
        {
            pFileName = mFileName;
        }

        if (std.path.getExt(pFileName) != "ddoc")
        {
            char[] lAltName;
            //mNoLink = (std.path.getExt(pFileName) == "di");
            mNoLink = false;
            mModuleName = FileToModulename(pFileName, lAltName);
            lObjectName = addExt(pFileName,ObjExt);
            mObjectName = util.pathex.AbbreviateFileName(util.pathex.CanonicalPath(lObjectName, false));
        }
        else
        {
            mNoLink = true;
            mModuleName = "";
            lObjectName = "";
            mObjectName = "";
        }

        /* If a specific path for object files has been supplied
           on the command line, and the current source file is
           relative to the current directory, then we need to
           prepend the specified object location path.
        */
        if (ObjWritePath.length != 0 && mObjectName.length != 0)
        {
            if (mObjectName == lObjectName)
            {
                mObjectName = ObjWritePath ~ std.path.getBaseName(mObjectName);
                version(none)
                {
                    foreach(int i, inout char c; mObjectName)
                    {
                        if (c == ':' && i > 1)
                            c = '\\';
                    }
                }
                util.pathex.MakePath(mObjectName);
            }
        }

        if (smUseModBaseName)
        {
            mObjectName = getBaseName(mObjectName);
        }

        mBuildNumber = -1;

        mFileTime = new util.fdt.FileDateTime(pFileName);
        mDependantsTime  = mFileTime;

        mObjectTime   = new util.fdt.FileDateTime(mObjectName);
        UpdateDependantTime(mObjectTime);
        version(BuildVerbose)
        {
            if(vVerboseMode == True)
            {
                if (mFileTime !is null)
                    writefln("Time %s for source %s", mFileTime.toString(), mFileName);

                if (mObjectTime !is null)
                    writefln("Time %s for object %s", mObjectTime.toString(), mObjectName);
            }
        }

        search();
    }

debug(dtor)
    {
// --------------------------------------------------------------------
    ~this()
// --------------------------------------------------------------------
    {
        writefln("Finis: %s", mFileName);
    }
}


// --------------------------------------------------------------------
    void search()
// --------------------------------------------------------------------
    {
        FileDateTime lCurFileTime;
        bool lCanUse;
        int lTextPos = 0;
        char[] lFileText;


        if(mHasBeenSearched)
        {
            return;
        }

        if (util.file2.FileExists(mFileName) == false)
        {
            return;
        }

        version(BuildVerbose)
        {
            if(vVerboseMode == True)
                writefln("Scanning %s", util.pathex.AbbreviateFileName(mFileName));
        }

        if (mHasBeenSearched == false)
        {
            smScanOrder.length = smScanOrder.length + 1;
            smScanOrder[$-1] = mFileName;
        }

        if (std.path.getExt(mFileName) != "ddoc")
        {
            // Grab the original text, which must exist.
            lFileText = GetText(mFileName, GetOpt.Exists);

            // Check if any macro processing is required.
            if ((mMacroInput == True) && (std.path.getExt(mFileName) != "d"))
            {
                char[] lNewFile;
                lNewFile = std.path.addExt(mFileName, "d");
                if (util.macro.RunMacro(lFileText, "build", lNewFile))
                {
                    std.file.write(lNewFile, lFileText);
                    mHasBeenSearched = true;
                    mIgnore = true;
                    version(BuildVerbose)
                    {
                        if(vVerboseMode == True)
                            writefln("Macro output %s", lNewFile);
                    }
                    new Source(lNewFile);
                    delete lFileText;
                    return;
                }
            }

            // Extract all the module references.
            ProcessTokens(lFileText, lTextPos);
            delete lFileText; // Remove it from GC control.

            lCurFileTime = new FileDateTime();
            // Examine each extracted module file.
            if ( (mReferencedImports.length > 0) && (AutoImports() == True))
            {

                AddRoot( std.path.getDirName(util.pathex.CanonicalPath(mFileName, false)) );
            }
            if (AutoImports() == True) {
            foreach(char[] lNextFile; mReferencedImports)
            {
                if (mCollectUses)
                {
                    smUses[mFileName ~ " <> " ~ lNextFile] = true;
                    smUsedBy[lNextFile ~ " <> " ~ mFileName] = true;
                }
                if(lNextFile in smSourceIndex)
                {
                    // Known file so just grab its mod time
                    lCurFileTime = smSourceIndex[lNextFile].DependantsTime;
                }
                else
                {
                    // Ignore specified modules as we assume they are in the lib.
                    lCanUse = true;
                    if (!(ModulesToIgnore is null))
                    {
                        foreach(char[] lNextModule; ModulesToIgnore() ){
                            int lFindPos;
                            char[] lType = "package";
                            char[] lFullFileName;
                            version(Windows)
                            {
                                char[] lLowerMod;
                                lFullFileName = std.string.tolower(util.pathex.CanonicalPath(lNextFile));
                                lLowerMod = std.string.tolower(lNextModule);
                                version(Windows)
                                {
                                    // Just in case a Windows user used unix style separators.
                                    lLowerMod = std.string.replace(lLowerMod, `/`, `\`);
                                }

                                // Check for package name
                                lFindPos = std.string.find(lFullFileName,
                                                        std.path.sep ~ lLowerMod ~ std.path.sep);
                                if (lFindPos == -1) {
                                    // It might be a package at the current module level.
                                    lFindPos = std.string.find(lFullFileName,
                                                        lLowerMod ~ std.path.sep);
                                    if (lFindPos != 0)
                                        lFindPos = -1;
                                }
                                // Check for module in subdirectory
                                if (lFindPos == -1) {
                                    lType = "module";
                                    lFindPos = std.string.find(lFullFileName,
                                                        std.path.sep ~ lLowerMod ~ ".d");
                                }
                                // Check for module in current directory
                                if (lFindPos == -1)
                                {
                                    lType = "module";
                                    if (lFullFileName == util.pathex.CanonicalPath(lLowerMod ~ ".d"))
                                        lFindPos = 0;
                                }
                            }
                            version(Posix)
                            {
                                // Check for package name
                                lFullFileName = util.pathex.CanonicalPath(lNextFile);
                                lFindPos = std.string.find(lFullFileName,
                                                        std.path.sep ~ lNextModule ~ std.path.sep);
                                if (lFindPos == -1) {
                                    // It might be a package at the current module level.
                                    lFindPos = std.string.find(lFullFileName,
                                                        lNextModule ~ std.path.sep);
                                    if (lFindPos != 0)
                                        lFindPos = -1;
                                }
                                // Check for module in subdirectory
                                if (lFindPos == -1) {
                                    lType = "module";
                                    lFindPos = std.string.find(lFullFileName,
                                                        std.path.sep ~ lNextModule ~ ".d");
                                }
                                // Check for module in current directory
                                if (lFindPos == -1) {
                                    lType = "module";
                                    if (lFullFileName == util.pathex.CanonicalPath(lNextModule ~ ".d"))
                                        lFindPos = 0;
                                }
                            }

                            if( lFindPos >= 0) {
                                version(BuildVerbose)
                                {
                                    if (vVerboseMode == True)
                                        writefln("Ignoring %s (%s: %s)", lNextFile, lType, lNextModule);
                                }

                                lCanUse = false;
                                break;
                            }
                        }
                    }
                    if (lCanUse){
                        // Not known yet, so add it and grab its mod time
                        char[] lUseName = GetFullPathnameScan(lNextFile, ~0);
                        lCurFileTime = (new Source(lUseName)).DependantsTime;
                    }


                }

                // Ensure we get the most recent mod time.
                UpdateDependantTime (lCurFileTime);
            }
            }

        }
        mHasBeenSearched = true;
    }

// --------------------------------------------------------------------
    void UpdateDependantTime(FileDateTime pDateTime)
// --------------------------------------------------------------------
    {
        if (pDateTime is null)
            return;

        if (pDateTime > mDependantsTime)
        {
            version(BuildVerbose)
            {
                if (vVerboseMode == True)
                    writefln("Updating %s dependants time from %s to %s",
                                mFileName,
                                mDependantsTime.toString(),
                                pDateTime.toString()
                            );
            }
            mDependantsTime = pDateTime;
        }
    }

    static bool WasMainFound() { return mainFound; }
    static void WasMainFound(bool pValue) { mainFound = pValue; }

    static bool WasMainGUI() { return mainGUI; }
    static void WasMainGUI(bool pValue) { mainGUI = pValue; }

    static bool WasMainDLL() { return mainDLL; }
    static void WasMainDLL(bool pValue) { mainDLL = pValue; }

// --------------------------------------------------------------------
    bool IncrementBuildNumber()
// --------------------------------------------------------------------
    {
        char[] lFileName;
        Source lBNSource;
        char[] lBaseDir;

        if (mBuildNumber < 0)
            return false;
        else {
        lFileName = ModuleToFilename(mModuleName ~ "_bn");
        lBaseDir = std.path.getDirName(mFileName);
        if (lBaseDir.length > 0 && std.path.getDirName(lFileName).length == 0)
            lFileName = std.path.getDirName(mFileName) ~
                        std.path.sep ~ lFileName;

        lFileName = util.pathex.AbbreviateFileName (
                        util.pathex.CanonicalPath(lFileName, false));
        if (std.file.exists(lFileName))
        {
            std.file.remove(lFileName);
        }

        mBuildNumber++;

        {
            char[] lAltName;
            std.file.write(lFileName,
                std.string.format(
                "module %s;\n"
                "// This file is automatically maintained by the BUILD utility,\n"
                "// Please refrain from manually editing it.\n"
                "long auto_build_number = %d;\n",
                    FileToModulename(lFileName, lAltName),
                    mBuildNumber)
                );
        }

        if (! (lFileName in smSourceIndex) )
        {
            if (mCollectUses)
            {
                smUses[mFileName ~ " <> " ~ lFileName] = true;
                smUsedBy[lFileName ~ " <> " ~ mFileName] = true;
            }
            lBNSource = new Source(lFileName);
            lBNSource.search();
        }
        else
        {
            lBNSource = smSourceIndex[lFileName];
        }
        // Force it to be compiled by pretending it hasn't got an OBJ file.
        lBNSource.mObjectTime = new FileDateTime();
        return true;
        }
    }

    } // End public

    //----------------------------------------------------------
  private {

    // -------------------------------------------
    void ActivateVersion(char[] pID)
    // -------------------------------------------
    {
        if (pID.length > 0)
        {
            if (std.ctype.isdigit (pID[0]))
                mVersionLevel = atoi(pID);
            else
                mActiveVersions [ pID ] = true;
        }
    }

    // -------------------------------------------
    bool IsActiveVersion(char[] pID)
    // -------------------------------------------
    {
        if (pID.length == 0)
            return false;

        if (std.ctype.isdigit(pID[0]))
        {
            long lLevel = atoi(pID);
            if (vVersionLevel > mVersionLevel)
                return lLevel <= vVersionLevel ? true : false ;
            else
                return lLevel <= mVersionLevel ? true : false ;
        }
        else
        return (pID in vActiveVersions) != null ? true :
                 (pID in mActiveVersions) != null ? true : false ;
    }

    // -------------------------------------------
    void ActivateDebug(char[] pID)
    // -------------------------------------------
    {
        static const char[] lDefaultLevel = "1";
        if (pID.length == 0)
            pID = lDefaultLevel;

        if (std.ctype.isdigit(pID[0]))
            mDebugLevel = atoi(pID);
        else
            mActiveDebugs [ pID ] = true;

    }

    // -------------------------------------------
    bool IsActiveDebug(char[] pID)
    // -------------------------------------------
    {

        if (pID.length == 0)
            pID = "1";

        if (std.ctype.isdigit(pID[0]))
        {
            long lLevel = atoi(pID);
            if (vDebugLevel > mDebugLevel)
                return lLevel <= vDebugLevel ? true : false ;
            else
                return lLevel <= mDebugLevel ? true : false ;
        }
        else
            return (pID in vActiveDebugs) != null ? true :
                     (pID in mActiveDebugs) != null ? true : false ;
    }

    // -------------------------------------------
    void ProcessTokens (char[] pFileText, inout int pPos, char[] pEndStmt = kCloseBrace)
    // -------------------------------------------
    {
        /* This scans the source text for specific tokens until the 'pEndStmt'
           token is found, or end of text.
        */
        char[] lCurToken;
        char[] lPrevToken;
        int lLastPos;

        lCurToken = "";
        lLastPos = pFileText.length-1;

        lblNextToken:
        while ((lPrevToken = lCurToken.dup, lCurToken = GetNextToken (pFileText, pPos)) !is null)
        {
            switch(lCurToken) {
                case kOpenBrace:
                    ProcessTokens (pFileText, pPos);
                    break;

                case "\\":
                    // Ignore escaped tokens.
                    if (pPos <= lLastPos )
                        pPos++;
                    break;

                case "\"":
                    // ** drop through **
                case "\'":
                    // Handle various string and character literals.
                    while ((pPos <= lLastPos) && (pFileText[pPos] != lCurToken[0]))
                        if (pFileText[pPos] == '\\')
                            pPos += 2;
                        else
                            pPos++;
                    pPos++;
                    break;

                case "`": // Skip over a raw string
                    while ( (pPos <= lLastPos) && (pFileText[pPos] != '`'))
                        pPos++;
                    pPos++;
                    break;

                case "r":
                    if ( (pPos <= lLastPos) && (pFileText[pPos] == '\"') )
                    {   // Skip over a raw string
                        pPos++;
                        do {pPos++;}
                            while ( (pPos <= lLastPos) && (pFileText[pPos] != '\"'));
                        pPos++;
                    }
                    break;

                case "main":
                case "WinMain":
                case "DllMain":
                    if ( (lPrevToken != "class") &&
                         (lPrevToken != "template")
                        ) {
                        doMain(pFileText, pPos, lCurToken);
                    }
                    break;

                case "version":
                    doVersion(pFileText, pPos);
                    break;

                case "debug":
                    doDebug(pFileText, pPos);
                    break;

                case "import":
                    doImport(pFileText, pPos);
                    break;

                case "module":
                    doModule(pFileText, pPos);
                    break;

                case "Ddoc":
                    if (lPrevToken.length == 0)
                    {
                        // Only applies if 'Ddoc' is first token in file.
                        mNoLink = true;
                        break lblNextToken;
                    }
                    break;

                case "pragma":
                    doPragma(pFileText, pPos);
                    break;

                default:
                    if (lCurToken in AttributeBlocks) {
                        doAttribute(pFileText, pPos, lCurToken);

                    } else if (lCurToken == pEndStmt) {
                        break lblNextToken;
                    }
            } // end switch
        } // end while
    }

    //----------------------------------------------------------
    void doMain (in char[] pFileText, inout int pPos, char[] pCurrentToken)
    {
        int lSavedPos;
        char[] lToken;

        lSavedPos = pPos;
        lToken = GetNextToken(pFileText,pPos);
        if (lToken == kOpenParen) {
            mainFound = true;
            version(Windows) {
                if (pCurrentToken == "WinMain") {
                    mainGUI = true;
                }
                else if (pCurrentToken == "DllMain") {
                    mainDLL = true;
                }
            }
        } else {
            pPos = lSavedPos;
        }

    }

    //----------------------------------------------------------
    void doVersion (in char[] pFileText, inout int pPos)
    {
        char[] lCurrentToken;
        char[] lVersionId;
        int lSavedPos;

        lCurrentToken = GetNextToken (pFileText, pPos);
        if (lCurrentToken == "=")
        {
            // Activate the following identifer version.
            this.ActivateVersion( GetNextToken (pFileText, pPos) );
            GetNextToken(pFileText, pPos); // Throw away the trailing ';'
            return;
        }

        if (lCurrentToken != kOpenParen)
        {
            return; // Not likely as this is bad syntax.
        }

        // **** Assume that correct syntax has been used. ****
        // Pick out the version identifier and skip over the closing parenthesis.
        lVersionId = GetNextToken (pFileText, pPos);
        lCurrentToken = GetNextToken (pFileText, pPos);

        if ( IsActiveVersion(lVersionId) )
        {
            // thus the following tokens must be processed.
            lSavedPos = pPos; // Remember where we are.
            lCurrentToken = GetNextToken (pFileText, pPos);
            if (lCurrentToken == kOpenBrace)
            {
                // process the stuff in the block
                ProcessTokens (pFileText, pPos);
            }
            else
            {
                // Not a block so we just process the next statement only.
                pPos = lSavedPos;  // Back up one token.
                ProcessTokens (pFileText, pPos, ";");
            }

            /* If the next token is an 'else', I must skip over the statement
               or block that follows the 'else'. Otherwise this marks the
               end of the version statement.
            */
            // Remember where we are.
            lSavedPos = pPos;
            lCurrentToken = GetNextToken(pFileText, pPos);
            if (lCurrentToken == "else")
            {
                lCurrentToken = GetNextToken(pFileText, pPos);
                if (lCurrentToken == kOpenBrace)
                {
                    // Skip over a block
                    skipContent(pFileText, pPos);
                }
                else
                {
                    // skip over a statement.
                    skipContent(pFileText, pPos, ";");
                }
            }
            else
            {
                // It wasn't an 'else' so be back up and let the calling
                // routine handle it.
                pPos = lSavedPos;
            }
            return;
        }

        /* Not an active version so therefore the following statement/block
           must not be processed.
        */
        lCurrentToken = GetNextToken(pFileText, pPos);

        if ( lCurrentToken != kOpenBrace)
        {
            skipContent(pFileText, pPos, ";");
            return;
        }

        skipContent(pFileText, pPos);

        lSavedPos = pPos;
        lCurrentToken = GetNextToken(pFileText, pPos);
        if (lCurrentToken != "else")
        {
            pPos = lSavedPos;
            return;
        }

        lSavedPos = pPos;
        lCurrentToken = GetNextToken(pFileText, pPos);
        if (lCurrentToken == kOpenBrace)
        {
            ProcessTokens(pFileText, pPos);
        }
        else
        {
            pPos = lSavedPos;
            ProcessTokens(pFileText, pPos, ";");
        }

    }

    //----------------------------------------------------------
    void doDebug(in char[] pFileText, inout int pPos)
    {
        char[] lCurrentToken;
        char[] lDebugId;
        int lSavedPos;

        lSavedPos = pPos;
        lCurrentToken = GetNextToken (pFileText, pPos);
        if (lCurrentToken == "=")
        {
            // Activate the following debug identifer.
            this.ActivateDebug( GetNextToken (pFileText, pPos) );
            GetNextToken(pFileText, pPos); // Throw away the trailing ';'
            return;
        }

        if (lCurrentToken != kOpenParen)
        {
            lDebugId = "1";
            // Back track to the token after the 'debug'
            pPos = lSavedPos;
        }
        else
        {
            // Pick out the debug identifier and skip over the closing parenthesis.
            lDebugId = GetNextToken (pFileText, pPos);
            lCurrentToken = GetNextToken (pFileText, pPos);
        }

        if ( IsActiveDebug(lDebugId) )
        {
            // thus the following tokens must be processed.
            lSavedPos = pPos; // Remember where we are.
            lCurrentToken = GetNextToken (pFileText, pPos);
            if (lCurrentToken == kOpenBrace)
            {
                // process the stuff in the block
                ProcessTokens (pFileText, pPos);
            }
            else
            {
                // Not a block so we just process the next statement only.
                pPos = lSavedPos;  // Back up one token.
                ProcessTokens (pFileText, pPos, ";");
            }

            /* If the next token is an 'else', I must skip over the statement
               or block that follows the 'else'. Otherwise this marks the
               end of the debug statement.
            */
            // Remember where we are.
            lSavedPos = pPos;
            lCurrentToken = GetNextToken(pFileText, pPos);
            if (lCurrentToken == "else")
            {
                lCurrentToken = GetNextToken(pFileText, pPos);
                if (lCurrentToken == kOpenBrace)
                {
                    // Skip over a block
                    skipContent(pFileText, pPos);
                }
                else
                {
                    // skip over a statement.
                    skipContent(pFileText, pPos, ";");
                }
            }
            else
            {
                // It wasn't an 'else' so be back up and let the calling
                // routine handle it.
                pPos = lSavedPos;
            }
            return;
        }

        /* Not an active version so therefore the following statement/block
           must not be processed.
        */
        lCurrentToken = GetNextToken(pFileText, pPos);

        if ( lCurrentToken != kOpenBrace)
        {
            skipContent(pFileText, pPos, ";");
            return;
        }

        skipContent(pFileText, pPos);

        lSavedPos = pPos;
        lCurrentToken = GetNextToken(pFileText, pPos);
        if (lCurrentToken != "else")
        {
            pPos = lSavedPos;
            return;
        }

        lSavedPos = pPos;
        lCurrentToken = GetNextToken(pFileText, pPos);
        if (lCurrentToken == kOpenBrace)
        {
            ProcessTokens(pFileText, pPos);
        }
        else
        {
            pPos = lSavedPos;
            ProcessTokens(pFileText, pPos, ";");
        }

    }

    //----------------------------------------------------------
    void doImport (in char[] pFileText, inout int pPos)
    {
        char[] lCurrentToken;
        char[] lModName;
        int lSavedPos;

        // import lModName.lModName, lModName, lModName.lModName.lModName;
        // import name = module : method, method, ... ;
        // import name1 = mod1, name2 = mod2, ... ;

        while ((lSavedPos = pPos,
                lCurrentToken = GetNextToken (pFileText, pPos)) !is null
                   && (lCurrentToken != ";"))
        {
            if ( lCurrentToken == ",")
            {
                if (lModName.length > 0)
                {
                    mReferencedImports ~= ModuleToFilename(lModName);
                    lModName = "";
                }
            }
            else if (lCurrentToken == "=")
            {
                lModName = "";
            }
            else if (lCurrentToken == ":")
            {
                if (lModName.length > 0)
                {
                    mReferencedImports ~= ModuleToFilename(lModName);
                    lModName = "";
                }
                // Once you hit a colon, there are no more module names
                // in this statement.
                while ((lCurrentToken = GetNextToken (pFileText, pPos)) !is null
                           && (lCurrentToken != ";"))
                {
                    return;
                }
            }
            else
            {
                lModName ~= lCurrentToken;
            }
        }
        // Don't forget the last one!
        if (lModName.length > 0) {
            mReferencedImports ~= ModuleToFilename(lModName);
        }
        if (lCurrentToken == ";")
            pPos = lSavedPos;
    }
    //----------------------------------------------------------
    void doModule (in char[] pFileText, inout int pPos)
    {
        char[] lCurrentToken;
        char[] lModName;
        int lSavedPos;

        // module lModName [.lModName];
        while ((lSavedPos = pPos,
                lCurrentToken = GetNextToken (pFileText, pPos)) !is null
                   && (lCurrentToken != ";"))
        {
            lModName ~= lCurrentToken;
        }

        if (lModName.length > 0 )
        {
            mModuleName = lModName;
            version(BuildVerbose)
            {
                if (vVerboseMode == True)
                    writefln("Module name set to '%s'", mModuleName);
            }
        }

        if (lCurrentToken == ";")
            pPos = lSavedPos;
    }

    //----------------------------------------------------------
    void doPragma (in char[] pFileText, inout int pPos)
    {
        /* Looking for syntax form ... pragma(<type> [ , <id> [,<id>]...] );
        */
        char[] lCurrentToken;
        char[] lPragmaId;
        int lSavedPos;

        lPragmaId.length = 0;
        if (GetNextToken(pFileText, pPos) == kOpenParen )
        {
            lCurrentToken = GetNextToken(pFileText,pPos);
            if (lCurrentToken == "link")
            {
                while(true)
                {
                    lPragmaId = "";
                    while ( (lCurrentToken = GetNextToken(pFileText,pPos)) !is null)
                    {
                        if ( (lCurrentToken == "\"") || (lCurrentToken == "`") ) {
                            lCurrentToken = GetStringLit(pFileText,pPos, lCurrentToken[0]);
                        }

                        if ((lCurrentToken != ",") && (lCurrentToken != kCloseParen))
                        {
                            lPragmaId ~= lCurrentToken;
                        }
                        else
                            break;
                    }

                    version (Windows) {
                    // If it has no extension, add the 'lib' one.
                    for(int i = lPragmaId.length-1; i >=0 ; i--)
                    {
                        if (lPragmaId[i] == '.')
                        {
                            // Check to see if this is a 'versioned'
                            // library file name, eg.  "glade-2.0"
                            if (i == lPragmaId.length - 1)
                                lPragmaId ~= LibExt;
                            else if (std.ctype.isdigit(lPragmaId[i+1]))
                                lPragmaId ~= "." ~ LibExt;
                            break;
                        }
                        if (i == 0)
                        {
                            // Not a dot to be seen ;-)
                            lPragmaId ~= "." ~ LibExt;
                        }
                    }
                    } else {
                        // if it doesn't start with -l, add it
                        if (lPragmaId.length > 2 &&
                            lPragmaId[0..2] != "-l") {
                            lPragmaId = "-l" ~ lPragmaId;
                        }
                    }
                    // Add link path to compiler switches.
                    if (AddLink != null)
                        AddLink(lPragmaId.dup);
                    if (lCurrentToken == kCloseParen)
                    {
                        break;
                    }
                }
            } else if (lCurrentToken == "build_def"){
                // Collect records for the optlink module definition file.
                lPragmaId = "";
                while ( (lCurrentToken = GetNextToken(pFileText,pPos)) !is null)
                {
                    if ( (lCurrentToken == "\"") || (lCurrentToken == "`") ) {
                        lCurrentToken = GetStringLit(pFileText,pPos, lCurrentToken[0]);
                    }

                    if ((lCurrentToken != ",") && (lCurrentToken != kCloseParen)) {
                        if (AddBuildDef != null)
                            AddBuildDef(lCurrentToken.dup);
                    }
                    if (lCurrentToken == kCloseParen){
                        break;}
                }

            } else if (lCurrentToken == "nolink")
            {
                // This source file is NOT to be linked
                mNoLink = true;

                // Skip over the trailing parenthesis.
                GetNextToken(pFileText,pPos);

            } else if (lCurrentToken == "ignore")
            {
                // This source file is NOT to be compiled or linked
                mNoLink = true;
                mIgnore = true;

                // Skip over the trailing parenthesis.
                GetNextToken(pFileText,pPos);

            } else if (lCurrentToken == "target"){
                if ( (lCurrentToken = GetNextToken(pFileText,pPos)) == ",")
                {
                    lCurrentToken = GetNextToken(pFileText,pPos);
                    if ( (lCurrentToken == "\"") || (lCurrentToken == "`") ) {
                        lCurrentToken = GetStringLit(pFileText,pPos, lCurrentToken[0]);
                    }
                    if (AddTarget != null)
                        AddTarget(lCurrentToken.dup);
                }

                while(lCurrentToken != kCloseParen)
                {   // Skip everything until we find a closing paren.
                    lCurrentToken = GetNextToken(pFileText,pPos);
                }

            } else if (lCurrentToken == "build")
            {
                char[] lExternFile;
                char[][] lExternOpts;
                if ( (lCurrentToken = GetNextToken(pFileText,pPos)) == ",")
                {
                    lCurrentToken = GetNextToken(pFileText,pPos);
                    if ( (lCurrentToken == "\"") || (lCurrentToken == "`") )
                    {
                        lExternFile = GetStringLit(pFileText,pPos, lCurrentToken[0]);
                        lCurrentToken = GetNextToken(pFileText,pPos);
                    }
                    else if ((lCurrentToken == ",") || (lCurrentToken == kCloseParen))
                        lExternFile = "";
                    else
                    {
                        lExternFile = lCurrentToken;
                        lCurrentToken = GetNextToken(pFileText,pPos);
                    }

                    while (lCurrentToken != kCloseParen)
                    {
                        while (lCurrentToken == ",")
                            lCurrentToken = GetNextToken(pFileText,pPos);

                        if (lCurrentToken != kCloseParen)
                        {
                            lExternOpts.length = lExternOpts.length + 1;
                            if ( (lCurrentToken == "\"") || (lCurrentToken == "`") )
                            {
                                lExternOpts[$-1] = GetStringLit(pFileText,pPos, lCurrentToken[0]);
                            }
                            else
                                lExternOpts[$-1] = lCurrentToken;

                            lCurrentToken = GetNextToken(pFileText,pPos);
                        }

                    }
                }

                while(lCurrentToken != kCloseParen)
                {   // Skip everything until we find a closing paren.
                    lCurrentToken = GetNextToken(pFileText,pPos);
                }

                if (lExternFile.length == 0)
                    lExternFile = mFileName;

                RunExternal(lExternFile, lExternOpts, mFileName);

            } else if (lCurrentToken == "include"){

                if ( (lCurrentToken = GetNextToken(pFileText,pPos)) == ",")
                {
                    lCurrentToken = GetNextToken(pFileText,pPos);
                    if ( (lCurrentToken == "\"") || (lCurrentToken == "`") )
                    {
                        lCurrentToken = GetStringLit(pFileText,pPos, lCurrentToken[0]);
                    }
                    else
                    {
                        char[] lLookAhead;
                        lSavedPos = pPos;
                        lLookAhead = GetNextToken(pFileText,pPos);
                        while(lLookAhead != kCloseParen)
                        {   // Append everything until we find a closing paren.
                            lCurrentToken ~= lLookAhead;
                            lSavedPos = pPos;
                            lLookAhead = GetNextToken(pFileText,pPos);
                        }
                        pPos = lSavedPos;
                    }
                    if (std.string.tolower(std.path.getExt(lCurrentToken)) == "ddoc")
                    {
                        mReferencedImports ~= lCurrentToken;
                    }
                    else
                    {
                        mReferencedImports ~= ModuleToFilename(lCurrentToken);
                    }
                }

                while(lCurrentToken != kCloseParen)
                {   // Skip everything until we find a closing paren.
                    lCurrentToken = GetNextToken(pFileText,pPos);
                }

            } else if (lCurrentToken == "export_version"){

                while ( (lCurrentToken = GetNextToken(pFileText,pPos)) == ",")
                {
                    lCurrentToken = GetNextToken(pFileText,pPos);
                    if ( (lCurrentToken == `"`) || (lCurrentToken == "`") )
                    {
                        lCurrentToken = `"` ~ GetStringLit(pFileText,pPos, lCurrentToken[0]) ~ `"`;
                    }
                    AddCompilerArg(`+v+` ~ lCurrentToken );
                }

                while(lCurrentToken != kCloseParen)
                {   // Skip everything until we find a closing paren.
                    lCurrentToken = GetNextToken(pFileText,pPos);
                }
            } else if (lCurrentToken == "compiler_arg"){

                while ( (lCurrentToken = GetNextToken(pFileText,pPos)) == ",")
                {
                    lCurrentToken = GetNextToken(pFileText,pPos);
                    if ( (lCurrentToken == `"`) || (lCurrentToken == "`") )
                    {
                        lCurrentToken = `"` ~ GetStringLit(pFileText,pPos, lCurrentToken[0]) ~ `"`;
                    }
                    mLocalArgs ~= lCurrentToken;
                }

                while(lCurrentToken != kCloseParen)
                {   // Skip everything until we find a closing paren.
                    lCurrentToken = GetNextToken(pFileText,pPos);
                }
            }

        }
    }

    //----------------------------------------------------------
    void doAttribute (in char[] pFileText, inout int pPos, char[] pAttrType)
    {
        char[] lCurrentToken;
        char[] lNextToken;
        int lSavedPos;

        // Handle private/public/etc... blocks.
        lSavedPos = pPos;
        lCurrentToken = GetNextToken(pFileText,pPos);

        if (lCurrentToken == kOpenBrace) // read a block statement
        {
            ProcessTokens (pFileText, pPos);

        } else {
            // Check for special auto build number import.
            if ((pAttrType == "private") && (lCurrentToken == "import"))
            {
                lCurrentToken = GetNextToken(pFileText,pPos);
                while ( (lNextToken = GetNextToken(pFileText,pPos)) != ";")
                {
                    lCurrentToken ~= lNextToken;
                }

                if (lCurrentToken == mModuleName ~ "_bn")
                {
                    mBuildNumber = LoadBuildNumber(mModuleName, mFileName);
                }

            }
            // Revert to the position just after the attribute.
            pPos = lSavedPos;
        }

    }

    //----------------------------------------------------------
    /* Get the next token, skipping over comments. */
    char[] GetNextToken (in char[] pFileText, inout int pPos)
    {
        int lLastPos;

        lLastPos = pFileText.length - 1;
        while (pPos <= lLastPos)
        {
            // Check for comments ...
            if ( (pFileText[pPos] == '/') && (pPos < lLastPos) )
            {
                // Check for multiline unnested comments
                if (pFileText [pPos+1] == '*') {
                    pPos += 2;
                    while (pPos < lLastPos) {
                        if (pFileText [pPos] == '*' && pFileText [pPos+1] == '/') {
                            pPos += 2;
                            break;
                        }
                        else
                            pPos++;
                    }
                } else
                // Check for single line comments
                if (pFileText [pPos+1] == '/') {
                    pPos += 2;
                    while ((pPos <= lLastPos) && (pFileText[pPos] != '\n')) {
                        pPos++;
                        }

                } else
                // Check for multiline nested comments
                if (pFileText [pPos+1] == '+') {
                    int lDepth = 1;

                    pPos += 2;
                    while (pPos <= lLastPos) {
                        if (pFileText [pPos] == '/'){
                            if ((pPos < lLastPos) && (pFileText [pPos+1] == '+')) {
                                lDepth++;
                                pPos += 2;
                            }
                            else
                                pPos++;
                        } else if (pFileText [pPos] == '+') {
                            if ((pPos < lLastPos) && (pFileText [pPos+1] == '/')) {
                                pPos += 2;
                                if (lDepth == 1) {
                                    break;
                                }
                                lDepth--;
                            }
                            else
                                pPos++;
                        } else {
                            pPos++;
                        }
                    }

                    if (pPos > lLastPos) { throw new SourceException("Mismatched nested comments in " ~ mFileName); }
                }
            } // else
            // Check for 'words'
            if (isalpha (pFileText [pPos])) {
                int lStart = pPos;
                pPos++;
                while ((pPos <= lLastPos) && ((isalnum (pFileText [pPos]) || pFileText [pPos] == '_'))) {
                    pPos ++;
                }
                return pFileText[lStart .. pPos];

            } else
            // Check for whitespace
            if (isspace (pFileText [pPos])) {
                pPos++;

            } else
            {
            // Return whatever character we have discovered.
                pPos++;
                return pFileText[pPos-1 .. pPos];
            }
        }

        return null;
    }

    //----------------------------------------------------------
    void skipContent (in  char[] pFileText, inout int pPos, char[] pEndStmt = kCloseBrace)
    {
        // Skips thru nested blocks.

        /* The initial token is assumed to be
           the first token inside a '{' '}' pair.
           */
        char[] lCurrentToken;

        while ((lCurrentToken = GetNextToken (pFileText, pPos)) !is null)
        {
            if (lCurrentToken == pEndStmt)
            {
                return;
            }
            else if (lCurrentToken == kOpenBrace)
                skipContent (pFileText, pPos);

        }
    }

    //----------------------------------------------------------
    char[] GetStringLit (in  char[] pFileText, inout int pPos, char pEndStmt = '"')
    {
        int lStartLit;
        int lEndLit;

        lStartLit = pPos;

        while( (pPos < pFileText.length) && (pFileText[pPos] != pEndStmt) )
        {
            pPos++;
        }
        lEndLit = pPos;
        if (pPos < pFileText.length)
            pPos++; // Skip over lit end char.

        return pFileText[lStartLit .. lEndLit];

    }


  } // end private

} // end class

char[] ModuleToFilename(char[] pModuleName)
{
    char[] lFileName;

    // Replace dots with the opsys path separator
    lFileName = util.str.ReplaceChar(pModuleName.dup, '.', std.path.sep[0]);
    // Add the 'd' extention and append the full path
    lFileName = GetFullPathnameScan( addExt( lFileName, "d" ), ~0 );

    version(BuildVerbose)
    {
        if(vVerboseMode == True)
            writefln(" module->file %s => %s",pModuleName,lFileName);
    }
    return lFileName;
}

char[] FileToModulename(char[] pFileName, inout char[] pAltName)
{
    char[] lModuleName;
    char[] lTemp;

    // Copy the name
    lModuleName = util.pathex.AbbreviateFileName(pFileName, GetImportRoots() );
    if (pAltName.ptr == null)
        pAltName = lModuleName.dup;


    // Remove file extension.
    if (lModuleName[$-2 .. $] == ".d")
    {
        lModuleName.length = lModuleName.length - 2;
    }

    version(Windows) {
        // Remove the 'Drive' letter if present.
        if (lModuleName.length > 1  &&  lModuleName[1] == ':')
        {
            lModuleName = lModuleName[2..$];
        }
        if (lModuleName.length > 0  &&  lModuleName[0] == std.path.sep[0])
        {
            lModuleName = lModuleName[1..$];
        }
    }
    // Replace opsys path separators with dots.
    lModuleName = util.str.ReplaceChar(lModuleName, std.path.sep[0], '.');

    version(BuildVerbose)
    {
        if(vVerboseMode == True)
            writefln(" file->module %s => %s",pFileName,lModuleName);
    }
    return lModuleName;
}


int LoadBuildNumber(char[] pModuleName, char[] pFileName)
{
    char[][] lFileLines;
    char[] lFileName;
    int lBuildNumber = 0;
    char[] lBaseDir;

    lFileName = ModuleToFilename(pModuleName ~ "_bn");
    lBaseDir = std.path.getDirName(pFileName);
    if (lBaseDir.length > 0 && std.path.getDirName(lFileName).length == 0)
        lFileName = std.path.getDirName(pFileName) ~ std.path.sep ~ lFileName;

    lFileName = util.pathex.AbbreviateFileName (
                    util.pathex.CanonicalPath(lFileName, false));
    if (std.file.exists(lFileName))
    {
        lFileLines = GetTextLines( lFileName, util.fileex.GetOpt.Exists );
        BLK_FindBN:
        foreach (char[] lLine; lFileLines)
        {
            if ( util.str.IsLike(lLine, cast(dchar[])"*long auto_build_number = *;*") == True )
            {
                for(int i = std.string.find(lLine,"=") + 2; i < lLine.length; i++)
                {
                    int n = std.string.find("0123456789", lLine[i..i+1] );
                    if (n >= 0)
                        lBuildNumber = lBuildNumber * 10 + n;
                    else if(lLine[i] == ';')
                        break;
               }
            }
        }
    }
    else
    {
        char[] lAltName;
        std.file.write(lFileName,
            std.string.format("module %s;\n" , FileToModulename(lFileName, lAltName)) ~
            "// This file is automatically maintained by the BUILD utility,\n"
            "// Please refrain from manually editing it.\n"
            "long auto_build_number = 0;\n"
            );
        lBuildNumber = 0;
    }
    return lBuildNumber;
}

// -------------------------------------------
void ActivateVersion(char[] pID)
// -------------------------------------------
{
    if (pID.length > 0)
    {
        if (std.ctype.isdigit (pID[0]))
        // Note that even though we capture this here,
        // levels are not yet implemented in the
        // source scanner.
            vVersionLevel = atoi(pID);
        else
            vActiveVersions [ pID ] = true;
    }
}

// -------------------------------------------
void ActivateDebug(char[] pID)
// -------------------------------------------
{
    static const char[] lDefaultLevel = "1";
    if (pID.length == 0)
        pID = lDefaultLevel;

    if (std.ctype.isdigit(pID[0]))
    // Note that even though we capture this here,
    // levels are not yet implemented in the
    // source scanner.
        vDebugLevel = atoi(pID);
    else
        vActiveDebugs [ pID ] = true;

}

// -------------------------------------------
void SetKnownVersions()
// -------------------------------------------
{

    version(DigitalMars)  ActivateVersion("DigitalMars");
    version(X86)          ActivateVersion("X86");
    version(PPC)          ActivateVersion("PPC");
    version(AMD64)        ActivateVersion("AMD64");
    version(PPC64)        ActivateVersion("PPC64");
    version(Windows)      ActivateVersion("Windows");
    version(Win32)        ActivateVersion("Win32");
    version(Win64)        ActivateVersion("Win64");
    version(linux)        ActivateVersion("linux");
    version(darwin)       ActivateVersion("darwin");
    version(Unix)         ActivateVersion("Unix");
    version(unix)         ActivateVersion("unix");
    version(Posix)        ActivateVersion("Posix");
    version(LittleEndian) ActivateVersion("LittleEndian");
    version(BigEndian)    ActivateVersion("BigEndian");
    version(D_InlineAsm)  ActivateVersion("D_InlineAsm");

    version(BuildVerbose)
    {
        ActivateVersion("BuildVerbose");
        if (vVerboseMode == True)
            foreach(char[] k; vActiveVersions.keys){
                writefln("Active Version: '%s'", k);
            }
    }
}

struct ExternRef
{
    char[]   FilePath;
    char[][] ToolOpts;
    char[]   Prefix;
    char[]   Postfix;
    char[]   Rule;
}
private
{
    ExternRef[]  vExternals;
}

//-------------------------------------------------------
int ProcessExternal( ExternRef pRef, char[] pScanningFile)
//-------------------------------------------------------
{
    int lResult = -1;
    static Rule[] lRules;
    char[] lExtension;
    char[] lInFile;
    char[] lOutFile;
    FileDateTime lInDate;
    FileDateTime lOutDate;
    char[] lCommand;


    if (lRules.length == 0)
        lRules = LoadRules();

    lExtension = std.path.getExt(pRef.FilePath);
    foreach(int lRuleIdx, Rule r; lRules)
    {
        lInFile = "";
        if (pRef.Rule.length > 0)
        {
            if (pRef.Rule != r.Name)
            {
                if (lRuleIdx + 1 == lRules.length)
                    throw new SourceException(
                            std.string.format("%s: Cannot find rule '%s'",
                                               pScanningFile, pRef.Rule));
                continue;
            }
            if (lExtension.length == 0)
            {
                lExtension = r.Input;
                pRef.FilePath ~= "." ~ lExtension;
            }

            if ( (lExtension != r.Input) && (lExtension != r.Output))
                throw new SourceException(
                        std.string.format("%s: Using rule '%s' for file '%s'"
                                          " but no matching file type in rule.",
                                               pScanningFile, pRef.Rule, pRef.FilePath));
        }

        if (lExtension == r.Input)
        {
            lInFile = pRef.FilePath;
            lOutFile = std.path.addExt(lInFile, r.Output);

        } else if (lExtension == r.Output)
        {
            lOutFile = pRef.FilePath;
            lInFile = std.path.addExt(lOutFile, r.Input);
        }

        if (lInFile.length == 0)
            continue;

        lInFile = util.pathex.LocateFile(lInFile, GetImportRoots());
        if (! util.file2.FileExists( lInFile ) )
            throw new SourceException(
                std.string.format("External input file '%s' not found", lInFile));

        char[] lTemp;
        lTemp = "a=" ~ pRef.Prefix ~ "," ~
                "b=" ~ util.pathex.GetFileBaseName(lInFile) ~ "," ~
                "c=" ~ pRef.Postfix;
        lOutFile = util.str.Expand("{a}{b}{c}", lTemp);
        char[] lInPath = getDirName(lInFile);
        if (lInPath.length > 0 && util.str.ends(lInPath, std.path.sep) == False)
            lInPath ~= std.path.sep;
        lOutFile = lInPath ~ lOutFile;
        lOutFile = std.path.addExt(lOutFile, r.Output);

        lInFile = util.pathex.AbbreviateFileName(lInFile);
        lOutFile = util.pathex.AbbreviateFileName(lOutFile);

        lInDate = new FileDateTime(lInFile);
        lOutDate = new FileDateTime(lOutFile);
        if ((lInDate > lOutDate) || (vForceCompile == True))
        {
            char[] lKeyValues;
            char[] lExe;
            char[] lArgs;
            int lPos;
            int lInQuote;

            // Ensure that the output file's path exists.
            util.pathex.MakePath(lOutFile);

            // Build up the parameters for the tool.
            lKeyValues = "@IN=" ~ lInFile ~ "," ~
                         "@OUT=" ~ lOutFile ~ "," ~
                         "@IBASE=" ~ util.pathex.GetBaseName(lInFile) ~ "," ~
                         "@OBASE=" ~ util.pathex.GetBaseName(lOutFile) ~ "," ~
                         "@IPATH=" ~ std.path.getDirName(lInFile) ~ "," ~
                         "@OPATH=" ~ std.path.getDirName(lOutFile)
                    ;
            foreach(char[] lOpt; pRef.ToolOpts)
            {
                if (std.string.find(lOpt, "=") != -1)
                    lKeyValues ~= "," ~ lOpt;
            }
            lCommand = util.str.Expand(r.Tool,lKeyValues);

            // Separate the tool executable from its arguments.
            lInQuote = 0;
            for(lPos = 0; lPos < lCommand.length; lPos++)
            {
                if (lInQuote != 1)
                {
                    if (lCommand[lPos] == ' ' || lInQuote > 1)
                    {
                        lExe = lCommand[0.. lPos].dup;
                        if (lInQuote > 1)
                            lPos--;
                        lArgs = lCommand[lPos+1 .. $].dup;
                        break;
                    }
                    else if (lCommand[lPos] == '"')
                    {
                        lInQuote++;
                    }
                }
                else if (lCommand[lPos] == '"')
                {
                    lInQuote++;
                }
            }

            // Run external tool.
            lResult = RunCommand(lExe, lArgs);
            if (lResult != 0)
                return lResult;
        }

        // Find out what to do with the input file.
        if (r.InUse == eRuleUsage.Compile)
        {
            if (Source[lInFile] is null)
                new Source(lInFile);
        }
        else if (r.InUse == eRuleUsage.Link)
        {
            AddLink(lInFile.dup);
        }
        else if (r.InUse == eRuleUsage.Ignore)
        {
            Source lSource;
            lSource = Source[lInFile];
            if (lSource !is null)
                lSource.Ignore = true;
        }

        // Find out what to do with the output file.
        if (r.OutUse == eRuleUsage.Compile)
        {
            new Source(lOutFile, Source.EMode.Update);
        }
        else if (r.OutUse == eRuleUsage.Link)
        {
            AddLink(lOutFile.dup);
        }

    }

    return 0;
}

struct Rule
{
    char[] Name;
    char[] Input;
    char[] Output;
    char[] Tool;
    eRuleUsage InUse;
    eRuleUsage OutUse;
};


//-------------------------------------------------------
Rule[] LoadRules()
//-------------------------------------------------------
{
    Rule[] lRules;
    char[][] lRuleText;
    char[] lRuleDefnFile;

    static char[] kRuleKey = "rule=";

    lRuleDefnFile = util.pathex.LocateFile( vRDFName,
                                            getDirName(GetAppPath()) ~
                                            std.path.pathsep ~
                                            util.str.GetEnv(vPathId)
                                           );
    version(BuildVerbose)
    {
        if (vVerboseMode == True)
            writefln("Rule Definitions from %s", lRuleDefnFile);
    }

    util.fileex.GetTextLines( lRuleDefnFile, lRuleText );
    foreach(char[] lLine; lRuleText)
    {
        lLine = util.str.strip(lLine);
        if (util.str.begins(lLine, kRuleKey ) == True)
        {
            if (lRules.length > 0)
            {
                if (lRules[$-1].Tool.length == 0)
                {
                    throw new SourceException(
                        std.string.format("Rule '%s' does not specify a tool to use.",
                            lRules[$-1].Name));
                }
            }

            lRules.length = lRules.length + 1;
            lRules[$-1].Name = util.str.strip(lLine[5 .. $]);
            lRules[$-1].InUse = eRuleUsage.Ignore;
            lRules[$-1].OutUse= eRuleUsage.Link;
        }
        else if (lRules.length > 0)
        {
            char[][] lKeyValue;
            lKeyValue = std.string.split(lLine, "=");
            if (lKeyValue.length == 2)
            {
                lKeyValue[0] = util.str.strip(lKeyValue[0]);
                lKeyValue[1] = util.str.strip(lKeyValue[1]);

                if (lKeyValue[0] == "in")
                    lRules[$-1].Input = lKeyValue[1];

                else if (lKeyValue[0] == "out")
                    lRules[$-1].Output = lKeyValue[1];

                else if (lKeyValue[0] == "tool")
                    lRules[$-1].Tool = lKeyValue[1];

                else if (lKeyValue[0] == "use_in")
                {
                    foreach(eRuleUsage i, char[] lName; vUseNames)
                        if (lKeyValue[1] == lName)
                            lRules[$-1].InUse = i;
                }
                else if (lKeyValue[0] == "use_out")
                {
                    foreach(eRuleUsage i, char[] lName; vUseNames)
                        if (lKeyValue[1] == lName)
                            lRules[$-1].OutUse = i;
                }
            }
        }
    }

    version(BuildVerbose) if (vVerboseMode == True)
    {
        foreach(Rule r; lRules)
        {
            writefln("Rule '%s' ==> in:%s, out:%s, tool:'%s', use_in:'%s', use_out:'%s'",
                        r.Name, r.Input, r.Output, r.Tool,
                        vUseNames[r.InUse], vUseNames[r.OutUse]
                     );
        }
    }

    return lRules;
}

// -------------------------------------------
void RunExternal(char[] pPath, char[][] pOpts, char[] pScanningFile)
// -------------------------------------------
{
    if (pPath.length == 0)
        return;

    vExternals.length = vExternals.length + 1;
    vExternals[$-1].FilePath = pPath;
    foreach(char[] lOpt; pOpts)
    {
        char[] lUCOpt = std.string.toupper(lOpt);

        if (util.str.begins(lUCOpt, "@PRE=") == True)
            vExternals[$-1].Prefix = lOpt[5..$];
        else if (util.str.begins(lUCOpt, "@POS=") == True)
            vExternals[$-1].Postfix = lOpt[5..$];
        else if (util.str.begins(lUCOpt, "RULE=") == True)
            vExternals[$-1].Rule = lOpt[5..$];


        vExternals[$-1].ToolOpts ~= lOpt;
    }

    version(BuildVerbose)
    {
        if (vVerboseMode == True)
        {
            writef("New external file to be built: %s", pPath);
            foreach( char[] lOpt; pOpts)
                writef(" `%s`", lOpt);
            writefln("");
        }
    }

    int lRunResult = ProcessExternal( vExternals[$-1], pScanningFile );
    if (lRunResult != 0)
        // If an external tool fails, stop immediately.
        throw new SourceException(std.string.format("External Tool for %s failed with code %s", pPath, lRunResult));
}

ExternRef[] Externals()
{
    return vExternals;
}
