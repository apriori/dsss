/**************************************************************************

        @file file2.d

        Copyright (c) 2006 Derek Parnell

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


        @version        Initial version, June 2006
        @author         Derek Parnell


**************************************************************************/

module util.file2;
private import util.file2_bn;   // The build number for this module.

version(unix)   version = Unix;
version(Unix)   version = Posix;
version(linux)  version = Posix;
version(darwin) version = Posix;

private{
    static import std.file;
    static import std.stdio;
    bool[char[]] lExistingFiles;
}

static this()
{
    debug(1)
    {
        writefln(__FILE__ ~ " build #%d", auto_build_number);
    }
}

// --------------------------------------------------
bool FileExists(char[] pFileName)
{
    if (pFileName in lExistingFiles)
    {
        return true;
    }
    try {
    if(std.file.isfile(pFileName) && std.file.exists(pFileName))
    {
        lExistingFiles[pFileName] = true;
        return true;
    }
    } catch { };
    return false;
}

// --------------------------------------------------
void PurgeFileExistsCache()
{
    char[][] lKeys;

    lKeys = lExistingFiles.keys.dup;
    foreach(char[] lFile; lKeys)
    {
        lExistingFiles.remove(lFile);
    }
}

