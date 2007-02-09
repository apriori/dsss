CROSS=
CXX=$(CROSS)g++
NATIVECXX=g++
CXXFLAGS=-O2 -g

EXEEXT=

LDFLAGS=
WA=-Wl,--whole-archive
NWA=-Wl,--no-whole-archive

AR=$(CROSS)ar
ARFLAGS=rc
RANLIB=$(CROSS)ranlib

PREFIX=/usr

OBJS=\
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
  response.o \
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

all: rebuild$(EXEEXT) rebuild.conf/default gendymods

rebuild$(EXEEXT): libdmd.a
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(WA) libdmd.a $(NWA) -o rebuild$(EXEEXT)

libdmd.a: id.c impcnvtab.c $(OBJS)
	$(AR) $(ARFLAGS) libdmd.a $(OBJS)

id.c: idgen$(EXEEXT)
	./idgen$(EXEEXT)

idgen$(EXEEXT): idgen.o
	$(NATIVECXX) $(CXXFLAGS) $(LDFLAGS) idgen.o -o idgen$(EXEEXT)

idgen.o: idgen.c
	$(NATIVECXX) $(CXXFLAGS) -c idgen.c -o idgen.o

impcnvtab.c: impcnvgen$(EXEEXT)
	./impcnvgen$(EXEEXT)

impcnvgen$(EXEEXT): impcnvgen.o
	$(NATIVECXX) $(CXXFLAGS) $(LDFLAGS) impcnvgen.o -o impcnvgen$(EXEEXT)

impcnvgen.o: impcnvgen.c
	$(NATIVECXX) $(CXXFLAGS) -c impcnvgen.c -o impcnvgen.o

rebuild.conf/default: choosedc$(EXEEXT)
	./choosedc$(EXEEXT)

choosedc$(EXEEXT): choosedc.o nwhereami.o
	$(NATIVECXX) $(CXXFLAGS) $(LDFLAGS) choosedc.o nwhereami.o -o choosedc$(EXEEXT)

choosedc.o: choosedc.c
	$(NATIVECXX) $(CXXFLAGS) -c choosedc.c -o choosedc.o

nwhereami.o: whereami.c
	$(NATIVECXX) $(CXXFLAGS) -c whereami.c -o nwhereami.o

gendymods:
	./dymods

.SUFFIXES: .c .o

.c.o:
	$(CXX) $(CXXFLAGS) -D_DH -DIN_DMDFE -c $< -o $@

install:
	mkdir -p $(PREFIX)/bin
	mkdir -p $(PREFIX)/etc/rebuild
	cp -pf rebuild$(EXEEXT) $(PREFIX)/bin
	cp -pRf rebuild.conf/* $(PREFIX)/etc/rebuild/
	./instdymods $(PREFIX)

clean:
	rm -f rebuild$(EXEEXT) libdmd.a $(OBJS)
	rm -f id.c id.h idgen$(EXEEXT) idgen.o
	rm -f impcnvtab.c impcnvtab.h impcnvgen$(EXEEXT) impcnvgen.o
	rm -f rebuild.conf/default choosedc$(EXEEXT) choosedc.o nwhereami.o
	rm -f dyloadposix.o gdc-posix-dymoduleinit.o
