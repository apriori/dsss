CROSS=
CXX=$(CROSS)g++
NATIVECXX=g++
CXXFLAGS=-O2 -g

EXEEXT=

LDFLAGS=

PREFIX=/usr
BINDIR=$(PREFIX)/bin
SHAREDIR=$(PREFIX)/share
MANDIR=$(SHAREDIR)/man
DOCDIR=$(SHAREDIR)/doc
SYSCONFDIR=$(PREFIX)/etc

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
  interpret.o \
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

all: rebuild$(EXEEXT) rebuild.conf/default

rebuild$(EXEEXT): id.c impcnvtab.c $(OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(OBJS) -o rebuild$(EXEEXT)

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
  
rebuild.conf/default: rebuild_choosedc$(EXEEXT)
	./rebuild_choosedc$(EXEEXT)

rebuild_choosedc$(EXEEXT): choosedc.o nwhereami.o
	$(NATIVECXX) $(CXXFLAGS) $(LDFLAGS) choosedc.o nwhereami.o -o rebuild_choosedc$(EXEEXT)

choosedc.o: choosedc.c
	$(NATIVECXX) $(CXXFLAGS) -c choosedc.c -o choosedc.o

nwhereami.o: whereami.c
	$(NATIVECXX) $(CXXFLAGS) -c whereami.c -o nwhereami.o

.SUFFIXES: .c .o

.c.o:
	$(CXX) $(CXXFLAGS) -D_DH -DIN_DMDFE -c $< -o $@

install:
	mkdir -p $(BINDIR)
	mkdir -p $(MANDIR)/man1
	mkdir -p $(DOCDIR)/rebuild
	mkdir -p $(SYSCONFDIR)/rebuild
	mkdir -p $(SHAREDIR)/rebuild
	cp -pf rebuild$(EXEEXT) $(BINDIR)
	cp -pf rebuild_choosedc$(EXEEXT) $(BINDIR)
	ln -s rebuild$(EXEEXT) $(BINDIR)/rerun$(EXEEXT)
	cp -rf rebuild.1 $(MANDIR)/man1
	cp -pf README $(DOCDIR)/rebuild
	cp -pRf rebuild.conf/* $(SYSCONFDIR)/rebuild/
	cp -pf testtango.d $(SHAREDIR)/rebuild
	./instdymods $(PREFIX)

clean:
	rm -f rebuild$(EXEEXT) $(OBJS)
	rm -f id.c id.h idgen$(EXEEXT) idgen.o
	rm -f impcnvtab.c impcnvtab.h impcnvgen$(EXEEXT) impcnvgen.o
	rm -f rebuild.conf/default rebuild_choosedc$(EXEEXT) choosedc.o nwhereami.o
