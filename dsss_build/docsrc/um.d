/* This is used to generate the user manual for Build.

--usage:
   build um.d -clean

*/

version(build)
{
    pragma(nolink);
    pragma(include, user_manual.ddoc);
    pragma(include, pragmas);
    pragma(include, introduction);
    pragma(include, User_Manual);
    pragma(include, rules);
    pragma(include, autobuild);
    pragma(include, command_line);
    pragma(include, switches);
    pragma(include, configuration_file);
    pragma(include, profile_file);
    pragma(include, response_file);
    pragma(include, todo);
    pragma(include, dlls);
    pragma(include, change_log);
    pragma(include, macros);

}
