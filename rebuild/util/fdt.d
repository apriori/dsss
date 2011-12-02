/* *************************************************************************

        @file fdt.d

        Copyright (c) 2005 Derek Parnell

                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, January 2005
        @author         Derek Parnell


**************************************************************************/

/**
 * A File Date-Time type.

 * This data type is used to compare and format date-time data associated
 * with files.

 * Authors: Derek Parnell
 * Date: 08 aug 2006
 * History:
 * Licence:
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

**/

module util.fdt;
version(unix)  version = Unix;

private
{
    version(all)
    {
        static import util.str;
        static import std.utf;
        static import std.file;
    }
}

/**
     Defines the capabilities of the datatype
**/
class FileDateTime
{
    private:
    
    std.file.SysTime mDT;
    bool mSet = false;

    public:

    this()
    {
    }

    this(string pFileName)
    {
        GetFileTime( pFileName );
    }

    this(wstring pFileName)
    {
        GetFileTime( std.utf.toUTF8(pFileName) );
    }

    this(dstring pFileName)
    {
        GetFileTime( std.utf.toUTF8(pFileName) );
    }

    int opCmp(FileDateTime pOther)
    {
        if (!mSet)
            return -1;

        if (!pOther.mSet)
            return 1;

        if (mDT > pOther.mDT)
            return 1;
        if (mDT < pOther.mDT)
            return -1;
        return 0;
    }

    override string toString()
    {
        if (!mSet)
            return "not recorded";
        else
            return std.string.format("%d", mDT);
    }

    private void GetFileTime(string pFileName)
    {
        std.file.SysTime accessTime;
        std.file.SysTime modtime;

        scope(success)
        {
            mDT = modtime;
            mSet = true;
        }
        scope(failure)
        {
            mSet = false;
        }

        std.file.getTimes(pFileName, accessTime, modtime);
    }
} // End of class definition.
