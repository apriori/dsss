Ddoc

$(TOPIC_H pragmas,Pragmas)
$(SECTION
The $(B build) utility supports the use of various pragma statements.
A pragma is a special statement embedded in the source code that
 provides information to tools reading the source code.

They take the forms ...
$(CODE
$(B pragma$(LP)) $(ANG name) $(B $(RP);)
$(B pragma$(LP)) $(ANG name) $(B ,) $(ANG option) $(SQR $(B ,) $(ANG option)) $(B $(RP);)
)

If the D compiler doesn't recognise the pragma, it will fail. So to
'hide' them from the compiler, you need to wrap them in a $(B version)
block. All the pragmas used by this utility need to be enclosed in
a $(I build) version.

$(EXAMPLE ,
$(I version)(build) { pragma(nolink); }
)
)



$(SECTION
$(SECTION_H pragma_link,pragma: link)
This nominates one or more libraries that are required to be linked in.
If your applications needs code from a library to be linked in, rather than
supplying source code, you can tell $(I build) which libraries are needed.
This can happen when using a library provided by a third-party.

$(EXAMPLE 1,
// This app needs the MyGUI.lib library to be used.
version(build) { pragma(link, MyGUI); }
)

$(EXAMPLE 2,
// This app needs the a DB library and TCP library to be used.
version(build) { pragma(link, EuDB, TCP4Win); }
)
)


$(SECTION
$(SECTION_H pragma_nolink,pragma: nolink)
This identifies that the current module is not to be be linked in.
Normally, each object file created by the compiler is linked in, but
 if the supplied source file is just a stub for code which is externally
 defined in a library, then you do not need the 'stub' object file.

$(EXAMPLE ,
version(build) { pragma(nolink); }
)
)

$(SECTION
$(SECTION_H pragma_ignore,pragma: ignore)
This identifies that the current module is not to be passed to
the compiler or linker. It is however scanned by Build and can thus
contain Build pragma directives and import statements. This would be
used to create a special $(I all.d) file to pull in all the modules
for a library or program.

$(EXAMPLE ,
version(build) pragma(ignore);
// A list of files to include into a library.
import util.files;
import util.gfx;
import util.physics;
import util.render;
)
)

$(SECTION
$(SECTION_H pragma_include,pragma: include)
This identifies a required file which is not otherwise imported.
In some applications, especially ones converted over from C, it is
possible that the file on the $(I Build) command line does not directly
or indirectly import a required file. In those situations, you can
use this pragma to tell build to include it in the compilation checking
process.
$(BL)
The name provided in the $(I include) pragma is assumed to be a module name
and is thus converted to a D source file name with path. The one exception
to this is if the name provided ends in ".ddoc" it is assumed to be a
Ddoc macro definition file and is taken as given rather than being transformed
from a module specification to a path and file name.

$(EXAMPLE ,
// Tell 'build' that prime.d must be included (it contains the main function.)
  version(build) { pragma(include, prime); }

// Tell 'build' that user\base.d must be included
  version(build) { pragma(include, user.base); }

// Tell 'build' that docdef\qwerty.ddoc must be included
  version(build) { pragma(include, docdef\qwerty.ddoc); }
)
)

$(SECTION
$(SECTION_H pragma_target,pragma: target)
This identifies the basename of the target file.
By default, the target name is based on the first file on the command line.
But if you include this pragma, the name identified in the pragma becomes
the default name. In either case, the $(B -T) switch overrides the default name.

If two or more $(I target) pragmas are found, the first one is the one
that is used and the others are ignored (though mentioned if in
verbose mode).
$(EXAMPLE ,
// Tell 'build' to create WhizzBang.exe
version(build) { pragma(target, "WhizzBang"); }

)
)

$(SECTION
$(SECTION_H pragma_build,pragma: build)
This identifies a file that needs an external program to build it.
Some applications need to link in object files created by C source, or
by a $(I resource) compiler, or whatever. This pragma identifies a file
that needs to be created by something other than the D compiler. The
format is ...
$(CODE
pragma(build, "FILENAME" [, "OPTIONS"] ...);
)
where $(I FILENAME) is either the file to create, or the file to use when
creating the required file to use in the build process. Note that if you
just supply an empty string $(QUOTE) the file that contains the pragma is
used.
$(BL)
For example, if you had a Windows resource file
that needed to be compiled, you could code the pragma as either ...
$(CODE
// Compile the images into a resource obj and add images.res to linker.
pragma(build, "images.rc");
)
or
$(CODE
// Compile the images into a resource obj and add images.res to linker.
pragma(build, "images.res");
)

The first example specifies the source file to be passed to the resource
compiler and the second example specifies the output of the resource compiler.
In either case, this utility uses the rules in a $(EXREF rules.html, Rule Definition File) to
decide what to do.
$(BL)
The utility searches for the $(I FILENAME) in the currently defined 'import'
paths and if doesn't exist, $(I Build) will abort.
$(BL)
The $(I OPTIONS) can be included if you need to pass any special values
to the external tool. There can be any number of these, but each one must
take the form $(QUOTE $(ANG KEYWORD)=$(ANG VALUE)). For example $(BR)
$(CODE
pragma(build, "dbapi.c", "COPT=-wc -x", "HDR=abc.hp");
)
The OPTIONS values are used as replacement text for token in the
Rule Definition File's 'tool' specification. In the example above,
the tokens {COPT} and {HDR}, if found in the 'tool' line, would be
replaced with $(I -wc -x) and $(I abc.hp) respectively.
$(BL)
There are some OPTIONS that have a special meaning to $(I Build).
$(DEFINITIONS
$(DEFITEM rule=$(ANG name), This identifies the name of the rule to use.
If this isn't supplied, the rule is found by matching the file extention
on the $(I FILENAME) against the $(I in=) and $(I out=) file types in
each rule definition.)
$(DEFITEM @pre=$(ANG text), This text is prepended to the $(I FILENAME) to form
the output file's name. Thus is the $(I FILENAME) was $(QUOTE foo.d) and $(ANG text)
was $(QUOTE dd) the output file name would formed as $(QUOTE ddfoo.d). This
can be used in conjunction with the $(I @pos=) OPTION.)
$(DEFITEM @pos=$(ANG text),  This text is appended to the $(I FILENAME) to form
the output file's name. Thus is the $(I FILENAME) was $(QUOTE foo.d) and $(ANG text)
was $(QUOTE _ri) the output file name would formed as $(QUOTE foo_ri.d). This
can be used in conjunction with the $(I @pre=) OPTION.)
)
$(BL)
The output file to the external tool is checked to see if it is still
up to date and the tool is only called if the output file's date is earlier
than the input file's date (or a forced compile is requested).
$(BL)
By default, the output file from the external tool is added to the linkage
set of files, and the input file is ignored. These behaviours can be changed
by options in the $(EXREF rules.html, Rule definition). It is possible to tell $(I Build) to
compile, link or ignore the input file and/or the output file.
$(BL)
All these external programs are run before the D compiler is invoked.

$(EXAMPLE ,
// Tell 'build' that it needs to use a rule called 'Resource'
// to call an external program to build an up-to-date version
// of 'images.rc'
version(build) { pragma(build, "images.rc", "rule=Resource"); }
)
)

$(SECTION
$(SECTION_H pragma_export_version,pragma: export_version)
This allows you to set a global version identifier.
DMD allows you to set a version identifier in your code, but the scope
of that is only for the module it is set in. This pragma gives you the
ability to declare a version identifier which is applied to all modules
being compiled, and not just the 'current' module.

$(EXAMPLE ,
    version(build) pragma(export_version, Unix);
    version(build) pragma(export_version, Limited);
)

These lines will cause the compiler to have these version identifiers
added to the command line switches, thus making them effectively global.

You can list more than one identifier on the pragma statement ...
$(CODE
    version(build) pragma(export_version, Unix, Limited);
)

)

$(SECTION
$(SECTION_H pragma_build_def,pragma: build_def)
This supplies an option to be placed in an OptLink definition file.
You can have $(I build) create a customised OptLink definition file
by coding as many $(I build_def) pragmas as required. However, $(I build) will
only allow the first of each type of Definition File command to be used. This
means that if you code ...
$(CODE
pragma (build_def, "EXETYPE DOS");
pragma (build_def, "EXETYPE NT");
)
Then the EXETYPE DOS will be used and the 'NT' line ignored. You can use
explicit build_def pragmas to override the default ones generated by
 $(I build) for Windows programs or DLL libraries.

The syntax for these pragma is
$(CODE
pragma(build_def, $(ANG QUOTED_STRING) );
)

$(EXAMPLE ,
  version(build) {
    pragma (build_def, "VERSION 1.1");
    version(DOS) {
      pragma (build_def, "EXETYPE DOS");
    }
    version(WIN) {
      pragma (build_def, "EXETYPE NT");
      pragma (build_def, "SUBSYSTEM WINDOWS,4.0");
    }
  }
)

$(NOTE You can supply $(B anything) in the text string and it is used verbatim.
There is no restrictions on what you can include in this pragma.)
)

Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for BUILD
 Product = Build Utility
