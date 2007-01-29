/**************************************************************************

        @file macro.d

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
module util.macro;

private {
    static import util.str;

    static import std.stdio;
    static import std.string;
    static import std.regexp;
    static import util.booltype;   // definition of True and False
    alias util.booltype.True True;
    alias util.booltype.False False;
    alias util.booltype.Bool Bool;
    static import util.fileex;
    static import util.str;
}

struct Substitute
{
    enum SubType
    {
        Text,
        Word,
        RegExp
    }
    SubType Type;
    char[] Pattern;
    char[] Resolution;
    char[] EscapeOpen;
    char[] EscapeClose;
    bool Used;
    bool Recurse;
}

struct TextSpan
{
    char[] Text;
    int Start;
    int End;
}

/** Scans through pText from pStartPos onwards, looking for pSubString.
  * returns: A TextSpan structure
  * params:
  *     pText = The text to scan through
  *     pSubString = The substring to look for.
  *     pStartPos = The starting point within pText to begin scanning.
*/
TextSpan findspan(char[] pText, char[] pSubString, uint pStartPos = 0)
{
    TextSpan lResult;

    lResult.Text = pSubString;
    lResult.Start = std.string.find(pText[pStartPos..$], pSubString);
    if (lResult.Start != -1)
    {
        lResult.Start += pStartPos;
        lResult.End = lResult.Start + pSubString.length;
    }
    return lResult;
}

/** Checks that pString at pStartPos contains pSubString.
  * returns: A TextSpan structure
  * params:
  *     pString = The text to check
  *     pSubString = The substring to look for.
  *     pStartPos = The starting point within pString to begin checking.
*/
TextSpan matchspan(char[] pString, char[] pSubString, uint pStartPos = 0)
{
    TextSpan lResult;
    int lEnd;


    lEnd = pStartPos + pSubString.length;
    lResult.Start = -1;
    if ((lEnd <= pString.length) && (pString[pStartPos .. lEnd] == pSubString))
    {
        lResult.Text = pSubString;
        lResult.Start = pStartPos;
        lResult.End = lEnd;
    }

    return lResult;
}

char[] ConditionalSpace(char[] pToken, char[] pSubString, char[] pString, int pStart, int pEnd)
{
    // Deal with any forced space markers.
    if (util.str.begins(pSubString, pToken) == True)
        if (pStart == 0 || std.ctype.isspace(pString[pStart-1]))
            pSubString = pSubString[pToken.length..$];
        else
            pSubString = " " ~ pSubString[pToken.length..$];


    if (util.str.ends(pSubString, pToken) == True)
        if (pEnd >= pString.length || std.ctype.isspace(pString[pEnd]))
            pSubString = pSubString[0..$-pToken.length];
        else
            pSubString = pSubString[0..$-pToken.length] ~ " ";
    return pSubString;
}

TextSpan FindPattern(Substitute pMacro, char[] pText, int pStartPos)
{
    TextSpan lResultPos;
    uint lNextPos;
    char[][] lPatternTokens;
    int lStartPos;
    int lEndPos;
    int lTokenIndex;
    uint lNextScan;
    bool lNeedsChanging;

    lResultPos.Text = "";
    lResultPos.Start = -1;
    lResultPos.End = 0;

    if (pMacro.Type == Substitute.SubType.Text)
    {
        // Simple case of text substitution.
        lResultPos = findspan(pText, pMacro.Pattern, pStartPos);
        return lResultPos;
    }
    else if (pMacro.Type == Substitute.SubType.Word)
    {
        /* The idea here is that the pattern represents one or more
           words. Which means that the entire matching text must be
           surrounded by 'non'-word characters and only have whitespace
           in between matching sub-words.
           e.g.  pattern = "end procedure" would find a match in  ...
                 "end    procedure"
                 ".end\t\tprocedure."
               but not
                 "bend procedure"
                 "end.procedure"

           By 'non'-word I mean that if the pattern starts with an alpha-
           numeric character then its non-word character would be a non-
           alphanumeric, and visa versa.
        */

        // Split the pattern into separate words.
        lPatternTokens = std.string.split(pMacro.Pattern, " ");
        if (lPatternTokens.length == 0)
        {
            return lResultPos;
        }

        // Now find the set of adjacent words in the text.
        lNextPos = 0;
        lNextScan = pStartPos;
        lNeedsChanging = false;

        L_Next_Scan:while(true)
        {
            TextSpan lPos;

            // Locate start of pattern by scanning through until
            // a match for the first token word is found.
            lTokenIndex = 0;
            lPos = findspan(pText, lPatternTokens[lTokenIndex], lNextScan);
            if (lPos.Start == -1)
            {
                // The first token in the pattern was not found,
                // so move on to the next pattern.
                return lResultPos;
            }

            // Record where to start looking for the next matching token.
            lNextPos  = lPos.Start;
            lNextScan = lPos.End;

            /* For 'word' tokens, this is a valid match only if ...
                ** It is at the start of the line, or
                ** preceded by whitespace, or
                ** starts with an alpha and preceded by a non-alpha, or
                ** starts with a non-alpha and preceded by an alpha
            */
            if ((lPos.Start != 0) &&
                (std.ctype.isspace(pText[lPos.Start-1]) == 0) &&
                ((std.ctype.isalnum(pText[lPos.Start]) != 0) ==
                 (std.ctype.isalnum(pText[lPos.Start-1]) != 0)
                 ))
                // Not a valid token, so scan the text beyond where
                // this bad token was found, looking for a good one.
            {
                continue L_Next_Scan;
            }

            // Record the pattern's starting point in the text.
            lStartPos = lPos.Start;

            // Locate the rest of the inner-words.
            while(lTokenIndex+1 < lPatternTokens.length)
            {
                // Record where to continue searching from.
                lNextPos = lPos.End;

                // If I'm at the end of the text then this is not
                // a matching pattern.
                if ( lNextPos == pText.length)
                {
                    continue L_Next_Scan;
                }

                // Word-type tokens (except the last) must be followed
                // by whitespace
                if ( std.ctype.isspace(pText[lNextPos]) == 0)
                {
                    continue L_Next_Scan;
                }

                // Skip over any white space
                lNextPos++;
                while( (lNextPos < pText.length) && (std.ctype.isspace(pText[lNextPos])))
                    lNextPos++;

                // Move on to the next pattern token.
                lTokenIndex++;
                lPos = matchspan(pText, lPatternTokens[lTokenIndex], lNextPos);

                // If this token doesn't match then we only have a partial
                // pattern match, thus we continue looking for the pattern.
                if (lPos.Start == -1)
                {
                    continue L_Next_Scan;
                }

            }

            // Look at last token.

            lPos = matchspan(pText, lPatternTokens[lTokenIndex], lNextPos);
            // If this token doesn't match then we only have a partial
            // pattern match, thus we continue looking for the pattern.
            if (lPos.Start == -1)
            {
                return lResultPos;
            }

            lEndPos = lPos.End;
            if (lEndPos == pText.length)
            {
                // Found a perfect match (at end of text!)
            }
            else if (std.ctype.isspace(pText[lEndPos]) != 0)
            {
                // The char after the pattern is white space so
                // we have a match.
            }
            else if ((std.ctype.isalnum(pText[lEndPos-1]) != 0) !=
                (std.ctype.isalnum(pText[lEndPos])   != 0))
            {
                // The last char of the last token is a different
                // type of char to the one following it.
            }
            else
            {
                lNextScan = lStartPos + 1;
                continue L_Next_Scan;
            }
            lResultPos.Start = lStartPos;
            lResultPos.End = lEndPos;
            lResultPos.Text = pText[lStartPos .. lEndPos];
            break;
        }
        return lResultPos;
    }
    else
        return lResultPos;
}

bool RunMacro( inout char[] pText, char[] pScope, inout char[] pOutFile)
{
    bool lChanged;
    int lNextPattern;
    Substitute[] lMacros;

    if (! (pScope in vScopes) )
    {
        return false;
    }

    lMacros = vScopes[pScope];
    lChanged = false;

    // Check that this is really a text buffer and not a binary buffer.
    for(int i = 0; i < 1000 && i < pText.length; i++)
    {
        if (pText[i] > 127) // Sorry, ASCII only for now.
            return false;

        if (pText[i] < 8)
            return false;

        if ((pText[i] > 13) && (pText[i] < ' '))
            return false;
    }

    // Extract any embedded macro commands.
    {
        char[][] lTextLines;
        char[][] lLocalMac;
        char[][] lMsgs;
        char[] lLocalScope = __FILE__ ~ __TIMESTAMP__;

        lTextLines = std.string.split(pText,"\n");
        int i;
        while(i < lTextLines.length)
        {
            char[] lLine;
            lLine = lTextLines[i];
            i++;
            if (lLine.length == 0)
                continue;
            if (lLine[0] != '@')
                continue;
            if (util.str.begins(lLine, "@outfile ") == True)
            {
                pOutFile = util.str.strip(lLine[9 .. $]);
            }
            else
            {
                lLocalMac ~= lLine[1..$].dup;
            }
            i--;
            lTextLines = lTextLines[0..i] ~ lTextLines[i+1 .. $];
        }
        pText.length = 0;
        foreach(char[] lLine; lTextLines)
        {
            pText ~= lLine ~ "\n";
        }
        AddMacros(lLocalScope, lLocalMac, lMsgs);
        if (lLocalScope in vScopes)
            lMacros = vScopes[lLocalScope] ~ lMacros;
        vScopes.remove(lLocalScope);
    }

    // Prepare pattern array.
    foreach(inout Substitute lMacro; lMacros)
    {
        lMacro.Used = false;
        if (lMacro.Type == Substitute.SubType.RegExp)
            lMacro.Recurse = false;
        else
            lMacro.Recurse = (FindPattern(lMacro, lMacro.Resolution, 0).Start == -1);
    }

    // Examine the text for patterns.
    L_Next_Pattern:while(lNextPattern < lMacros.length)
    {
        TextSpan lPos;
        uint lNextPos;
        char[][] lPatternTokens;
        int lStartPos;
        int lEndPos;
        int lTokenIndex;
        uint lNextScan;
        bool lNeedsChanging;
        Substitute *lMacro;

        lMacro = &lMacros[lNextPattern];
        lNextPattern++;

        if (lMacro.Recurse == false && lMacro.Used == true)
        {
            continue L_Next_Pattern;
        }

        if (lMacro.Type == Substitute.SubType.RegExp)
        {
            char[] lResult;
            if (std.regexp.find(pText, lMacro.Pattern, "m") != -1)
            {
                lResult = std.regexp.sub(pText,
                            lMacro.Pattern,
                            lMacro.Resolution,
                            "gm");
                lMacro.Used = true;
                if (lResult != pText)
                {
                    lChanged = true;
                    pText = lResult;
                }
                else {
                    lResult = null;
                }
            }

            continue L_Next_Pattern;
        }

        lNextScan = 0;
        while( (lPos = FindPattern(*lMacro, pText, lNextScan)).Start != -1)
        {
            pText = pText[0..lPos.Start] ~ lMacro.Resolution ~ pText[lPos.End..$];
            lChanged = true;

            // Skip over new text to avoid recursive substitutions.
            lNextScan = lPos.Start + lMacro.Resolution.length;
            if (lMacro.Recurse)
            {
                lNextPattern = 0;
                continue L_Next_Pattern;
            }
        }

        lMacro.Used = true;
    }
    return lChanged;
}

bool ConvertFile(char[] pFile, char[] pScope, inout char[] pAltFile)
{
    char[] lFileText;
    bool lResult;
    lFileText = util.fileex.GetText(pFile);
    lResult = RunMacro(lFileText, pScope, pAltFile);
    if (lResult)
    {
        if (pAltFile.length > 0)
            util.fileex.CreateTextFile(pAltFile, lFileText);
        else
            // No output file name given so return the converted text itself.
            pAltFile = lFileText;
    }

    return lResult;
}

void AddMacros(char[] pScope, char[][] pSourceLines, inout char[][] pMessages)
{
    char[] lOpen;
    char[] lClose;
    char[] lEscapeOpen;
    char[] lEscapeClose;
    char[] lCommentLead;
    char[] lSep;
    static char[] lDefOpen = "\"";
    static char[] lDefClose = "\"";
    static char[] lDefEscapeOpen = "\\";
    static char[] lDefEscapeClose = "";
    static char[] lDefCommentLead = "#";
    static char[] lDefSep = "=";

    lOpen = lDefOpen;
    lClose = lDefClose;
    lEscapeOpen = lDefEscapeOpen;
    lEscapeClose = lDefEscapeClose;
    lCommentLead = lDefCommentLead;
    lSep = lDefSep;

   foreach(char[] lArg; pSourceLines)
    {
        char[][] lOptions;

        lArg = util.str.ExpandEnvVar(lArg);
        // Locate any comment text in the line.
        int lPos = std.string.find(lArg, lCommentLead);
        if (lPos != -1)
        {
            // Truncate the line at the comment lead-in character.
            lArg.length = lPos;
        }

        lArg = std.string.strip(lArg);
        if (lArg.length > 1)
        {
            if (util.str.begins(lArg, "replace ") == True || util.str.begins(lArg,"regexp ") == True)
            {
                int lStartPos;
                int lEndPos;
                bool lEndFound;
                int lDataPos;
                char[] lPattern;
                char[] lResolution;
                Substitute.SubType lPatternType;
                bool lDoRegExp;

                if (util.str.begins(lArg,"regexp ") == True)
                {
                    lDoRegExp = true;
                    lArg = std.string.strip(lArg[7..$]);
                    lPatternType = Substitute.SubType.RegExp;
                }
                else
                {
                    lDoRegExp = false;
                    lArg = std.string.strip(lArg[8..$]);
                }

                // Format should be [<open>] <pattern> [<close>] = [<open>] <resolution> [<close>]
                if (util.str.begins(lArg, lOpen) == True)
                {
                    if (! lDoRegExp)
                        lPatternType = Substitute.SubType.Text;
                    lEndPos = std.string.find(lArg[lOpen.length .. $], lClose);
                    if (lEndPos == -1)
                    {
                        // No pattern end marker so treat as comment.
                        break;
                    }
                    lEndPos += lOpen.length;
                    lPattern = lArg[lOpen.length .. lEndPos];
                    lArg = util.str.strip(lArg[lEndPos+1 .. $]);
                    lEndPos = std.string.find(lArg, lSep);
                    if (lEndPos == -1)
                    {
                        // No pattern end marker so treat as comment.
                        break;
                    }
                }
                else
                {
                    if (! lDoRegExp)
                        lPatternType = Substitute.SubType.Word;
                    lEndPos = std.string.find(lArg, "=");
                    if (lEndPos == -1)
                    {
                        // No pattern end marker so treat as comment.
                        break;
                    }
                    lPattern = util.str.stripr(lArg[0..lEndPos]);
                }

                // Pluck out the resolution text.
                lArg = util.str.strip(lArg[lEndPos+1 .. $]);
                if (util.str.begins(lArg, lOpen) == True)
                {
                    if (util.str.ends(lArg, lClose) == True)
                    {
                        lResolution = lArg[lOpen.length .. $-lClose.length];
                    }
                    else
                    {
                        lResolution = lArg[lOpen.length .. $];
                    }
                }
                else
                {
                    lResolution = lArg;
                }

                lResolution = std.string.replace(lResolution,
                                        lEscapeOpen ~ "n" ~ lEscapeClose,
                                        "\n");
                lResolution = std.string.replace(lResolution,
                                        lEscapeOpen ~ "t" ~ lEscapeClose,
                                        "\t");
                lResolution = ConditionalSpace(lEscapeOpen ~ "s" ~ lEscapeClose,
                                        lResolution, lResolution, 0, lResolution.length-1);

                { // Add this macro to the right scope.
                    Substitute lNewMacro;
                    lNewMacro.Type = lPatternType;
                    lNewMacro.Pattern = lPattern;
                    lNewMacro.Resolution = lResolution;
                    lNewMacro.EscapeOpen = lEscapeOpen;
                    lNewMacro.EscapeClose = lEscapeClose;
                    RegisterMacro(pScope, lNewMacro);
                }

            }
            else if (util.str.begins(lArg, "delim ") == True )
            {

                lArg = std.string.strip(lArg[6..$]);

                lOptions = std.string.split(lArg);
                foreach(char[] lOption; lOptions)
                {
                    if (lOption == "std")
                    {
                        lOpen = lDefOpen;
                        lClose = lDefClose;
                        lEscapeOpen = lDefEscapeOpen;
                        lEscapeClose = lDefEscapeClose;
                        lCommentLead = lDefCommentLead;
                        lSep = lDefSep;
                    }
                    else
                    {
                        char[][] lKeyValue;
                        lKeyValue = std.string.split(lOption, lSep);
                        switch (lKeyValue[0])
                        {
                            case "open":
                                lOpen = lKeyValue[1];
                                break;
                            case "close":
                                lClose = lKeyValue[1];
                                break;
                            case "escapeopen":
                                lEscapeOpen = lKeyValue[1];
                                break;
                            case "escapeclose":
                                lEscapeClose = lKeyValue[1];
                                break;
                            case "comment":
                                lCommentLead = lKeyValue[1];
                                break;
                            case "equate":
                                lSep = lKeyValue[1];
                                break;
                            default:
                                pMessages ~= std.string.format("Bad Macro 'delim' option '%s'",
                                            lOption);
                                // Ignore bad options.
                                break;
                        }
                    }
                }
            }
            else
            {
                pMessages ~= std.string.format("Bad configuration command '%s'", lArg);
            }
        }
    }
}

Substitute[][char[]] vScopes;

void RegisterMacro(char[] pScope, Substitute pNewMacro)
{
    Substitute[] lKnownMacros;

    if ((pScope in vScopes))
        lKnownMacros = vScopes[pScope];

    lKnownMacros.length = lKnownMacros.length + 1;
    lKnownMacros[$-1] = pNewMacro;
    vScopes[pScope] = lKnownMacros;
}
