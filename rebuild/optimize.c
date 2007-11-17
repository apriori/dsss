
// Compiler implementation of the D programming language
// Copyright (c) 1999-2007 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#include <stdio.h>
#include <ctype.h>
#include <assert.h>
#include <math.h>

#if __DMC__
#include <complex.h>
#endif

#include "lexer.h"
#include "mtype.h"
#include "expression.h"
#include "declaration.h"
#include "aggregate.h"
#include "init.h"


#ifdef IN_GCC
#include "d-gcc-real.h"

/* %% fix? */
extern "C" bool real_isnan (const real_t *);
#endif

static real_t zero;	// work around DMC bug for now


/*************************************
 * If expression is a variable with a const initializer,
 * return that initializer.
 */

Expression *fromConstInitializer(int result, Expression *e1)
{
    //printf("fromConstInitializer(result = %x, %s)\n", result, e1->toChars());
    Expression *e = e1;
    if (e1->op == TOKvar)
    {	VarExp *ve = (VarExp *)e1;
	VarDeclaration *v = ve->var->isVarDeclaration();
	if (v && (v->isConst() || v->isInvariant()))
	{
	    Type *tb = v->type->toBasetype();
	    if (result & WANTinterpret ||
		(tb->ty != Tsarray && tb->ty != Tstruct)
	       )
	    {
		if (v->init)
		{
		    if (v->inuse)
			goto L1;
		    Expression *ei = v->init->toExpression();
		    if (!ei)
			goto L1;
		    if (v->scope)
		    {
			v->inuse++;
			e = ei->syntaxCopy();
			e = e->semantic(v->scope);
			e = e->implicitCastTo(v->scope, v->type);
			v->scope = NULL;
			v->inuse--;
		    }
		    else if (!ei->type)
		    {
			goto L1;
		    }
		    else
			// Should remove the copy() operation by
			// making all mods to expressions copy-on-write
			e = ei->copy();
		}
		else
		{
		    e = v->type->defaultInit();
		    e->loc = e1->loc;
		}
		if (e->type != v->type)
		{
		    e = e->castTo(NULL, v->type);
		}
		if (e->type != e1->type)
		{   // Type 'paint' operation
		    e = e->copy();
		    e->type = e1->type;
		}
		e = e->optimize(result);
		//printf("e = %s, e1->type = %s, v->type = %s, e->type = %s\n", e->toChars(), e1->type->toChars(), v->type->toChars(), e->type->toChars());
	    }
	}
    }
L1:
    return e;
}


Expression *Expression::optimize(int result)
{
    //printf("Expression::optimize(result = x%x) %s\n", result, toChars());
    return this;
}

Expression *VarExp::optimize(int result)
{
    return fromConstInitializer(result, this);
}

Expression *TupleExp::optimize(int result)
{
    for (size_t i = 0; i < exps->dim; i++)
    {   Expression *e = (Expression *)exps->data[i];

	e = e->optimize(WANTvalue | (result & WANTinterpret));
	exps->data[i] = (void *)e;
    }
    return this;
}

Expression *ArrayLiteralExp::optimize(int result)
{
    if (elements)
    {
	for (size_t i = 0; i < elements->dim; i++)
	{   Expression *e = (Expression *)elements->data[i];

	    e = e->optimize(WANTvalue | (result & WANTinterpret));
	    elements->data[i] = (void *)e;
	}
    }
    return this;
}

Expression *AssocArrayLiteralExp::optimize(int result)
{
    assert(keys->dim == values->dim);
    for (size_t i = 0; i < keys->dim; i++)
    {   Expression *e = (Expression *)keys->data[i];

	e = e->optimize(WANTvalue | (result & WANTinterpret));
	keys->data[i] = (void *)e;

	e = (Expression *)values->data[i];
	e = e->optimize(WANTvalue | (result & WANTinterpret));
	values->data[i] = (void *)e;
    }
    return this;
}

Expression *StructLiteralExp::optimize(int result)
{
    if (elements)
    {
	for (size_t i = 0; i < elements->dim; i++)
	{   Expression *e = (Expression *)elements->data[i];
	    if (!e)
		continue;
	    e = e->optimize(WANTvalue | (result & WANTinterpret));
	    elements->data[i] = (void *)e;
	}
    }
    return this;
}

Expression *TypeExp::optimize(int result)
{
    return this;
}

Expression *UnaExp::optimize(int result)
{
    e1 = e1->optimize(result);
    return this;
}

Expression *NegExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(result);
    if (e1->isConst() == 1)
    {
	e = Neg(type, e1);
    }
    else
	e = this;
    return e;
}

Expression *ComExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(result);
    if (e1->isConst() == 1)
    {
	e = Com(type, e1);
    }
    else
	e = this;
    return e;
}

Expression *NotExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(result);
    if (e1->isConst() == 1)
    {
	e = Not(type, e1);
    }
    else
	e = this;
    return e;
}

Expression *BoolExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(result);
    if (e1->isConst() == 1)
    {
	e = Bool(type, e1);
    }
    else
	e = this;
    return e;
}

Expression *AddrExp::optimize(int result)
{   Expression *e;

    //printf("AddrExp::optimize(result = %d) %s\n", result, toChars());
    e1 = e1->optimize(result);
    // Convert &*ex to ex
    if (e1->op == TOKstar)
    {	Expression *ex;

	ex = ((PtrExp *)e1)->e1;
	if (type->equals(ex->type))
	    e = ex;
	else
	{
	    e = ex->copy();
	    e->type = type;
	}
	return e;
    }
    if (e1->op == TOKvar)
    {	VarExp *ve = (VarExp *)e1;
	if (!ve->var->isOut() && !ve->var->isRef() &&
	    !ve->var->isImportedSymbol())
	{
	    SymOffExp *se = new SymOffExp(loc, ve->var, 0, ve->hasOverloads);
	    se->type = type;
	    return se;
	}
    }
    if (e1->op == TOKindex)
    {	// Convert &array[n] to &array+n
	IndexExp *ae = (IndexExp *)e1;

	if (ae->e2->op == TOKint64 && ae->e1->op == TOKvar)
	{
	    integer_t index = ae->e2->toInteger();
	    VarExp *ve = (VarExp *)ae->e1;
	    if (ve->type->ty == Tsarray
		&& !ve->var->isImportedSymbol())
	    {
		TypeSArray *ts = (TypeSArray *)ve->type;
		integer_t dim = ts->dim->toInteger();
		/*if (index < 0 || index >= dim)
		    error("array index %jd is out of bounds [0..%jd]", index, dim); */
		e = new SymOffExp(loc, ve->var, index * ts->nextOf()->size());
		e->type = type;
		return e;
	    }
	}
    }
    return this;
}

Expression *PtrExp::optimize(int result)
{
    //printf("PtrExp::optimize(result = x%x) %s\n", result, toChars());
    e1 = e1->optimize(result);
    // Convert *&ex to ex
    if (e1->op == TOKaddress)
    {	Expression *e;
	Expression *ex;

	ex = ((AddrExp *)e1)->e1;
	if (type->equals(ex->type))
	    e = ex;
	else
	{
	    e = ex->copy();
	    e->type = type;
	}
	return e;
    }
    // Constant fold *(&structliteral + offset)
    if (e1->op == TOKadd)
    {
	Expression *e;
	e = Ptr(type, e1);
	if (e != EXP_CANT_INTERPRET)
	    return e;
    }

    return this;
}

Expression *CallExp::optimize(int result)
{
    //printf("CallExp::optimize(result = %d) %s\n", result, toChars());
    Expression *e = this;

    e1 = e1->optimize(result);
    if (e1->op == TOKvar)
    {
	FuncDeclaration *fd = ((VarExp *)e1)->var->isFuncDeclaration();
	if (fd)
	{
	    //enum BUILTIN b = fd->isBuiltin();
	    //if (b)
            if (0)
	    {
		//e = eval_builtin(b, arguments);
		//if (!e)			// failed
		    e = this;		// evaluate at runtime
	    }
	    /* else if (result & WANTinterpret)
	    {
		Expression *eresult = fd->interpret(NULL, arguments);
		if (eresult && eresult != EXP_VOID_INTERPRET)
		    e = eresult;
		else
		    error("cannot evaluate %s at compile time", toChars());
	    } */
	}
    }
    return e;
}


Expression *CastExp::optimize(int result)
{
    //printf("CastExp::optimize(result = %d) %s\n", result, toChars());
    //printf("from %s to %s\n", type->toChars(), to->toChars());
    //printf("from %s\n", type->toChars());
    //printf("type = %p\n", type);
    assert(type);
    enum TOK op1 = e1->op;

    e1 = e1->optimize(result);
    e1 = fromConstInitializer(result, e1);

    if ((e1->op == TOKstring || e1->op == TOKarrayliteral) &&
	(type->ty == Tpointer || type->ty == Tarray) &&
	e1->type->nextOf()->size() == type->nextOf()->size()
       )
    {
	e1 = e1->castTo(NULL, type);
	//printf(" returning1 %s\n", e1->toChars());
	return e1;
    }

    if (e1->op == TOKstructliteral &&
	e1->type->implicitConvTo(type) >= MATCHconst)
    {
	e1->type = type;
	//printf(" returning2 %s\n", e1->toChars());
	return e1;
    }

    /* The first test here is to prevent infinite loops
     */
    if (op1 != TOKarrayliteral && e1->op == TOKarrayliteral)
	return e1->castTo(NULL, to);
    if (e1->op == TOKnull &&
	(type->ty == Tpointer || type->ty == Tclass || type->ty == Tarray))
    {
	e1->type = type;
	return e1;
    }

    if (result & WANTflags && type->ty == Tclass && e1->type->ty == Tclass)
    {
	// See if we can remove an unnecessary cast
	ClassDeclaration *cdfrom;
	ClassDeclaration *cdto;
	int offset;

	cdfrom = e1->type->isClassHandle();
	cdto   = type->isClassHandle();
	if (cdto->isBaseOf(cdfrom, &offset) && offset == 0)
	{
	    e1->type = type;
	    return e1;
	}
    }

    // We can convert 'head const' to mutable
    if (to->constConv(e1->type) >= MATCHconst)
    {
	e1->type = type;
	return e1;
    }

    Expression *e;

    if (e1->isConst())
    {
	if (e1->op == TOKsymoff)
	{
	    if (type->size() == e1->type->size() &&
		type->toBasetype()->ty != Tsarray)
	    {
		e1->type = type;
		return e1;
	    }
	    return this;
	}
	if (to->toBasetype()->ty == Tvoid)
	    e = this;
	else
	    e = Cast(type, to, e1);
    }
    else
	e = this;
    //printf(" returning3 %s\n", e->toChars());
    return e;
}

Expression *BinExp::optimize(int result)
{
    //printf("BinExp::optimize(result = %d) %s\n", result, toChars());
    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (op == TOKshlass || op == TOKshrass || op == TOKushrass)
    {
	if (e2->isConst() == 1)
	{
	    integer_t i2 = e2->toInteger();
	    d_uns64 sz = e1->type->size() * 8;
	    if (i2 < 0 || i2 > sz)
	    {   error("shift assign by %jd is outside the range 0.." ZU, i2, sz);
		e2 = new IntegerExp(0);
	    }
	}
    }
    return this;
}

Expression *AddExp::optimize(int result)
{   Expression *e;

    //printf("AddExp::optimize(%s)\n", toChars());
    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (e1->isConst() && e2->isConst())
    {
	if (e1->op == TOKsymoff && e2->op == TOKsymoff)
	    return this;
	e = Add(type, e1, e2);
    }
    else
	e = this;
    return e;
}

Expression *MinExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (e1->isConst() && e2->isConst())
    {
	if (e2->op == TOKsymoff)
	    return this;
	e = Min(type, e1, e2);
    }
    else
	e = this;
    return e;
}

Expression *MulExp::optimize(int result)
{   Expression *e;

    //printf("MulExp::optimize(result = %d) %s\n", result, toChars());
    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (e1->isConst() == 1 && e2->isConst() == 1)
    {
	e = Mul(type, e1, e2);
    }
    else
	e = this;
    return e;
}

Expression *DivExp::optimize(int result)
{   Expression *e;

    //printf("DivExp::optimize(%s)\n", toChars());
    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (e1->isConst() == 1 && e2->isConst() == 1)
    {
	e = Div(type, e1, e2);
    }
    else
	e = this;
    return e;
}

Expression *ModExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (e1->isConst() == 1 && e2->isConst() == 1)
    {
	e = Mod(type, e1, e2);
    }
    else
	e = this;
    return e;
}

Expression *shift_optimize(int result, BinExp *e, Expression *(*shift)(Type *, Expression *, Expression *))
{   Expression *ex = e;

    e->e1 = e->e1->optimize(result);
    e->e2 = e->e2->optimize(result);
    if (e->e2->isConst() == 1)
    {
	integer_t i2 = e->e2->toInteger();
	d_uns64 sz = e->e1->type->size() * 8;
	if (i2 < 0 || i2 > sz)
	{   // error("shift by %jd is outside the range 0.." ZU, i2, sz);
	    e->e2 = new IntegerExp(0);
	}
	if (e->e1->isConst() == 1)
	    ex = (*shift)(e->type, e->e1, e->e2);
    }
    return ex;
}

Expression *ShlExp::optimize(int result)
{
    //printf("ShlExp::optimize(result = %d) %s\n", result, toChars());
    return shift_optimize(result, this, Shl);
}

Expression *ShrExp::optimize(int result)
{
    //printf("ShrExp::optimize(result = %d) %s\n", result, toChars());
    return shift_optimize(result, this, Shr);
}

Expression *UshrExp::optimize(int result)
{
    //printf("UshrExp::optimize(result = %d) %s\n", result, toChars());
    return shift_optimize(result, this, Ushr);
}

Expression *AndExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (e1->isConst() == 1 && e2->isConst() == 1)
	e = And(type, e1, e2);
    else
	e = this;
    return e;
}

Expression *OrExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (e1->isConst() == 1 && e2->isConst() == 1)
	e = Or(type, e1, e2);
    else
	e = this;
    return e;
}

Expression *XorExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (e1->isConst() == 1 && e2->isConst() == 1)
	e = Xor(type, e1, e2);
    else
	e = this;
    return e;
}

Expression *CommaExp::optimize(int result)
{   Expression *e;

    //printf("CommaExp::optimize(result = %d) %s\n", result, toChars());
    e1 = e1->optimize(result & WANTinterpret);
    e2 = e2->optimize(result);
    if (!e1 || e1->op == TOKint64 || e1->op == TOKfloat64 || !e1->checkSideEffect(2))
    {
	e = e2;
	if (e)
	    e->type = type;
    }
    else
	e = this;
    //printf("-CommaExp::optimize(result = %d) %s\n", result, e->toChars());
    return e;
}

Expression *ArrayLengthExp::optimize(int result)
{   Expression *e;

    //printf("ArrayLengthExp::optimize(result = %d) %s\n", result, toChars());
    e1 = e1->optimize(WANTvalue | (result & WANTinterpret));
    e = this;
    if (e1->op == TOKstring || e1->op == TOKarrayliteral || e1->op == TOKassocarrayliteral)
    {
	e = ArrayLength(type, e1);
    }
    return e;
}

Expression *EqualExp::optimize(int result)
{   Expression *e;

    //printf("EqualExp::optimize(result = %x) %s\n", result, toChars());
    e1 = e1->optimize(WANTvalue | (result & WANTinterpret));
    e2 = e2->optimize(WANTvalue | (result & WANTinterpret));
    e = this;

    Expression *e1 = fromConstInitializer(result, this->e1);
    Expression *e2 = fromConstInitializer(result, this->e2);

    e = Equal(op, type, e1, e2);
    if (e == EXP_CANT_INTERPRET)
	e = this;
    return e;
}

Expression *IdentityExp::optimize(int result)
{   Expression *e;

    //printf("IdentityExp::optimize(result = %d) %s\n", result, toChars());
    e1 = e1->optimize(WANTvalue | (result & WANTinterpret));
    e2 = e2->optimize(WANTvalue | (result & WANTinterpret));
    e = this;

    if (this->e1->isConst() && this->e2->isConst())
    {
	e = Identity(op, type, this->e1, this->e2);
    }
    return e;
}

Expression *IndexExp::optimize(int result)
{   Expression *e;

    //printf("IndexExp::optimize(result = %d) %s\n", result, toChars());
    Expression *e1 = this->e1->optimize(WANTvalue | (result & WANTinterpret));
    e1 = fromConstInitializer(result, e1);
    e2 = e2->optimize(WANTvalue | (result & WANTinterpret));
    e = Index(type, e1, e2);
    if (e == EXP_CANT_INTERPRET)
	e = this;
    return e;
}

Expression *SliceExp::optimize(int result)
{   Expression *e;

    //printf("SliceExp::optimize(result = %d) %s\n", result, toChars());
    e = this;
    e1 = e1->optimize(WANTvalue | (result & WANTinterpret));
    if (!lwr)
    {	if (e1->op == TOKstring)
	{   // Convert slice of string literal into dynamic array
	    Type *t = e1->type->toBasetype();
	    if (t->nextOf())
		e = e1->castTo(NULL, t->nextOf()->arrayOf());
	}
	return e;
    }
    e1 = fromConstInitializer(result, e1);
    lwr = lwr->optimize(WANTvalue | (result & WANTinterpret));
    upr = upr->optimize(WANTvalue | (result & WANTinterpret));
    e = Slice(type, e1, lwr, upr);
    if (e == EXP_CANT_INTERPRET)
	e = this;
    //printf("-SliceExp::optimize() %s\n", e->toChars());
    return e;
}

Expression *AndAndExp::optimize(int result)
{   Expression *e;

    //printf("AndAndExp::optimize(%d) %s\n", result, toChars());
    e1 = e1->optimize(WANTflags | (result & WANTinterpret));
    e = this;
    if (e1->isBool(FALSE))
    {
	e = new CommaExp(loc, e1, new IntegerExp(loc, 0, type));
	e->type = type;
	e = e->optimize(result);
    }
    else
    {
	e2 = e2->optimize(WANTflags | (result & WANTinterpret));
	/*if (result && e2->type->toBasetype()->ty == Tvoid && !global.errors)
	    error("void has no value"); */
	if (e1->isConst())
	{
	    if (e2->isConst())
	    {	int n1 = e1->isBool(1);
		int n2 = e2->isBool(1);

		e = new IntegerExp(loc, n1 && n2, type);
	    }
	    else if (e1->isBool(TRUE))
		e = new BoolExp(loc, e2, type);
	}
    }
    return e;
}

Expression *OrOrExp::optimize(int result)
{   Expression *e;

    e1 = e1->optimize(WANTflags | (result & WANTinterpret));
    e = this;
    if (e1->isBool(TRUE))
    {	// Replace with (e1, 1)
	e = new CommaExp(loc, e1, new IntegerExp(loc, 1, type));
	e->type = type;
	e = e->optimize(result);
    }
    else
    {
	e2 = e2->optimize(WANTflags | (result & WANTinterpret));
	/*if (result && e2->type->toBasetype()->ty == Tvoid && !global.errors)
	    error("void has no value"); */
	if (e1->isConst())
	{
	    if (e2->isConst())
	    {	int n1 = e1->isBool(1);
		int n2 = e2->isBool(1);

		e = new IntegerExp(loc, n1 || n2, type);
	    }
	    else if (e1->isBool(FALSE))
		e = new BoolExp(loc, e2, type);
	}
    }
    return e;
}

Expression *CmpExp::optimize(int result)
{   Expression *e;

    //printf("CmpExp::optimize() %s\n", toChars());
    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    if (e1->isConst() == 1 && e2->isConst() == 1)
    {
	e = Cmp(op, type, this->e1, this->e2);
    }
    else
	e = this;
    return e;
}

Expression *CatExp::optimize(int result)
{   Expression *e;

    //printf("CatExp::optimize(%d) %s\n", result, toChars());
    e1 = e1->optimize(result);
    e2 = e2->optimize(result);
    e = Cat(type, e1, e2);
    if (e == EXP_CANT_INTERPRET)
	e = this;
    return e;
}


Expression *CondExp::optimize(int result)
{   Expression *e;

    econd = econd->optimize(WANTflags | (result & WANTinterpret));
    if (econd->isBool(TRUE))
	e = e1->optimize(result);
    else if (econd->isBool(FALSE))
	e = e2->optimize(result);
    else
    {	e1 = e1->optimize(result);
	e2 = e2->optimize(result);
	e = this;
    }
    return e;
}


