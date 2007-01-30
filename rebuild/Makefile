CXX=g++
NATIVECXX=g++
CXXFLAGS=-O2 -g
LDFLAGS=
EXEEXT=

OBJS= \
access.o \
array.o \
attrib.o \
cast.o \
class.o \
compile.o \
cond.o \
config.o \
constfold.o \
dchar.o \
declaration.o \
delegatize.o \
doc.o \
dsymbol.o \
dump.o \
entity.o \
enum.o \
expression.o \
func.o \
gnuc.o \
hdrgen.o \
html.o \
id.o \
identifier.o \
impcnvtab.o \
import.o \
inifile.o \
init.o \
inline.o \
lexer.o \
link.o \
lstring.o \
macro.o \
mangle.o \
mars.o \
mem.o \
module.o \
mtype.o \
opover.o \
optimize.o \
parse.o \
root.o \
scope.o \
statement.o \
staticassert.o \
stringtable.o \
struct.o \
template.o \
unialpha.o \
utf.o \
version.o \
whereami.o

all: rebuild$(EXEEXT)

rebuild$(EXEEXT): id.c impcnvtab.c $(OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(OBJS) -o rebuild$(EXEEXT)

id.c: idgen$(EXEEXT)
	./idgen$(EXEEXT)

impcnvtab.c: impcnvgen$(EXEEXT)
	./impcnvgen$(EXEEXT)

idgen$(EXEEXT): idgen.o
	$(NATIVECXX) $(CXXFLAGS) $(LDFLAGS) idgen.o -o idgen$(EXEEXT)

impcnvgen$(EXEEXT): impcnvgen.o
	$(NATIVECXX) $(CXXFLAGS) $(LDFLAGS) impcnvgen.o -o impcnvgen$(EXEEXT)

idgen.o: idgen.c
	$(NATIVECXX) $(CXXFLAGS) -c idgen.c -o idgen.o

impcnvgen.o: impcnvgen.c
	$(NATIVECXX) $(CXXFLAGS) -c impcnvgen.c -o impcnvgen.o

.SUFFIXES: .c .o

.c.o:
	$(CXX) $(CXXFLAGS) -D_DH -DIN_REBUILD -c $< -o $@

clean:
	rm -f rebuild$(EXEEXT) $(OBJS) \
		id.c id.h idgen$(EXEEXT) idgen.o \
		impcnvtab.c impcnvtab.h impcnvgen$(EXEEXT) impcnvgen.o
