Ddoc

$(TOPIC_H introduction,Introduction)
$(SECTION
This is a utility to build an application using the D programming language.
It does this by examining the files supplied on the command line
to work out what are the dependant files, and then determines which
source files need to be compiled, which macro files need to be transformed,
which resource files need to be generated, and which object files and
libraries need to be linked to create the executable.

Alternatively, it can be used to create a Library file rather than an
 executable.

The aim of the utility is to help remove the need for $(I make) files
 or similar devices.
)

Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for BUILD
 Product = Build Utility
