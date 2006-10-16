Ddoc

$(TOPIC_H switches,Switches)
$(SECTION
$(I Bud) supports a number of command line switches to control its
default assumptions. All switches begin with a $(B '-'). Any switch that
begins with a double dash $(B '--') has the effect of cancelling that
switch.
$(EXAMPLE ,
build myapp @dbg --info
)
The above example grabs any switches from the 'dbg' response file and the
'--info' will cancel out any '-info' that might have been in that response
file.
)

$(SECTIONDEF_H switch_nodef,switch: -nodef, Prevent a Module Definition File being created)
$(INDENT $(BR)
Normally, the utility will automatically create a Module Definition File
for the linker. This will typically contain the EXETYPE command and any other
commands as specified in any pragma($(EXDEF pragmas#pragma_build_def,build_def))
statements found in the source files. If you specify this switch, you will
have to provide your own Module Definition File or its equivalent on the
command line.
)

$(SECTIONDEF_H switch_v,switch: -v, Global verbose mode)
$(INDENT $(BR)
Sets $(I verbose) mode on for both $(I Bud) and for the compiler.
)

$(SECTIONDEF_H switch_V,switch: -V, Normal verbose mode)
$(INDENT $(BR)
Set $(I verbose) mode on for just $(I Bud) and $(B not) for the compiler.
)

$(SECTIONDEF_H switch_explicit,switch: -explicit, Process only explicitly named files)
$(INDENT $(BR)
Normally, the utility will compile not only the files named in the command line,
but also any file named in $(I import) statements if they require it. This
switch will force the utility to only compile files named on the
command line.
$(EXAMPLE Only compile the two files named,
build fileone.d filetwo.d -explicit
)
)

$(SECTIONDEF_H switch_usefinal,switch: -usefinal, Allow the processing of
 'FINAL' processing)
$(INDENT $(BR)
By default, all the $(I FINAL) commands found in the configuration files
are processed after successful compilation. You can control whether you
want this or not by using this switch.
$(EXAMPLE Prevent processing of FINAL commands,
-usefinal=no
)
$(EXAMPLE Ensure processing of FINAL commands (default),
-usefinal=yes
)
)

$(SECTIONDEF_H switch_emptyargs,switch: -emptyargs, Ignore empty commandline arguments)
$(INDENT $(BR)
By default, if $(I Bud) comes across any empty arguments from either the commandline
or configuration file, they are simply ignored. However by setting this switch
to 'yes', you can force $(I Bud) to abort if it finds an empty argument.
$(EXAMPLE Abort on finding an empty argument,
-emptyargs=no
)
$(EXAMPLE Ignore empty arguments (default),
-emptyargs=yes
)
)

$(SECTIONDEF_H switch_names,switch: -names, Display Names)
$(INDENT $(BR)
Displays the names of the files used in building the target.
)

$(SECTIONDEF_H switch_DCPATH,switch: -DCPATH, Identifies where the compiler has been installed.)
$(INDENT $(BR)
Normally, $(I Bud) scans the PATH environment symbol to find where the
 D compiler is located. However, if you need to use the compiler from
 a different location, you would use this switch to tell $(I Bud) where
 it is.

$(NB If you use this switch, and the current CFPATH value is
identical to the current DCPATH value, then this switch will change
both to the new value. The assumption is that the configuration
file is in the same directory as the compiler. If this is not the case,
you will also need to use the $(EXDEF switches,#switch_CFPATH,-CFPATH) switch.)

$(EXAMPLE ,
  -DCPATHc:\old\dmd\bin
)
)

$(SECTIONDEF_H switch_CFPATH,switch: -CFPATH, Identifies where the D config file has been installed.)
$(INDENT $(BR)
Normally, $(I Bud) looks in the same place that the compiler is
 installed in, but if you need to use a different configuration
 path from that, you would use this switch to tell $(I Bud) where
 it is.

$(EXAMPLE ,
  -CFPATHc:\myproject\configs
)
)

$(SECTIONDEF_H switch_BCFPATH,switch: -BCFPATH, Identifies where a $(I Bud) config file has been installed.)
$(INDENT $(BR)
$(I Bud) looks for configuration files in the following places... $(BR)
$(LIST
  $(ITEM The directory that the utility is installed in)
  $(ITEM The directory defined by this switch -BCFPATH or the BCFPATH environment switch)
  $(ITEM The directory that the compiler is installed in)
  $(ITEM The current directory)
  )
$(EXAMPLE ,
  -BCFPATHc:\myproject\configs
)
)

$(SECTIONDEF_H switch_full,switch: -full, Causes all source files to be compiled.)
$(INDENT $(BR)
Normally, $(I Bud) only compiles a source file if it's object file
is out of date or missing. This switch forces all source files to be
recompiled, even if not strictly required.

$(NB  Module sources in the $(I ignore) list are still ignored though.)
)

$(SECTIONDEF_H switch_link,switch: -link, Forces the linker to be called instead of the librarian.)
$(INDENT $(BR)
Normally, if $(I Bud) does not find a $(B main()) or $(B WinMain()) function
 in the source files, it creates a library to contain the object
files. But when this switch is used, $(I Bud) will attempt to
 create an application by calling the linker rather than the librarian.

You would typically use this if the $(I main) function was being supplied
from an existing library or object file rather than one of your source files.
)

$(SECTIONDEF_H switch_exec,switch: -exec$(ANG args), Runs a program after successful linking.)
$(INDENT $(BR)
If the link is successful, this will cause the
executable just created to run. You can give it
run time arguments. Anything after the '-exec' will
placed in the program's command line. You will need
to quote any embedded spaces.

$(EXAMPLE ,
    -exec"abc.de second"
)
)

$(SECTIONDEF_H switch_od,switch: -od$(ANG path), Nominates the temporary file directory.)
$(INDENT $(BR)
By default, the utility creates any work files in the same directory
as the target file. You can use this switch to nominate an alternative
location for these files. The directory is created if it doesn't exist.
$(BL)
For the $(I DigitalMars) compiler, this also specifies the top-level
location where object files are created. By default, object files
are created in the same directory as the corresponding source file.

$(EXAMPLE ,
        -odC:\temp\workarea
)
)

$(SECTIONDEF_H switch_nolink,switch: -nolink, Ensures that the linker is not called.)
$(INDENT $(BR)
Normally, if $(I Bud) finds a $(B main()) or $(B WinMain()) function, it
tries to create an application by calling the linker. If you use
this switch however, the linker will not be called.

You would typically do this if you wanted to create a library that
stores your $(I main) function in it, in which case you'd also use the
$(EXDEF switches#switch_lib, -lib) switch. But you could just create a set of
object files without linking them with this switch.
)

$(SECTIONDEF_H switch_lib,switch: -lib, Forces the object files to be placed in a library.)
$(INDENT $(BR)
Normally, if $(I Bud) finds a $(B main()) or $(B WinMain()) function, it
tries to create an application by calling the linker. But if you
use this switch, the librarian is called instead of the linker.

You would typically do this if you wanted to create a library that
stores your $(I main) function in it, in which case you'd also use the
$(EXDEF switches#switch_nolink, -nolink) switch.
)

$(SECTIONDEF_H switch_obj,switch: -obj, Shorthand for using both $(EXDEF switches#switch_nolink,-nolink)
 and $(EXDEF switches#switch_nolib,-nolib) switches.)
$(INDENT $(BR)
Normally $(I Bud) tries to create either an executable or a library file.
However sometimes you just need the object files to be created.
This switch is literally the same has if you had placed both -nolink and
-nolib on the command line. As this is a common way to compile
modules to just get their object files, without doing anything else,
this neat shorthand is available.
)

$(SECTIONDEF_H switch_nolib,switch: -nolib, Ensures that the object files are not used to form a library.)
$(INDENT $(BR)
Normally, if $(I Bud) does not find a $(B main()) or a $(B WinMain()) function,
it calls the librarian to create a library for your object files.
But if you use this switch, the librarian is not called.
)

$(SECTIONDEF_H switch_allobj,switch: -allobj, Ensures that all object files are added to a library.)
$(INDENT $(BR)
Normally, $(I Bud) will only create a library using the object files
that are in the same directory as the new library. You would use
this switch if you wanted all object files created by this build
session to be included in the library.
)

$(SECTIONDEF_H switch_cleanup,switch: -cleanup, Ensures that all working files created during the run are removed.)
$(INDENT $(BR)
Normally, $(I Bud) does not delete any object files or working files
when it finishes a session. You can use this switch to have $(I Bud)
clean up after itself. This will remove all object files created
in this run, plus any temporary work files.
$(BL)
$(NB This can also be supplied as $(B -clean) as an alias.)
)

$(SECTIONDEF_H switch_LIBOPT,switch: -LIBOPT$(ANG option(s)), Allows commandline options to be passed to the librarian.)
$(INDENT $(BR)
This allows you to pass one or more command line arguments to the librarian.

$(EXAMPLE Set the page size to 32Kb,
    -LIBOPT-p32
)
$(EXAMPLE Embedded spaces enclosed in quotes.,
    "-LIBOPT -l -i"
)
)

$(SECTIONDEF_H switch_LIBPATH,switch: -LIBPATH$(ANG path), Used to add a search path for library files.)
$(INDENT $(BR)
This allows you to add one or more paths to be searched for library files.
$(BL)
This might be used when you don't want to permanently update the
standard search paths.
$(EXAMPLE ,
    -LIBPATH=c:\mylibs;d:\3rdparty;c:\lib\debuglibs
)
)

$(SECTIONDEF_H switch_R,switch: -R$(ANG option),
            Determines if the compiler tools use a response file or not.)
$(INDENT $(BR)
For $(I DigitalMars) tools in the Windows environment, a response file is
the default, but for $(I other) tools and other operating systems the
default is to use command line arguments.
$(BL)
This switch has three formats: $(BL)
$(LIST
 $(ITEM -Ry to use a response file )
 $(ITEM -Rn to use command line arguments )
 $(ITEM -R to reverse the current setting.)
 )
$(BL)
The use of a response file is only really needed when the command line
arguments are going to be more than the operating system can handle
on a single command line. However, it is always a safe option, so if
in doubt you may as well use it.

A response file contains all the arguments that would have gone on the
command line. They are arranged as one argument per line.

Not all tools respect the response file idea however the Windows based
 $(I DigitalMars) tools do understand it.
$(INDENT $(BR)
 Without a response file the compiler might be invoked thus:
$(CODE
dmd -op -release appmain.d somemod.obj -IC:\DLibs
)
But with a response file, these arguments are first written out to
a text file (the response file) and the compiler is invoked :
$(CODE
dmd @appmain.rsp
)


The $(I appmain.rsp) would contain the lines :
$(CODE
-op
-release
appmain.d
somemod.obj
-IC:\DLibs
)
)
)

$(SECTIONDEF_H switch_test,switch: -test,
     Does a test run only. No compiling$(COMMA) linking or library work is done.)
$(INDENT $(BR)
This will display the command lines instead of running them. It can be used
to see what would happen without actually building anything.
)

$(SECTIONDEF_H switch_PP,switch: -PP$(ANG path),
     Adds a project path to the source search list.)
$(INDENT $(BR)
This is used to add a path that will be searched when $(I Bud) is
looking for source files that are only supplied with relative paths.
$(BL)
The default source file search list is just the current directory. This switch
adds a single path to that list. You can have any number of -PP switches
on your command line. The utility scans through them in the order they
appear as required.

$(EXAMPLE ,
build editor codeparser -PPc:\projects\myeditor\source
)
In the above example, $(I Bud) will look for 'editor.d' and 'codeparser.d'
first in the current directory and then, if it didn't find them, in the
folder 'c:\projects\myeditor\source'.
)

$(SECTIONDEF_H switch_RDF,switch: -RDF$(ANG file),
     Defines a file to override the default $(EXREF rules.html,Rule Definition File).)
$(INDENT $(BR)
The default file is called $(B default.rdf). But if you need to provide
an alternate file, you can use this switch.

$(EXAMPLE ,
-RDFmyrules.xyz
)
)

$(SECTIONDEF_H switch_MDF,switch: -MDF$(ANG file),
     Defines a file to override the default $(EXREF macros.html,Macro Definition File).)
$(INDENT $(BR)
The default file is called $(B build.mdf). But if you need to provide
an alternate file, you can use this switch.

$(EXAMPLE ,
-MDFmymacros.xyz
)
)

$(SECTIONDEF_H switch_dll,switch: -dll,
     Forces a DLL library to be created.)
$(INDENT $(BR)
$(NB This only applies to Windows environment.)
$(BL)
Normally, if $(I Bud) finds a $(B DllMain()) function it automatically
creates a DLL library. However, if you need to force a DLL
library to be created instead of a normal library, you would use this switch.
)

$(SECTIONDEF_H switch_gui,switch: -gui,
     Forces a GUI application to be created.)
$(INDENT $(BR)
$(NB This only applies to Windows environment.)
$(BL)
Normally, if $(I Bud) finds a $(B WinMain()) function it automatically
creates a GUI application. However, if you need to force a GUI
application, you would use this switch.
$(BL)
This switch can also be used to specify which version of Windows to
build the application for. To do this, it takes the format of
-gui:X.Y where $(I X.Y) is the Windows version number. Use 4.0
for Windows NT, 2000, and ME, and 5.0 for Windows XP.
$(BL)
By default, $(I Bud) uses the version of Windows it is running under.
)

$(SECTIONDEF_H switch_info,switch: -info, Displays information about $(I Bud).)
$(INDENT $(BR)
Displays the version and path of the $(I Bud) application.
$(EXAMPLE ,
Path and Version : y:\util\build.exe v2.9(1197)
  built on Wed Aug 10 11:03:42 2005
)
)

$(SECTIONDEF_H switch_help,switch: -help, Displays the full text of the Usage information.)
$(INDENT $(BR)
This displays the commandline syntax, including all the switches, used
to run $(I Bud).
$(BL)
This has the aliases of $(B -h) and $(B -?)
)

$(SECTIONDEF_H switch_silent,switch: -silent, Prevents unnecessary messages being displayed.)
$(INDENT $(BR)
Some messages are just informational and under some circumstances they
can interfer with reading the output.
)

$(SECTIONDEF_H switch_noautoimport,switch: -noautoimport,
    Prevents source file paths from being added to the list of Import Roots.)
$(INDENT $(BR)
By default, for each source file that imports a module, it's path is added
to the list of paths that will be searched for module source files. If you
do not wish that behaviour, you will need to use this switch. In that case,
the compiler will only search the paths specified in the compiler's
configuration file, the current directory, and any explicitly added paths
on the command line.

$(EXAMPLE ,
build myApp -noautoimport
)
)

$(SECTIONDEF_H switch_X,switch: -X$(ANG name),
    Identifies a module or package to ignore.)
$(INDENT $(BR)
Normally, $(I Bud) assumes that all imported modules are available
to be recompiled if required. You would use this switch if you explictly
did not want $(I Bud) to recompile a module.

$(NB The $(I Phobos) package of modules is automatically ignored. This
means that $(I Bud) does not try to recompile phobos.)

$(EXAMPLE ignore the module (or package) called 'parser',
-Xparser
)
)

$(SECTIONDEF_H switch_M,switch: -M$(ANG name),
    Identifies a module or a package to notice (not ignore).)
$(INDENT $(BR)
You would use this to name any module that is not part of the target's
dependancies, or is one of the $(I ignored) modules.

You can use this switch to recompile $(I phobos).

$(EXAMPLE (notice the Phobos package),
-Mphobos
)
)

$(SECTIONDEF_H switch_T,switch: -T$(ANG name),
    Identifies the target name to build.)
$(INDENT $(BR)
Normally, $(I Bud) derives the target name from the first file name
on the command line, or from the pragma(target) if present.
If however, you wish to override that, use this switch.

$(NB This switch allows the use of a special token, $(B {Target}),
which is replaced by the default target name. You can use
this form in a $(EXDEF response_file,Response File) so that you can
use it for building any application.)

$(EXAMPLE ,
build editor -Ttestapp
)
In the example above, the executable built would be called
(in Windows) 'testapp.exe' rather than the normal 'editor.exe'.

$(EXAMPLE Generate a name derived from the default name,
build editor -Ttest_{Target}
)
In the example above, the executable built would be called
(in Windows) 'test_editor.exe'.
)


$(SECTIONDEF_H switch_autowinlibs,switch: -AutoWinLibs(=$(ANG Yes/No)),
   Give Windows libraries to linker)
$(INDENT $(BR)
By default, when creating a Windows GUI application, $(I Bud) will
supply a list of commonly used windows libraries to the linker. However,
if for some reason you do not want this to happen, you can use this switch
to disable that. $(BL)
$(B Note:) that this switch is not valid for Posix editions of $(I Bud).
)

$(SECTIONDEF_H switch_modules,switch: -modules(=$(ANG name)),
   Create a Module List File)
$(INDENT $(BR)
Use this switch to cause a Module List File to be created. This
file will contain a list of all the module names processed by
$(I Bud). You can use the Configuration File to specify the
layout of this file, but by default the file will look like
a Ddoc macro definition ...

 $(CITE
   MODULES =
     $(DOLLAR)$(PAREN MODULE mod1)
     $(DOLLAR)$(PAREN MODULE mod2)
     ...
   )
The name of the Module List File will be as specified on the switch, but
if not supplied it takes the form of $(I $(ANG target)_modules.ddoc ).
)

$(SECTIONDEF_H switch_uses,switch: -uses$(SQR =outputname),
    Create the Uses/Used-By cross reference file.)
$(INDENT $(BR)
This causes $(I Bud) to create a file that details the modules that
are used by a module and the modules that uses a module.
$(BL)
You can optionally specify a name for the cross reference file. If you
don't then the name of the cross reference file takes the Target file's
base name and adds the extension ".use".
$(BL)
The file is in two sections. The first, headed by the line $(QUOTE $(SQR USES))
lists each file that has been analyzed. Each line has the file name followed
by $(QUOTE <>) followed by the path of a module that the file uses.
The second, headed by the line $(QUOTE $(SQR USEDBY))
lists each module that has been used. Each line has the module followed
by $(QUOTE <>) followed by the name of the file that uses it.
$(BL)
Each section is sorted in ascending order.

$(EXAMPLE The layout of the cross reference file,
build tres -uses=xref.txt
type xref.txt
$(CODE
[USES]
bar.d <> y:\dmd\src\phobos\std\stdio.d
foo.d <> bar.d
tres.d <> foo.d
tres.d <> tres_bn.d
tres.d <> y:\dmd\src\phobos\std\stdio.d
[USEDBY]
bar.d <> foo.d
foo.d <> tres.d
tres_bn.d <> tres.d
y:\dmd\src\phobos\std\stdio.d <> bar.d
y:\dmd\src\phobos\std\stdio.d <> tres.d
)
)
)

$(SECTIONDEF_H switch_UMB,switch: -UMB=$(ANG Yes/No),
    Determines where the linker expects the object files.)
$(INDENT $(BR)
For $(B DMD) environments, $(I Bud) expects that object files will be created
in the same directory as the source file, or in the directory
specified in any $(LOCAL switch_od,-od) switch. However, this switch
can tell $(I Bud) to expect them in the current directory.
$(BL)
For $(B GDC) environments, $(I Bud) expects that object files will be created
in the current directory. However  this switch can tell $(I Bud) to expect
then to be in same directory as the source file, or in the directory
specified in any $(LOCAL switch_od,-od) switch.
$(BL)
The forms $(B -UMB, -UMB=Yes, -UMB:Yes, -UMB=Y, -UMB:Y, -UMB=, -UMB:) all
mean the same; that the object files are expected in the current directory.
Any other form of the switch (eg. $(B -UMB=No) ) will make the utility
expect the object files to be in the same directory as the source files.
$(BL)
Unless you have some special need to do this, the -UMB switch is not
really required.
$(BL)
$(EXAMPLE ,
build editor -UMB=Yes
)
In the example above, the utility will expect object files to be created
in the current directory.

)

Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for Bud
 Product = $(I Bud) Utility
