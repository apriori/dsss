Ddoc

$(TOPIC_H todo,Things Still To Do)
$(SECTION
Ideas that have yet to be implemented.
Note that some of these may never be implemented but they are still
listed here as a reminder.

$(LIST
    $(ITEM Be able to update a library rather than just create libraries.)
    $(ITEM Support the concept of a 'Plugin' block of code.

    $(CODE
version (build) pragma(plugin, $(ANG tool)[,delim=xxx],[, $(ANG parms)] ) { [body] }
    )
    This block would be replaced by the stdout data of calling 'tool $(ANG params)' and
    sending it the content of $(ANG body) via stdin.
    )
    $(ITEM Support limited preprocessor capability.
    Something like pragma(macro, $(ANG preprocessor commands)); and replacing
    source text of the form @{tokenname}@ with the value of the token.
    )
    $(ITEM To specify compiler command line
    options inside the source code by using a the new pragma COMPILE_OPTS.
    In this case, it will compile the source that contains this pragma
    as a separate step using the supplied options in the pragma statement.
    )
)
)


Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for BUILD
 Product = Build Utility
