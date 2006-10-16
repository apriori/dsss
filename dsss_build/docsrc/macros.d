Ddoc

$(TOPIC_H macros,Macros)
$(SECTION
The $(I macro) system in $(I Bud) works by transforming the contents of a file,
via the use of special commands, into a new file that will be
compiled.
$(BL)
The macro system is fairly restricted for now but a much more powerful
facility will be available in subsequent releases of $(I Bud). However, in spite
of this, a lot can be achieved by the current macro facility.
$(BL)
)

$(SECTION $(B How it Works)$(BR)
$(I Bud) firstly examines the default Macro Definition File $(PAREN MDF)
and preprocesses
the defined special commands in preparation for any macro files it may be
presented with. Next, whenever it encounters a macro file on the command
line or response file, it transforms the macro file, based on the commands
from the $(B MDF) and any embedded commands, into a file that is later compiled.
)

$(SECTION $(B Macro Definition File)$(BR)
The format of the MDF is a text file that can contain any number of
defined commands and comments. Comments start with a $(B #)
$(PAREN hash symbol) and extend to the end of the line. Blank lines
are ignored also. Commands take the form ... $(BR)
    $(INDENT
        $(B $(ANG action)$(S)$(ANG pattern)$(S)=$(S)$(ANG replacement))
    )
where $(ANG action) can be
    $(LIST
        $(ITEM replace)
        $(ITEM regexp)
     )
)
$(SECTION $(LINE) The action $(QUOTE $(B replace)) will replace all occurances of
$(B $(ANG pattern)) with the $(B $(ANG replacement)) text. The $(ANG pattern)
can take two forms: a quoted string, or an unquoted set of words. If the
pattern is enclosed in quotes it represents a literal string of characters
to be replaced wherever it is found in the macro file. If the pattern is
not enclosed in quotes it represents a set of adjacent words to be found
and replaced by the replacement text.
$(EXAMPLE Word replacement,
replace end$(S)proc$(S)=$(S)}
)
will match $(QUOTE $(S)end$(S)proc$(S)) and $(QUOTE $(S)end$(S)$(S)$(S)proc$(S)),
but will not match any of $(QUOTE $(S)bend$(S)proc$(S)),
$(QUOTE $(S)end$(S)procedure$(S)), or $(QUOTE $(S)end.proc$(S) ).

$(EXAMPLE Text replacement,
replace "end$(S)proc"$(S)=$(S)}
)
will match any of $(QUOTE end$(S)proc), $(QUOTE bend$(S)proc),
$(QUOTE end$(S)procedure),
but will not match $(QUOTE end$(S)$(S)$(S)proc) or
$(QUOTE end.proc )
$(BL)
The $(ANG replacement) text will have to be quoted if it must begin or end
with spaces.
$(EXAMPLE Leading and trailing blanks in replacement text,
replace vernote$(S)=$(S)"$(S)$(S)$(S)Version$(S)1.0,$(S)"
)
)

$(SECTION $(LINE) The action $(QUOTE $(B regexp)) will replace all occurances of
$(B $(ANG pattern)) with the $(B $(ANG replacement)) text. The $(ANG pattern)
is a regular expression.

$(EXAMPLE Regular Expression replacement,
regexp inc\s+(\w+) = $(DOLLAR)1++
)
will match "inc" followed by one or more spaces followed by one or more
'word' characters such as $(QUOTE inc$(S)$(S)myvar) and replace the matching
pattern with the word in the pattern followed by "++". In this case it would
be replaced by $(QUOTE myvar++).

$(EXAMPLE C-style assert,
regexp assert\((.*),(.*)\); = if (!($1)) {writefln(`%%s:%%s`, `$1`, $2); assert(0);}
// usage
assert(somefield > 3, "More than 4 is required");
// transformation
if (!(somefield > 3)) {writefln(`%s:%s`, `somefield > 3`, "More than 4 is required"); assert(0);}
)

$(BL)
The $(ANG replacement) text will have to be quoted if it must begin or end
with spaces.
$(EXAMPLE Leading and trailing blanks in replacement text,
regexp (Version\s)(\?) = "$(S)$(S)$(S)$(DOLLAR)1$(S)5.0"
)
)

$(SECTION $(LINE) There are some special tokens that can be in the
replacement text.
$(TABLE
$(ROW $(CELL \n) $(CELL New Line) $(CELL An end-of-line marker replaces this token.) )
$(ROW $(CELL \t) $(CELL Tab) $(CELL A tabulator character (ASCII 09) replaces this token.) )
$(ROW $(CELL \s) $(CELL Conditional Space) $(CELL If the previous output character
                                               is not a space then a space
                                               character replaces this token
                                               otherwise the token is removed.) )
)
)

$(SECTION $(LINE) Sometimes, it will be necessary to have one of the
delimiter characters, such as the $(I quote) character
or the $(I equals) symbol, as a part of the pattern or replacement text.
In order to allow this, the MDF can contain override commands that specify
alternatives to use for the rest of the MDF or another override. $(BL)
The override command has the format $(BR)
    $(INDENT
        $(B delim$(S)$(ANG type)$(S)=$(S)$(ANG alternative))
    )
where $(ANG type) can be
    $(TABLE
      $(THEAD
        $(ROW $(THCELL $(B Type))        $(THCELL Description) $(THCELL Example) $(THCELL Default))
      )
        $(ROW $(CELL $(B open))          $(CELL Begins a pattern or replacement text) $(CELL open=<) $(CELL "))
        $(ROW $(CELL $(B close))         $(CELL Ends a pattern or replacement text) $(CELL close=>) $(CELL "))
        $(ROW $(CELL $(B escapeopen))    $(CELL Begins a special token ) $(CELL escapeopen=%) $(CELL \ ))
        $(ROW $(CELL $(B escapeclose))   $(CELL Ends a special token) $(CELL escapeclose=%) $(CELL ))
        $(ROW $(CELL $(B comment))       $(CELL Defines the comment leading text) $(CELL comment=;) $(CELL #))
        $(ROW $(CELL $(B equate))        $(CELL Defines the 'equals' symbol) $(CELL equate=:) $(CELL =))
     )

Another form of the $(B delim) command is $(BR)
    $(INDENT
        $(B delim$(S) std)
    )
which restores all the default delimiter values.
)
$(SECTION $(LINE)
All the commands above can be embedded inside a macro file. To do this,
the commands must be prefixed with an $(B '@' ) symbol and start on
first column.
$(EXAMPLE ,
@replace becos because
)
Additionally there is another command that is only recognized when embedded
in a macro file. This is the $(B output) command. It tells $(I Bud) what
name to use for the transformed file.
$(EXAMPLE Send output to another file,
@output ../result/mytest.d
)
If the $(B output) command is not found in a file, the transformed file
is assumed to tbe the same name as the macro file but with ".d" as
the extension. In other words, "test.mac" when transformed becomes "test.d".
$(BL)
It is important to note that $(B all) embedded macro commands are removed from
the transformed file and that no embedded macro command can modify any other
embedded macro command.
)

Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for Bud
 Product = $(I Bud) Utility
 ROW     = <tr class="macrorow">$0</tr>
 THEAD   = <thead class="macrothead">$0</thead>
 THCELL = <td class="macrothcell">$0</td>
 CELL   = <td class="macrocell">&nbsp;$0&nbsp;</td>
