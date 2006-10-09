Ddoc

$(TOPIC_H dll_libraries,DLL Libraries)
$(SECTION
$(SHORT_TITLE How to create a DLL library using Build.)
$(BR)
When Build finds a $(B DllMain()) function, or the $(B -dll) switch is used, it
creates a special type of Module Definition file, and sets the target to
to be a DLL file. The Module Definition file generated takes the form ...
$(CODE
LIBRARY "$(ANG targetname).dll";
EXETYPE NT
SUBSYSTEM WINDOWS,$(ANG version)
CODE PRELOAD DISCARDABLE SHARED EXECUTE
DATA PRELOAD SINGLE WRITE
)
You can replace any of these by explicitly coding a
pragma($(EXREF pragmas#pragma_build_def,build_def))
with different options than these defaults shown here.

Also, if you have the program $(B implib) in your path, it will be run
after the DLL file is created, in order to also create a $(B .lib)
library to interface with the DLL. Build currently supports both the
$(I DigitalMars) version and the $(I Borland (Inprise)) version of $(B implib).
)


Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for BUILD
 Product = Build Utility
