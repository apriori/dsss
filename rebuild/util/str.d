/**************************************************************************

        @file str.d

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


        @version        Initial version, January 2005        @author         Derek Parnell


**************************************************************************/

///topic Strings
///info
// Miscellaneous routines and symbols used when working with character strings

module util.str;

private{
    static import util.linetoken;
    static import util.booltype;   // definition of True and False
    alias util.booltype.True True;
    alias util.booltype.False False;
    alias util.booltype.Bool Bool;

    static import std.utf;
    static import std.ctype;
    static import std.string;
    static import std.stdio;
    static import std.array;
    static import std.conv;
    // --------- C externals ----------------
    extern (C)
    {
        char*   getenv  (char *);
        int     putenv  (char *);
    }
}

public{



///topic Strings
///proc ReplaceChar(inout stringtype pText, dchar pFrom, dchar pTo)
///desc Replace all occurances a character with another.
//This examines each character in /i pText and where it matches /i pFrom
// it is replaced with /i pTo. /n
///b Note that /i pText can be a /string, /wstring, /dstring or /ubyte[] datatypes. /n
///b Note that if /i pText is a ubyte[] type, the /i pFrom and /i pTo must
//be either /b ubyte or /b char datatypes.
//
//Example:
///code
//  string test;
//  test = "abc,de,frgh,ijk,kmn";
//  ReplaceChar( test, ',', ':');
//  assert(test == "abc:de:frgh:ijk:kmn");
///endcode

//----------------------------------------------------------
ubyte[] ReplaceChar(in ubyte[] pText, ubyte pFrom, ubyte pTo)
//----------------------------------------------------------
out (pResult){
    ubyte[] lTempA;
    ubyte[] lTempB;

    assert( ! (pResult is null) );

    lTempA = pText.dup;
    lTempB = pResult.dup;
    assert(lTempA.length == lTempB.length);
    if ( pFrom != pTo)
    {
        foreach (uint i, ubyte c; lTempA)
        {
            if (c == pFrom)
            {
                assert(pTo == lTempB[i]);
            }
            else
            {
                assert(lTempA[i] == lTempB[i]);
            }
        }
    }
    else
        assert(lTempA == lTempB);
}
body {

    if (pFrom == pTo)
        return pText;

    foreach( uint i, ref ubyte lTestChar; pText)
    {
        if(lTestChar == pFrom) {
            ubyte[] lTemp = pText.dup;
            foreach( ref ubyte lNextChar; lTemp[i ..$]){
                if(lNextChar == pFrom) {
                    lNextChar = pTo;
                }
            }

            return lTemp;
        }
        else {
            if (i == pText.length-1)
            {
                return pText;
            }
            else
                continue;
        }

    }
    return pText;
}

//----------------------------------------------------------
ubyte[] ReplaceChar(in ubyte[] pText, char pFrom, char pTo)
//----------------------------------------------------------
{
    return ReplaceChar( pText, cast(ubyte)pFrom, cast(ubyte)pTo);
}


//----------------------------------------------------------
dstring ReplaceChar(in dstring pText, dchar pFrom, dchar pTo)
//----------------------------------------------------------
out (pResult){
    dstring lTempA;
    dstring lTempB;

    assert( ! (pResult is null) );

    lTempA = pText;
    lTempB = pResult;
    assert(lTempA.length == lTempB.length);
    if ( pFrom != pTo)
    {
        foreach (uint i, dchar c; lTempA)
        {
            if (c == pFrom)
            {
                assert(pTo == lTempB[i]);
            }
            else
            {
                assert(lTempA[i] == lTempB[i]);
            }
        }
    }
    else
        assert(lTempA == lTempB);
}
body {
    if (pFrom == pTo)
        return pText;

    else {
    foreach( uint i, ref dchar lTestChar; pText){
        if(lTestChar == pFrom) {
            dchar[] lTemp = pText.dup;
            foreach( ref dchar lNextChar; lTemp[i ..$]){
                if(lNextChar == pFrom) {
                    lNextChar = pTo;
                }
            }

            return std.conv.to!dstring(lTemp);
        }


    }
    // If I get here, no changes were done.
    return pText;
}
}


//----------------------------------------------------------
string ReplaceChar(in string pText, dchar pFrom, dchar pTo)
//----------------------------------------------------------
body {

    return std.utf.toUTF8( ReplaceChar( std.utf.toUTF32(pText), pFrom, pTo) );

}

//----------------------------------------------------------
wstring ReplaceChar(in wstring pText, dchar pFrom, dchar pTo)
//----------------------------------------------------------
body {

    return std.utf.toUTF16( ReplaceChar( std.utf.toUTF32(pText), pFrom, pTo) );

}

//----------------------------------------------------------
ubyte[] toStringZ(ubyte[] pData)
//----------------------------------------------------------
{
    ubyte[] lTemp;

    lTemp = pData.dup;
    lTemp ~= '\0';
    return lTemp;
}

//----------------------------------------------------------
string toStringZ(string pData)
//----------------------------------------------------------
{
    string lTemp;

    lTemp = pData;
    lTemp ~= '\0';
    return lTemp;
}

//----------------------------------------------------------
ubyte[] toStringA(string pData)
//----------------------------------------------------------
{
    ubyte[] lTemp;

    lTemp.length = pData.length;
    foreach( int i, char lCurrChar; pData)
    {
        lTemp[i] = cast(ubyte)lCurrChar;
    }

    return lTemp;
}
//----------------------------------------------------------
ubyte[] toStringA(wstring pData)
//----------------------------------------------------------
{
    ubyte[] lTemp;
    string lInter;

    lInter = std.utf.toUTF8( pData );
    lTemp.length = lInter.length;
    foreach( int i, char lCurrChar; lInter)
    {
        lTemp[i] = cast(ubyte)lCurrChar;
    }

    return lTemp;
}
//----------------------------------------------------------
ubyte[] toStringA(dstring pData)
//----------------------------------------------------------
{
    ubyte[] lTemp;
    string lInter;

    lInter = std.utf.toUTF8( pData );
    lTemp.length = lInter.length;
    foreach( int i, char lCurrChar; lInter)
    {
        lTemp[i] = cast(ubyte)lCurrChar;
    }

    return lTemp;
}
}

//----------------------------------------------------------
//----------------------------------------------------------
//----------------------------------------------------------
debug(str) private import std.stdio;
unittest{
    debug(str) std.stdio.writefln("%s", "str.UT01: b = ReplaceChar ( string a, lit, lit) ");
    string testA;
    string testB;
    string testC;

    testA = "abcdbefbq";
    testB = "a cd ef q";
    testC = ReplaceChar(testA, 'b', ' ');
    assert( testC == testB);
    assert( testA != testB);
}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT02: a = ReplaceChar ( string a, lit, lit) ");
    string testA;
    string testB;
    string testC;

    testA = "abcdbefbq";
    testB = "a cd ef q";
    testA = ReplaceChar(testA, 'b', ' ');
    assert( testA == testB);
}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT03: ReplaceChar ( string, 'b', 'b') ");
    string testA;
    string testB;
    string testC;

    testA = "abcdbefbq";
    testB = "abcdbefbq";
    testC = ReplaceChar(testA, 'b', 'b');
    assert( testC == testB);
    assert( testA == testB);
}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT04: ReplaceChar ( wstring, lit, lit) ");
    wstring testA;
    wstring testB;
    wstring testC;

    testA = "abcdbefbq";
    testB = "a cd ef q";
    testC = ReplaceChar(testA, 'b', ' ');
    assert( testC == testB);
    assert( testA != testB);
}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT05: ReplaceChar ( dstring, lit, lit) ");
    dstring testA;
    dstring testB;
    dstring testC;

    testA = "abcdbefbq";
    testB = "a cd ef q";
    testC = ReplaceChar(testA, 'b', ' ');
    assert( testC == testB);
    assert( testA != testB);
}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT06: ReplaceChar ( string, wchar, wchar) ");
    string testA;
    string testB;
    string testC;
    wchar f,t;

    testA = "abcdbefbq";
    testB = "a cd ef q";
    f = 'b';
    t = ' ';
    testC = ReplaceChar(testA, f, t);
    assert( testC == testB);
    assert( testA != testB);

}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT07: ReplaceChar ( dstring, dchar, dchar) ");
    dstring testA;
    dstring testB;
    dstring testC;
    dchar f,t;

    testA = "abcdbefbq";
    testB = "axcdxefxq";
    f = 'b';
    t = 'x';
    testC = ReplaceChar(testA, f, t);
    assert( testC == testB);
    assert( testA != testB);
}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT08: ReplaceChar ( ubyte[], ubyte, ubyte) ");
    ubyte[] testA;
    ubyte[] testB;
    ubyte[] testC;
    ubyte f,t;

    testA = toStringA(cast(string)"abcdbefbq");
    testB = toStringA(cast(string)"a cd ef q");
    f = 'b';
    t = ' ';
    testC = ReplaceChar(testA, f, t);
    assert( testC == testB);
    assert( testA != testB);
}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT09: ReplaceChar ( ubyte[], char, char) ");
    ubyte[] testA;
    ubyte[] testB;
    ubyte[] testC;
    char f,t;

    testA = toStringA(cast(string)"abcdbefbq");
    testB = toStringA(cast(string)"a cd ef q");
    f = 'b';
    t = ' ';
    testC = ReplaceChar(testA, f, t);
    assert( testC == testB);
    assert( testA != testB);
}

    // ---- toStringA() -----
unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT10: toStringA( string) ");
    ubyte[] testA;
    string testB;
    ubyte[] testC;
    int c;

    testB = "abcdef";
    testA = toStringA(testB);
    c = 0;
    assert(testA.length == testB.length);
    foreach (uint i, ubyte x; testA)
    {
        if (x == testB[i])
            c++;
    }
    assert( c == testA.length);
}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT11: toStringA( wstring) ");
    ubyte[] testA;
    wstring testB;
    ubyte[] testC;
    int c;

    testB = "abcdef";
    testA = toStringA(testB);
    c = 0;
    assert(testA.length == testB.length);
    foreach (uint i, ubyte x; testA)
    {
        if (x == testB[i])
            c++;
    }
    assert( c == testA.length);
}

unittest{
    debug(str)  std.stdio.writefln("%s", "str.UT12: toStringA( dstring) ");
    ubyte[] testA;
    dstring testB;
    ubyte[] testC;
    int c;

    testB = "abcdef";
    testA = toStringA(testB);
    c = 0;
    assert(testA.length == testB.length);
    foreach (uint i, ubyte x; testA)
    {
        if (x == testB[i])
            c++;
    }
    assert( c == testA.length);
}

public {
/*
    IsLike does a simple pattern matching process. The pattern
    string can contain special tokens ...
       '*'   Represents zero or more characters in the text.
       '?'   Represents exactly one character in the text.
       '\'   Is the escape pattern. The next text character
             must exactly match the character following the
             escape character. This is used to match the
             tokens if they appear in the text.


*/
Bool IsLike(dstring pText, dstring pPattern)
body {
    const dchar kZeroOrMore = '*';
    const dchar kExactlyOne = '?';
    const dchar kEscape     = '\\';
    size_t  lTX = 0;
    size_t  lPX = 0;
    size_t lPMark;
    size_t lTMark;

    lPMark = pPattern.length;
    lTMark = 0;

    // If we haven't got any pattern or text left then we can finish.
    while(lPX < pPattern.length && lTX < pText.length)
    {
        if (pPattern[lPX] == kZeroOrMore)
        {
            // Skip over any adjacent '*'
            while( lPX < pPattern.length &&
                   pPattern[lPX] == kZeroOrMore)
            {
                lPMark = lPX;
                lPX++;
            }

            // Look for next match in text for current pattern char
            if ( lPX >= pPattern.length)
            {
                // Skip rest of text if there is no pattern left. This
                // can occur when the pattern ends with a '*'.
                lTX = pText.length;
            }
            else while( lPX < pPattern.length && lTX < pText.length)
            {
                // Skip over any escape lead-in char.
                if (pPattern[lPX] == kEscape && lPX < pPattern.length - 1)
                    lPX++;

                if (pPattern[lPX] == pText[lTX] ||
                    pPattern[lPX] == kExactlyOne)
                {
                    // We found the start of a potentially matching sequence.
                    // so increment over the matching char in preparation
                    // for a new subsequence scan.
                    lPX++;
                    lTX++;
                    // Mark the place in the text in case we have to do
                    // a rescan later.
                    lTMark = lTX;

                    // Stop doing this subsequence scan.
                    break;
                }
                else
                {
                    // No match found yet, so look at the next text char.
                    lTX++;
                }
            }
        }
        else if (pPattern[lPX] == kExactlyOne)
        {
            // Don't bother comparing the text char, just assume it matches.
            lTX++;
            lPX++;
        }
        else
        {
            if (pPattern[lPX] == kEscape)
            {
                // Skip over the escape lead-in char.
                lPX++;
            }

            if (pText[lTX] == pPattern[lPX])
            {
                // Text char matches pattern char so slide both to next char.
                lTX++;
                lPX++;
            }
            else
            {
                // Non-match, so set index to last check point values,
                // and try a new subsequence scan.
                lPX = lPMark;
                lTX = lTMark;
            }
        }
    }

    if (lTX >= pText.length)
    {
        // Skip over any final '*' in pattern.
        while( lPX < pPattern.length && pPattern[lPX] == kZeroOrMore)
        {
            lPX++;
        }
    }

    // If I have no text and no pattern left then the text matched the pattern.
    if (lTX >= pText.length  && lPX >= pPattern.length)
        return True;
    // otherwise it doesn't.
    return False;
}

Bool IsLike(string pText, string pPattern )
{
    return IsLike( std.utf.toUTF32(pText), std.utf.toUTF32(pPattern));
}

}


//-------------------------------------------------------
Bool begins(string pString, string pSubString)
//-------------------------------------------------------
{
    return begins( std.utf.toUTF32(pString), std.utf.toUTF32(pSubString));
}

//-------------------------------------------------------
Bool begins(wstring pString, wstring pSubString)
//-------------------------------------------------------
{
    return begins( std.utf.toUTF32(pString), std.utf.toUTF32(pSubString));
}

//-------------------------------------------------------
Bool begins(dstring pString, dstring pSubString)
//-------------------------------------------------------
{
    if (pString.length < pSubString.length)
        return False;
    if (pSubString.length == 0)
        return False;

    if (pString[0..pSubString.length] == pSubString)
        return True;
    return False;
}

//-------------------------------------------------------
Bool ends(string pString, string pSubString)
//-------------------------------------------------------
{
    return ends( std.utf.toUTF32(pString), std.utf.toUTF32(pSubString));
}

//-------------------------------------------------------
Bool ends(wstring pString, wstring pSubString)
//-------------------------------------------------------
{
    return ends( std.utf.toUTF32(pString), std.utf.toUTF32(pSubString));
}

//-------------------------------------------------------
Bool ends(dstring pString, dstring pSubString)
//-------------------------------------------------------
{
    size_t lSize;

    if (pString.length < pSubString.length)
        return False;
    if (pSubString.length == 0)
        return False;

    lSize = pString.length-pSubString.length;
    if (pString[lSize .. $] != pSubString)
        return False;

    return True;
}


//-------------------------------------------------------
string enquote(string pString, char pTrigger = ' ', string pPrefix = `"`, string pSuffix = `"`)
//-------------------------------------------------------
{
    if ( (pString.length > 0) &&
         (std.string.indexOf(pString, pTrigger) != -1) &&
		 (begins(pString, pPrefix) == False) &&
		 (ends(pString, pSuffix) == False)
       )
        return pPrefix ~ pString ~ pSuffix;

    return pString;
}

//-------------------------------------------------------
wstring enquote(wstring pString, wchar pTrigger = ' ', wstring pPrefix = `"`, wstring pSuffix = `"`)
//-------------------------------------------------------
{
    if ( (pString.length > 0) &&
         (std.string.indexOf(pString, pTrigger),0 ) != -1 &&
		 (begins(pString, pPrefix) == False) &&
		 (ends(pString, pSuffix) == False)
       )
        return pPrefix ~ pString ~ pSuffix;

    return pString;
}

//-------------------------------------------------------
dstring enquote(dstring pString, dchar pTrigger = ' ', dstring pPrefix = `"`, dstring pSuffix = `"`)
//-------------------------------------------------------
{
    if ( (pString.length > 0) &&
         (std.string.indexOf(pString, pTrigger),0 ) != -1 &&
		 (begins(pString, pPrefix) == False) &&
		 (ends(pString, pSuffix) == False)
       )
        return pPrefix ~ pString ~ pSuffix;

    return pString;
}

unittest
{ // IsLike
     debug(str)  std.stdio.writefln("str.IsLike.UT00");
     assert( IsLike( "foobar"c, "foo?*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT01");
     assert( IsLike( "foobar"c, "foo*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT02");
     assert( IsLike( "foobar"c, "*bar"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT03");
     assert( IsLike( ""c, "foo*"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT04");
     assert( IsLike( ""c, "*bar"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT05");
     assert( IsLike( ""c, "?"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT06");
     assert( IsLike( ""c, "*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT06a");
     assert( IsLike( ""c, "x"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT06b");
     assert( IsLike( "x"c, ""c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT07");
     assert( IsLike( "f"c, "?"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT08");
     assert( IsLike( "f"c, "*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT09");
     assert( IsLike( "foo"c, "?oo"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT10");
     assert( IsLike( "foobar"c, "?oo"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT11");
     assert( IsLike( "foobar"c, "?oo*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT12");
     assert( IsLike( "foobar"c, "*oo*b*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT13");
     assert( IsLike( "foobar"c, "*oo*ar"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT14");
     assert( IsLike( "terrainformatica.com"c, "*.com"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT15");
     assert( IsLike( "12abcdef"c, "*abc?e*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT16");
     assert( IsLike( "12abcdef"c, "**abc?e**"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT17");
     assert( IsLike( "12abcdef"c, "*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT18");
     assert( IsLike( "12abcdef"c, "?*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT19");
     assert( IsLike( "12abcdef"c, "*?"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT20");
     assert( IsLike( "12abcdef"c, "?*?"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT21");
     assert( IsLike( "12abcdef"c, "*?*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT22");
     assert( IsLike( "12"c, "??"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT23");
     assert( IsLike( "123"c, "??"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT24");
     assert( IsLike( "12"c, "??3"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT25");
     assert( IsLike( "12"c, "???"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT25a");
     assert( IsLike( "123"c, "?2?"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT25b");
     assert( IsLike( "abc123def"c, "*?2?*"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT25c");
     assert( IsLike( "2"c, "2?*"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT26");
     assert( IsLike( ""c, ""c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT27");
     assert( IsLike( "abc"c, "abc"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT28");
     assert( IsLike( "abc"c, ""c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT29");
     assert( IsLike( "abc*d"c, "abc\\*d"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT30");
     assert( IsLike( "abc?d"c, "abc\\?d"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT31");
     assert( IsLike( "abc\\d"c, "abc\\\\d"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT31a");
     assert( IsLike( "abc*d"c, "abc\\*d"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT31b");
     assert( IsLike( "abc\\d"c, "abc\\*d"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT31c");
     assert( IsLike( "abc\\d"c, "abc\\*d"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT31d");
     assert( IsLike( "abc\\d"c, "*\\*d"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT31e");
     assert( IsLike( "abc\\d"c, "*\\\\d"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT32");
     assert( IsLike( "foobar"c, "foo???"c) == True);
     debug(str)  std.stdio.writefln("str.IsLike.UT33");
     assert(  IsLike( "foobar"c, "foo????"c) == False);
     debug(str)  std.stdio.writefln("str.IsLike.UT34");
     assert(  IsLike( "c:\\dindx_a\\index_000.html"c, "*index_???.html"c) == True);
}


unittest
{  // begins
     debug(str)  std.stdio.writefln("str.begins.UT01");
     assert( begins( cast(string)"foobar", cast(string)"o") == False);
     debug(str)  std.stdio.writefln("str.begins.UT02");
     assert( begins( cast(string)"foobar", cast(string)"f") == True);
     debug(str)  std.stdio.writefln("str.begins.UT03");
     assert( begins( cast(string)"foobar", cast(string)"fo") == True);
     debug(str)  std.stdio.writefln("str.begins.UT04");
     assert( begins( cast(string)"foobar", cast(string)"foo") == True);
     debug(str)  std.stdio.writefln("str.begins.UT05");
     assert( begins( cast(string)"foobar", cast(string)"foob") == True);
     debug(str)  std.stdio.writefln("str.begins.UT06");
     assert( begins( cast(string)"foobar", cast(string)"fooba") == True);
     debug(str)  std.stdio.writefln("str.begins.UT07");
     assert( begins( cast(string)"foobar", cast(string)"foobar") == True);
     debug(str)  std.stdio.writefln("str.begins.UT08");
     assert( begins( cast(string)"foobar", cast(string)"foobarx") == False);
     debug(str)  std.stdio.writefln("str.begins.UT09");
     assert( begins( cast(string)"foobar", cast(string)"oo") == False);
     debug(str)  std.stdio.writefln("str.begins.UT10");
     assert( begins( cast(string)"foobar", cast(string)"") == False);
     debug(str)  std.stdio.writefln("str.begins.UT11");
     assert( begins( cast(string)"", cast(string)"") == False);
}

unittest
{  // ends
     debug(str)  std.stdio.writefln("str.ends.UT01");
     assert( ends( cast(string)"foobar", cast(string)"a") == False);
     debug(str)  std.stdio.writefln("str.ends.UT02");
     assert( ends( cast(string)"foobar", cast(string)"r") == True);
     debug(str)  std.stdio.writefln("str.ends.UT03");
     assert( ends( cast(string)"foobar", cast(string)"ar") == True);
     debug(str)  std.stdio.writefln("str.ends.UT04");
     assert( ends( cast(string)"foobar", cast(string)"bar") == True);
     debug(str)  std.stdio.writefln("str.ends.UT05");
     assert( ends( cast(string)"foobar", cast(string)"obar") == True);
     debug(str)  std.stdio.writefln("str.ends.UT06");
     assert( ends( cast(string)"foobar", cast(string)"oobar") == True);
     debug(str)  std.stdio.writefln("str.ends.UT07");
     assert( ends( cast(string)"foobar", cast(string)"foobar") == True);
     debug(str)  std.stdio.writefln("str.ends.UT08");
     assert( ends( cast(string)"foobar", cast(string)"foobarx") == False);
     debug(str)  std.stdio.writefln("str.ends.UT09");
     assert( ends( cast(string)"foobar", cast(string)"oo") == False);
     debug(str)  std.stdio.writefln("str.ends.UT10");
     assert( ends( cast(string)"foobar", cast(string)"") == False);
     debug(str)  std.stdio.writefln("str.ends.UT11");
     assert( ends( cast(string)"", cast(string)"") == False);
}

string Expand(string pOriginal, string pTokenList,
                string pLeading = "{", string pTrailing = "}")
{
    return std.utf.toUTF8( Expand (
                    std.utf.toUTF32(pOriginal),
                    std.utf.toUTF32(pTokenList),
                    std.utf.toUTF32(pLeading),
                    std.utf.toUTF32(pTrailing)
                    ) ) ;

}

dstring Expand(dstring pOriginal, dstring pTokenList,
                dstring pLeading = "{", dstring pTrailing = "}")
{
    dstring lResult;
    dstring[] lTokens;
    sizediff_t lPos;
    struct KV
    {
        dstring Key;
        dstring Value;
    }

    KV[] lKeyValues;

    lResult = pOriginal;

    // Split up token list into separate token pairs.
    lTokens = util.linetoken.TokenizeLine(pTokenList, ","d, "", "");
    foreach(dstring lKV; lTokens)
    {
        dstring[] lKeyValue;
        if (lKV.length > 0)
        {
            lKeyValue = util.linetoken.TokenizeLine(lKV, "="d, "", "");
            lKeyValues.length = lKeyValues.length + 1;
            lKeyValues[$-1].Key = lKeyValue[0];
            lKeyValues[$-1].Value = lKeyValue[1];
        }
    }

    // First to the simple replacements.
    foreach(KV lKV; lKeyValues)
    {
        dstring lToken;

        lToken = pLeading ~ lKV.Key ~ pTrailing;
        while( (lPos = std.string.indexOf(lResult, lToken, std.string.CaseSensitive.no)) != -1 )
        {
            lResult = lResult[0..lPos] ~
                      lKV.Value ~
                      lResult[lPos + lToken.length .. $];
        }
    }

    // Now check for conditional replacements
    foreach(KV lKV; lKeyValues)
    {
        dstring lToken;
        dstring lOptValue;

        // First check for missing conditionals...
        lToken = pLeading ~ "?" ~ lKV.Key ~ ":";
        while ( (lPos = find(lResult, lToken,0)) != -1)
        {
            sizediff_t lEndPos;
            lEndPos = find(lResult, pTrailing, lPos+lToken.length);
            if (lEndPos != -1)
            {
                lOptValue = lResult[lPos+lToken.length..lEndPos];
                if (lKV.Value.length == 0)
                {
                    lResult = lResult[0..lPos] ~
                              lOptValue ~
                              lResult[lEndPos+pTrailing.length .. $];
                }
                else
                {
                    lResult = lResult[0..lPos] ~
                              lKV.Value ~
                              lResult[lEndPos+pTrailing.length .. $];
                }
            }

        }

        // Next check for present conditionals...
        lToken = pLeading ~ "?" ~ lKV.Key ~ "=";
        while ( (lPos = find(lResult, lToken, 0)) != -1)
        {
            sizediff_t lEndPos;
            lEndPos = find(lResult, pTrailing, lPos+lToken.length);
            if (lEndPos != -1)
            {
                lOptValue = lResult[lPos+lToken.length..lEndPos];
                if (lKV.Value.length != 0)
                {
                    lResult = lResult[0..lPos] ~
                              lOptValue ~
                              lResult[lEndPos+pTrailing.length .. $];
                }
                else
                {
                    lResult = lResult[0..lPos] ~
                              lResult[lEndPos+pTrailing.length .. $];
                }
            }

        }
    }

    // Now remove all unused tokens.
    while( (lPos = find(lResult, pLeading,0 )) != -1)
    {
        sizediff_t lPos1;
        sizediff_t lPos2;
        sizediff_t lPos3;

        lPos2 = find(lResult, pTrailing, lPos + 1 );
        if (lPos2 == -1)
            break;

        if (lResult[lPos+1] == '?')
        {
            lPos3 = find(lResult, ":"d, lPos + 1 );
            if (lPos3 != -1 && lPos3 < lPos2)
            {
                // Replace entire token with default value from within token.
                lResult = lResult[0 .. lPos] ~
                    lResult[lPos3+1 .. lPos2] ~
                    lResult[lPos2 + pTrailing.length .. $];
            }
            else
            {
                // Remove entire token from result.
                lResult = lResult[0 .. lPos] ~
                    lResult[lPos2 + pTrailing.length .. $];
            }
        }
        else
            // Remove entire token from result.
            lResult = lResult[0 .. lPos] ~
                lResult[lPos2 + pTrailing.length .. $];
    }

    return lResult;
}
unittest
{  // Expand
     assert( Expand( "foo{what}"c, "what=bar"c) == "foobar");
     assert( Expand( "foo{what}"c, "when=bar"c) == "foo");
     assert( Expand( "foo{what}"d, "what="d) == "foo");
     assert( Expand( "foo what"c, "what=bar"c) == "foo what");
     assert( Expand( "foo^what$"c, "what=bar"c, "^"c, "$"c) == "foobar");
     assert( Expand( "foo$(what)"c, "what=bar"c, "$("c, ")"c) == "foobar");
     assert( Expand( "foo{?what:who}bar"c, "what="c) == "foowhobar");
     assert( Expand( "foo{?what:who}bar"c, ""c) == "foowhobar");
     assert( Expand( "foo{?what:who}bar"c, "who=why"c) == "foowhobar");
     assert( Expand( "foo{?what:who}bar"c, "what=when"c) == "foowhenbar");
     assert( Expand( "foo{?what=who}bar"c, "what="c) == "foobar");
     assert( Expand( "foo{?what=who}bar"c, ""c) == "foobar");
     assert( Expand( "foo{?what=who}bar"c, "who=why"c) == "foobar");
     assert( Expand( "foo{?what=,}bar"c, "what=when"c) == "foo,bar");
}

string toASCII(string pUTF8)
{
    bool lChanged;
    char[] lResult;
    // Convert non-ASCII chars based on the Microsoft DOS Western Europe charset
    static string lTranslateTable =
        "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F"
        "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F"
        " !\"#$%&'()*+,-./0123456789:;<=>?"
        "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
        "`abcdefghijklmnopqrstuvwxyz{|}~ "
        "CueaaaaceeeiiiAAEaAooouuyOUo$Oxf"
        "aiounNa0?R!24!<>-----AAAC----c$-"
        "------aA-------$dDEEEiIII----|I-"
        "OBOOoOmdDUUUyY-'-+=3PS/,0:.132- ";
    lResult = pUTF8.dup;
    for (int i = 0; i < lResult.length; i++)
    {
        if (lResult[i] > 127)
        {
            if (lChanged == false)
            {
                lResult = pUTF8.dup;
                lChanged = true;
            }
            lResult[i] = lTranslateTable[lResult[i]];
        }
    }
    return std.conv.to!string(lResult);
}

/**************************************
 * Split s[] into an array of lines,
 * using CR, LF, or CR-LF as the delimiter.
 * The delimiter is not included in the line.
 */


private static dstring Unicode_WhiteSpace =
    "\u0009\u000A\u000B\u000C\u000D"  // TAB, NL, , NP, CR
    // "\u0020"  // SPACE
    "\u0085" // <control-0085>
    // "\u00A0" // NO-BREAK SPACE
    "\u1680" // OGHAM SPACE MARK
    "\u180E" // MONGOLIAN VOWEL SEPARATOR
    "\u2000\u2001\u2002\u2003\u2004"
    "\u2005\u2006\u2007\u2008"
    "\u2009\u200A" // EN QUAD..HAIR SPACE
    "\u2028" // LINE SEPARATOR
    "\u2029" // PARAGRAPH SEPARATOR
    // "\u202F" // NARROW NO-BREAK SPACE
    "\u205F" // MEDIUM MATHEMATICAL SPACE
    "\u3000" // IDEOGRAPHIC SPACE
    "\ufffd" // Stop
    ;

bool UC_IsSpace(dchar pChar)
{
    int i;
    if (pChar == '\u0020') // Common case first.
        return true;

    while( pChar > Unicode_WhiteSpace[i])
        i++;
    return (pChar == Unicode_WhiteSpace[i] ? true : false);
}

// Returns a slice up to the first whitespace (if any)
string findws(string pText)
{
    foreach(int lPos, dchar c; pText)
    {
        if (UC_IsSpace(c))
            return pText[0..lPos];
    }
    return pText;
}
unittest
{
    assert(findws("abc def") == "abc");
    assert(findws("\u3056\u2123 def") == "\u3056\u2123");
    assert(findws("\u3056\u2123\u2028def") == "\u3056\u2123");
}

// Returns a slice from the last whitespace (if any) to the end
dstring findws_r(dstring pText)
{
    sizediff_t lPos = pText.length-1;
    while (lPos >= 0 && !UC_IsSpace(pText[lPos]))
        lPos--;

    return pText[lPos+1..$];
}

/*****************************************
 * Strips leading or trailing whitespace, or both.
 */

dstring stripl(dstring s)
{
    int i;

    foreach (int p, dchar c; s)
    {
	    if (!UC_IsSpace(c))
	    {
    	    i = p;
	        break;
        }
    }
    return s[i .. s.length];
}
string stripl(string s) /// ditto
{
    return std.utf.toUTF8(stripl(std.utf.toUTF32(s)));
}


dstring stripr(dstring s) /// ditto
{
    sizediff_t i;

    for (i = s.length-1; i >= 0; i--)
    {
	if (!UC_IsSpace(s[i]))
	    break;
    }
    return s[0 .. i+1];
}

string stripr(string s) /// ditto
{
    return std.utf.toUTF8(stripr(std.utf.toUTF32(s)));
}

dstring strip(dstring s) /// ditto
{
    return stripr(stripl(s));
}

wstring strip(wstring s) /// ditto
{
    return std.utf.toUTF16(stripr(stripl(std.utf.toUTF32(s))));
}

string strip(string s) /// ditto
{
    return std.utf.toUTF8(stripr(stripl(std.utf.toUTF32(s))));
}

unittest
{
    dstring s;

    s = strip("  foo\t "d);
    assert(s == "foo"d);
    s = stripr("  foo\t "d);
    assert(s == "  foo"d);
    s = stripl("  foo\t "d);
    assert(s == "foo\t "d);
}

template Tfind(T)
{
    sizediff_t find(immutable(T)[] pText, immutable(T)[] pSubText, size_t pFrom = 0)
    {
        sizediff_t lTexti;
        sizediff_t lSubi;
        sizediff_t lPos;
        sizediff_t lTextEnd;

        if (pFrom < 0)
            pFrom = 0;

        // locate first match.
        lSubi = 0;
        lTexti = pFrom;
        // No point in looking past this position.
        lTextEnd = pText.length - pSubText.length + 1;
        while(lSubi < pSubText.length)
        {
            while(lTexti < lTextEnd && pSubText[lSubi] != pText[lTexti])
            {
                lTexti++;
            }
            if (lTexti >= pText.length)
                return -1;

            lPos = lTexti;  // Mark possible start of substring match.

            lTexti++;
            lSubi++;
            // Locate all matches
            while(lTexti < pText.length && lSubi < pSubText.length &&
                        pSubText[lSubi] == pText[lTexti])
            {
                lTexti++;
                lSubi++;
            }
            if (lSubi == pSubText.length)
                return lPos;
            lSubi = 0;
            lTexti = lPos + 1;
        }
        return -1;
    }
}
alias Tfind!(dchar).find find;
alias Tfind!(wchar).find find;

unittest
{
    dstring Target = "abcdefgcdemn"d;
    assert( find(Target, "mno") == -1);
    assert( find(Target, "mn") == 10);
    assert( find(Target, "cde") == 2);
    assert( find(Target, "cde"d, 3) == 7);
    assert( find(Target, "cde"d, 8) == -1);
    assert( find(Target, "cdg") == -1);
    assert( find(Target, "f") == 5);
    assert( find(Target, "q") == -1);
    assert( find(Target, "a"d, 200) == -1);
    assert( find(Target, "") == -1);
    assert( find("", Target, 0) == -1);
    assert( find(""d, "") == -1);
    assert( find(Target, "d"d, -4) == 3);
}

string TranslateEscapes(string pText)
{
    char[] lResult;
    sizediff_t lInPos;
    sizediff_t lOutPos;

    if (std.string.indexOf(pText, '\\') == -1)
        return pText;

    lResult.length = pText.length;
    lInPos = 0;
    lOutPos = 0;

    while(lInPos < pText.length)
    {
        if (pText[lInPos] == '\\' && lInPos+1 != pText.length)
        {
            switch (pText[lInPos+1])
            {
                case 'n':
                    lInPos += 2;
                    lResult[lOutPos] = '\n';
                    break;
                case 't':
                    lInPos += 2;
                    lResult[lOutPos] = '\t';
                    break;
                case 'r':
                    lInPos += 2;
                    lResult[lOutPos] = '\r';
                    break;
                case '\\':
                    lInPos += 2;
                    lResult[lOutPos] = '\\';
                    break;
                default:
                    lResult[lOutPos] = pText[lInPos];
                    lInPos++;
            }
        }
        else
        {
            lResult[lOutPos] = pText[lInPos];
            lInPos++;
        }

        lOutPos++;
    }

    return std.conv.to!string(lResult[0..lOutPos]);
}

unittest
{
    assert( TranslateEscapes("abc") == "abc");
    assert( TranslateEscapes("\\n") == "\n");
    assert( TranslateEscapes("\\t") == "\t");
    assert( TranslateEscapes("\\r") == "\r");
    assert( TranslateEscapes("\\\\") == "\\");
    assert( TranslateEscapes("\\q") == "\\q");
}

// Function to replace tokens in the form %<SYM>%  with environment data.
// Note that '%%' is replaced by a single '%'.
// -------------------------------------------
string ExpandEnvVar(string pLine)
// -------------------------------------------
{
    string lLine;
    string lSymName;
    sizediff_t lPos;
    sizediff_t lEnd;

    lPos = std.string.indexOf(pLine, '%');
    if (lPos == -1)
        return pLine;

    lLine = pLine[0.. lPos];
    for( ; lPos < pLine.length; lPos++ )
    {
        if (pLine[lPos] == '%')
        {
            if (lPos+1 != pLine.length && pLine[lPos+1] == '%')
            {
                lLine ~= '%';
                lPos++;
                continue;
            }

            for(lEnd = lPos+1; (lEnd < pLine.length) && (pLine[lEnd] != '%'); lEnd++ )
            {
            }
            if (lEnd < pLine.length)
            {
                lSymName = pLine[lPos+1..lEnd];

                if (lSymName.length > 0)
                {
                    lLine ~= GetEnv(std.utf.toUTF8(lSymName));
                }
                lPos = lEnd;
            }
            else
            {
                lLine ~= pLine[lPos];
            }
        }
        else
        {
            lLine ~= pLine[lPos];
        }
    }
    return lLine;
}
unittest {
    SetEnv("EEVA", __FILE__ );
    SetEnv("EEVB", __DATE__ );
    SetEnv("EEVC", __TIME__ );
    assert( ExpandEnvVar("The file '%EEVA%' was compiled on %EEVB% at %EEVC%") ==
      "The file '" ~ __FILE__ ~"' was compiled on " ~
      __DATE__ ~ " at " ~ __TIME__);
}

//-------------------------------------------------------
string GetEnv(string pSymbol)
//-------------------------------------------------------
{
    return std.process.getenv(pSymbol);
}

//-------------------------------------------------------
void SetEnv(string pSymbol, string pValue, bool pOverwrite = true)
//-------------------------------------------------------
{
    if (pOverwrite || GetEnv(pSymbol).length == 0)
        std.process.setenv(pSymbol, pValue, true);
}

unittest {
    SetEnv("SetEnvUnitTest", __FILE__ ~ __TIMESTAMP__);
    assert( GetEnv("SetEnvUnitTest") == __FILE__ ~ __TIMESTAMP__);
}

template Tyn(T)
{
//-------------------------------------------------------
bool YesNo(immutable(T)[] pText, bool pDefault)
//-------------------------------------------------------
{
    bool lResult = pDefault;
    foreach(int i, dchar c; pText)
    {
        if (c == '=' || c == ':')
        {
            pText = stripl(pText[i+1 .. $]);
            break;
        }
    }
    if (pText.length > 0)
    {
        if (pText[0] == 'Y' || pText[0] == 'y')
            lResult = true;
        else if (pText[0] == 'N' || pText[0] == 'n')
            lResult = false;
    }

    return lResult;
}
//-------------------------------------------------------
void YesNo(immutable(T)[] pText, out bool pResult, bool pDefault)
//-------------------------------------------------------
{
    pResult = YesNo(pText, pDefault);
}

//-------------------------------------------------------
void YesNo(immutable(T)[] pText, out immutable(T)[] pResult, bool pDefault)
//-------------------------------------------------------
{
    pResult = (YesNo(pText, pDefault) ? cast(immutable(T)[])"Y" : cast(immutable(T)[])"N");
}

//-------------------------------------------------------
void YesNo(immutable(T)[] pText, out T pResult, bool pDefault)
//-------------------------------------------------------
{
    pResult = (YesNo(pText, pDefault) ? 'Y' : 'N');
}
//-------------------------------------------------------
void YesNo(immutable(T)[] pText, out Bool pResult, Bool pDefault)
//-------------------------------------------------------
{
    pResult = (YesNo(pText, (pDefault==True?true:false)) ? True : False);
}
}
alias Tyn!(dchar).YesNo YesNo;
alias Tyn!(char).YesNo YesNo;
