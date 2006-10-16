Ddoc

$(TOPIC_H command_line,Command Line)
$(SECTION
The $(I Bud) utility supplies the source file and optional switches via
the command line. The typical format of the $(I Bud) utility's command
line is ...
$(CODE
      $(B build) $(ANG sourcefile) $(SQR  $(ANG switches) ) $(SQR  $(ANG otherfiles) )
)

You can however specify the files and switches in any order you like.
$(BL)
Normally you would only supply a single file name to $(I Bud), that being
 the source file of the top-level file in the application. Typically
 the one that has the 'main()' or 'WinMain()' function, though this is
 not strictly necessary.
$(BL)
The files supplied on the command line can be a mixture of source files,
macro files, object files, resource files, resource source files, libraries,
and any other type of file needed to build an application or library.
$(BL)
If you run the utility without any files and without any switches, it
 display a $(I help) screen with some details about the switches. That looks
 something similar to this ...
$(CODE
  Path and Version : C:\Program Files\build.exe v3.6(339)
  Usage: build sourcefile [options objectfiles libraries]
    $(B  sourcefile )D source file
    $(B -v)         Verbose (passed through to D)
    $(B -V)         Verbose (NOT passed through)
    $(B -names)     Displays the names of the files used to build the target.
    $(B -DCPATH$(ANG path)) $(ANG path) is where the compiler has been installed.
               Only needed if the compiler is not in the system's
               PATH list. Used if you are testing an alternate
               version of the compiler.
    $(B -CFPATH$(ANG path)) $(ANG path) is where the D config file has been installed.
    $(B -full)      Causes all source files, except ignored modules,
                to be compiled.
    $(B -link)      Forces the linker to be called instead of the librarian.
                (Only needed if the source files do not contain
                 main/WinMain)
    $(B -nolink)    Ensures that the linker is not called.
                (Only needed if main/WinMain is found in the source
                 files and you do NOT want an executable created.)
    $(B -lib)       Forces the object files to be placed in a library.
                (Only needed if main/WinMain is found in the source
                 files AND you want it in a library instead of
                 an executable.)
    $(B -modules$(ANG =name)) Create a Module List File.
    $(B -nolib)     Ensures that the object files are not used to form
                a library.
                (Only needed if main/WinMain is not found in the source
                 files and you do NOT want a library.)
    $(B -obj)       This is the same as having both -nolink and -nolib
                switches on the command line. It is just a shorthand.
    $(B -allobj)    Ensures that all object files are added to a
                library.
                (Normally only those in the same directory are added.)
    $(B -cleanup)   Ensures that all object files created during the run
                are removed at the end of the run, plus other work files.
    $(B -clean)     Same as -cleanup
    $(B -test)      Does everything as normal except it displays the commands
                  instead of running them. Also, the auto-build-numbers are
                  not incremented.
    $(B -si)        Search the Import Path(s) for files specified on
                   the command line.
    $(B -MDF$(ANG path))  Overrides the default Macro Definition File
    $(B -RDF$(ANG path))  Overrides the default Rule Definition File
    $(B -gui[:x.y]) Forces a GUI application to be created. The optional
                :x.y can be used to build an application for a
                specific version of Windows. eg. -gui:4.0
                (Only needed if WinMain is not found in the source files
                or if you wish to override the default Windows version)
    $(B -dll)       Forces a DLL library to be created.
                      (Only needed if DllMain is not found in the source files.)
    $(B -LIBOPT $(ANG opt)) Allows you to pass $(ANG opt) to the librarian
    $(B -LIBPATH=$(ANG pathlist)) Used to add a semi-colon delimited list
                of search paths for library files.
    $(B -X$(ANG module)) Packages and Modules to ignore (eg. -Xmylib)
    $(B -M$(ANG module)) Packages and Modules to notice (eg. -Mphobos)
    $(B -T$(ANG targetname)) The name of the target file to create. Normally
                the target name istaken from the first or only name
                of the command line.
    $(B -R=$(ANG Yes/No)) Indicates whether to use a response file or command line
                   arguments with the compiler tools.
                 $(B -R=Yes) will cause a response to be used.
                 $(B -R=No) will cause command line arguments to be used.
                 $(B -R) will reverse the current usage.
                  Note that the default for Windows $(I DigitalMars) is to use a response file
                  but for all other environments it is to use command line arguments.
    $(B -info)      Displays the version and path of the $(I Bud) application
    $(B -help)      Displays the full 'usage' help text.
    $(B -h)         Same as /-help, displays the full 'usage' help text.
    $(B -?   )      Same as /-help, displays the full 'usage' help text.
    $(B -silent)    Avoids unnecessary messages being displayed.
    $(B -noautoimport) Turns off the automatic addition of source paths
                   to the list of Import Roots.
    $(B -exec$(ANG param))   If the link is successful, this will cause the
                   executable just created to run. You can give it
                   run time parameters. Anything after the '-exec' will
                   placed in the program's command line. You will need
                   to quote any embedded spaces.
    $(B -od$(ANG path))  Nominate the directory where temporary (work) files
                   are to be created. By default they are created in
                   the same directory as the target file.
    $(B -nodef)     Prevents a Module Definition File being automatically created.
                This will override any pragma($(EXDEF pragmas#pragma_build_def,build_def))
                 statements in the source code.
    $(B -UMB=$(ANG Yes/No)) If $(B Yes) this forces the utility to expect
                 the object file to be created or residing in the current
                 directory.
    $(B [...])      All other options, objectfiles and libraries are
                passed to the compiler
)

See also $(EXDEF response_file,Response File)
)


Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for Bud
 Product = $(I Bud) Utility
