/**************************************************************************

        @file fileex.d

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


        @version        Initial version, March 2005
        @author         Derek Parnell


**************************************************************************/

module util.fileex;

version(unix)   version = Unix;
version(Unix)   version = Posix;
version(linux)  version = Posix;
version(darwin) version = Posix;

private{
    static import std.file;
    static import std.string;
    static import std.path;
    static import std.ctype;
    static import std.regexp;
    static import std.stdio;

    static import util.str;
    static import util.booltype;   // definition of True and False
    alias util.booltype.True True;
    alias util.booltype.False False;
    alias util.booltype.Bool Bool;
    static import util.pathex;
    static import util.file2;

    char[][] vGrepOpts;

    class FileExException : Error
    {
        this(char[] pMsg)
        {
            super (__FILE__ ~ ":" ~ pMsg);
        }
    }
    // --------- C externals ----------------
    extern (C)
    {
        int     system  (char *);
    }

}

public {
    version(BuildVerbose) Bool vVerbose;
    Bool vTestRun;
    char[] vExeExtension;
    char[] vPathId;
}
// Module constructor
// ----------------------------------------------
static this()
// ----------------------------------------------
{
    version(Windows)
    {
        vExeExtension = "exe";
        vPathId = "PATH";
    }
    version(Posix)
    {
        vExeExtension = "";
        vPathId = "PATH";
    }
    version(BuildVerbose) vVerbose = False;
    vTestRun = False;
}

enum GetOpt
{
    Exists = 'e',   // Must exist otherwise Get fails.
    Always = 'a'    // Get always returns something, even if it's just
                    //   empty lines for a missing file.
};

// Read an entire file into a string.
char[] GetText(char[] pFileName, GetOpt pOpt = GetOpt.Always)
{
    char[] lFileText;
    if (std.file.exists( pFileName))
    {
        lFileText = cast(char[]) std.file.read(pFileName);
        if ( (lFileText.length == 0) ||
             (lFileText[$-1] != '\n'))
             lFileText ~= std.path.linesep;
    }
    else if (pOpt == GetOpt.Exists) {
        throw new Exception( std.string.format("File '%s' not found.", pFileName));
    }
    return lFileText;

}

// Read a entire file in to a set of lines (strings).
char[][] GetTextLines(char[] pFileName, GetOpt pOpt = GetOpt.Always)
{
    char[][] lLines;
    char[]   lText;
    lText = GetText(pFileName, pOpt);
    lLines = std.string.splitlines( lText );
    return lLines;
}

enum CreateOpt
{
    New = 'n',      // Must create a new file, thus it cannot already exist.
    Create = 'c',   // Can either create or replace; it doesn't matter.
    Replace = 'r'   // Must replace an existing file.
};

void CreateTextFile(char[] pFileName, char[][] pLines, CreateOpt pOpt = CreateOpt.Create)
{
    char[] lBuffer;
    bool lFileExists;

    lFileExists = (std.file.exists( pFileName) ? true : false);
    if (pOpt == CreateOpt.Replace && !lFileExists)
        throw new Exception( std.string.format("File '%s' doesn't exist.", pFileName));

    if (pOpt == CreateOpt.New && lFileExists)
        throw new Exception( std.string.format("File '%s' already exists.", pFileName));

    if (std.file.exists(pFileName))
        std.file.remove(pFileName);

    foreach(char[] lText; pLines) {
        // Strip off any trailing line-end chars.
        for(int i = lText.length-1; i >= 0; i--)
        {
            if (std.string.find(std.path.linesep, lText[i]) == -1)
            {
                if (i != lText.length-1)
                    lText.length = i+1;
                break;
            }
        }

        // Append the opsys' line-end convention.
        lBuffer ~= lText ~ std.path.linesep;
    }
    std.file.write(pFileName, lBuffer);
}

void CreateTextFile(char[] pFileName, char[] pLines, CreateOpt pOpt = CreateOpt.Create)
{
    char[] lBuffer;
    bool lFileExists;
    char[][] lLines;

    // Split into lines, disregarding line-end conventions.
    lLines = std.string.splitlines(pLines);
    // Write out the text using the opsys' line-end convention.
    CreateTextFile(pFileName, lLines, pOpt);
}

long grep(char[] pData, char[] pPattern)
{
    return std.regexp.find(pData, pPattern, vGrepOpts[$-1]);
}

ulong[] FindInFile(char[] pFileName, char[] pText, char[] pOptions = "", uint pMax=1)
{
    bool lCaseSensitive;
    bool lRegExp;
    bool lWordOnly;
    bool lCounting;
    auto char[] lBuffer;
    int lPos;
    int lStartPos;
    ulong[] lResult;
    int function(char[] a, char[] b) lFind;
    char[] lGrepOpt;


    lCaseSensitive = true;
    lRegExp = false;
    lGrepOpt = "m";
    lWordOnly = false;
    lCounting = true;
    foreach (char c; pOptions)
    {
        switch (c)
        {
            case 'i', 'I':
                lCaseSensitive = false;
                break;

            case 'r', 'R':
                lRegExp = true;
                break;

            case 'w', 'W':
                lWordOnly = true;
                break;

            case 'a', 'A':
                lCounting = false;
                break;

            case 'd', 'D':
                lCaseSensitive = true;
                lRegExp = false;
                lWordOnly = false;
                lCounting = true;
                break;

            default:
                // Ignore unrecognized options.
                break;
        }
    }

    if (lRegExp)
    {
        lFind = cast(int function(char[] a, char[] b)) &grep;
        if (lCaseSensitive)
            lGrepOpt ~= 'i';

        vGrepOpts ~= lGrepOpt;
        lWordOnly = false;
    }
    else
    {
        if (lCaseSensitive)
            lFind = cast(int function(char[] a, char[] b)) &std.string.find;
        else
            lFind = cast(int function(char[] a, char[] b)) &std.string.ifind;
    }

    // Pull the entire text into RAM.
    lBuffer = cast(char[])std.file.read(pFileName);

    // Locate next instance and process it.
    while ( lStartPos = lPos, (lPos = lFind(lBuffer[lStartPos..$], pText)) != -1)
    {
        lPos += lStartPos;
        if (lWordOnly)
        {
            // A 'word' is an instance not surrounded by alphanumerics.
            if (lPos > 0)
            {
                if (std.ctype.isalnum(lBuffer[lPos-1]) )
                {
                    // Instance preceeded by a alphanumic so I
                    // move one place to the right and try to find
                    // another instance.
                    lPos++;
                    continue;
                }
            }
            if (lPos + pText.length < lBuffer.length)
            {
                if (std.ctype.isalnum(lBuffer[lPos + pText.length - 1]) )
                {
                    // Instance followed by a alphanumic so I
                    // move one place to the right and try to find
                    // another instance.
                    lPos++;
                    continue;
                }
            }
        }

        // Add this instance's position to the results list.
        lResult ~= lPos;

        // If I'm counting the number of hits, see if I've got the
        // requested number yet. If so, stop searching.
        if (lCounting)
        {
            pMax--;
            if (pMax == 0)
                break;
        }

        // Skip over current instance.
        lPos += pText.length;

        // If there is not enough characters left, then stop searching.
        if ((lBuffer.length - lPos) < pText.length)
            break;

    }
    if (vGrepOpts.length > 0)
        vGrepOpts.length = vGrepOpts.length - 1;

    return lResult;
}

//-------------------------------------------------------
int RunCommand(char[] pExeName, char[] pCommand)
//-------------------------------------------------------
{

    if (vExeExtension.length > 0)
    {
        if (std.path.getExt(pExeName).length == 0)
            pExeName ~= "." ~ vExeExtension;
    }

    if (util.pathex.IsRelativePath(pExeName) == True)
    {
        char[] lExePath;
        lExePath = util.pathex.FindFileInPathList(vPathId, pExeName);
        if (util.str.ends(lExePath, std.path.sep) == False)
            lExePath ~= std.path.sep;

        pExeName = util.pathex.CanonicalPath(lExePath ~ pExeName, false);
    }

    if (util.file2.FileExists(pExeName) == false)
    {
        throw new std.file.FileException(std.string.format("Cannot find application '%s' to run", pExeName));
    }
    return RunCommand(pExeName ~ " " ~ pCommand);
}

//-------------------------------------------------------
int RunCommand(char[] pCommand)
//-------------------------------------------------------
{
    int lRC;
    int lTrueRC;

    if (vTestRun == True) {
        std.stdio.writefln("Command: '%s'",pCommand);
        return 0;
    }
    else
    {


        version(BuildVerbose)
        {
            if(vVerbose == True)
                std.stdio.writefln("Running '%s'",pCommand);
        }

        lRC = system(std.string.toStringz(pCommand));
        version(Posix) lTrueRC = ((lRC & 0xFF00) >> 8);
        version(Windows) lTrueRC = lRC;

        version(BuildVerbose)
        {
            if(vVerbose == True) {
                if (lTrueRC == 0){
                    std.stdio.writefln("Successful");
                } else {
                    std.stdio.writefln("Failed. Return code: %04x",lRC);
                }
            }
        }
        return lTrueRC;
    }
}

