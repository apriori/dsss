Ddoc

$(TOPIC_H rule_definition_file, Rule Definition File)
$(SECTION
This file holds the definitions of the rules used to create files
using tools other than the D compiler.
$(BL)
This feature is not as advanced as the typical $(B makefile) abilities but is
useful for simple situations. Specifically, it only caters for
tools that take a single input file to create the required output file.
$(BL)
The default Rule Definition File is called $(QUOTE default.rdf) but this
can be changed in the $(EXREF configuration_file.html, Configuration File).
If you don't specify a full path to the file, $(I Bud) searches for it.
It first first looks in the directory where $(I Bud) is installed, and if
it is not found there, the scans throught the directories in the
PATH environment symbol.
$(BL)
The default RDF can also be overridden by the -RDF command line switch.
$(BL)
The Rule Definition File is a text file that contains one or more $(I rules).
Each rule is defined in a set of lines. The first line in a
$(I rule) $(B must) be the $(QUOTE rule=) line.

$(TABLE
  $(THEAD
     $(THCELL Keyword) $(THCELL Mandatory?) $(THCELL Usage)
  )
  $(ROW
     $(CELL rule=$(ANG name)) $(CELL Yes) $(CELL Defines the name of this rule.)
     )
  $(ROW
     $(CELL tool=$(ANG command pattern)) $(CELL Yes) $(CELL Defines the command line to use.)
     )
  $(ROW
     $(CELL in=$(ANG extension)) $(CELL No) $(CELL Specifies the file type (extension) of the input file)
     )
  $(ROW
     $(CELL out=$(ANG extension)) $(CELL No) $(CELL Specifies the file type (extension) of the output file)
     )
  $(ROW
     $(CELL in_use=$(ANG usage code)) $(CELL No)
                      $(CELL Specifies what to do with the input file
                            after the tool has run. The $(ANG usage code) can be one of
                            $(QUOTE compile), $(QUOTE link), or $(QUOTE ignore).
                            The default if not specified is $(QUOTE ignore).)
    )
  $(ROW
     $(CELL out_use=$(ANG usage code)) $(CELL No)
                      $(CELL Specifies what to do with the output file
                            after the tool has run. The $(ANG usage code) can be one of
                            $(QUOTE compile), $(QUOTE link), or $(QUOTE ignore).
                            The default if not specified is $(QUOTE link).)
  )
)
$(BL)
Any other line in the file, not starting with one of the above keywords
is simply ignored (treated as comments).
$(BL)
The $(QUOTE tool=$(ANG command pattern)) line can contain special tokens.
These are keywords enclosed
in braces. At compile time, the tokens are replaced by replacement text
taken from the $(B pragma(build)) statement that invoked the rule. In addition,
$(I Bud) also generates some reserved tokens.
$(TABLE
$(THEAD
$(ROW $(THCELL Reserved Token) $(THCELL Usage))
)
$(ROW $(CELL @IN) $(CELL the name of the input file))
$(ROW $(CELL @OUT) $(CELL the name of the output file))
$(ROW $(CELL @IBASE) $(CELL the basename* of the input file.))
$(ROW $(CELL @OBASE) $(CELL the basename* of the output file.))
$(ROW $(CELL @IPATH) $(CELL the path of the input file.))
$(ROW $(CELL @OPATH) $(CELL the path of the output file.))
)
$(NOTE *This is everything up to but not including the final '.' character in the name.)
$(I Bud) ensures that the outfile's path will exist before the tool
is run.
$(EXAMPLE Sample RDF,
----- Windows Resource Compiler --------
This uses pragma( $(B build), "$(ANG sourcefile).rc");
$(DASHES)$(DASHES)$(DASHES)$(DASHES)
rule=Resources
in=rc
out=res
tool=rc /r {@IN} /fo {@OUT}

----- DMD C linkage --------------------
This uses pragma( $(B build), "$(ANG sourcefile).c", "COPT=$(ANG options)", "HDR=$(ANG whatever)");
$(DASHES)$(DASHES)$(DASHES)$(DASHES)
rule=DMD C/C++
in=c
out=obj
tool=dmc -c {COPT} {@IN} -o{@OUT} {HDR}
)

)


Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for Bud
 Product = $(I Bud) Utility
