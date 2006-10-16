Ddoc

$(TOPIC_H profile_file,Profile File)
$(SECTION
The utility's profile is used to specify various values
for the utility. The file is called $(B build.pfl). You can have from zero
to three profile files because the $(I Bud) utility looks in each
of three places for a profile file, and it uses each one that it finds.
It looks in the folder that $(I Bud) is installed, then in the folder
that the compiler is installed, and finally in the current folder.
$(BL)
The profile file consists of one or more command lines.
Each command line is specified in a single text line, but you can have any
number of command lines in the configuration file.

$(B Supported Commands) $(BR)
The commands currently supported are ... $(BR)
$(B  CMDLINE )$(BR)
You can specify all command line switch values with this configuration
option. You can also specify multiple switches on the same option line.
$(CODE
CMDLINE=-inline -w
)


$(B Environment Symbol Substitution) $(BR)
Before each configuration file option line is processed, it is first checked
for any references to Environment symbols. Each reference is replaced by
the value of that symbol. References take the form $(B %$(ANG SYMNAME)%)
$(BR)
There are two special symbols: $(B @D) is replaced by the compiler's
path, and $(B @P) is replaced by the compiler's configuration file's path.

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
$(B Comments) $(BR)
You may place comments in a configuration file. A comment starts
 with a $(B #) character and extends to the end of the line.
$(BL)
Blank lines are ignored.

$(EXAMPLE ,
build myapp.d +final
)
where if a group called '[final]' is contained in any configuration
file, the options in that group are used.

$(EXAMPLE contents of [final],
    # This creates a production (release) edition of the app.
    [final]
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
