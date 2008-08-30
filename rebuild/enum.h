
// Compiler implementation of the D programming language
// Copyright (c) 1999-2008 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#ifndef DMD_ENUM_H
#define DMD_ENUM_H

#ifdef __DMC__
#pragma once
#endif /* __DMC__ */

#include "root.h"
#include "dsymbol.h"

struct Identifier;
struct Type;
struct Expression;
#ifdef _DH
struct HdrGenState;
#endif


struct EnumDeclaration : ScopeDsymbol
{   /* enum ident : memtype { ... }
     */
    Type *type;			// the TypeEnum
    Type *memtype;		// type of the members

#if V1
    integer_t maxval;
    integer_t minval;
    integer_t defaultval;	// default initializer
#else
    Expression *maxval;
    Expression *minval;
    Expression *defaultval;	// default initializer

    Scope *scope;		// !=NULL means context to use
#endif
    int isdeprecated;

    EnumDeclaration(Loc loc, Identifier *id, Type *memtype);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void semantic(Scope *sc);
    int oneMember(Dsymbol **ps);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Type *getType();
    const char *kind();
#if V2
    Dsymbol *search(Loc, Identifier *ident, int flags);
#endif
    int isDeprecated();			// is Dsymbol deprecated?

    void emitComment(Scope *sc);
    void toDocBuffer(OutBuffer *buf);

    EnumDeclaration *isEnumDeclaration() { return this; }

    void toDebug();

    Symbol *sinit;
    Symbol *toInitializer();
};


struct EnumMember : Dsymbol
{
    Expression *value;
    Type *type;

    EnumMember(Loc loc, Identifier *id, Expression *value, Type *type);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();

    void emitComment(Scope *sc);
    void toDocBuffer(OutBuffer *buf);

    EnumMember *isEnumMember() { return this; }
};

#endif /* DMD_ENUM_H */
