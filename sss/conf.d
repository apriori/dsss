/**
 * DSSS configuration stuff
 * 
 * Authors:
 *  Gregor Richards
 * 
 * License:
 *  Copyright (C) 2006  Gregor Richards
 *  
 *  This file is part of DSSS.
 *  
 *  DSSS is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *  
 *  DSSS is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with DSSS; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

module sss.conf;

import std.ctype;
import std.file;
import std.process;
import std.stdio;
import std.string;

import std.c.stdlib;

import sss.clean;

import hcf.env;
import hcf.path;
import hcf.process;

import util.booltype;
import util.fdt;
import util.str;

version (Windows) {
    import bcd.windows.windows;
}

alias std.string.find find;

/** The default config file name */
const char[] configFName = "dsss.conf";

/** The lastbuild config file name */
const char[] configLBName = "dsss.last";

/** The dsss_build line */
char[] dsss_build;

/** Options added to dsss_build */
char[] dsss_buildOptions;

/** The prefix to which DSSS was installed */
char[] installPrefix;

/** The provided prefix */
char[] forcePrefix;

/** The prefix to which other binaries should be installed */
char[] binPrefix;

/** The prefix to which libraries are installed */
char[] libPrefix;

/** The prefix to which includes are installed */
char[] includePrefix;

/** The prefix to which manifests are installed */
char[] manifestPrefix;

/** The prefix to which the source list is downloaded */
char[] srcListPrefix;

/** The prefix for scratch work */
char[] scratchPrefix;

/** The location of stub.d (used to make stub D libraries) */
char[] stubDLoc;

/** The location of dsssdll.d (used to make DLLs from any library) */
char[] dsssDllLoc;

/* It's often useful to know whether we're using GNU and/or Posix, as GNU on
 * Windows tends to do some things Posixly. */
version (build) {
    version (GNU) {
        pragma(export_version, "GNU_or_Posix");
    } else version (Posix) {
        pragma(export_version, "GNU_or_Posix");
    }
}

/** Set prefixes automatically, given argv[0] */
void getPrefix(char[] argvz)
{
    char[] bname;
    if (!whereAmI(argvz, installPrefix, bname)) {
        writefln("Failed to determine DSSS' installed prefix.");
        exit(1);
    }
    
    // set the prefix to actually install things to
    
    // using this directory, find include and library directories
    if (exists(installPrefix ~ std.path.sep ~ "sss" ~ std.path.sep ~ "main.d")) {
        // this is probably the build prefix
        if (forcePrefix == "") {
            forcePrefix = installPrefix ~ std.path.sep ~ "inst";
        }
        
        char[] sssBaseLoc = installPrefix ~ std.path.sep ~ "sss" ~ std.path.sep;
        stubDLoc = sssBaseLoc ~ "stub.d";
        dsssDllLoc = sssBaseLoc ~ "dssdll.d";
        
        // set build environment variable
        version (Posix) {
            dsss_build = installPrefix ~
                std.path.sep ~ "dsss_build" ~
                std.path.sep ~ "dsss_build";
            setEnvVar("DSSS_BUILD", dsss_build);
        } else version (Windows) {
            dsss_build = installPrefix ~
                std.path.sep ~ "dsss_build" ~
                std.path.sep ~ "dsss_build.exe";
            setEnvVar("DSSS_BUILD", dsss_build);
        } else {
            static assert(0);
        }
    } else {
        // slightly more complicated for a real install
        if (forcePrefix == "") {
            forcePrefix = getDirName(installPrefix);
        }
        
        char[] sssBaseLoc = forcePrefix ~ std.path.sep ~
            "include" ~ std.path.sep ~
            "d" ~ std.path.sep ~
            "sss" ~ std.path.sep;
        stubDLoc = sssBaseLoc ~ "stub.d";
        dsssDllLoc = sssBaseLoc ~ "dsssdll.d";
        
        // set build environment variable
        version (Posix) {
            dsss_build = installPrefix ~
                 std.path.sep ~ "dsss_build";
            setEnvVar("DSSS_BUILD", dsss_build);
        } else version (Windows) {
            dsss_build = installPrefix ~
                std.path.sep ~ "dsss_build.exe";
            setEnvVar("DSSS_BUILD", dsss_build);
        } else {
            static assert(0);
        }
    }
    
    binPrefix = forcePrefix ~ std.path.sep ~ "bin";
    libPrefix = forcePrefix ~ std.path.sep ~ "lib";
    includePrefix = forcePrefix ~ std.path.sep ~
        "include" ~ std.path.sep ~
        "d";
    manifestPrefix = forcePrefix ~ std.path.sep ~
        "share" ~ std.path.sep ~
        "dsss" ~ std.path.sep ~
        "manifest";
    srcListPrefix = forcePrefix ~ std.path.sep ~
        "share" ~ std.path.sep ~
        "dsss" ~ std.path.sep ~
        "sources";
    
    // set the scratch prefix and some some environment variables
    version (Posix) {
        scratchPrefix = "/tmp";
        
        setEnvVar("DSSS", installPrefix ~ "/dsss");
        setEnvVar("PREFIX", forcePrefix);
        setEnvVar("BIN_PREFIX", binPrefix);
        setEnvVar("LIB_PREFIX", libPrefix);
        setEnvVar("INCLUDE_PREFIX", includePrefix);
        setEnvVar("EXE_EXT", "");
        
        // make sure components run with libraries, etc
        setEnvVar("PATH", binPrefix ~ ":" ~ getEnvVar("PATH"));
        char[] ldlibp = getEnvVar("LD_LIBRARY_PATH");
        if (ldlibp == "") {
            ldlibp = libPrefix;
        } else {
            ldlibp = libPrefix ~ ":" ~ ldlibp;
        }
        setEnvVar("LD_LIBRARY_PATH", ldlibp);
    } else version (Windows) {
        scratchPrefix = forcePrefix ~ std.path.sep ~ "tmp";
        
        setEnvVar("DSSS", installPrefix ~ "/dsss.exe");
        setEnvVar("PREFIX", forcePrefix);
        setEnvVar("BIN_PREFIX", binPrefix);
        setEnvVar("LIB_PREFIX", libPrefix);
        setEnvVar("INCLUDE_PREFIX", includePrefix);
        setEnvVar("EXE_EXT", ".exe");
        
        // path for both bin and lib
        setEnvVar("PATH", binPrefix ~ ";" ~ libPrefix ~ ";" ~ getEnvVar("PATH"));
    } else {
        static assert(0);
    }
    
    dsss_build ~= " -I" ~ includePrefix ~ " -LIBPATH=" ~ libPrefix ~ " -LIBPATH=. " ~
        dsss_buildOptions ~ " ";
}

/** DSSS configuration information - simply a list of sections, then an array
 * of settings for those sections */
class DSSSConf {
    /// Configurable sections
    char[][] sections;
    
    /// Settings per section
    char[][char[]][char[]] settings;
}

/** Generate a DSSSConf from dsss.conf, or generate a dsss.conf from buildElems */
DSSSConf readConfig(char[][] buildElems, bool genconfig = false, char[] configF = configFName)
{
    /* config file format: every line is precisely one section, setting, block
     * opener or block closer. The only valid block opener is 'version' */
    
    /** A function to tokenize a single config file line */
    char[][] tokLine(char[] line)
    {
        /** All tokens read thusfar */
        char[][] tokens;
        
        /** Current token */
        char[] tok;
        
        /** Add the current token */
        void addToken()
        {
            if (tok != "") {
                tokens ~= tok;
                tok = "";
            }
        }
        
        for (int i = 0; i < line.length; i++) {
            if (isalnum(line[i])) {
                tok ~= line[i..i+1];
            } else if (iswhite(line[i])) {
                addToken();
            } else if (line[i] == '=' ||
                       line[i] == ':') {
                // the rest is all one token
                addToken();
                tok ~= line[i];
                addToken();
                
                tok ~= line[(i + 1) .. $];
                
                // trim whitespace of the setting
                while (tok.length && iswhite(tok[0])) tok = tok[1..$];
                
                if (tok.length) addToken();
                break;
            } else {
                addToken();
                tok ~= line[i..i+1];
                addToken();
            }
        }
        addToken();
        
        return tokens;
    }
    
    /// The actual configuration store
    DSSSConf conf = new DSSSConf();
    
    /// The data from the config file
    char[] confFile;
    
    if (exists(configFName)) {
        if (genconfig) {
            // this makes no sense
            writefln("Will not generate a config file when a config file already exists.");
            exit(1);
        }
        
        // before reading the config, distclean if it's changed
        if (configF == configFName) {
            if (exists(configLBName)) {
                if (fileNewer(configFName, configLBName)) {
                    // our config has changed
                    distclean(readConfig(null, false, configLBName));
                }
            }
        
            // copy in our new dsss.lastbuild
            std.file.copy(configFName, configLBName);
        }
        
        // Read the config file
        confFile = cast(char[]) std.file.read(configFName);
    } else {
        // Generate the config file
        if (buildElems.length == 0) {
            // from nothing - just make every directory into a library
            char[][] dires = listdir(".");
            foreach (dire; dires) {
                if (isdir(dire) &&
                    dire[0] != '.') {
                    confFile ~= "[" ~ dire ~ "]\n";
                }
            }
            
        } else {
            // from a list
            foreach (build; buildElems) {
                if (!exists(build)) {
                    writefln("File %s not found!", build);
                } else {
                    confFile ~= "[" ~ build ~ "]\n";
                }
            }
        }
        
        if (genconfig) {
            // write it
            std.file.write(configFName, confFile);
        }
        
    }
    
    
    // Normalize it
    confFile = replace(confFile, "\r", "");
        
    // Split it by lines
    char[][] lines = split(confFile, "\n");
        
    /// Current section
    char[] section;
        
    /// Tested versions
    bool[char[]] versions;
    
    // set up the defaults for the top-level section
    conf.settings[""] = null;
    conf.settings[""]["name"] = getBaseName(getcwd());
    conf.settings[""]["version"] = "latest";
    
    // parse line-by-line
    for (int i = 0; i < lines.length; i++) {
        char[] line = lines[i];
            
        /** A function to close the current scope */
        void closeScope(bool ignoreElse = false)
        {
            int depth = 1;
            for (i++; i < lines.length; i++) {
                char[][] ntokens = tokLine(lines[i]);
                if (ntokens.length == 0) continue;
                    
                // possibly change the depth
                if (ntokens[0] == "}") {
                    // check for else
                    if (ntokens.length >= 3 &&
                        ntokens[1] == "else") {
                        if (!ignoreElse) {
                            // rewrite this line for later parsing
                            lines[i] = std.string.join(ntokens[2 .. $], " ");
                            depth--;
                            i--;
                        } else if (ntokens[$ - 1] != "{") {
                            // drop the depth even though we won't reparse it
                            depth--;
                        }
                        
                    } else {
                        depth--;
                    }
                    
                    if (depth == 0) {
                        return; // done! :)
                    }
                } else if (ntokens[$ - 1] == "{") {
                    depth++;
                }
            }
            // didn't close!
            writefln("DSSS config error: unclosed scope.");
            exit(1);
        }
        
        // combine lines
        while (i < lines.length - 1 &&
               line.length &&
               line[$ - 1] == '\\') {
            i++;
            line = line[0 .. ($ - 1)] ~ lines[i];
        }
        
        // then parse it
        char[][] tokens = tokLine(line);
        if (tokens.length == 0) continue;
        
        // then do something with it
        if (tokens[0] == "[" &&
            tokens[$ - 1] == "]") {
            // a section header
            char[] path = std.string.join(tokens[1 .. ($ - 1)], "");
            // allow \'s for badly-written conf files
            path = std.string.replace(path, "\\", "/");
            
            section = canonPath(path);
            conf.settings[section] = null;
                
            // need to have some default settings: target and type
            if (section == "*") {
                // "global" section, no target/type
            } else if (section == "") {
                // top-level section
            } else if (section.length > 0 &&
                       section[0] == '+') {
                // special section
                conf.sections ~= section;
                conf.settings[section]["type"] = "special";
                conf.settings[section]["target"] = section[1..$];
                
            } else if (!exists(section)) {
                writefln("WARNING: Section for nonexistant file %s.", section);
            } else {
                conf.sections ~= section;
                
                if (isdir(section)) {
                    conf.settings[section]["type"] = "library";
                    
                    // target according to the library naming convention
                    char[] pkg = canonPath(section);
                    
                    // LNC:
                    // D<compiler>-<package-with-hyphens>
                    
                    // D
                    char[] lname = "D";
                    
                    // <compiler>
                    // FIXME: this should check with dsss_build
                    version (GNU) {
                        lname ~= "G";
                    } else version (DigitalMars) {
                        lname ~= "D";
                    } else {
                        static assert(0);
                    }
                    lname ~= "-";
                        
                    // <package>
                    // swap out /'s
                    pkg =
                        std.string.replace(pkg, std.path.sep, "-");
                    // name it
                    conf.settings[section]["target"] =
                        lname ~ pkg;
                        
                } else {
                    conf.settings[section]["type"] = "binary";
                    conf.settings[section]["target"] = std.path.getName(section);
                }
            }
                
            // FIXME: guarantee that sections aren't repeated
                
        } else if (tokens[0] == "version") {
            /* a version statement, must be of one form:
             *  * version(version) {
             *  * version(!version) {
             */
            
            if ((tokens.length != 5 ||
                 tokens[1] != "(" ||
                 tokens[3] != ")" ||
                 tokens[4] != "{") &&
                (tokens.length != 6 ||
                 tokens[1] != "(" ||
                 tokens[2] != "!" ||
                 tokens[4] != ")" ||
                 tokens[5] != "{")) {
                writefln("DSSS config error: malformed version line.");
                exit(1);
            }
            
            // whether the comparison is valid
            bool valid = false;
            char[] vertok;
            if (tokens[2] == "!") {
                // assume valid
                valid = true;
                vertok = tokens[3];
            } else {
                vertok = tokens[2];
            }
            
            if (!(vertok in versions)) {
                /* now check if this version is defined by making a .d file and
                 * building it */
                std.file.write("dsss_tmp.d", cast(void[])
                               ("version (" ~ vertok ~ ") {\n" ~
                                "pragma(msg, \"y\");\n" ~
                                "} else {\n" ~
                                "pragma(msg, \"n\");\n" ~
                                "}\n"));
                PStream comp = new PStream(dsss_build ~ "-full -obj -clean dsss_tmp.d");
                char yn = '\0';
                while (yn == '\0')
                    comp.read(yn);
                
                std.file.remove("dsss_tmp.d");
                
                if (yn == 'y') {
                    // true version
                    versions[vertok] = true;
                } else {
                    versions[vertok] = false;
                }
            }
            
            // now choose our path
            if (versions[vertok]) valid = !valid;
            if (!valid) {
                // false, find the end to this block
                closeScope();
            }
         
        } else if (tokens.length == 3 &&
                   tokens[1] == ":") {
            // a command
            if (tokens[0] == "warn") {
                // a warning
                writefln("WARNING: %s", tokens[2]);
            } else if (tokens[0] == "error") {
                // an error
                writefln("ERROR: %s", tokens[2]);
            }
            
        } else if (tokens.length == 3 &&
                   tokens[1] == "=") {
            // a setting
            conf.settings[section][std.string.tolower(tokens[0])] = expandEnvVars(tokens[2]);
                
        } else if (tokens.length == 1 &&
                   isalnum(tokens[0][0])) {
            // a setting with no value
            conf.settings[section][std.string.tolower(tokens[0])] = "";
            
        } else if (tokens.length == 4 &&
                   tokens[1] == "+" &&
                   tokens[2] == "=") {
            // append to a setting
            char[] setting = std.string.tolower(tokens[0]);
            if (setting in conf.settings[section]) {
                conf.settings[section][setting] ~= " " ~ expandEnvVars(tokens[3]);
            } else {
                conf.settings[section][setting] = expandEnvVars(tokens[3]);
            }
                
        } else if ((tokens.length == 1 &&
                    (tokens[0] == "}" ||
                     tokens[0] == "{")) ||
                   tokens[0] == "#") {
            // this is ignored, just a scope we're in or a comment
            
        } else if (tokens.length > 2 &&
                   tokens[0] == "}" &&
                   tokens[1] == "else") {
            // skip this else case
            closeScope(true);
            
        } else {
            writefln("DSSS config error: unrecognized line '%s'.", lines[i]);
            exit(1);
                
        }
    }
    
    // now apply global settings to every other setting
    if ("*" in conf.settings) {
        char[][char[]] gsettings = conf.settings["*"];
        conf.settings.remove("*");
        
        // for each section ...
        foreach (key, settings; conf.settings) {
            // for each global setting ...
            foreach (skey, sval; gsettings) {
                // if it's not overridden ...
                if (!(skey in settings)) {
                    // then set it
                    settings[skey] = sval;
                }
            }
        }
    }
    
    return conf;
}

/** Get a list of files from a target */
char[][] targetToFiles(char[] target, DSSSConf conf)
in {
    assert(target in conf.settings);
}
body {
    char[][char[]] settings = conf.settings[target];
    char[][] files;
    
    // 1) get the exclusion list
    char[][] exclude;
    if ("exclude" in settings) {
        exclude = split(settings["exclude"]);
        
        // canonicalize and un-Windows-ize the paths
        for (int i = 0; i < exclude.length; i++) {
            exclude[i] = std.string.replace(canonPath(exclude[i]),
                                            "\\", "/");
        }
    }
    bool excluded(char[] path)
    {
        for (int i = 0; i < exclude.length; i++) {
            if (fnmatch(path, exclude[i])) {
                return true;
            }
        }
        return false;
    }
    
    // 2) stomp through the directory adding files
    void addDir(char[] ndir, bool force = false)
    {
        // make sure it's not excluded for any reason
        if (!force &&
            (ndir in conf.settings || // a separate target
             excluded(ndir))) {
            return;
        }
        
        // not excluded, get the list of files
        char[][] dirFiles = listdir(ndir);
        foreach (file; dirFiles) {
            if (!file.length) continue; // shouldn't happen
            
            // ignore dotfiles (mainly to ignore . and ..)
            if (file[0] == '.') continue;
            
            // make this the full path
            file = ndir ~ std.path.sep ~ file;
            
            if (isdir(file)) {
                // perhaps recurse
                addDir(file);
            } else if (std.string.tolower(getExt(file)) == "d") {
                // or just add it
                if (!excluded(file)) {
                    files ~= file;
                }
            }
        }
    }
    addDir(target, true);
    
    return files;
}

/** Perform a pre- or post- script step */
void dsssScriptedStep(char[] step)
{
    // since parts of the script can potentially change the directory, store it
    char[] origcwd = getcwd();
    
    // split the steps by ;
    char[][] cmds = std.string.split(step, ";");
    
    foreach (cmd; cmds) {
        // clean cmd
        while (iswhite(cmd[0])) cmd = cmd[1..$];
        while (iswhite(cmd[$-1])) cmd = cmd[0..($-1)];
        writefln("Command: %s", cmd);
        
        // run it
        char[] ext = std.string.tolower(getExt(cmd));
        if (ext == "d") {
            // if it's a .d file, -exec it
            saySystemDie(dsss_build ~ "-clean -exec " ~ cmd);
        } else if (cmd.length > 8 &&
                   cmd[0..8] == "install ") {
            // doing an install
            char[][] comps = std.string.split(cmd);
            if (comps.length != 3) continue; // FIXME: not valid
            
            // do this install
            // check for / or \
            int slloc = std.string.rfind(comps[1], '/');
            if (slloc == -1)
                std.string.rfind(comps[1], '\\');
            
            if (slloc != -1) {
                // path provided
                copyInFile(comps[1][(slloc + 1) .. $],
                               comps[2],
                               comps[1][0 .. (slloc + 1)]);
                } else {
                    copyInFile(comps[1], comps[2]);
            }
         
        } else if (cmd.length > 3 &&
                   cmd[0..3] == "cd ") {
            // change directories
            char[][] comps = std.string.split(cmd);
            if (comps.length != 2) continue; // FIXME: not valid
            
            // change our directory
            chdir(comps[1]);
        
        } else {
            // hopefully we can just run it
            saySystemDie(cmd);
        }
    }
    
    chdir(origcwd);
}

/** Get sources from a list of elements (sources or targets) */
char[][] sourcesByElems(char[][] buildElems, DSSSConf conf)
{
    char[][] buildSources;
    
    if (buildElems.length) {
        // now select the builds that have been requested
        foreach (be; buildElems) {
            // search for a section or target with this name
            bool found = false;
            
            foreach (section; conf.sections) {
                if (fnmatch(section, be)) {
                    // build this
                    buildSources ~= section;
                    found = true;
                    continue;
                }
                
                // not the section name, so try "target"
                if (fnmatch(conf.settings[section]["target"], be)) {
                    
                    // build this (by section name)
                    buildSources ~= section;
                    found = true;
                }
            }
            
            if (!found) {
                // didn't match anything!
                writefln("%s is not described in the configuration file.", be);
                exit(1);
            }
        }
        
    } else {
        // no builds selected, build them all
        buildSources = conf.sections;
    }
    
    return buildSources;
}

/** Get the soversion from a configuration */
char[] getSoversion(char[][char[]] settings)
{
    // get the soversion
    if ("soversion" in settings) {
        return settings["soversion"];
    } else {
        return "0.0.0";
    }
}

/** Get a full shared library file name from configuration */
char[] getShLibName(char[][char[]] settings)
{
    char[] target = settings["target"];
    
    version (Posix) {
        // lib<target>.so.<soversion>
        return "lib" ~ target ~ ".so." ~ getSoversion(settings);
    } else version (Windows) {
        // <target>.dll
        return target ~ ".dll";
    } else {
        static assert(0);
    }
}

/** Get a short shared library file names */
char[][] getShortShLibNames(char[][char[]] settings)
{
    char[] target = settings["target"];
    
    version (Posix) {
        // lib<target>.so.<first part of soversion>
        char[] soversion = getSoversion(settings);
        char[][] res;
        int dotloc;
        
        // cut off each dot one-by-one
        while ((dotloc = rfind(soversion, '.')) != -1) {
            soversion = soversion[0..dotloc];
            res ~= ("lib" ~ target ~ ".so." ~ soversion);
        }
        res ~= "lib" ~ target ~ ".so";
        
        return res;
    } else version (Windows) {
        // no short version
        return null;
    } else {
        static assert(0);
    }
}

/** Get a necessary flag while building shared libraries */
char[] getShLibFlag(char[][char[]] settings)
{
    version (Posix) {
        // need a soname
        char[][] shortshlibnames = getShortShLibNames(settings);
        char[] sonver;
        if (shortshlibnames.length >= 2) {
            sonver = shortshlibnames[1];
        } else {
            sonver = getShLibName(settings);
        }
        return "-SHLIBOPT-Wl,-soname=" ~ sonver;
    }
    return "";
}

/** Return true or false for whether shared libraries are supported */
bool shLibSupport()
{
    static bool tested = false;
    static bool supported = false;
    
    if (!tested) {
        // ask dsss_build
        PStream comp = new PStream(dsss_build ~ "-shlib-support");
        char yn = '\0';
        while (yn == '\0')
            comp.read(yn);
        
        supported = (yn == 'y');
        
        tested = true;
    }
    
    return supported;
}

/** Is file a newer than file b? */
bool fileNewer(char[] a, char[] b)
{
    FileDateTime fdta = new FileDateTime(a);
    FileDateTime fdtb = new FileDateTime(b);
    return (fdta > fdtb);
}

/** Copy a file into a directory */
void copyInFile(char[] file, char[] prefix, char[] from = "")
{
    if (!exists(prefix)) {
        writefln("+ making directory %s", prefix);
        mkdirP(prefix);
    }
            
    writefln("+ copying %s", file);
    version (Posix) {
        // preserve permissions
        saySystemDie("cp -af " ~ from ~ file ~ " " ~ prefix ~ std.path.sep ~ file);
    } else {
        copy(from ~ file, prefix ~ std.path.sep ~ file);
    }
}

/** Expand environment variables in the provided string */
char[] expandEnvVars(char[] from)
{
    char[] ret = from ~ "";
    
    // now expand
    for (int i = 0; i < ret.length; i++) {
        if (ret[i] == '$') {
            // find the end
            int j;
            for (j = i + 1; j < ret.length &&
                 (isalnum(ret[j]) || ret[j] == '_');
                 j++) {}
                    
            // expand
            char[] envvar;
            envvar = getEnvVar(ret[(i + 1) .. j]);
            ret = ret[0 .. i] ~
            envvar ~
            ret[j .. $];
        }
    }
    
    return ret;
}
