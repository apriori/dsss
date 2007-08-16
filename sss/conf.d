/**
 * DSSS configuration stuff
 * 
 * Authors:
 *  Gregor Richards
 * 
 * License:
 *  Copyright (c) 2006, 2007  Gregor Richards
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a
 *  copy of this software and associated documentation files (the "Software"),
 *  to deal in the Software without restriction, including without limitation
 *  the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *  and/or sell copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 */

module sss.conf;

import std.ctype;
import std.file;
import std.process;
import std.stdio;
import std.stream;
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

alias std.process.system system;
alias std.string.find find;
alias std.string.iswhite iswhite;

extern (C) int access(char*, int);
enum accessRights : int {
        F_OK = 0,
        X_OK,
        W_OK,
        R_OK
};

/** The default config file name */
const char[] configFName = "dsss.conf";

/** The lastbuild config file name */
const char[] configLBName = "dsss.last";

/** The dsss_build line */
char[] dsss_build;

/** Options added to dsss_build */
char[] dsss_buildOptions;

/** Is DSSS installed, or is it being run out of the source directory? */
bool inSourceDir;

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

/** The prefix to which documentation is installed */
char[] docPrefix;

/** The prefix to which manifests are installed */
char[] manifestPrefix;

/** The prefix to which configuration files are installed */
char[] etcPrefix;

/** The prefix to which the source list is downloaded */
char[] srcListPrefix;

/** The location of candydoc.tar.gz */
char[] candyDocPrefix;

/** The location of dsss_lib_test.d */
char[] dsssLibTestDPrefix;

/** Are we doing documentation? */
bool doDocs = false;

/** Are we doing documentation for binaries? */
bool doDocBinaries = false;

/** Should we delete response files? */
bool deleteRFiles = true;

/** Should we generate test binaries? */
bool testLibs = false;

/** Should we build debug versions? */
bool buildDebug = false;

/** The prefix for scratch work */
char[] scratchPrefix;

/** The location of stub.d (used to make stub D libraries) */
char[] stubDLoc;

/** The location of dsssdll.d (used to make DLLs from any library) */
char[] dsssDllLoc;

/** Usedirs (dirs to import both includes and libs from */
char[][] useDirs;

/** Tested versions (for the target) */
bool[char[]] versions;
    
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
    
    installPrefix = canonPath(installPrefix);
    
    // get some default usedirs
    useDirs ~= canonPath(installPrefix ~ std.path.sep ~ "..");
    version (Posix) {
        char[] home = getEnvVar("HOME");
        if (home != "") {
            useDirs ~= canonPath(home ~ std.path.sep ~ "d");
        }
    }
    
    // set the prefix to actually install things to
    
    // using this directory, find include and library directories
    if (exists(installPrefix ~ std.path.sep ~ "sss" ~ std.path.sep ~ "main.d")) {
        // this is probably the build prefix
        inSourceDir = true;
        
        if (forcePrefix == "") {
            forcePrefix = installPrefix ~ std.path.sep ~ "inst";
        } else {
            forcePrefix = canonPath(forcePrefix);
        }
        
        char[] sssBaseLoc = installPrefix ~ std.path.sep ~ "sss" ~ std.path.sep;
        stubDLoc = sssBaseLoc ~ "stub.d";
        dsssDllLoc = sssBaseLoc ~ "dssdll.d";
        
        // get rebuild environment variable
        version (Posix) {
            dsss_build = installPrefix ~
                std.path.sep ~ "rebuild" ~
                std.path.sep ~ "rebuild";
        } else version (Windows) {
            dsss_build = installPrefix ~
                std.path.sep ~ "rebuild" ~
                std.path.sep ~ "rebuild.exe";
        } else {
            static assert(0);
        }
        
        setEnvVar("DSSS_BUILD", dsss_build);
        
        if (!candyDocPrefix.length)
            candyDocPrefix = canonPath(
                installPrefix ~ std.path.sep ~
                "candydoc.tar.gz");
        if (!dsssLibTestDPrefix.length)
            dsssLibTestDPrefix = canonPath(
                installPrefix ~ std.path.sep ~
                "sss" ~ std.path.sep ~
                "dsss_lib_test.d");
    } else {
        inSourceDir = false;
        
        // slightly more complicated for a real install
        if (forcePrefix == "") {
            forcePrefix = getDirName(installPrefix);
            
            // if this is inaccessible, we need to make a better decision
            version (Posix) {
                if (access((forcePrefix ~ '\0').ptr, accessRights.W_OK) != 0) {
                    // choose $HOME/d
                    if (home != "") {
                        char[] newPrefix = canonPath(home ~ "/d");
                        writefln("Default prefix %s is unwritable, using %s instead.",
                                 forcePrefix, newPrefix);
                        forcePrefix = newPrefix;
                    }
                }
            }
            
        } else {
            forcePrefix = canonPath(forcePrefix);
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
                 std.path.sep ~ "rebuild";
        } else version (Windows) {
            dsss_build = installPrefix ~
                std.path.sep ~ "rebuild.exe";
        } else {
            static assert(0);
        }
        
        // if we don't have rebuild next to us, try to use it without a path
        if (!std.file.exists(dsss_build)) {
            version (Posix) {
                dsss_build = "rebuild";
            } else version (Windows) {
                dsss_build = "rebuild.exe";
            } else {
                static assert(0);
            }
        }
        
        setEnvVar("DSSS_BUILD", dsss_build);
        
        if (!candyDocPrefix.length)
            candyDocPrefix = canonPath(
                installPrefix ~ std.path.sep ~
                ".." ~ std.path.sep ~
                "share" ~ std.path.sep ~
                "dsss" ~ std.path.sep ~
                "candydoc.tar.gz");
        if (!dsssLibTestDPrefix.length)
            dsssLibTestDPrefix = canonPath(
                installPrefix ~ std.path.sep ~
                ".." ~ std.path.sep ~
                "share" ~ std.path.sep ~
                "dsss" ~ std.path.sep ~
                "dsss_lib_test.d");
    }
    
    if (!binPrefix.length)
        binPrefix = forcePrefix ~ std.path.sep ~ "bin";
    if (!libPrefix.length)
        libPrefix = forcePrefix ~ std.path.sep ~ "lib";
    if (!includePrefix.length)
        includePrefix = forcePrefix ~ std.path.sep ~
             "include" ~ std.path.sep ~
             "d";
    if (!docPrefix.length)
        docPrefix = forcePrefix ~ std.path.sep ~
            "share" ~ std.path.sep ~
            "doc";
    if (!manifestPrefix.length)
        manifestPrefix = forcePrefix ~ std.path.sep ~
            "share" ~ std.path.sep ~
            "dsss" ~ std.path.sep ~
            "manifest";
    if (!etcPrefix.length) {
        if (forcePrefix == "/usr") {
            // in the case of /usr, use /etc instead of /usr/etc
            etcPrefix = "/etc";
        } else {
            etcPrefix = forcePrefix ~ std.path.sep ~
                "etc";
        }
    }
    if (!srcListPrefix.length)
        srcListPrefix = canonPath(
            forcePrefix ~ std.path.sep ~
            "share" ~ std.path.sep ~
            "dsss" ~ std.path.sep ~
            "sources");
    
    // set the scratch prefix and some some environment variables
    version (Posix) {
        scratchPrefix = "/tmp";
        
        setEnvVar("DSSS", installPrefix ~ std.path.sep ~ bname);
        setEnvVar("PREFIX", forcePrefix);
        setEnvVar("BIN_PREFIX", binPrefix);
        setEnvVar("LIB_PREFIX", libPrefix);
        setEnvVar("INCLUDE_PREFIX", includePrefix);
        setEnvVar("DOC_PREFIX", docPrefix);
        setEnvVar("ETC_PREFIX", etcPrefix);
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
        scratchPrefix = canonPath(installPrefix ~ std.path.sep ~
                                  ".." ~ std.path.sep ~
                                  "tmp");
        
        setEnvVar("DSSS", installPrefix ~ std.path.sep ~ bname);
        setEnvVar("PREFIX", forcePrefix);
        setEnvVar("BIN_PREFIX", binPrefix);
        setEnvVar("LIB_PREFIX", libPrefix);
        setEnvVar("INCLUDE_PREFIX", includePrefix);
        setEnvVar("DOC_PREFIX", docPrefix);
        setEnvVar("ETC_PREFIX", etcPrefix);
        setEnvVar("EXE_EXT", ".exe");
        
        // path for both bin and lib
        setEnvVar("PATH", binPrefix ~ ";" ~ libPrefix ~ ";" ~ getEnvVar("PATH"));
    } else {
        static assert(0);
    }
    
    dsss_build ~= " -Idsss_imports" ~ std.path.sep ~
        " -I. -S." ~ std.path.sep ~
        " -I" ~ includePrefix ~ " -S" ~ libPrefix ~ std.path.sep ~ " " ~
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
            if (isalnum(line[i]) ||
                line[i] == '_') {
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
                while (tok.length && iswhite(tok[$-1])) tok = tok[0..($-1)];
                
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
                    char[] pkg = std.string.replace(canonPath(section),
                                                    "\\", "/");
                    
                    // LNC:
                    // D<compiler>-<package-with-hyphens>
                    
                    // D
                    char[] lname = "D";
                    
                    // <compiler>
                    // FIXME: this should check with dsss_build
                    if (targetVersion("GNU")) {
                        lname ~= "G";
                    } else if (targetVersion("DigitalMars")) {
                        lname ~= "D";
                    } else {
                        lname ~= "O";
                    }
                    lname ~= "-";
                        
                    // <package>
                    // swap out /'s
                    pkg =
                        std.string.replace(pkg, "/", "-");
                    // name it
                    conf.settings[section]["target"] =
                        lname ~ pkg;
                        
                } else {
                    conf.settings[section]["type"] = "binary";
                    conf.settings[section]["target"] = std.path.getName(section);
                }
            }
                
            // FIXME: guarantee that sections aren't repeated
                
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
            
            testVersion(vertok);
            
            // now choose our path
            if (versions[vertok]) valid = !valid;
            if (!valid) {
                // false, find the end to this block
                closeScope();
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

/** Test if a version is set in the target (put into versions array) */
void testVersion(char[] vertok)
{
    if (!(vertok in versions)) {
        /* now check if this version is defined by making a .d file and
         * building it */
        int ret = system(dsss_build ~ "-testversion=" ~ vertok);
        
        if (ret == 0) {
            // true version
            versions[vertok] = true;
        } else {
            versions[vertok] = false;
        }
    }
}

/** Check a target version */
bool targetVersion(char[] vertok)
{
    testVersion(vertok);
    return versions[vertok];
}

/** If the target matches GNU OR Posix, this returns true */
bool targetGNUOrPosix()
{
    testVersion("GNU");
    testVersion("Posix");
    return (versions["GNU"] || versions["Posix"]);
}

/** Get a list of files from a target */
char[][] targetToFiles(char[] target, DSSSConf conf, bool includeDi = false)
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
            if (fnmatch(std.string.replace(path, "\\", "/"), exclude[i])) {
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

            // get the extension
            char[] ext = std.string.tolower(getExt(file)).dup;
            
            if (isdir(file)) {
                // perhaps recurse
                addDir(file);

            } else if (ext == "d") {
                // or just add it
                if (!excluded(file)) {
                    files ~= file;
                }

            } else if (ext == "di") {
                // only add .di files if we should
                if (includeDi) {
                    files ~= file;
                }
            }
        }
    }
    
    if (isdir(target)) {
        addDir(target, true);
    } else {
        files ~= target;
    }
    
    return files;
}

/** Perform a pre- or post- script step. Returns a list of installed files (if
 * applicable) */
char[][] dsssScriptedStep(DSSSConf conf, char[] step)
{
    // list of installed files
    char[][] manifest;
    
    // since parts of the script can potentially change the directory, store it
    char[] origcwd = getcwd();
    
    // split the steps by ;
    char[][] cmds = std.string.split(step, ";");
    
    foreach (cmd; cmds) {
        // clean cmd
        while (cmd.length > 0 && iswhite(cmd[0])) cmd = cmd[1..$];
        while (cmd.length > 0 && iswhite(cmd[$-1])) cmd = cmd[0..($-1)];
        writefln("Command: %s", cmd);
        
        // run it
        char[] ext = std.string.tolower(getExt(cmd));
        if (find(cmd, ' ') == -1 && ext == "d") {
            // if it's a .d file, -exec it
            saySystemDie(dsss_build ~ "-full -exec " ~ cmd);

        } else if (cmd.length > 5 &&
                   cmd[0..5] == "warn ") {
            writefln("WARNING: %s", cmd[5..$]);

        } else if (cmd.length > 6 &&
                   cmd[0..6] == "error ") {
            writefln("ERROR: %s", cmd[6..$]);
            exit(1);
            
        } else if (cmd.length > 8 &&
                   cmd[0..8] == "install ") {
            // doing an install
            char[][] comps = std.string.split(cmd);
            if (comps.length != 3) continue; // FIXME: not valid
            
            // do this install
            // check for / or \
            int slloc = std.string.rfind(comps[1], '/');
            if (slloc == -1)
                slloc = std.string.rfind(comps[1], '\\');
            
            // strip off the prefix from our manifest path
            char[] manifestPath = comps[2] ~ std.path.sep;
            if (manifestPath.length > forcePrefix.length &&
                manifestPath[0 .. forcePrefix.length] == forcePrefix)
                manifestPath = manifestPath[forcePrefix.length + 1 .. $];
            
            if (slloc != -1) {
                // path provided
                char[] f = comps[1][(slloc + 1) .. $];
                copyInFile(f,
                           comps[2],
                           comps[1][0 .. (slloc + 1)]);
                manifest ~= (manifestPath ~ f);
            } else {
                copyInFile(comps[1], comps[2]);
                manifest ~= (manifestPath ~ comps[1]);
            }

        } else if (cmd.length > 11 &&
                   cmd[0..11] == "installdir ") {
            // crawl for files, installing each
            char[][] comps = std.string.split(cmd);
            if (comps.length != 3) continue; // FIXME: not valid

            /// install the files in this directory
            void instDir(char[] ndir, char[] ipostfix = "") {
                char[][] dirFiles = listdir(ndir);
                foreach (file; dirFiles) {
                    // either recurse,
                    if (isdir(ndir ~ std.path.sep ~ file)) {
                        instDir(ndir ~ std.path.sep ~ file, ipostfix ~ std.path.sep ~ file);

                    } else {
                        // or install this file
                        dsssScriptedStep(conf, "install " ~
                                         ndir ~ std.path.sep ~ file ~ " " ~
                                         comps[2] ~ ipostfix);

                    }
                }
            }

            // start with the base
            instDir(comps[1]);
            
        } else if (cmd.length > 3 &&
                   cmd[0..3] == "cd ") {
            // change directories
            char[][] comps = std.string.split(cmd);
            if (comps.length != 2) continue; // FIXME: not valid
            
            // change our directory
            chdir(comps[1]);
            
        } else if (cmd.length > 5 &&
                   cmd[0..5] == "eval ") {
            // run the command, execute its output
            PStream proc;
            
            cmd = cmd[5..$];
            if (std.string.tolower(getExt(cmd)) == "d") {
                proc = new PStream(dsss_build ~ "-full -exec " ~ cmd);
            } else {
                proc = new PStream(cmd);
            }
            
            // now catch its output
            char[] readbuf;
            char readc;
            while (true) {
                try {
                    proc.read(readc);
                } catch (ReadException e) {
                    break;
                }
                readbuf ~= readc;
            }
            
            // and run it
            manifest ~= dsssScriptedStep(conf, readbuf);
            
            proc.close();
            
        } else if (cmd.length > 4 &&
                   (cmd[0..4] == "set " ||
                    cmd[0..4] == "add ")) {
            int i;
            
            bool adding = (cmd[0..4] == "add ");
            
            // set <section>.<setting> <value>
            cmd = cmd[4..$];
            
            // 1) get the <section>:<setting>
            char[] sset = cmd.dup;
            for (i = 0; i < cmd.length; i++) {
                if (cmd[i] == ' ') {
                    sset = sset[0 .. i];
                    cmd = cmd[i+1 .. $];
                    i = 0;
                    break;
                }
            }
            
            if (i == cmd.length) cmd = "";
            
            // 2) divide <section>:<setting>
            char[] section, setting;
            int dotloc = find(sset, ':');
            if (dotloc == -1) {
                section = "";
                setting = sset;
            } else {
                section = sset[0..dotloc].dup;
                setting = sset[dotloc+1 .. $].dup;
            }
            
            // 3) perhaps get a list of sections
            char[][] useSections;
            if (section == "*") {
                useSections = conf.sections;
            } else {
                useSections ~= section;
            }
            
            // 4) set
            foreach (sect; useSections) {
                if (sect in conf.settings) {
                    // perhaps add
                    if (adding) {
                        if (setting in conf.settings[sect]) {
                            cmd = conf.settings[sect][setting] ~ " " ~ cmd;
                        }
                    }
                    conf.settings[sect][setting] = cmd.dup;
                }
            }
            
        } else {
            // hopefully we can just run it
            saySystemDie(cmd);
        }
    }
    
    chdir(origcwd);
    
    return manifest;
}

/** Get sources from a list of elements (sources or targets) */
char[][] sourcesByElems(char[][] buildElems, DSSSConf conf)
{
    char[][] buildSources;
    
    if (buildElems.length == 0 && "defaulttargets" in conf.settings[""]) {
        buildElems = split(conf.settings[""]["defaulttargets"], " ");
    }
    
    if (buildElems.length) {
        if (buildElems.length == 1 && buildElems[0] == "all") {
            buildSources = conf.sections;
            
        } else {
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
    
    if (targetVersion("Posix")) {
        // lib<target>.so.<soversion>
        return "lib" ~ target ~ ".so." ~ getSoversion(settings);
    } else if (targetVersion("Windows")) {
        // <target>.dll
        return target ~ ".dll";
    } else {
        assert(0);
    }
}

/** Get a short shared library file names */
char[][] getShortShLibNames(char[][char[]] settings)
{
    char[] target = settings["target"];
    
    if (targetVersion("Posix")) {
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
    } else {
        // no short version
        return null;
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
        return "-L-soname=" ~ sonver;
    }
    return "";
}

/** Return true or false for whether libraries are safe  */
bool libsSafe()
{
    static bool tested = false;
    static bool safe = false;
    
    if (!tested) {
        int ret = system(dsss_build ~ "-libs-safe");
        safe = (ret == 0);
        tested = true;
    }
    
    return safe;
}

/** Return true or false for whether shared libraries are supported */
bool shLibSupport()
{
    static bool tested = false;
    static bool supported = false;
    
    if (!tested) {
        // ask dsss_build
        int ret = system(dsss_build ~ "-shlib-support");
        
        supported = (ret == 0);
        
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
        char[] target = prefix ~ std.path.sep ~ file;
        
        // preserve permissions
        saySystemDie("cp -fpRL " ~ from ~ file ~ " " ~ target);
        
        // but then guarantee the permissions we made aren't too bad (ignore errors)
        system("chmod a+rX " ~ target ~ " 2> /dev/null");
        
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

/** Read .dsssrc file */
char[][] readDSSSRC()
{
    char[] dsssrc;

    version (Windows) {
        // on Windows, just look in bindir
        char[] bindir, binname;
        if (whereAmI("dsss", bindir, binname)) {
            if (exists(bindir ~ "\\dsss.rc")) {
                dsssrc = cast(char[]) std.file.read(bindir ~ "\\dsss.rc");
            }
        }

    } else {
        char[] home = getEnvVar("HOME");
        if (exists(home ~ "/.dsssrc")) {
            dsssrc = cast(char[]) std.file.read(home ~ "/.dsssrc");
        }

    }

    // now split it up
    char[][] rcsplit = split(dsssrc);
    char[][] ret;
    foreach (se; rcsplit) {
        if (se != "") {
            ret ~= se;
        }
    }
    return ret;
}
