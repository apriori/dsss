Ddoc

$(TOPIC_H change_log, Change Log)
$(SECTION
A list of changes and fixes that have been made.

$(SUBSECTION_H ,v3.03 -- 20/September/2006 )
$(LIST
    $(ITEM ** $(B FIX: Ticket #33) For unix editions, 'pthread' is
    now a default library, '-g' is used instead of '/co' to generate
    debug data, '-o ' is used instead of '-of', and spaces are placed
    in between consecutive '-L' switches.  Note that if you want to place
    library files on the command line, you still have to include the '.a'
    file suffix.
    )
    $(ITEM ** $(B FIX: Ticket #34) For GNU, 'gdc' is the default
    linker, the library switch is now '-L-l', 'gphobos' is used instead of
    'phobos', and the makefile includes the '-version=BuildVerbose' switch.
    )
    $(ITEM ** $(B FIX: Ticket #35) It is now possible to use relative
    paths on the command line files.
    )
    $(ITEM ** $(B FIX) If you use the '-od' switch then the '-op' switch
    is not used.
    )
    $(ITEM ** $(B CHG: Ticket #36) The default name for the executable is
     now 'bud', but you can change it to anything you like.
    )
    $(ITEM ** $(B CHG: Ticket #37) Changed defaults to support GDC
     out-of-the-box.
    )
    $(ITEM ** $(B ENH) The utility now also checks for a '[darwin]'
    section in the Configuration File.
    )
    $(ITEM ** $(B ENH) The utility now supports the import syntax that
    was introduced with DMD v0.163.
    )
    $(ITEM ** $(B ENH) The distribution now includes example configuration
    files for a number of environments.
    )
    $(ITEM ** $(B ENH) The Configuration File now supports a new $(I FINAL)
    command that allows you to run jobs after a successful build.
    )
)

$(SUBSECTION_H ,v3.02 -- 23/June/2006 )
$(LIST
    $(ITEM ** $(B FIX: Ticket #27) When using 'gcc' as the linker tool,
    $(I $(B the utility)) now uses a space character to delimit file names.
    )
    $(ITEM ** $(B FIX: Ticket #28) The Optlink switch options  are now
     correctly placed in a response file )
    $(ITEM ** $(B FIX: Ticket #29) The $(I -exec) now works correctly. )
    $(ITEM ** $(B FIX: Ticket #32) The Windows executable in the distro
    now updates the auto_build_number.)
    $(ITEM ** $(B ENH: Ticket #30) The Rules subsystem can now be used
    to generate D source code. There are number of changes in this area
    so read the $(EXREF rules.html, rules documentation) and
    $(EXREF pragmas.html, pragma documentation) for details. )
    $(ITEM ** $(B ENH: Ticket #31) It is now possible to stop a source file
    from being compiled. A new $(QUOTE pragma(ignore)) has been implemented.)
    $(ITEM ** $(B ENH:) There are some new $(I configuration) items that
    can be used to adjust the tools usage. Have a look at the example
    configuration file in the distrubution package.
    )
)

$(SUBSECTION_H ,v3.01 -- 09/June/2006 )
$(LIST
    $(ITEM ** $(B FIX: Ticket #18) The tool now ignores duplicate source
    file names supplied to it from anywhere.)
    $(ITEM ** $(B FIX: Ticket #19) The tool now only passes object files,
    library files, DigitalMars .def files, and resource files to the linker.)
    $(ITEM ** $(B FIX: Ticket #20) The 'Rules' system can now handle creation
    of D source files.)
    $(ITEM ** $(B FIX: Ticket #22) A few spelling errors corrected in the
    documentation.)
    $(ITEM ** $(B FIX: Ticket #23) When using a response file for the
    DigitalMars linker, the tool now makes provision for Resource Files.)
    $(ITEM ** $(B FIX: Ticket #24) The tool now recognises .di files as
    source files for the purposes of determining dependancies, but does
    not allow them to be presented on the DMD compiler's command line.)
    $(ITEM ** $(B FIX: Ticket #25) The tool now scans the PATH environment
    symbol rather than assuming that supplie executable file names that
    do not have a path are in the current directory.)
    $(ITEM ** $(B FIX: Ticket #26) The LINKCMD configuration item is now
    corrected parsed.)
    $(ITEM ** $(B ENH:) The 'Rules' functionality now allows some new special
    tokens that represent the Basename and Path of the input and output files.)
    $(ITEM ** $(B ENH:) The 'Rules' functionality now ensures that the
    output file's path exists prior to running the Rule's tool application.)
    $(ITEM ** $(B ENH:) The LINKCMD is now able to be used in the $(I $(B utility))
    configuration file.)
    $(ITEM ** $(B ENH:) A new switch "-uses" will cause the tool to
    create a cross-reference file that details what modules use what,
    and what modules are used by other modules.)
)


$(SUBSECTION_H ,v3.00 -- 05/June/2006 )
$(LIST
    $(ITEM ** $(B FIX:) $(I $(B the utility)) was using the wrong object file during
    linkages if a target object file did not exist but one with the same name
    existed in any of the Import paths.
    )
    $(ITEM ** $(B FIX:) With the $(I -R=No) switch, when using the Digital
     Mars linker, $(I $(B the utility)) was not formatting the command line correctly.
    )
    $(ITEM ** $(B FIX: Ticket #10 ) The tool now recognises the
     $(EXREF pragmas.html#pragma_link, pragma linked) object files when
     building a library.
    )
    $(ITEM ** $(B FIX: Ticket #9 ) Now, if the output file created by the
     rule ends with the library extention, it is presented to the linker
     as a library rather than an object file.
    )
    $(ITEM ** $(B FIX: ) $(I thanks to gmiller:) Added booltype.d to
     Makefile files.
    )
    $(ITEM ** $(B FIX: Ticket #15 ) GDC places object files in the
    directory from which it is called so the tool no longer assumes the
    same directory as the corresponding source file.
    )
    $(ITEM ** $(B FIX: Ticket #17 ) Hopefully its a more posix-friendly
    tool now. Most of the hard-coded switches and options that are
    environment related are now user-configurable via the $(EXREF configuration_file.html,
    Configuration File) functionality.
    )
    $(ITEM ** $(B FIX: ) $(I thanks to gmiller:) Corrected the imports
    in $(I util.fileex.d)
    )
    $(ITEM ** $(B FIX: ) $(I thanks to gmiller:) Module and package exclusion
    was not working if your current directory was in a directory tree that
    contained the module/package you were excluding. For example if your
    current directory was C:\dmd\src\phobos it would not exclude any of the
    'std' modules.)

    $(ITEM ** $(B ENH: ) Any file name on the command line with an extention
     of $(I ".brf" ) will be used as a $(EXREF response_file.html, Build Response File)
    )

    $(ITEM ** $(B ENH: ) If there is nothing on the command line and the
    file 'build.brf' exists in the current directory, then it will be
    used as the $(EXREF response_file.html, Build Response File) for this run.
    )

    $(ITEM ** $(B ENH: ) Will now look for the compiler's configuration file
    in the following areas...
      $(LIST
        $(ITEM If defined, the directory defined by the $(I ConfigPath)
        configuration item in $(I the utility's) configuration file. And in this
        case it doesn't look anywhere in any of the areas listed below.)
        $(ITEM The current directory.)
        $(ITEM The directory named in the $(I HOME) environment symbol.)
        $(ITEM For Windows environments only, the directory named in
        the combination of the $(I HOMEDRIVE) and $(I HOMEPATH) environment symbols.)
        $(ITEM The same directory in which the compiler resides.)
        $(ITEM The directory defined by the $(I EtcPath) configuration item
        in $(I the utility's) configuration file.)
        )
    )

    $(ITEM ** $(B ENH: ) It is now possible to add environment specific items
    to the build.cfg file. To do so, add the items to the appropriate item group...
$(CITE
$(SQR Windows)
# items that only apply when building in Windows.

$(SQR Posix)
# items that only apply when building in Posix (unix).

$(SQR DigitalMars)
# items that only apply when building with DigitalMars tools.

$(SQR GNU)
# items that only apply when building with GNU tools.

$(SQR Windows:DigitalMars)
# items that only apply when building with DigitalMars tools in Windows.

$(SQR Windows:GNU)
# items that only apply when building with GNU tools in Windows.

$(SQR Posix:DigitalMars)
# items that only apply when building with DigitalMars tools in Posix.

$(SQR Posix:GNU)
# items that only apply when building with GNU tools in Posix.
)
    )

    $(ITEM ** $(B ENH: ) A new switch, $(B -UMB=$(ANG( Yes/No))) is used
    to specify where the linker expects the object files to be. Unless
    this switch is used the linker is assumed to look for the object files
    in the same directory as the source files. However if the linker that
    you use expects them to be all in the current directory, you can use
    $(B -UMB=yes) to ensure that the compiler places object files in the
    current directory.
    )

    $(ITEM ** $(B ENH: ) A new switch, $(B -modules=$(ANG( name))) is used
    create a Module List File.
    )

    $(ITEM ** $(B CHG: ) When building the $(I $(B the utility)) application itself,
    you must now add $(B -version=BuildVerbose) to the command line if
    you want an edition of $(I $(B the utility)) that supports the $(B -V) $(PAREN verbose) switch. As
    shipped, the pre-built editions of $(I $(B the utility)) do not support
    the $(B -V) switch.
    )
)

$(SUBSECTION_H ,v2.10 -- 06/Apr/2006 )
$(LIST
    $(ITEM ** $(B FIX: ) The default Build Response File invoked when just
    placing '@' on the command line is now correctly named "build.brf")
    $(ITEM ** $(B ENH: )  For Windows environments, command line files can now use
    either "/" or "\" as path separator characters.)
    $(ITEM ** $(B ENH: )  The linker program is now used directly rather than being
    invoked via DMD. )
    $(ITEM ** $(B ENH: ) You can now specify the default linker switches in
    the Build Configuration File. )
    $(ITEM ** $(B ENH: ) Using the new switch $(I -PP ), you can now
    specify additional paths to search for files.)
    $(ITEM ** $(B ENH:) Support for $(I Ddoc) files.)
    $(ITEM ** $(B CHG: ) The files are now compiled and linked in the
    same order that they are scanned in. Previously the order depended
    on the hashing algorithm of D's associative array implementation and
    the names of the directories containing the source files.
    )
    $(ITEM ** $(B CHG:) The "-run" switch renamed to "-exec" to avoid clashing with dmd.)
)

$(SUBSECTION_H ,v2.09 -- 10/Aug/2005)
$(LIST
    $(ITEM ** $(B FIX:) $(I Thanks to barrett9h (rodolfo)): Now correctly handles the return value
    from Unix system() call.)
    $(ITEM ** $(B FIX:) $(I Thanks to oniony): Now handles non_ASCII characters in PATH
    environment symbol.)
    $(ITEM ** $(B CHG:) The "-silent" switch now also hides the linker stdout display.)
    $(ITEM ** $(B CHG:) Now supports and requires DMD v0.126 and GDC v0.13 or later.)
    $(ITEM ** $(B ENH:) New pragma(export_version) allows specified version identifiers to
    be passed to all modules being compiled.)
    $(ITEM ** $(B ENH:) New command line switch "-run" to run the program
    after a successful link.)
)

$(SUBSECTION_H ,v2.08 -- 29/May/2005)
$(LIST
    $(ITEM ** $(B FIX:) $(I Thanks to teqdruid): In Unix environments,
    any pragma(link, $(ANG name)) statements were not sending the correct
    syntax to the compiler's command line. The "$(ANG name)" is now prefixed
    with "-L-l" for Unix systems.)
    $(ITEM ** $(B FIX:) $(I Thanks to Carlos): In Unix environments, any "-version"
    switch on the Utility's command line was not being converted to the correct Unix
    format of "-fversion...". So now, if the utility gets
    either "-version..." or "-fversion=..." on its command line, it will
    recognise it as a 'Version' request for the compiler $(B and) output
    it on the command line in the correct format for the environment it
    is running in, namely "-fversion..." for GNU (gdc) and "-version..."
    for Windows. $(BR)
    $(NB The same applies to the "-debug..." and "-fdebug..." switches.)
    )
    $(ITEM ** $(B FIX:) The pragma(nolink) was being ignored under some circumstances.
    Now it splits the compilation phase
    from the linking phase and excludes the 'nolink' files from the linker's
    command line.)
    $(ITEM ** $(B FIX:) $(I Thanks to kris): 'debug' statements were not being taken into account when
    examining code for import statements.)
    $(ITEM ** $(B FIX:) 'debug' and 'version' levels are now being taken into account.)
    $(ITEM ** $(B FIX:) 'debug' and 'version' values being set inside a source file
    were being made global rather than module scoped.)
    $(ITEM** $(B FIX:) $(I Thanks to carlos): The utility was not processing the
    -I switch correctly when using GDC compiler.)
    $(ITEM ** $(B ENH:) The utility can now accept the -I switch in two forms:
    $(B -I$(ANG path)) and $(B -I $(ANG path)) on its command line, regardless of which
    compiler is being used. When invoking the compiler, it uses the correct
    format on the command line of the compiler being used, namely "-I$(ANG path)" to
    DMD compiler and "-I $(ANG path)" to GDC.)
    $(ITEM ** $(B ENH:) The path of any source file that imports a module
    will be added to the list of root paths to search for module source
    files. This means that you can now have module source files referenced
    relative to the source file that imports them. This is the new default
    behaviour but it can be turned off by using the new -noautoimport switch
    or for individual files by placing them inside parenthesis.)
    $(ITEM ** $(B ENH:) New switch $(I -noautoimport) is used to turn off the
    automatic adding of search roots based on the path of the source files
    being compiled.)
    $(ITEM ** $(B ENH:) New switch $(I -LIBPATH=) is used to add search paths for
    library files.)
    $(ITEM ** $(B WARN:) The utility only does a single scan of each source file
    and thus if an file sets a 'debug' or 'version' value after a function
    which uses that value, it will be ignored. You are requested to ensure that
    all your 'debug' and 'version' setting is done prior to the first module
    member.)
)

$(SUBSECTION_H ,v2.07 -- 06/May/2005)
$(LIST
$(ITEM ** $(B ENH): New switch $(I -nodef) to prevent the utility from
automatically creating a Module Definition File (.def))
$(ITEM ** $(B ENH): You can now specify default, and special, settings for
the utility's command line. These are placed in a text configuration file called
$(B build.cfg). The utility first looks in the same directory as the
utility's executable for the configuration file. After processing any
configuration file found there, it then looks in the same directory as
the compiler for a configuration file (build.cfg) and processes it if
found.)
$(ITEM ** $(B ENH): To support special command line settings that may be
specified in the utility's configuration file(s), you can indicate
one or more setting groups on the command line. These take the format of
+groupname. The configuration file(s) are scanned for special group settings
after the default ones have been processed.)
$(ITEM ** $(B ENH): To remove an earlier specified command line switch, you
can prepend it with a hyphen. This new feature may be needed when command
line switches can come from multiple sources (the original command line,
utility response files, and utility configuration files), and you need
to remove a switch that may have been provided by some other source. $(BR)
For example to negate an earlier "-unittest" switch you code add "--unittest"
to the command line.)
$(ITEM ** $(B ENH): New switch $(I -od) is used to nominate a directory for
temporary files. For the $(I DigitalMars) compiler, this also is used as the location
to create object files.
)
)

$(SUBSECTION_H ,v2.06 -- 04/May/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to phoenix): When emitting commandline parameters for
the compiler or librarian, it was possible to have some ending with $(B \") which caused
the shell to $(I escape) the quote character and thus provide incorrect parameters to
the compiler.
)
)

$(SUBSECTION_H ,v2.05 -- 02/May/2005)
$(LIST
$(ITEM ** $(B FIX): When supplying some forms of relative paths, the
utility would crash or give the wrong canonical form of the path. This
effected formats like \..\anything and  C:..\anything
)
$(ITEM ** $(B FIX): The utility now assumes the current directory if it can not
locate the compiler using the paths on the system PATH symbol.
)
$(ITEM ** $(B FIX): The utility now assumes the compiler's location if no path
for the configuration file has been specified.
)
$(ITEM ** $(B FIX): The utility now supports better parsing of the lines in the
configuration file. It handles odd variations of embedded quotes.
)
$(ITEM ** $(B ENH): The utility now supports Windows 95/98/ME for file times.
)
)

$(SUBSECTION_H ,v2.04 -- 29/Apr/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to Nils Hensel): The utility was not correctly
parsing the DFLAGS line in the configuration file when it contained
embedded quote characters.
)
$(ITEM ** $(B FIX): $(I Thanks to Anders F Bjoerklund): The utility was not treating
directory names that contained dots correctly.
)
$(ITEM ** $(B FIX): $(I Thanks to Carlos): Unix-style files that end with a nested comment
delimiter are now handled correctly.
)
$(ITEM ** $(B ENH): /i"thanks to qbert(Charlie)": The location of the librarian tool can now
be specified. It can be explictly named on a LIBCMD= line inside the
DMD configuration file, or failing that, implictly assumed to be in the
same directory as the DMD linker.
)
$(ITEM ** $(B ENH): A new commandline switch -LIBOPT which allows you to pass
commandline options to the librarian.
)
)

$(SUBSECTION_H ,v2.03 -- 20/Apr/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to Carlos): The linux build had a spelling mistake
in source.d (line 286). The indentifier "lNextMod" should have been coded
 as "lNextModule".
)
)

$(SUBSECTION_H ,v2.02 -- 19/Apr/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to Carlos): The utility was not handling the situation
where a simple statement, rather than a block statement, followed a version
directive.
)
$(ITEM ** $(B FIX): $(I Thanks to aldacron): The utility now respects the compiler's
'Output file' switch. Which is '-of[filename]' for DMD and '-o [filename]'
for GNU. The utility treats it as an alias for its -T switch.
)
$(ITEM ** $(B FIX): $(I Thanks to aldacron): The utility now respects the DMD compiler's
'Object Path' switch. If you have '-odsomepath' on the command line, the
utility adds this to the search path when checking for up-to-date files,
and will clean up files in that directory if requested to (-clean). It will
also create the directory if it doesn't exist.
)
)

$(SUBSECTION_H ,v2.01 -- 18/Apr/2005)
$(LIST
$(ITEM ** $(B FIX): /i"thanks to Justin (jcc7)": If an excluded module (-X) was
in a package at the current directory level, it was not being excluded.
)
)

$(SUBSECTION_H ,v2.00 -- 08/Apr/2005)
$(LIST
$(ITEM ** $(B FIX): Now supports the raw-string delimiter ` in the utility's own
pragma commands.
)
$(ITEM ** $(B FIX): Now handles backslash escapes in the utility's own
pragma commands.
)
$(ITEM ** $(B ENH): New -silent switch avoids all unnecessary messages.
)
$(ITEM ** $(B ENH): New -help switch displays full usage text. Aliases: -h, -?
)
)

$(SUBSECTION_H ,v1.19 -- 04/Apr/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to Ben Hinkle). When creating a library in Linux,
the utility was looking for $(I .obj) files instead of $(I .o) files.
)
$(ITEM ** $(B FIX)" When creating a library, if a source file had more than one
$(I .d) in its name, the utility would look for the wrong object file for it.
)
)

$(SUBSECTION_H ,v1.18 -- 03/Apr/2005)
$(LIST
$(ITEM ** $(B FIX): If mixed case was used, it was possible to have duplicate
element types in a OptLink module definition file. Effected the use of
pragma(build_def).
)
$(ITEM ** $(B ENH): Some performance improvements.
)
)

$(SUBSECTION_H ,v1.17 -- 30/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): In Windows systems, the utility now does case-insensitive
 path name compares.
)
$(ITEM ** $(B FIX): A bug in the String Search function crashed the utility
when the -T switch was used with target names less than 9 characters long.
)
$(ITEM ** $(B ENH): The new switch $(B -obj) is available. This is just a shorthand
for having both $(I -nolib) and $(I -nolink) on the command line.
)
)

$(SUBSECTION_H ,v1.16 -- 28/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): The utility now handles quotes around pragma(link) references.
)
$(ITEM ** $(B FIX): The utility now handles multiple references to the same module
even though they are using different 'path' specifications.
)
$(ITEM ** $(B ENH): The utility now has support for making Windows DLL files.
)
)

$(SUBSECTION_H ,v1.15 -- 24/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): The utility now checks for more recent libraries and
object files as added by pragma(link), pragma(build), and command line. It
didn't used to rebuild the executable if only a new version of a library
was present.
)
$(ITEM ** $(B FIX): The order of the librarian parameters was incorrect.
)
$(ITEM ** $(B FIX): The utility was not using the correct path name if importing
modules from some Import paths.
)
$(ITEM ** $(B ENH): Verbose mode now shows the ignored and noticed packages.
)
)

$(SUBSECTION_H ,v1.14 -- 23/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to teqDruid.) For GNU platforms, the utility
 now passes any library name found in pragma(link,...) to the linker.
)
$(ITEM ** $(B FIX): Nows correctly handles unix and Microsoft line-ends.
)
$(ITEM ** $(B FIX): $(I Thanks to Ben Hinkle.) Using relative paths '..' and '.'
now work correctly on the -I switch.
)
$(ITEM ** $(B FIX): $(I Thanks to Ben Hinkle.) The correct librarian program 'ar'
is now called on unix systems.
)
$(ITEM ** $(B ENH): The new switch -names displays the names of the files
used in building the target. This is not a noisy as verbose mode.
)
$(ITEM ** $(B ENH): New pragma $(B include) used to identify a file that
must be included in the compilation process but is not one that
is imported by any file in the group. Only needed if command line
 file does not otherwise import the required file. Can be used to
 include the file containing the 'main' function from a file that
does not import that file. Rarely needed.
)
$(ITEM ** $(B ENH): New pragma $(B build) used to build 'foreign' file types
that D doesn't know about.
)
$(ITEM ** $(B ENH): New pragma $(B target) used to nominate the default target
file name.
)
$(ITEM ** $(B ENH): You can now use a symbolic target name on the -T switch.
)
)

$(SUBSECTION_H ,v1.13 -- 13/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): Explictly included paths entered on the -I switch are
now added to the dmd command line.
)
$(ITEM ** $(B FIX): Explictly excluded modules (via -X) were only checking package
names. They also check for module names now.
)
$(ITEM ** $(B FIX): Imported files are now looked for relative to the current directory
before the import paths are checked.
)
$(ITEM ** $(B FIX): The utility now checks the DFLAG environment symbol in
non-$(I DigitalMars) D compilers.
)
$(ITEM ** $(B CHG): The switch -nounittest is now deprecated and ignored if used.
The default setting is no longer to compile with unittests turned on.
)
)

$(SUBSECTION_H ,v1.12 -- 6/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): The response file (-Ry) is now only the default when using
$(I DigitalMars) tools on Windows. All other environments do not use the response
file by default.
)
)

$(SUBSECTION_H ,v1.11 -- 4/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): No long outputs empty compiler tool switches.
)
)

$(SUBSECTION_H ,v1.10 -- 4/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to Carlos.) Better support for GDC command line switches.
)
$(ITEM ** $(B FIX): $(I Thanks to Carlos.) Cause 'Unix' version to trigger Posix code.
)
$(ITEM ** $(B FIX): $(I Thanks to Carlos.) The vUseResponseFile variable was only being
declared in the Windows version.
)
$(ITEM ** $(B FIX): No passes space-embedded switches and paths to the compiler
tools correctly.
)
$(ITEM ** $(B ENH): If an environment symbol called DFLAGS has been defined, it is
analyzed. This is done before any configuration file processing.
)
$(ITEM ** $(B ENH): New command line switch -test. This shows the command lines
instead of running them. No compiling or linking is done.
)
)

$(SUBSECTION_H ,v1.9 -- 3/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to Carlos.) For unix, it now uses ':' instead of ';' for path
separators when parsing the configuration file lines.
)
$(ITEM ** $(B FIX): $(I Thanks to Carlos.) The default location for the configuration
file was being ignored.
)
$(ITEM ** $(B ENH): A new command line switch $(B -R) used to control the use
 of a response file for the compiler tools.
)
)

$(SUBSECTION_H ,v1.8 -- 1/Mar/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to Anders F Bjoerklund:) Removed nonASCII chars from source code.
)
$(ITEM ** $(B FIX): $(I Thanks to Anders F Bjoerklund:) Changed version(GDC) to version(GNU)
)
$(ITEM ** $(B FIX): Changed compiler name for GNU versions from 'dmd' to 'gdc'
)
$(ITEM ** $(B FIX): $(I Thanks to Carlos.) The application was incorrectly parsing the DFLAGS sc.ini line.
)
$(ITEM ** $(B ENH): $(I Thanks to Anders F Bjoerklund:) Provided a Makefile for the initial
compile of the application.
)
)

$(SUBSECTION_H ,v1.7 -- 28/Feb/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to clayasaurus.) Linux edition was not compiling
due to a missing 'version(Windows)' block around the use of vWinVer
)
)

$(SUBSECTION_H ,v1.6 -- 28/Feb/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to Kris.) The utility was not including the DCPATH value
when invoking the compiler.
)
$(ITEM ** $(B ENH): When building a Windows app, the .DEF file now includes the
version of windows that $(I this) application is being run on.
)
$(ITEM ** $(B ENH): The command line switch $(B -gui) can now have an optional
 version information to specify which Windows version to build for.
The default Windows Version used is the one for the version running
 this utility.
)
$(ITEM ** $(B ENH): New command line switch -info to display the utility's version #.
)
)

$(SUBSECTION_H ,v1.5 -- 25/Feb/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to clayasaurus.) Now only displays the CFPATH
 and DCPATH messages when $(I verbose) mode is on.
)
$(ITEM ** $(B FIX): $(I Thanks to kris.) Hardcoded default for DMD path was
misleading when dmd.exe was not in the Windows PATH.
)
$(ITEM ** $(B FIX): The utility was not correctly parsing empty raw strings ``.
)
$(ITEM ** $(B ENH): $(I Thanks to kris.) If the -DCPATH switch is used, then
if the existing DCPATH and CFPATH are the same, this switch changes both.
)
)

$(SUBSECTION_H ,v1.4 -- 24/Feb/2005)
$(LIST
$(ITEM ** $(B FIX): $(I Thanks to Abscissa.) The -version switch was being interpreted as
 a file to compile.
)
$(ITEM ** $(B FIX): $(I Thanks to brad.) Linux version was using the wrong package name
when formatting a file date for display.
)
$(ITEM ** $(B FIX): $(I Thanks to brad.) Linux version was not setting the target
name correctly which resulted in the first source file being compiled twice.
)
$(ITEM ** $(B FIX): $(I Thanks to brad.) Parsing the DFLAG line in the dmd options
file was not dealing with whitespace delimiters.
)
$(ITEM ** $(B ENH): When specifing an alternate target file, you can now also
 specify a path for the target, and that path is created for you if it
doesn't exist.
)
)

$(SUBSECTION_H ,v1.3 -- 23/Feb/2005)
$(LIST
$(ITEM ** $(B ENH): Put in a workaround for DMD (Windows) not using the sc.ini
file correctly. The utility now explicitly adds any DFLAG options from
the sc.ini file into the .rsp file.
)
$(ITEM ** $(B FIX): The utility now correctly handles ';' delimited DFLAG options
in the sc.ini file.
)
$(ITEM ** $(B ENH): Now supports the use of 'response' files on the command line
)
$(ITEM ** $(B ENH): Now supports the -T command line switch to supply an
 alternate tareget name.
)
)

$(SUBSECTION_H ,v1.2 -- 21/Feb/2005)
$(LIST
$(ITEM ** $(B ENH): $(I Thanks to Anders F Bjoerklund:) Added better support for 'darwin'
       and 'gdc'.
)
)
)
Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for bud
 Product = bud Utility
