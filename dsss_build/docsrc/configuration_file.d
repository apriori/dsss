Ddoc

$(TOPIC_H configuration_file,Configuration File)
$(SECTION
The utility's configuration file is used to specify your default options
for the utility. The file is called $(B build.cfg). You can have from zero
to four configuration files because the $(I Bud) utility looks in each
of four places for a configuration file, and it uses each one that it finds.
It looks in the folder that $(I Bud) is installed, then in a user defined
alternative path (defined by -BCFPATH switch), then in the folder
that the compiler is installed, and finally in the current folder.
$(BL)
$(B Note:) The alternative location is optional. It can be specified in
an environment switch called BCFPATH or in a command line switch
of the same name, -BCFPATH.
$(BL)
The configuration file consists of one or more command lines.
Each command line is specified in a single text line, but you can have any
number of command lines in the configuration file.
$(BL)
The command lines take the form of
$(CODE
$(ANG COMMAND)=$(ANG VALUE)
)

$(B Supported Commands) $(BR)
The commands currently supported are ... $(BR)
$(B  CMDLINE )$(BR)
You can specify all command line switch values with this configuration
option. You can also specify multiple switches on the same option line.
$(CODE
CMDLINE=-inline -w
)

$(B LIBCMD) $(BR)
This specifies the location and program name for the librarian application
you want to invoke when creating libraries.
$(CODE
   LIBCMD=D:\Applications\dm\bin\lib.exe
)

$(B LINKCMD) $(BR)
This specifies the location and program name for the linker application
you want to invoke when creating executables.
$(CODE
   LINKCMD=ld
)

$(B LINKSWITCH) $(BR)
This specifies the default set of switches passed to the linker. If this
command is not in the configuration file, the built-in default is "/noi"
when using the DMD linker.
$(CODE
LINKSWITCH=/info
)

$(B FINAL) $(BR)
This specifies a command that will run after the target has been
successfully created. There can be any number of $(I FINAL) commands
in a configuration file; they are all executed, and in the order presented.
$(BL)
You can place special tokens in the $(I FINAL) command line and these will
be replaced just before running the command line.
$(TABLE
  $(THEAD
     $(THCELL Token) $(THCELL Replacement)
   )
   $(ROW
    $(CELL $(B $(BRACE Target))) $(CELL The full path and name of the target file created)
    )
   $(ROW
    $(CELL $(B $(BRACE TargetPath))) $(CELL The path of the target file created)
    )
   $(ROW
    $(CELL $(B $(BRACE TargetBase))) $(CELL The name of the target file created)
    )
)
$(CODE
FINAL="c:\program files\upx202w\upx" --best -q {Target} >nul
)

$(B INIT:) $(BR)
This specifies an internal string value. The format is actually
$(I INIT:$(B stringname)) where $(I stringname) identifies the specific
internal string to set.
$(CODE
   INIT:MapSwitch = -M
)
$(INDENT
$(SECTION The identifiers for the settable strings are detailed below.)
$(TABROW ExeExtension, The file extension for executable files. $(EG exe))
$(TABROW LibExtension, The file extension for library files.$(EG lib))
$(TABROW ObjExtension, The file extension for object files.$(EG obj))
$(TABROW ShrLibExtension, The file extension for shared libraries files.$(EG dll))
$(TABROW SrcExtension   , The file extension for D source files.$(EG d))
$(TABROW MacroExtension ,  The file extension for macro files.$(EG mac))
$(TABROW DdocExtension  , The file extension for D Documentation files.$(EG ddoc))
$(TABROW CompilerExe    , The file name of the compiler.$(EG dmd.exe))
$(TABROW CompileOnly    , The switch that is passed to the compiler to tell
                          it not to link, just compile the files instead.$(EG -c))
$(TABROW LinkerExe      , The file name of the linker.$(EG link.exe))
$(TABROW ConfigFile     , The name of the compiler's configuration file. $(EG sc.ini))
$(TABROW CompilerPath   , If the compiler is not in the standard search PATH,
                          this specifies the location of the compiler. $(EG F:\dmd\bin))
$(TABROW ConfigPath     , This will specify where to look for the compiler's
                          configuration file. It overrrides the default
                          places to look for it. $(EG D:\configarea))
$(TABROW LinkerPath     , If not overriden by any LINKCMD=
                          option found in the compiler's configuration file,
                          this specifies the location of the linker.
                          $(EG F:\dm\bin)
                          $(BR)If this empty and there is no LINKCMD= found,
                          the linker is assumed to be in the same place as the
                          compiler.
                          )
$(TABROW LinkerDefs     , The default set of switches for the linker. These are
                          applied to every link run. $(EG /noi /map))
$(TABROW LibPaths       , The default set of paths used by the linker to
                          scan for library files. $(EG C:\mylibs;c:\dfl))
$(TABROW ConfigSep      , The delimiter used to separate paths in the
                          $(I LibPaths) list. $(EG ;))
$(TABROW Librarian      , The name of the librarian tool. $(EG lib.exe ))
$(TABROW LibrarianOpts  , The default switches that are always passed to
                          the librarian tool. $(EG -c -p256))
$(TABROW VersionSwitch  , The switch that sets a $(I version) symbol for the
                          compiler. $(EG -version))
$(TABROW DebugSwitch    , The switch that sets a $(I debug) symbol for the
                          compiler. $(EG -debug))
$(TABROW CompilerDefs   , The default switches that are always passed to
                          the compiler. $(EG -op)
                          $(BR) Note that in the DigitalMars environment if
                          you don't specify any CompilerDefs, "-op" is
                          assumed.)
$(TABROW OutFileSwitch  , The switch tells $(I Bud)
                          where to create the executable file. $(EG -of))
$(TABROW ImportPath     , This is the switch for the compiler to tell it where
                          to search for imported modules. $(EG -I))
$(TABROW LinkLibSwitch  , This is the switch for the linker to tell it
                          a library to use. $(EG -l))
$(TABROW LibPathSwitch  , This is the switch for the linker to tell it
                          where to search for the libraries. $(EG -L))
$(TABROW MapSwitch      , This is the switch for the linker to tell it
                          to create a map file. Note that the DigitalMars
                          linker does not have a switch for this function.
                          $(EG -M))
$(TABROW SymInfoSwitch  , This is the switch for the linker to tell it
                          to insert symbolic debugging information into
                          the executable.$(EG /co))
$(TABROW BuildImportPath, This is the switch for $(I Bud) to tell it
                          a path to scan for imported modules. $(EG -I))
$(TABROW ImportPathDelim, This is the switch for $(I Bud) to tell it
                          which character is used to delimit paths on
                          a BuildImportPath list. $(EG ;))
$(TABROW OutputPath     , This is the switch for $(I Bud) to tell it
                          the path to use for all temporary output files. $(EG -od))
$(TABROW RunSwitch      , This is the switch for $(I Bud) to tell it
                          to run the application once it successfully
                          compiles. $(EG -exec))
$(TABROW LibrarianPath  , This is the default path where build will run
                          the librarian tool from. It will be overridden
                          by a 'LIBCMD=' in the configuration file or
                          on the commandline. $(EG c:\tools\))
$(TABROW ResponseExt    , This is the file extension that $(I Bud) will use
                          for its response files. $(EG brf))
$(TABROW DefResponseFile, This is the name of the $(I Bud) default
                          response file. $(EG build.brf))
$(TABROW RDFName        , This is the name of the $(I Bud) default
                          Rules Definition File. $(EG default.rdf))
$(TABROW DefMacroDefFile, This is the name of the $(I Bud) default
                          Macro Definition File. $(EG build.mdf))
$(TABROW LinkerStdOut   , This is the commandline option given to the linker
                          when the $(I Bud) commandline has the $(I "-silent")
                          switch. $(EG >nul))
$(TABROW IgnoredModules , This is a comma delimited list of modules or packages
                          to ignore. $(I Bud) will not scan these modules and
                          packages for dependancies. $(EG std,dfl,dui)
                          If none is specified by this configuration item then
                          'phobos' is assumed.)
$(TABROW AssumedLibs    , This is a comma delimited list of libraries that
                          are passed to the linker. $(EG dfl,mt) $(BL)
                          If the application being compiled has a WinMain
                          function or is otherwise identified as a Windows
                          application then the following are automatically
                          passed to the linker. $(BR)
                          $(LIST
                                $(ITEM gdi32.lib)
                                $(ITEM advapi32.lib)
                                $(ITEM COMCTL32.LIB)
                                $(ITEM comdlg32.lib)
                                $(ITEM CTL3D32.LIB)
                                $(ITEM kernel32.lib)
                                $(ITEM ODBC32.LIB)
                                $(ITEM ole32.lib)
                                $(ITEM OLEAUT32.LIB)
                                $(ITEM shell32.lib)
                                $(ITEM user32.lib)
                                $(ITEM uuid.lib)
                                $(ITEM winmm.lib)
                                $(ITEM winspool.lib)
                                $(ITEM wsock32.lib)
                          )
                          $(BL)
                          If the application is being compiled in a Unix
                          environment then the following are automatically
                          passed to the linker. $(BR)
                          $(LIST
                                $(ITEM c)
                                $(ITEM phobos)
                                $(ITEM m)
                          )
)
$(TABROW PathId         , The name of the environment symbol used by $(I Bud)
                          when scanning for executables. $(EG PATH))
$(TABROW HomePathId     , The name of the environment symbol used by $(I Bud)
                          when scanning for configuration file. $(EG HOME))
$(TABROW EtcPath        , The name of an alternative path used by $(I Bud)
                          when scanning for configuration file. $(EG c:\etc\))
$(TABROW GenDebugInfo   , The switch that tells $(I Bud) and the compiler
                          to insert debugging information into the object
                          files. $(EG -g))
$(TABROW ModOutPrefix   , If the $(I Bud) switch $(I $(QUOTE -modules)) was
                          used, this defines the string which $(I Bud) will
                          begin the Modules List output file with.
                          $(EG  MODULES = \n))
$(TABROW ModOutSuffix   , If the $(I Bud) switch $(I $(QUOTE -modules)) was
                          used, this defines the string which $(I Bud) will
                          end the Modules List output file with.
                          $(EG  ))
$(TABROW ModOutBody     , If the $(I Bud) switch $(I $(QUOTE -modules)) was
                          used, this defines the string which $(I Bud) will
                          use as a template for each module being listed.
                          $(EG     $(DOLLAR)(MODULE {mod})) $(BL)
                          Note that {mod} will be replaced with the module's
                          name and {src} will be replaced with the source
                          file's name.)
$(TABROW ModOutDelim    , If the $(I Bud) switch $(I $(QUOTE -modules)) was
                          used, this defines the string which $(I Bud) will
                          insert in between each listed module.
                          $(EG \n))
$(TABROW ModOutFile     , If the $(I Bud) switch $(I $(QUOTE -modules)) was
                          used, this defines the output file's suffix. This
                          is only used if the $(I $(QUOTE -modules)) switch
                          did not specify an exact file name to use. In which
                          case the Target name is used as a prefix and this
                          string as the suffix.
                          $(EG _modules.ddoc  ))

$(TABROW ArgDelim       , This value will be the delimiter for file groups
                          on the linker command line. A file group is a set
                          of like filetypes such as $(I objects) or $(I libraries)
                          $(EG $(COMMA) ))
$(TABROW ArgFileDelim   , This value will be the delimiter for files within
                          a file group on the linker command line. A file group is a set
                          of like filetypes such as $(I objects) or $(I libraries)
                          $(EG + ) )
$(TABROW PostSwitches   , If 'yes' this causes linker switches to go after
                          all the other command line entries, otherwise the
                          switches precede them.
                          $(EG Yes ) )
$(TABROW AppendLinkSwitches, If 'yes' this causes linker switches to be
                          appended to the last item on the command line
                          otherwise there will be a gap between the last
                          item and the first switch.
                          $(EG Yes ) )
)

$(EXAMPLE ,
INIT:MacroExtension = bmc
INIT:LinkerPath = /u2/qwerty/
INIT:AssumedLibs = c,kde,mgui
)

$(B Default Values for Configuration Items)
$(TABLE
  $(THEAD
    $(THCELLS $(I INIT:) item,DigitalMars-Windows,GDC-Windows,DigitalMars-Unix,GDC-Unix)
  )
  $(ROW  $(CELLS ExeExtension,exe,exe,,))
  $(ROW  $(CELLS LibExtension,lib,lib,a,a))
  $(ROW  $(CELLS ObjExtension,obj,obj,o,o))
  $(ROW  $(CELLS ShrLibExtension,dll,dll,s,s))
  $(ROW  $(CELLS SrcExtension,d,d,d,d))
  $(ROW  $(CELLS MacroExtension,mac,mac,mac,mac))
  $(ROW  $(CELLS DdocExtension,ddoc,ddoc,ddoc,ddoc))
  $(ROW  $(CELLS CompilerExe,dmd.exe,gdc.exe,dmd,gdc))
  $(ROW  $(CELLS CompileOnly,-c,-c,-c,-c))
  $(ROW  $(CELLS LinkerExe,link.exe,gdc.exe,gcc,gdmd))
  $(ROW  $(CELLS ConfigFile,sc.ini,,dmd.conf,))
  $(ROW  $(CELLS ConfigPath,,,,))
  $(ROW  $(CELLS CompilerPath,,,,))
  $(ROW  $(CELLS LinkerPath,,,,))
  $(ROW  $(CELLS LinkerDefs,/noi/map,,,))
  $(ROW  $(CELLS LibPaths,,,,))
  $(ROW  $(CELLS ConfigSep,;,;,:,:))
  $(ROW  $(CELLS Librarian,lib.exe,ar.exe,ar,ar))
  $(ROW  $(CELLS LibrarianOpts,-c -p256,-c,-r,-r))
  $(ROW  $(CELLS VersionSwitch,-version,-fversion,-version,-fversion))
  $(ROW  $(CELLS DebugSwitch,-debug,-fdebug,-debug,-fdebug))
  $(ROW  $(CELLS OutFileSwitch,-of,$(QUOTE -o ),-of,$(QUOTE -o )))
  $(ROW  $(CELLS ImportPath,-I,$(QUOTE -I ),-I,$(QUOTE -I )))
  $(ROW  $(CELLS LinkLibSwitch,-l,-l,-l,-l-L))
  $(ROW  $(CELLS LibPathSwitch,-L,-L,-L,-L))
  $(ROW  $(CELLS MapSwitch,-M,-M,-M,-M))
  $(ROW  $(CELLS SymInfoSwitch,/co,/co,/co,/co))
  $(ROW  $(CELLS BuildImportPath,-I,-I,-I,-I))
  $(ROW  $(CELLS ImportPathDelim,;,;,;,;))
  $(ROW  $(CELLS OutputPath,-od,-od,-od,-od))
  $(ROW  $(CELLS RunSwitch,-exec,-exec,-exec,-exec))
  $(ROW  $(CELLS LibrarianPath,,,,))
  $(ROW  $(CELLS ResponseExt,brf,brf,brf,brf))
  $(ROW  $(CELLS DefResponseFile,build.brf,build.brf,build.brf,build.brf))
  $(ROW  $(CELLS RDFName,default.rdf,default.rdf,default.rdf,default.rdf))
  $(ROW  $(CELLS DefMacroDefFile,build.mdf,build.mdf,build.mdf,build.mdf))
  $(ROW  $(CELLS LinkerStdOut,>nul,>nul,>/dev/null,>/dev/null))
  $(ROW  $(CELLS IgnoredModules,,,,))
  $(ROW  $(CELLS AssumedLibs,,,,))
  $(ROW  $(CELLS PathId,PATH,PATH,PATH,PATH))
  $(ROW  $(CELLS ModOutPrefix,$(QUOTE MODULES = \n),$(QUOTE MODULES = \n),$(QUOTE MODULES = \n),$(QUOTE MODULES = \n)))
  $(ROW  $(CELLS ModOutSuffix,,,,))
  $(ROW  $(CELLS ModOutBody,$(QUOTE     $(DOLLAR)(MODULE {mod})\n),$(QUOTE     $(DOLLAR)(MODULE {mod})\n),$(QUOTE     $(DOLLAR)(MODULE {mod})\n),$(QUOTE     $(DOLLAR)(MODULE {mod})\n)))
  $(ROW  $(CELLS ModOutDelim,,,,))
  $(ROW  $(CELLS ModOutFile,_modules.ddoc,_modules.ddoc,_modules.ddoc,_modules.ddoc))
  $(ROW  $(CELLS GenDebugInfo,-g,-g,-g,-g))
  $(ROW  $(CELLS CompilerDefs,,,-version=Posix,-fversion=Posix))
  $(ROW  $(CELLS HomePathId,HOME,HOME,HOME,HOME))
  $(ROW  $(CELLS EtcPath,,,/etc/,/etc/))
  $(ROW  $(CELLS ArgDelim,$(COMMA),,,))
  $(ROW  $(CELLS ArgFileDelim,+,,,))
  $(ROW  $(CELLS PostSwitches,Yes,No,No,No))
  $(ROW  $(CELLS AppendLinkSwitches,Yes,No,No,No))
)

$(B Environment Symbol Substitution) $(BR)
Before each configuration file option line is processed, it is first checked
for any references to Environment symbols. Each reference is replaced by
the value of that symbol. References take the form $(B %$(ANG SYMNAME)%)
$(BR)
There are three special symbols: $(B @D) is replaced by the compiler's
path, $(B @P) is replaced by the compiler's configuration file's path,
and $(B %%) is replaced by a single $(B %) character and can be used
to avoid an unwanted environment symbol substitution.

$(EXAMPLE Assuming you had set BUILDOPTS=-w -g,
CMDLINE=%BUILDOPTS%    # Allow switches to be passed via enviroment symbol.
)
would mean that "-w -g" would be automatically placed on the utility's
commandline whenever you ran it.
$(BL)
$(B Groups) $(BR)
It is possible to specify groups of configuration options that are only
applied if explictly nominated on the command line. A group starts with
a line in the format $(B [$(ANG groupname)]) where $(I groupname) can be any
text that doesn't include spaces. A group ends on the last line before the
next group in the file.

$(EXAMPLE a Group,
   [dbg] # To produce a debug edition of an application.
   CMDLINE=-unittest
   CMDLINE=--release
   CMDLINE=--inline
   CMDLINE=-g
   CMDLINE=-w
   CMDLINE=-full
   CMDLINE=-T{Target}_{Group}
)

All the options lines before the first group are known as the default
options because these are always applied. To apply the options in a group
you need to specify which group(s) you want on the command line, or via
a $(EXDEF response_file, response file). The group name is prepended with a plus sign on
the command line. To apply the 'debug' group in the above example, you
place on the command line $(B +dbg)
$(BL)
There are few optional predefined group names that are used when building
for specific environments.
$(INDENT
    $(CITE
        $(SQR Windows)
        # items that only apply when building in Windows.

        $(SQR Posix)
        # items that only apply when building in Posix (unix).

        $(SQR darwin)
        # items that only apply when building in Macintosh Darwin (OS X).

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
These groups are automatically used when building in the appropriate
enviroments and do not explicitly have to be mentioned on the command line.
$(BL)
$(B Comments) $(BR)
You may place comments in a configuration file. A comment starts
 with a $(B #) character and extends to the end of the line.
$(BL)
Blank lines are ignored.

$(EXAMPLE ,
build myapp.d +production
)
where if a group called '[production]' is contained in any configuration
file, the options in that group are used.

$(EXAMPLE contents of [production],
    # This creates a production (release) edition of the app.
    [production]
    CMDLINE=-T{Target}_{Group}  # Set the name of the executable.
    CMDLINE=-release   # Don't generate runtime checks.
    CMDLINE=-full      # Force compilation of all files.
    CMDLINE=-cleanup   # remove work files when completed
    CMDLINE=-inline    # Allow inlining to occur
    CMDLINE=--debug*   # Turn off any debug switches
    CMDLINE=--unittest # Turn off any unittest switches
    CMDLINE=--w        # Turn off warnings
    CMDLINE=--g        # Turn off embedded debug symbolic info.
)

You can any number of configuration file group references on a command line. They
 are processed in the order they appear.
)


Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for Bud
 Product = $(I Bud) Utility
 EG    = <span class="eg">Example: "$0"</span>
 MYTITLE = $(Title)
 TABLE   = <table class="conftab">$0</table>
 THEAD   = <thead class="confthead">$0</thead>
 ROW     = <tr class="confrow">$0</tr>
 THCELLS = <td class="confthcell">$1</td><td class="confthcell">$2</td><td class="confthcell">$3</td><td class="confthcell">$4</td><td class="confthcell">$5</td>
 CELLS   = <td class="confcell"><strong>$1</strong>&nbsp;</td><td class="confcell">$2&nbsp;</td><td class="confcell">$3&nbsp;</td><td class="confcell">$4&nbsp;</td><td class="confcell">$5&nbsp;</td>
