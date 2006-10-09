Ddoc

$(TOPIC_H response_file,Response File)
$(SECTION
A response file is a file that contains command line values.
$(BL)
You can specify all or any command line values in a
response file. Each value appears in its own line in the
response file and you reference this file by prefixing
its name with an '@' symbol on the command line.
$(BL)
You may place comments in a response file. A comment starts
 with a $(B #) character and extends to the end of the line.

$(EXAMPLE ,
   build @final
)
where a file called 'final.brf' contains the command
line values, including other response file references.

$(EXAMPLE contents of final.brf,
# This creates a production (release) edition of the app.
-T{Target}_release  # Set the name of the executable.
-release   # Don't generate runtime checks.
-full      # Force compilation of all files.
-cleanup   # remove work files when completed
-inline    # Allow inlining to occur
)

The command line for your build could then look like ...
$(CODE
    build myapp @final
)

If the response file reference is just a single '@' then
 build looks for a file called 'build.brf'
$(BL)
You can any number of response file references on a command line. They
 are processed in the order they appear.
)



Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for BUILD
 Product = Build Utility
