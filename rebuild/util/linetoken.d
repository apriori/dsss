/**************************************************************************

        @file linetoken.d

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
module util.linetoken;

private {
    static import std.ctype;
    static import std.string;
    static import std.utf;
    import std.conv;

}
string[] TokenizeLine(string pSource,
                      string pDelim = ",",
                      string pComment = "//",
                      string pEscape = "\\")
{
    dstring[] lTemp;
    string[] lResult;

    lTemp= TokenizeLine( std.utf.toUTF32(pSource),
                         std.utf.toUTF32(pDelim),
                         std.utf.toUTF32(pComment),
                         std.utf.toUTF32(pEscape) );
    foreach(dstring lLine; lTemp )
    {
        lResult ~= std.utf.toUTF8( lLine );
    }

    return lResult;
}

dstring[] TokenizeLine(dstring pSource,
                       dstring pDelim = ",",
                       dstring pComment = "//",
                       dstring pEscape = "\\")
{
    dstring[] lResult;
    dchar lOpenBracket;
    dchar lCloseBracket;
    int lNestLevel;
    sizediff_t lInToken;
    dstring lDelim;
    sizediff_t lTrimSpot;
    sizediff_t lPos;
    bool lLitMode;

    static dstring vOpenBracket  = "\"'([{`";
    static dstring vCloseBracket = "\"')]}`";

    if (pDelim.length > 0)
        // Only use single-char delimiters. Excess chars are ignored.
        lDelim ~= pDelim[0];
    else
        lDelim = "";   // Meaning 'any group of whitespace chars'

    lInToken = -1;
    lTrimSpot = -1;
    foreach(int i, dchar c; pSource)
    {
        if (lNestLevel == 0)
        {   // Check for comment string.
            if (pComment.length > 0)
            {
                if (c == pComment[0])
                {
                    if ((pSource.length - i) > pComment.length)
                    {
                        if (pSource[i .. i + pComment.length] == pComment)
                            break;
                    }
                }
            }
        }

        if(lInToken == -1)
        {
            // Not in a token yet.
            if (std.ctype.isspace(c))
                continue;  // Skip over spaces

            // Non-space so a token is about to start.
            lInToken = lResult.length;
            lResult.length = lInToken + 1;
            lTrimSpot = -1;
        }

        if (lLitMode)
        {   // In literal character mode, so just accept the char
            // without examining it.
            lResult[lInToken] ~= c;
            lLitMode = false;
            lTrimSpot = -1;
            continue;
        }

        if (pEscape.length > 0 && (c == pEscape[0]))
        {   // Slip into literal character mode
            lLitMode = true;
            continue;
        }

        if (lNestLevel == 0)
        {   // Only check for delimiters if not in 'bracket'-mode.
            if (lDelim.length == 0)
            {
                if (std.ctype.isspace(c))
                {
                    lTrimSpot = -1;
                    lInToken = -1;
                    // Go fetch next character.
                    continue;
                }
            }
            else if (c == lDelim[0])
            {
                // Found a token delimiter, so I end the current token.
                if (lTrimSpot != -1)
                {
                    // But first I trim off trailing spaces.
                    lResult[lInToken].length = lTrimSpot-1;
                    lTrimSpot = -1;
                }
                lInToken = lResult.length;
                lResult.length = lInToken + 1;
                // Go fetch next character.
                continue;
            }
        }

        if (lResult[lInToken].length == 0)
        {
            // Not started a token yet.
            dstring lChar;
            lPos = std.string.indexOf(std.utf.toUTF8(vOpenBracket), to!char(c));
            if (lPos != -1)
            {
                // An 'open' bracket was found, so make this its
                // own token, start another new one, and go into
                // 'bracket'-mode.
                lResult[lInToken] ~= c;

                lInToken = lResult.length;
                lResult.length = lInToken + 1;

                lOpenBracket = c;
                lCloseBracket = vCloseBracket[lPos];
                lNestLevel = 1;
                // Go fetch next character.
                continue;
            }
        }

        if (lNestLevel > 0)
        {
            if (c == lCloseBracket)
            {
                lNestLevel--;
                if (lNestLevel == 0)
                {
                    // Okay, I've found the end of the bracketed chars.
                    // Note that this doesn't necessarily mean the end of
                    // a token was also found. And I can start checking
                    // again for trailing spaces.
                    lTrimSpot = -1;

                    // Go fetch next character
                    continue;
                }
            } else if (c == lOpenBracket)
            {
                // Note that the char is added to the token too.
                lNestLevel++;
            }
        }

        // Finally, I get to add this char to the token.
        lResult[lInToken] ~= c;

        if (lNestLevel == 0)
            // Only check for trailing spaces if not in 'bracket'-mode
            if (std.ctype.isspace(c))
            {
                // It was a space, so it is potentially a trailing space,
                // thus I mark its spot (if it's the first in a set of spaces.)
                if (lTrimSpot == -1)
                    lTrimSpot = lResult[lInToken].length;
            }
            else
               lTrimSpot = -1;

    }

    if (lResult.length == 0)
        lResult ~= "";

    if (lTrimSpot != -1)
    {
        // Trim off trailing spaces on last token.
        lResult[$-1].length = lTrimSpot-1;
    }

    return lResult;
}

/* How To Use ===============================
Insert this into your code ...

  private import linetoken;

Then to call it use ...

   string Toks;
   string InputLine;
   string DelimChar;
   string CommentString;

   Toks = TokenizeLine(InputLine, DelimChar, CommentString);
** Note that it accepts all 'string' or all 'dstring' arguments.

The routine scans the input string and returns a set of strings, one
per token found in the input string.

The tokens are delimited by the single character in DelimChar. However,
if DelimChar is an empty string, then tokens are delimited by any group
of one or more white-space characters. By default, DelimChar is ",".

If CommentString is not empty, then all parts of the input string from
the begining of the comment to the end are ignored. By default
CommentString is "//".

If a token begins with a quote (single, double or back), then you will
get back two tokens. The first is the quote as a single character string,
and the second is all the characters up to, but not including the next
quote of the same type. The ending quote is discarded.

If a token begins with a bracket (parenthesis, square, or brace), then you
will get back two tokens. The first is the opening bracket as a single
character string, and the second is all the characters up to, but not
including, the matching end bracket, taking nested brackets (of the same
type) into consideration.

All whitespace in between tokens is ignored, and not returned.

If the tokenizer finds a back-slash character (\), then next character
is always considered as a part of a token. You can use this to force
the delimiter character or spaces to be inserted into a token.

Examples:
   TokenizeLine(" abc, def , ghi, ")
 --> {"abc", "def", "ghi", ""}

   TokenizeLine("character    or spaces to be \t inserted", "")
 --> {"character", "or", "spaces", "to", "be", "inserted"}

   TokenizeLine(" abc; def , ghi; ", ";")
 --> {"abc", "def , ghi", "" }

   TokenizeLine(" abc, [def , ghi]           ")
 --> {"abc", "[", "def , ghi"}

   TokenizeLine(" abc, [def , ghi] // comment")
 --> {"abc", "[", "def , ghi"}

   TokenizeLine(" abc, [def , [ghi, jkl] ]  ")
 --> {"abc", "[", "def , [ghi, jkl] "}

   TokenizeLine(" abc, def , ghi ; comment", ",", ";")
 --> {"abc", "def", "ghi"}

   TokenizeLine(` abc, "def , ghi" , jkl `)
 --> {"abc", `"`, "def , ghi", "jkl"}
*/
