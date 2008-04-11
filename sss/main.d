/**
 * Main DSSS entry location
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

module sss.main;

import std.file;
import std.path;
import std.stdio;
import std.string;

import std.c.stdlib;

import sss.build;
import sss.clean;
import sss.conf;
import sss.genconfig;
import sss.install;
version (DSSS_Light) {} else {
    import sss.net;
}
import sss.uninstall;

const char[] DSSS_VERSION = "0.76";

private {
    /** Possible commands */
    enum cmd_t {
        NONE,
            BUILD,
            CLEAN,
            DISTCLEAN,
            INSTALL,
            BINSTALL,
            UNINSTALL,
            INSTALLED,
            NET,
            GENCONFIG
    }
    
    /** The command in use */
    cmd_t command;
}

int main(char[][] args)
{
    bool commandSet = false;
    
    /** Elements to build/install/something */
    char[][] buildElems;

    /** Overridden dsss.conf to use */
    char[] useDSSSConf = null;

    char[] val;

    // Now load in dsssrc
    args ~= readDSSSRC();
    
    for (int i = 1; i < args.length; i++) {
        char[] arg = args[i];
        
        /** A simple function to check for any help-type option */
        bool argIsHelp() {
            return (arg == "--help" ||
                    arg == "-help" ||
                    arg == "-h" ||
                    arg == "-?");
        }
        
        /** Parse an argument */
        bool parseArg(char[] arg, char[] expect, bool takesVal, char[]* val = null) {
            if (takesVal) {
                if (arg.length > expect.length + 2 &&
                    arg[0 .. (expect.length + 3)] == "--" ~ expect ~ "=") {
                    *val = arg[(expect.length + 3) .. $];
                    return true;
                } else if (arg.length > expect.length + 1 &&
                           arg[0 .. (expect.length + 2)] == "-" ~ expect ~ "=") {
                    *val = arg[(expect.length + 2) .. $];
                    return true;
                }
                return false;
            } else {
                if (arg == "--" ~ expect ||
                    arg == "-" ~ expect) return true;
                return false;
            }
        }
        
        if (!commandSet) {
            // no command set yet, DSSS options
            if (argIsHelp()) {
                usage();
                return 0;

            } else if (parseArg(arg, "config", true, &val)) {
                useDSSSConf = val.dup;
                
            } else if (arg == "build") {
                commandSet = true;
                command = cmd_t.BUILD;
                
            } else if (arg == "clean") {
                commandSet = true;
                command = cmd_t.CLEAN;
                
            } else if (arg == "distclean") {
                commandSet = true;
                command = cmd_t.DISTCLEAN;
                
            } else if (arg == "install") {
                commandSet = true;
                command = cmd_t.INSTALL;

            } else if (arg == "binstall") {
                commandSet = true;
                command = cmd_t.BINSTALL;
                
            } else if (arg == "uninstall") {
                commandSet = true;
                command = cmd_t.UNINSTALL;
                
            } else if (arg == "installed") {
                commandSet = true;
                command = cmd_t.INSTALLED;
                
            } else if (arg == "net") {
                version (DSSS_Light) {
                    writefln("The 'net' command is not supported in DSSS Light");
                    exit(1);
                } else {
                    commandSet = true;
                    command = cmd_t.NET;
                }
                
            } else if (arg == "genconfig") {
                commandSet = true;
                command = cmd_t.GENCONFIG;
                
            } else {
                writefln("Unrecognized argument: %s", arg);
                exit(1);
            }
            
        } else {
            /* generic options */
            if (argIsHelp()) {
                usage();
                return 0;
                
            } else if (parseArg(arg, "use", true, &val)) {
                // force a use-dir
                useDirs ~= makeAbsolute(val);
                
            } else if (parseArg(arg, "doc", false)) {
                doDocs = true;
                
            } else if (parseArg(arg, "doc-binaries", false)) {
                doDocs = true;
                doDocBinaries = true;

            } else if (parseArg(arg, "debug", false)) {
                buildDebug = true;

            } else if (parseArg(arg, "prefix", true, &val)) {
                // force a prefix
                forcePrefix = makeAbsolute(val);
                
            } else if (parseArg(arg, "keep-response-files", false)) {
                deleteRFiles = false;
                
            } else if (parseArg(arg, "bindir", true, &val)) {
                binPrefix = makeAbsolute(val);
                
            } else if (parseArg(arg, "libdir", true, &val)) {
                libPrefix = makeAbsolute(val);
                
            } else if (parseArg(arg, "includedir", true, &val)) {
                includePrefix = makeAbsolute(val);
                
            } else if (parseArg(arg, "docdir", true, &val)) {
                docPrefix = makeAbsolute(val);
                
            } else if (parseArg(arg, "sysconfdir", true, &val)) {
                etcPrefix = makeAbsolute(val);
                
            } else if (parseArg(arg, "scratchdir", true, &val)) {
                scratchPrefix = makeAbsolute(val);
                
            } else if (arg == "-arch" ||
                       arg == "-isysroot" ||
                       arg == "-framework") {
                // special Mac OS X flags
                dsss_buildOptions ~= arg ~ " ";
                i++;
                if (i >= args.length) {
                    writefln("Argument expected after %s", arg);
                    return 1;
                }
                dsss_buildOptions ~= args[i] ~ " ";
                
            } else if (arg.length >= 1 &&
                       arg[0] == '-') {
                // perhaps specific to a command
                if (command == cmd_t.BUILD) {
                    if (parseArg(arg, "test", false)) {
                        testLibs = true;
                    } else {
                        dsss_buildOptions ~= arg ~ " ";
                    }

                } else if (command == cmd_t.NET) {
                    version (DSSS_Light) {} else {
                        if (parseArg(arg, "source", true, &val)) {
                            forceMirror = val;
                        } else {
                            dsss_buildOptions ~= arg ~ " ";
                        }
                    }
                    
                } else {
                    // pass through to build
                    dsss_buildOptions ~= arg ~ " ";
                }
                
            } else {
                // something to pass in
                buildElems ~= arg;
            }
            
            /* there are presently no specific options */
        }
    }
    
    if (!commandSet) {
        usage();
        return 0;
    }
    
    // Before running anything, get our prefix
    getPrefix(args[0]);
    
    // add useDirs
    foreach (dir; useDirs) {
        dsss_build ~= "-I" ~ dir ~ std.path.sep ~
            "include" ~ std.path.sep ~
            "d -S" ~ dir ~ std.path.sep ~
            "lib ";
    }

    // if a specific dsss.conf file was requested, use it
    DSSSConf conf = null;
    if (useDSSSConf != "") {
        writefln("WARNING: The --config option is only recommended for testing, and should NOT be");
        writefln("         a part of your general build routine.");
        conf = readConfig(buildElems, false, useDSSSConf);
    }
    
    switch (command) {
        case cmd_t.BUILD:
            return sss.build.build(buildElems, conf);
            break;
            
        case cmd_t.CLEAN:
            return sss.clean.clean(conf);
            break;
            
        case cmd_t.DISTCLEAN:
            return sss.clean.distclean(conf);
            break;
            
        case cmd_t.INSTALL:
            return sss.install.install(buildElems, conf);
            break;

        case cmd_t.BINSTALL:
        {
            int bret = sss.build.build(buildElems, conf);
            if (bret) return bret;
            return sss.install.install(buildElems, conf);
            break;
        }
            
        case cmd_t.UNINSTALL:
            return sss.uninstall.uninstall(buildElems);
            break;
            
        case cmd_t.INSTALLED:
            return sss.uninstall.installed();
            break;
            
        case cmd_t.NET:
            version (DSSS_Light) {} else {
                return sss.net.net(buildElems);
            }
            break;
            
        case cmd_t.GENCONFIG:
            return sss.genconfig.genconfig(buildElems);
            break;
    }
    
    return 0;
}

/** Make a dir absolute */
char[] makeAbsolute(char[] path)
{
    if (!isabs(path)) {
        return getcwd() ~ std.path.sep ~ path;
    }
    return path;
}

void usage()
{
    if (command == cmd_t.NONE) {
        writefln(
`DSSS version ` ~ DSSS_VERSION ~ `
Usage: dsss [dsss options] <command> [options]
  DSSS Options:
    --help|-h: Display this help.
    --config=<alternative dsss.conf file>: Should be used for testing only.
  Commands:
    build:     build all or some binaries or libraries
    clean:     clean up object files from all or some builds
    distclean: clean up all files from all or some builds
    install:   install all or some binaries or libraries
    uninstall: uninstall a specified tool or library
    installed: list installed software`);
        version(DSSS_Light) {} else {
            writefln(
`    net:       Internet-based installation and package management`);
        }
        writefln(
`    genconfig: generate a config file`);
        
    } else if (command == cmd_t.BUILD) {
        writefln(
`Usage: dsss [dsss options] build [build options] [sources, binaries or packages]
  Build options:
    --test: test compiled libraries`
            );
        
    } else if (command == cmd_t.CLEAN) {
        writefln(
`Usage: dsss [dsss options] clean [clean options] [sources, binaries or packages]`
            );
        
    } else if (command == cmd_t.DISTCLEAN) {
        writefln(
`Usage: dsss [dsss options] distclean [distclean options] [sources, binaries or packages]`
            );
        
    } else if (command == cmd_t.INSTALL) {
        writefln(
`Usage: dsss [dsss options] install [install options] [sources, binaries or packages]`
            );
        
   } else if (command == cmd_t.BINSTALL) {
        writefln(
`Usage: dsss [dsss options] binstall [binstall options] [sources, binaries or packages]`
            );

   } else if (command == cmd_t.UNINSTALL) {
        writefln(
`Usage: dsss [dsss options] uninstall [uninstall options] <tools or libraries>`
            );
        
    } else if (command == cmd_t.INSTALLED) {
        writefln(
`Usage: dsss [dsss options] installed`
            );
        
    } else if (command == cmd_t.NET) {
        writefln(
`Usage: dsss [dsss options] net <net command> [options] <package name>
  Net commands:
    deps:    install (from the network source) dependencies of the present
             package
    depslist:list dependencies, but do not install them
    install: install a package via the network source
    fetch:   fetch but do not compile or install a package
    list:    list all installable packages
    search:  find an installable package by name
  Net options:
    --source=<URL>: Use the given URL for the sources list, rather than asking
            or using the last URL used.`
            );

        
    } else if (command == cmd_t.GENCONFIG) {
        writefln(
`Usage: dsss [dsss options] genconfig [install options] [sources, binaries or packages]`
            );
        
    }
    
    writefln(
`  Generic options (must come after the command):
    --help: display specific options and information
    --prefix=<prefix>: set the install prefix
    --doc: Generate/install documentation for libraries
    --doc-binaries: Generate/install documentation for libraries and binaries.
        This will generate a lot of needless documentation for prerequisite
        libraries, and is therefore not recommended for general use.
    --use=<directory containing import library includes and libs>
    --keep-response-files: Do not delete temporary rebuild response files

    --bindir=<dir> [default <prefix>/bin]
    --libdir=<dir> [default <prefix>/lib]
    --includedir=<dir> [default <prefix>/include/d]
    --docdir=<dir> [default <prefix>/share/doc]
    --sysconfdir=<dir> [default <prefix>/etc]
    --scratchdir=<dir> [default /tmp]

  All other options are passed through to rebuild and ultimately the compiler.`);
        
}
