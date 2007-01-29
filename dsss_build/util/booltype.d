/* *************************************************************************

        @file booltype.d

        Copyright (c) 2005 Derek Parnell



                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, January 2005
        @author         Derek Parnell


**************************************************************************/
/**
 * A formal Boolean type.

 * This boolean data type can only be used as a boolean and not a
 * pseudo bool as supplied by standard D.

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
module util.booltype;
version(build) version(BoolUnknown) pragma(include, booltypemac.ddoc);


/**
   Defines the capabilities of the datatype.

   $(BU_Extra)

**/

class Bool
{
    int m_Val;

    /**
       * Constructor
       * Params:
       *  x = zero sets value to False. Non-zero sets value to True.
       *
       * Examples:
       *  --------------------
       *   Bool a = new Bool(1);  // Sets initial to True.
       *   Bool b = new Bool(-1);  // Sets initial to True.
       *   Bool c = new Bool(100);  // Sets initial to True.
       *   Bool d = new Bool(0);  // Sets initial to False.
       *  --------------------
    **/
    this(int x) { m_Val = (x != 0 ? 1 : 0); }

    /**
       * Constructor
       * Params:
       *  x = Copies value to new object.
       *
       * Examples:
       *  --------------------
       *   Bool a = new Bool(True);  // Sets initial to True.
       *   Bool b = new Bool(False);  // Sets initial to False.
       *   Bool c = new Bool(a);  // Sets initial to True.
       *   Bool d = new Bool(b);  // Sets initial to False.
       *  --------------------
    **/
    this(Bool x) { m_Val = x.m_Val; }

    /**
       * Constructor
       * Params:
       *  x = zero sets value to True when the parameter is any of
          "TRUE","True","true","YES","Yes","yes","ON","On","on","T","t","1".
          Any other parameter value sets the boolean to False.
       *
       *
       * Examples:
       *  --------------------
       *   Bool a = new Bool("True");  // Sets initial to True.
       *   Bool b = new Bool("False");  // Sets initial to False.
       *   Bool c = new Bool("1");  // Sets initial to True.
       *   Bool d = new Bool("rabbit");  // Sets initial to False.
       *   Bool e = new Bool("on");  // Sets initial to True.
       *   Bool f = new Bool("off");  // Sets initial to False.
       *   Bool g = new Bool("");  // Sets initial to False.
       *  --------------------
    **/
    this(char[] x) {
        switch (x)
        {
            case "TRUE", "True", "true",
                 "YES",  "Yes",  "yes",
                 "ON",   "On",   "on",
                 "T", "t",
                 "1"
                 :
                m_Val = 1;
                break;
            default:
                m_Val = 0;
        }
    }

    version(BoolUnknown)
    {
     /**
       * Constructor
       *
       * This sets the boolean to Unknown.
       *
       * Examples:
       *  --------------------
       *   Bool a = new Bool();  // Sets initial to Unknown;
       *  --------------------
    **/
        this() { m_Val = -1; }
    }
    else
    {
     /**
       * Constructor
       *
       * This sets the boolean to False.
       *
       * Examples:
       *  --------------------
       *   Bool a = new Bool();  // Sets initial to False;
       *  --------------------
    **/
        this() { m_Val = 0; }
    }


    /**
       * Equality Operator
       * Params:
       *  pOther = The Boolean to compare this one to.
       *
       *
       * Examples:
       *  --------------------
       *   Bool a = SomeFunc();
       *   if (a == True) { . . . }
       *  --------------------
    **/
    int opEquals(Bool pOther) {
        version(BoolUnknown)
        {
        if (m_Val == -1)
            throw new BoolException("opEquals LHS is not set");

        if (pOther.m_Val == -1)
            throw new BoolException("opEquals RHS is not set");
        }
        return (m_Val == pOther.m_Val ? 1 : 0);
    }


    /**
       * Comparasion Operator
       *
       * False sorts before True.
       * Params:
       *  pOther = The Boolean to compare this one to.
       *
       *
       * Examples:
       *  --------------------
       *   Bool a = SomeFunc();
       *   Bool b = OtherFunc();
       *   if (a < b) { . . . }
       *  --------------------
    **/
    int opCmp(Bool pOther) {
        version(BoolUnknown)
        {
        if (m_Val == -1)
            throw new BoolException("opCmp LHS is not set");

        if (pOther.m_Val == -1)
            throw new BoolException("opCmp RHS is not set");
        }
        // False sorts before True.
        if (m_Val == pOther.m_Val)
            return 0;
        if (m_Val == 0)
            return -1;
        return 1;
    }

    /**
       * Complement Operator
       * Params:
       *  pOther = The Boolean to compare this one to.
       *
       *
       * Examples:
       *  --------------------
       *   Bool a = ~SomeFunc();
       *   if (a == True) { . . . }
       *  --------------------
    **/
    Bool opCom()
    {
        version(BoolUnknown)
        {
        if (m_Val == -1)
            throw new BoolException("opCom value is not set");
        }
        if (m_Val == 1)
            return False;
        return True;
    }

    /**
       * And Operator
       * Params:
       *  pOther = The Boolean to compare this one to.
       *
       *
       * Examples:
       *  --------------------
       *   Bool a = SomeFunc();
       *   Bool b = OtherFunc();
       *   Bool c = a & b;
       *  --------------------
    **/
    Bool opAnd(Bool pOther)
    {
        version(BoolUnknown)
        {
        if (m_Val == -1)
            throw new BoolException("opAnd LHS is not set");

        if (pOther.m_Val == -1)
            throw new BoolException("opAnd RHS is not set");
        }
        if (m_Val == 0 || pOther.m_Val == 0)
            return False;
        return True;
    }

    /**
       * Or Operator
       * Params:
       *  pOther = The Boolean to compare this one to.
       *
       *
       * Examples:
       *  --------------------
       *   Bool a = SomeFunc();
       *   Bool b = OtherFunc();
       *   Bool c = a | b;
       *  --------------------
    **/
    Bool opOr(Bool pOther)
    {
        version(BoolUnknown)
        {
        if (m_Val == -1)
            throw new BoolException("opOr LHS is not set");

        if (pOther.m_Val == -1)
            throw new BoolException("opOr RHS is not set");
        }
        if (m_Val == 1 || pOther.m_Val == 1)
            return True;
        return False;
    }

    /**
       * Xor Operator
       * Params:
       *  pOther = The Boolean to compare this one to.
       *
       *
       * Examples:
       *  --------------------
       *   Bool a = SomeFunc();
       *   Bool b = OtherFunc();
       *   Bool c = a ^ b;
       *  --------------------
    **/
    Bool opXor(Bool pOther)
    {
        version(BoolUnknown)
        {
        if (m_Val == -1)
            throw new BoolException("opXor LHS is not set");

        if (pOther.m_Val == -1)
            throw new BoolException("opXor RHS is not set");
        }
        if (m_Val == pOther.m_Val)
            return False;
        return True;
    }


    version(DDOC)
    {
        version(BoolUnknown)
        {
        /**
           * Convert to a displayable string.
           *
           * False displays as "False" and True dispays as "True".
           *
           * If the value has not been set yet, this returns "Unknown".
           *
           * Examples:
           *  --------------------
           *   Bool a = SomeFunc();
           *   std.stdio.writefln("The result was %s", a);
           *  --------------------
        **/
            char[] toString();
        }
        else
        {
        /**
           * Convert to a displayable string.
           *
           * False displays as "False" and True dispays as "True".
           *
           * Examples:
           *  --------------------
           *   Bool a = SomeFunc();
           *   std.stdio.writefln("The result was %s", a);
           *  --------------------
        **/
            char[] toString();
        }
    }
    else
    {

        char[] toString()
        {
            version(BoolUnknown)
            {
            if (m_Val == -1)
                return "Unknown".dup;
            }
            if (m_Val == 1)
                return "True".dup;

            return "False".dup;
        }
    }

    /**
       * Convert to an integer
       *
       * False converts to zero(0), and True converts to one(1).
       *
       * Examples:
       *  --------------------
       *   Bool a = SomeFunc();
       *   std.stdio.writefln("The result was %s", a.toInt);
       *  --------------------
    **/
    int toInt()
    {
        version(BoolUnknown)
        {
        if (m_Val == -1)
            throw new BoolException("toInt value is not set");
        }
        return m_Val;
    }

    /**
       * Creates a duplicate of the object.
       *
       * Examples:
       *  --------------------
       *   Bool a = SomeFunc();
       *   Bool b = a.dup;
       *  --------------------
    **/
    Bool dup()
    {
        version(BoolUnknown)
        {
        if (m_Val == -1)
            return new Bool();
        }

        return new Bool(m_Val);
    }

    version(BoolUnknown)
    {
        /**
           * Checks if the boolean has been set yet.
           *
           * Examples:
           *  --------------------
           *   if (someBool.isSet() == True)
           *   {
           *       doSomethingUseful();
           *   }
           *
           *  --------------------
        **/
        Bool isSet()
        {
            if (m_Val == -1)
                return True;
            return False;
        }
    }
}

static Bool True;   /// Literal 'True' value.

static Bool False;  /// Literal 'False' value.

version(BoolUnknown)
{
static Bool Unknown;  /// Literal 'Unknown' value.
}

private static this()
{
    True = new Bool(1);
    False = new Bool(0);
version(BoolUnknown)
{
    Unknown = new Bool();
}
}


version(BoolUnknown)
{
/**
   Defines the exception for this class.

**/
class BoolException : Exception
{
     /**
       * Constructor
       * Params:
       *  pMsg = Text of the message displayed during the exception.
       *
       * Examples:
       *  --------------------
       *   throw new BoolException("Some Message");
       *  --------------------
    **/
   this(char[] pMsg)
    {
        super(pMsg);
    }
}
}
