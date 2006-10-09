Ddoc

$(TOPIC_H description, Description)
$(SECTION
Build is a tool to assist building applications and libraries written
using the D programming language.
)


$(ABSTRACT
It is an effective replacement for
the general 'make' tools. The primary difference between $(I Build) and
other tools is that $(I Build) does not need you to create and maintain
'makefiles'. Instead, it analyses the source code files to determine
all dependancies and constructs the appropriate calls to the compiler,
linker and librarian.
$(BL)
The aim of $(I Build) is to create a target file from the source file(s)
supplied to it. This is usually an executable file but could also be
a library. In both cases, source files are converted to object files, and
then either linked to form an executable or packaged into a library file.
$(BL)
If, when creating a library, there are no object files to be packaged then
the library is not created. This might occur if all the source files contain
either 'pragma(nolink)' or are $(I DDoc) files.
)

$(TOC_SECTION
    $(TOC change_log, Change Log)
        $(TOC_SUB User_Manual, license, License)

    $(TOC introduction, Introduction)

    $(TOC pragmas, Pragmas)
        $(TOC_SUB pragmas,pragma_build, Build)
        $(TOC_SUB pragmas,pragma_build_def, Build Def)
        $(TOC_SUB pragmas,pragma_export_version, Export Version)
        $(TOC_SUB pragmas,pragma_ignore, Ignore)
        $(TOC_SUB pragmas,pragma_include, Include)
        $(TOC_SUB pragmas,pragma_link, Link)
        $(TOC_SUB pragmas,pragma_nolink, Nolink)
        $(TOC_SUB pragmas,pragma_target, Target)

    $(TOC autobuild, Auto Build Number)

    $(TOC rules, Rule Definition File)

    $(TOC macros, Macros)

    $(TOC command_line, Command Line)

    $(TOC switches,Switches)
        $(TOC_SUB switches,switch_help,-?)
        $(TOC_SUB switches,switch_allobj,-allobj)
        $(TOC_SUB switches,switch_autowinlibs,-AutoWinLibs)
        $(TOC_SUB switches,switch_CFPATH,-CFPATH)
        $(TOC_SUB switches,switch_cleanup,-clean)
        $(TOC_SUB switches,switch_cleanup,-cleanup)
        $(TOC_SUB switches,switch_DCPATH,-DCPATH)
        $(TOC_SUB switches,switch_dll,-dll)
        $(TOC_SUB switches,switch_exec,-exec$(ANG args))
        $(TOC_SUB switches,switch_full,-full)
        $(TOC_SUB switches,switch_gui,-gui)
        $(TOC_SUB switches,switch_help,-h)
        $(TOC_SUB switches,switch_help,-help)
        $(TOC_SUB switches,switch_info,-info)
        $(TOC_SUB switches,switch_lib,-lib)
        $(TOC_SUB switches,switch_LIBOPT,-LIBOPT$(ANG option(s)))
        $(TOC_SUB switches,switch_LIBPATH,-LIBPATH$(ANG path))
        $(TOC_SUB switches,switch_link,-link)
        $(TOC_SUB switches,switch_M,-M$(ANG name))
        $(TOC_SUB switches,switch_MDF,-MDF$(ANG file))
        $(TOC_SUB switches,switch_modules,-modules$(ANG =name))
        $(TOC_SUB switches,switch_names,-names)
        $(TOC_SUB switches,switch_noautoimport,-noautoimport)
        $(TOC_SUB switches,switch_nodef,-nodef)
        $(TOC_SUB switches,switch_nolib,-nolib)
        $(TOC_SUB switches,switch_nolink,-nolink)
        $(TOC_SUB switches,switch_obj,-obj)
        $(TOC_SUB switches,switch_od,-od$(ANG path))
        $(TOC_SUB switches,switch_PP,-PP$(ANG path))
        $(TOC_SUB switches,switch_R,-R$(ANG option))
        $(TOC_SUB switches,switch_RDF,-RDF$(ANG file))
        $(TOC_SUB switches,switch_silent, -silent)
        $(TOC_SUB switches,switch_T,-T$(ANG name))
        $(TOC_SUB switches,switch_test, -test)
        $(TOC_SUB switches,switch_uses, -uses)
        $(TOC_SUB switches,switch_UMB, -UMB)
        $(TOC_SUB switches,switch_v,-v (lowercase))
        $(TOC_SUB switches,switch_V,-V (uppercase))
        $(TOC_SUB switches,switch_X,-X$(ANG name))

    $(TOC response_file,Response File)
    $(TOC configuration_file,Configuration File)
    $(TOC profile_file,Profile File)
    $(TOC todo,Things Still To Do)
    $(TOC dlls,DLL Libraries)

)


$(SECTION $(SECTIONDEF_H copyright, Copyright:, &copy; 2005 Derek Parnell))
$(SECTION $(SECTIONDEF_H authors, Authors:, Derek Parnell - Melbourne))
$(SECTION $(SECTIONDEF_H create, Initial Creation:, January 2005))
$(SECTION $(SECTIONDEF_H version, Version:, 3.03))
$(SECTION $(SECTIONDEF_H date, Date:, 20 September 2006))
$(SECTION $(SECTION_H license, License:)
$(CITE
This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for damages
of any kind arising from the use of this software.
Permission is hereby granted to anyone to use this software for any
purpose, including commercial applications, and to alter it and/or
redistribute it freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must
   not claim that you wrote the original software. If you use this
   software in a product, an acknowledgment within documentation of
   said product would be appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must
   not be misrepresented as being the original software.
3. This notice may not be removed or altered from any distribution
   of the source.
4. Derivative works are permitted, but they must carry this notice
   in full and credit the original source.
)
)

$(SECTION
$(SECTIONDEF_H references, References:, This is based on the work called 'dmake v0.21' by Helmut Leitner
))



Macros:
 Copyright = &copy; 2006, Derek Parnell, Melbourne
 Title = User Manual for BUILD
 Product = Build Utility
