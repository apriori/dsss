Ddoc

$(TOPIC_H autobuild,Automatic build number)
$(SECTION
Automatically incremented build numbering for Modules
You can optionally specify that the $(I build) utility automatically
increments a build number for any module. You do this by supplying
 a single line in your source code in the form ... $(BR)
$(CODE
private import $(ANG $(B modulename))_bn;
)
Typically this line is placed immediately after the source file's
$(B module) statement, but that is not strictly necessary.

By having this line in your code, $(I build) then uses a file with the
 suffix "_bn.d" to maintain
the current build number for the $(ANG modulename). Note that $(I build)
 will create this file if it doesn't exist. Also note that
 $(I build) will update this file whenever the module file has been
 updated or its object file needs to be rebuilt, so you really
shouldn't modify it manually. Any manual changes will be deleted
 by $(I build). $(BR)

$(EXAMPLE
If your module is called "parser.d" you would have the lines ...,
module parser;
private import parser_bn;
)

You can access the build number from within the module thus ... $(BR)

$(CODE
writefln("The application build number is %d", auto_build_number);
)
You can access the build numbers of other modules in you application
 by importing the appropriate file and prefixing the references with
 the module names. $(BR)

$(EXAMPLE ,
module parser;  /// This module's name.
private import parser_bn;   /// This module's B/N
private import tokenizer_bn; /// Another module's B/N
. . .
writefln("Builds...");
writefln("  Parser %d", parser_bn.auto_build_number);
writefln("  Tokens %d", tokenizer_bn.auto_build_number);
)

The "_bn.d" file created by $(I build) for this module would look like ... $(BR)
$(CODE
module parser_bn;
/// This file is automatically maintained by the Bud utility,
/// Please refrain from manually editing it.
long auto_build_number = 77;
)

Of course the number $(I 77) is just an example. This number would actually
 start at 1 and increment whenever $(I Bud) needed to create a new object
file for the module.
)


Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for Bud
 Product = Bud Utility
