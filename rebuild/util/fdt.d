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
version(Unix)  version = Posix;
version(linux)  version = Posix;
version(darwin) version = Posix;

private
{
    version(all)
    {
        static import util.str;
        static import util.booltype;   // definition of True and False
        alias util.booltype.True True;
        alias util.booltype.False False;
        alias util.booltype.Bool Bool;
        static import std.utf;
        static import std.file;
    }
    version(Windows)      static import opsys = std.c.windows.windows;
    else version(linux)   static import opsys = std.c.linux.linux;
    else version(darwin)  static import opsys = std.c.unix.unix;
    else version(Unix)    static import opsys = std.c.unix.unix;

    version(Posix)   static import std.string;
}

public
{

    /**
         Defines the capabilities of the datatype
    **/
    version(Windows)
    {
        class FileDateTime
        {
            private
            {
                opsys.FILETIME mDT;
                Bool mSet;
            }

            /**
               * Constructor
               *
               * Defines a 'not recorded' date time.
               * Examples:
               *  --------------------
               *   FileDateTime a = new FileDateTime();  // Uninitialized date-time.
               *  --------------------
            **/
            this()
            {
                mSet = False;
                mDT.dwHighDateTime = 0;
                mDT.dwLowDateTime = 0;
            }

            /**
               * Constructor
               *
               * Gets the file's date time.
               *
               * Params:
               *    pFileName = The path and name of the file whose date-time
               *                you want to get.
               * Examples:
               *  --------------------
               *   auto a = new FileDateTime("c:\\temp\\afile.txt");
               *  --------------------
            **/
            this(char[] pFileName)
            {
                GetFileTime( std.utf.toUTF16(pFileName) );
            }

            /**
               * Constructor
               *
               * Gets the file's date time.
               *
               * Params:
               *    pFileName = The path and name of the file whose date-time
               *                you want to get.
               * Examples:
               *  --------------------
               *   auto a = new FileDateTime("c:\\temp\\afile.txt");
               *  --------------------
            **/
            this(wchar[] pFileName)
            {
                GetFileTime( pFileName );
            }

            /**
               * Constructor
               *
               * Gets the file's date time.
               *
               * Params:
               *    pFileName = The path and name of the file whose date-time
               *                you want to get.
               * Examples:
               *  --------------------
               *   auto a = new FileDateTime("c:\\temp\\afile.txt");
               *  --------------------
            **/
            this(dchar[] pFileName)
            {
                GetFileTime( std.utf.toUTF16(pFileName) );
            }

            /**
               * Equality Operator
               *
               * This is accurate to the second. That is, all times inside
               * the same second are considered equal. Milliseconds are
               * not considered.
               *
               * Params:
               *  pOther = The FileDateTime to compare this one to.
               *
               *
               * Examples:
               *  --------------------
               *   FileDateTime a = SomeFunc();
               *   if (a == FileDateTime("/usr2/bin/sample")) { . . . }
               *  --------------------
            **/
            int opEquals(FileDateTime pOther) { return Compare(pOther) == 0; }

            /**
               * Comparision Operator
               *
               * This is accurate to the second. That is, all times inside
               * the same second are considered equal. Milliseconds are
               * not considered.
               *
               * Params:
               *  pOther = The FileDateTime to compare this one to.
               *
               *
               * Examples:
               *  --------------------
               *   FileDateTime a = SomeFunc();
               *   if (a < FileDateTime("/usr2/bin/sample")) { . . . }
               *  --------------------
            **/
            int opCmp(FileDateTime pOther) { return Compare(pOther); }

            /**
               * Comparision Operator
               *
               * This is accurate to the second. That is, all times inside
               * the same second are considered equal. Milliseconds are
               * not considered.
               *
               * Params:
               *  pOther = The FileDateTime to compare this one to.
               *  pExact = Flag to indicate whether or not to compare
               *           milliseconds as well. The default is to ignore
               *           milliseconds.
               *
               * Returns: An integer that shows the degree of accuracy and
               *          the direction of the comparision.
               *
               * A negative value indicates that the current date-time is
               * less than the parameter's value. A positive return means
               * that the current date-time is greater than the parameter.
               * Zero means that they are equal in value.
               *
               * The absolute value of the returned integer indicates
               * the level of accuracy.
               * -----------------
               * 1 .. One of the date-time values is not recorded.
               * 2 .. They are not in the same year.
               * 3 .. They are not in the same month.
               * 4 .. They are not in the same day.
               * 5 .. They are not in the same hour.
               * 6 .. They are not in the same minute.
               * 7 .. They are not in the same second.
               * 8 .. They are not in the same millisecond.
               * -----------------
               *
               *
               * Examples:
               *  --------------------
               *   FileDateTime a = SomeFunc();
               *   if (a.Compare(FileDateTime("/usr2/bin/sample"), true)) > 0)
               *   { . . . }
               *  --------------------
            **/
            int Compare(FileDateTime pOther, bool pExact = false)
            {
                opsys.SYSTEMTIME lATime;
                opsys.SYSTEMTIME lBTime;
                int lResult;

                if (mSet == False)
                    if (pOther.mSet == False)
                        lResult = 0;
                    else
                        lResult = -1;

                else if (pOther.mSet == False)
                    lResult = 1;

                else {
                    opsys.FileTimeToSystemTime(&mDT, &lATime);
                    opsys.FileTimeToSystemTime(&pOther.mDT, &lBTime);

                    if (lATime.wYear > lBTime.wYear)
                        lResult = 2;
                    else if (lATime.wYear < lBTime.wYear)
                        lResult = -2;
                    else if (lATime.wMonth > lBTime.wMonth)
                        lResult = 3;
                    else if (lATime.wMonth < lBTime.wMonth)
                        lResult = -3;
                    else if (lATime.wDay > lBTime.wDay)
                        lResult = 4;
                    else if (lATime.wDay < lBTime.wDay)
                        lResult = -4;
                    else if (lATime.wHour > lBTime.wHour)
                        lResult = 5;
                    else if (lATime.wHour < lBTime.wHour)
                        lResult = -5;
                    else if (lATime.wMinute > lBTime.wMinute)
                        lResult = 6;
                    else if (lATime.wMinute < lBTime.wMinute)
                        lResult = -6;
                    else if (lATime.wSecond > lBTime.wSecond)
                        lResult = 7;
                    else if (lATime.wSecond < lBTime.wSecond)
                        lResult = -7;

                    else if (pExact)
                    {
                        if (lATime.wMilliseconds > lBTime.wMilliseconds)
                            lResult = 8;
                        else if (lATime.wMilliseconds < lBTime.wMilliseconds)
                            lResult = -8;
                        else
                            lResult = 0;
                    }
                }
                return lResult;
            }

            /**
               * Create a displayable format of the date-time.
               *
               * The display format is yyyy/mm/dd HH:MM:SS.TTTT
               *
               * Params:
               *  pExact = Display milliseconds or not. Default is to
               *           ignore milliseconds.
               *
               * Examples:
               *  --------------------
               *   FileDateTime a = SomeFunc();
               *   std.stdio.writefln("Time was %s", a);
               *  --------------------
            **/
            char[] toString(bool pExact = false)
            {
                opsys.TIME_ZONE_INFORMATION lTimeZone;
                opsys.SYSTEMTIME lSystemTime;
                opsys.SYSTEMTIME lLocalTime;
                opsys.FILETIME lLocalDT;

                if ( mSet == False )
                    return "not recorded";

                // Convert the file's time into the user's local timezone.
                if (std.file.useWfuncs)
                {
                    opsys.FileTimeToSystemTime(&mDT, &lSystemTime);
                    opsys.GetTimeZoneInformation(&lTimeZone);
                    opsys.SystemTimeToTzSpecificLocalTime(&lTimeZone, &lSystemTime, &lLocalTime);
                }
                else
                {
                    opsys.FileTimeToLocalFileTime(&mDT, &lLocalDT);
                    opsys.FileTimeToSystemTime(&lLocalDT, &lLocalTime);
                }

                // Return a standardized string form of the date-time.
                //    CCYY/MM/DD hh:mm:ss
                if (pExact)
                    return std.string.format("%04d/%02d/%02d %02d:%02d:%02d.%04d"
                         ,lLocalTime.wYear, lLocalTime.wMonth,  lLocalTime.wDay,
                         lLocalTime.wHour, lLocalTime.wMinute, lLocalTime.wSecond
                         ,lLocalTime.wMilliseconds
                         );
                else
                    return std.string.format("%04d/%02d/%02d %02d:%02d:%02d"
                         ,lLocalTime.wYear, lLocalTime.wMonth,  lLocalTime.wDay,
                         lLocalTime.wHour, lLocalTime.wMinute, lLocalTime.wSecond
                        );
            }

            private void GetFileTime (wchar[] pFileName)
            {

                opsys.WIN32_FIND_DATAW lFileInfoW;
                opsys.WIN32_FIND_DATA  lFileInfoA;
                opsys.FILETIME lWriteTime;
                char[] lASCII_FileName;

                opsys.HANDLE lFH;


                if (std.file.useWfuncs)
                {
                    lFH = opsys.FindFirstFileW (cast(wchar *)&(util.str.ReplaceChar(pFileName ~ cast(wchar[])"\0", '/', '\\')[0]), &lFileInfoW);
                    if(lFH != opsys.INVALID_HANDLE_VALUE) {
                        lWriteTime = lFileInfoW.ftLastWriteTime;
                    }
                }
                else
                {
                    lASCII_FileName = std.utf.toUTF8(util.str.ReplaceChar(pFileName ~ cast(wchar[])"\0", '/', '\\'));

                    lFH = opsys.FindFirstFileA (lASCII_FileName.ptr, &lFileInfoA);
                    if(lFH != opsys.INVALID_HANDLE_VALUE) {
                        lWriteTime = lFileInfoA.ftLastWriteTime;
                    }

                }

                if(lFH != opsys.INVALID_HANDLE_VALUE)
                {
                    mSet = True;
                    mDT = lWriteTime;
                    opsys.FindClose(lFH);
                }
                else
                {
                    mDT.dwHighDateTime = 0;
                    mDT.dwLowDateTime = 0;
                    mSet = False;
                }
            }

        } // End of class definition.



    }

    version(Posix)
    {
        class FileDateTime
        {
            private
            {
                ulong mDT;
                Bool mSet;
            }

            this()
            {
                mSet = False;
                mDT = 0;
            }

            this(char[] pFileName)
            {
                GetFileTime( pFileName );
            }

            this(wchar[] pFileName)
            {
                GetFileTime( std.utf.toUTF8(pFileName) );
            }

            this(dchar[] pFileName)
            {
                GetFileTime( std.utf.toUTF8(pFileName) );
            }

            int opCmp(FileDateTime pOther)
            {
                if (mSet == False)
                    return -1;

                if (pOther.mSet == False)
                    return 1;

                if (mDT > pOther.mDT)
                    return 1;
                if (mDT < pOther.mDT)
                    return -1;
                return 0;
            }

            char[] toString()
            {
                if ( mSet == False )
                    return "not recorded";
                else
                    return std.string.format("%d", mDT);
            }



            private void GetFileTime(char[] pFileName)
            {

                int lFileHandle;
                opsys.struct_stat lFileInfo;
                char *lFileName;

                lFileName = std.string.toStringz(pFileName);
                lFileHandle = opsys.open(lFileName, opsys.O_RDONLY);
                if (lFileHandle != -1)
                {
                    if(opsys.fstat(lFileHandle, &lFileInfo) == 0 )
                    {
                        mDT  = lFileInfo.st_mtime;
                        mSet = True;
                    }
                    else
                    {
                        mDT  = 0;
                        mSet = False;
                    }

                    opsys.close(lFileHandle);
                }
                else
                {
                    mDT  = 0;
                    mSet = False;
                }

            }
        } // End of class definition.
    }
}
