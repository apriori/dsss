/**************************************************************************

        @file pathex.d

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

module util.pathex;

private {
    static import util.str;
    static import util.booltype;   // definition of True and False
    alias util.booltype.True True;
    alias util.booltype.False False;
    alias util.booltype.Bool Bool;
    static import util.file2;

    static import std.path;
    static import std.file;
    static import std.string;
}

private {
    char[] vInitCurDir;
}
    debug(1)
    {
        private static import std.stdio;
    }

// Module constructor
// ----------------------------------------------
static this()
// ----------------------------------------------
{
    vInitCurDir = GetCurDir();
}

// ----------------------------------------------
char[] GetCurDir()
// ----------------------------------------------
{
    char[] lCurDir;

    lCurDir =  std.file.getcwd();
    // Ensure that it ends in a path separator.
    if (util.str.ends(lCurDir, std.path.sep) == False)
        lCurDir ~= std.path.sep;

    return lCurDir;
}

// ----------------------------------------------
char[] GetCurDir(char pDrive)
// ----------------------------------------------
{
    char[] lOrigDir;
    char[] lCurDir;
    char[] lDrive;

    lOrigDir =  std.file.getcwd();
    lDrive.length = 2;
    lDrive[0] = pDrive;
    lDrive[1] = ':';
    std.file.chdir(lDrive);
    lCurDir = std.file.getcwd();
    std.file.chdir(lOrigDir[0..2]);

    // Ensure that it ends in a path separator.
    if (util.str.ends(lCurDir, std.path.sep) == False)
        lCurDir ~= std.path.sep;

    return lCurDir;
}

// ----------------------------------------------
char[] GetInitCurDir()
// ----------------------------------------------
{
    return vInitCurDir;
}

// ----------------------------------------------
Bool IsRelativePath(char[] pPath)
// ----------------------------------------------
{
    version(Windows)
    {
        // Strip off an drive prefix first.
        if (pPath.length > 1 && pPath[1] == ':')
            pPath = pPath[2..$];
    }

    return ~(util.str.begins(pPath, std.path.sep));
}

// ----------------------------------------------
Bool IsAbsolutePath(char[] pPath)
// ----------------------------------------------
{
    version(Windows)
    {
        // Strip off an drive prefix first.
        if (pPath.length > 1 && pPath[1] == ':')
            pPath = pPath[2..$];
    }

    return util.str.begins(pPath, std.path.sep);
}

// ----------------------------------------------
char[] CanonicalPath(char[] pPath, bool pDirInput = true)
// ----------------------------------------------
{
    // Does not (yet) handle UNC paths or unix links.
    char[] lPath;
    int lPosA = -1;
    int lPosB = -1;
    int lPosC = -1;
    char[] lLevel;
    char[] lCurDir;
    char[] lDrive;

    lPath = pPath.dup;

    // Strip off any enclosing quotes.
    if (lPath.length > 2 && lPath[0] == '"' && lPath[$-1] == '"')
    {
        lPath = lPath[1..$-1];
    }

    // Replace any leading tilde with 'HOME' directory.
    if (lPath.length > 0 && lPath[0] == '~')
    {
        version(Windows) lPath = util.str.GetEnv("HOMEDRIVE") ~  util.str.GetEnv("HOMEPATH") ~ std.path.sep ~ lPath[1..$];
        version(Posix) lPath = util.str.GetEnv("HOME") ~ std.path.sep ~ lPath[1..$];
    }

    version(Windows)
    {
        if ( (lPath.length > 1) && (lPath[1] == ':' ) )
        {
            lDrive = lPath[0..2].dup;
            lPath = lPath[2..$];
        }

        if ( (lPath.length == 0) || (lPath[0] != std.path.sep[0]) )
        {
            if (lDrive.length == 0)
                lPath = GetCurDir ~ lPath;
            else
                lPath = GetCurDir(lDrive[0]) ~ lPath;

            if ( (lPath.length > 1) && (lPath[1] == ':' ) )
            {
                if (lDrive.length == 0)
                    lDrive = lPath[0..2].dup;
                lPath = lPath[2..$];
            }
        }

    }
    version(Posix){
        if ( (lPath.length == 0) || (lPath[0] != std.path.sep[0]) )
        {
            lPath = GetCurDir() ~ lPath;
        }
    }

    if (pDirInput && (lPath[$-std.path.sep.length .. $] != std.path.sep) ){
        lPath ~= std.path.sep;
    }

    lLevel = std.path.sep ~ "." ~ std.path.sep;
    lPosA = std.string.find(lPath, lLevel);
    while( lPosA != -1 ){
        lPath = lPath[0..lPosA] ~
                lPath[lPosA + lLevel.length - std.path.sep.length .. length];

        lPosA = std.string.find(lPath, lLevel);
    }

    lLevel = std.path.sep ~ ".." ~ std.path.sep;
    lPosA = std.string.find(lPath, lLevel);
    while( lPosA != -1 ){
        // Locate preceding directory separator.
        lPosB = lPosA-1;
        while((lPosB > 0) && (lPath[lPosB] != std.path.sep[0]))
            lPosB--;
        if (lPosB < 0)
            lPosB = 0;

        lPath = lPath[0..lPosB] ~
                lPath[lPosA + lLevel.length - std.path.sep.length .. length];

        lPosA = std.string.find(lPath, lLevel);
    }

    return lDrive ~ lPath;
}

// ----------------------------------------------
char[] ReplaceExtension(char[] pFileName, char[] pNewExtension)
// ----------------------------------------------
{
    char[] lNewFileName;

    lNewFileName = std.path.addExt(pFileName, pNewExtension);

    /* Needs this to work around the 'feature' in addExt in which
       replacing an extention with an empty string leaves a dot
       after the file name.
    */
    if (pNewExtension.length == 0)
    {
        if (lNewFileName.length > 0)
        {
            if (lNewFileName[length-1] == '.')
            {
                lNewFileName.length = lNewFileName.length - 1;
            }
        }
    }

    return lNewFileName;
}

// ----------------------------------------------
bool MakePath(char[] pNewPath)
// ----------------------------------------------
{
    /*
        This creates the path, including all intervening
        parent directories, specified by the parameter.

        Note that the path is only that portion of the
        parameter up to the last directory separator. This
        means that you can provide a file name in the parameter
        and it will still create the path for that file.

        This returns False if the path was not created. That
        could occur if the path already exists or if you do not
        permissions to create the path on the device, or if
        device is read-only or doesn't exist.

        This returns true if the path was created.
    */
    bool lResult;  // false means it did not create a new path.
    char[] lNewPath;
    char[] lParentPath;

    // extract out the directory part of the parameter.
    for (int i = pNewPath.length-1; i >= 0; i--)
    {
        if (pNewPath[i] == std.path.sep[0])
        {
            lNewPath = pNewPath[0 .. i].dup;
            break;
        }
    }
    version(Windows) {
        if ((lNewPath.length > 0) && (lNewPath[length-1] == ':'))
            lNewPath.length = 0;
    }

    if (lNewPath.length == 0)
        return false;
    else {
    // extract out the parent directory
    for (int i = lNewPath.length-1; i >= 0; i--)
    {
        if (lNewPath[i] == std.path.sep[0])
        {
            lParentPath = lNewPath[0 .. i].dup;
            break;
        }
    }

    // make sure the parent exists.
    version(Windows) {
        if ((lParentPath.length > 0) && (lParentPath[length-1] == ':'))
                lParentPath.length = 0;
    }
    if (lParentPath.length != 0)
    {
        MakePath(lParentPath ~ std.path.sep);
    }


    // create this directory
    try {
        std.file.mkdir(lNewPath);
        lResult = true;
    }
    catch (std.file.FileException E) {
         // Assume the exception is that the directory already exists.
         lResult = false;
    }
    return lResult;
    }
}

char[] AbbreviateFileName(char[] pName, char[][] pPrefixList = null)
{
    // If the file path supplied can be expressed relative to
    // the current directory, (without resorting to '..'), it
    // is returned in its shortened form.

    char[][] lPrefixList;
    char[] lShortName;
    char[] lTemp;
    char[] lOrigName;
    char[] lFullName;

    lPrefixList ~= util.pathex.GetInitCurDir();
    if (pPrefixList.length != 0)
    {
        lPrefixList.length = lPrefixList.length + pPrefixList.length;
        lPrefixList[1..$] = pPrefixList[];
    }
    lFullName = CanonicalPath(pName, false);
    LBL_CheckDirs:
    foreach (char[] lCurDir; lPrefixList)
    {
        lOrigName = lFullName.dup;
        if (lOrigName.length > lCurDir.length)
        {
            version(Windows)
            {
                if (std.string.tolower(lOrigName[0.. lCurDir.length]) ==
                    std.string.tolower(lCurDir) )
                {
                    lShortName = lOrigName[lCurDir.length .. $];
                    break LBL_CheckDirs;
                }

            }
            else
            {
                if (lOrigName[0.. lCurDir.length] == lCurDir )
                {
                    lShortName = lOrigName[lCurDir.length .. $];
                    break LBL_CheckDirs;
                }
            }
        }
    }

    if (lShortName.length == 0)
        lShortName = pName.dup;

    version(Windows)
    // Remove any double path seps.
    {{
        uint lPos;
        while ( (lPos = std.string.find(lShortName, `\\`)) != -1)
        {
            lShortName = lShortName[0..lPos] ~ lShortName[lPos+1 .. $];
        }
    }}
    return lShortName;
}

char[] LocateFile(char[] pFileName, char[] pPathList)
{
    return LocateFile(pFileName,
                        std.string.split(pPathList, std.path.pathsep));
}

char[] LocateFile(char[] pFileName, char[][] pPathList)
{
    char[] lFullName;

    foreach(char[] lPath; pPathList)
    {
        if (lPath.length == 0)
            lPath = std.path.curdir.dup;

        if (lPath[$-std.path.sep.length .. $] != std.path.sep)
            lPath ~= std.path.sep;

        lFullName = lPath ~ pFileName;
        if (util.file2.FileExists(lFullName) )
            return lFullName;
    }

    return pFileName;
}

/**
    Return everything up to but not including the final '.'
*/
char[] GetBaseName(char[] pPathFileName)
{
    char[] lBaseName;

    lBaseName = pPathFileName; //.dup;
    for(int i = lBaseName.length-1; i >= 0; i--)
    {
        if (lBaseName[i] == '.')
        {
            lBaseName.length = i;
            break;
        }
    }
    return lBaseName;
}

/**
    Return everything from the beginning of the file name
    up to but not including the final '.'
*/
char[] GetFileBaseName(char[] pPathFileName)
{
    char[] lBaseName;

    lBaseName = pPathFileName; //.dup;
    for(int i = lBaseName.length-1; i >= 0; i--)
    {
        if (lBaseName[i] == '.')
        {
            lBaseName.length = i;
            break;
        }
    }

    for(int i = lBaseName.length-1; i >= 0; i--)
    {
        version(Windows)
        {
            if (lBaseName[i] == '\\')
            {
                lBaseName = lBaseName[i+1 .. $];
                break;
            }
            if (lBaseName[i] == ':')
            {
                lBaseName = lBaseName[i+1 .. $];
                break;
            }
        }
        version(Posix)
        {
            if (lBaseName[i] == '/')
            {
                lBaseName = lBaseName[i+1 .. $];
                break;
            }
        }
    }
    return lBaseName;
}

// Function to locate where an file is installed from the supplied
// environment symbol, which is a list of paths.
// This returns the path to the file if the file exists otherwise null.
// -------------------------------------------
char[] FindFileInPathList(char[] pSymName, char[] pFileName)
// -------------------------------------------
{
    char[][] lPaths;
    char[]   lCompilerPath;
    char[]   lRawValue;

    // Assume that an environment symbol name was supplied,
    // but if that fails, assume its a list of paths.
    lRawValue = util.str.GetEnv(pSymName);
    if (lRawValue.length == 0)
        lRawValue = pSymName;

    // Rearrange path list into an array of paths.
    lPaths = std.string.split(util.str.toASCII(lRawValue), std.path.pathsep);

    lCompilerPath.length = 0;
    foreach(char[] lPath; lPaths)
    {
        if (lPath.length > 0)
        {
            // Ensure that the path ends with a valid separator.
            if (lPath[length-1] != std.path.sep[0] )
                lPath ~= std.path.sep;
            // If the file is in the current path we can stop looking.
            if(util.file2.FileExists(lPath ~ pFileName))
            {
                // Return the path we actually found it in.
                lCompilerPath = lPath;
                break;
            }
        }
    }

    return lCompilerPath;
}

