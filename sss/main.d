/**
 * Main DSSS entry location
 * 
 * Authors:
 *  Gregor Richards
 * 
 * License:
 *  Copyright (c) 2006  Gregor Richards
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

import sss.build;
import sss.clean;
import sss.conf;
import sss.genconfig;
import sss.install;
import sss.net;
import sss.uninstall;

const char[] DSSS_VERSION = "0.7";

private {
    /** Possible commands */
    enum cmd_t {
        NONE,
            BUILD,
            CLEAN,
            DISTCLEAN,
            INSTALL,
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
    
    /** Usedirs (dirs to import both includes and libs from */
    char[][] useDirs;
    
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
                
            } else if (arg == "uninstall") {
                commandSet = true;
                command = cmd_t.UNINSTALL;
                
            } else if (arg == "installed") {
                commandSet = true;
                command = cmd_t.INSTALLED;
                
            } else if (arg == "net") {
                commandSet = true;
                command = cmd_t.NET;
                
            } else if (arg == "genconfig") {
                commandSet = true;
                command = cmd_t.GENCONFIG;
                
            }
            
        } else if (command == cmd_t.GENCONFIG ||
                   command == cmd_t.UNINSTALL ||
                   command == cmd_t.NET) {
            /* commands with no special options (put them in their own else-if
             * if they gain options */
            if (argIsHelp()) {
                usage();
                return 0;
                
            } else {
                // a binary or library
                buildElems ~= arg;
            }
            
        } else if (command == cmd_t.CLEAN ||
                   command == cmd_t.DISTCLEAN ||
                   command == cmd_t.INSTALLED) {
            /* commands that take no options whatsoever */
            if (argIsHelp()) {
                usage();
                return 0;
                
            } else {
                writefln("ERROR: Command takes no arguments.");
            }
            
        } else if (command == cmd_t.BUILD) {
            char[] val;
            
            if (argIsHelp()) {
                usage();
                return 0;
                
            } else if (parseArg(arg, "use", true, &val)) {
                // force a use-dir
                useDirs ~= val;
                
            } else if (arg.length >= 1 &&
                       arg[0] == '-') {
                // pass through to build
                dsss_buildOptions ~= arg ~ " ";
                
            } else {
                buildElems ~= arg;
                
            }
            
        } else if (command == cmd_t.INSTALL) {
            char[] val;
            
            if (argIsHelp()) {
                usage();
                return 0;
                
            } else if (parseArg(arg, "prefix", true, &val)) {
                // force a prefix
                forcePrefix = val;
                
            } else {
                buildElems ~= arg;
            }
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
            "d -L" ~ dir ~ std.path.sep ~
            "lib ";
    }
    
    switch (command) {
        case cmd_t.BUILD:
            return sss.build.build(buildElems);
            break;
            
        case cmd_t.CLEAN:
            return sss.clean.clean();
            break;
            
        case cmd_t.DISTCLEAN:
            return sss.clean.distclean();
            break;
            
        case cmd_t.INSTALL:
            return sss.install.install(buildElems);
            break;
            
        case cmd_t.UNINSTALL:
            return sss.uninstall.uninstall(buildElems);
            break;
            
        case cmd_t.INSTALLED:
            return sss.uninstall.installed();
            break;
            
        case cmd_t.NET:
            return sss.net.net(buildElems);
            break;
            
        case cmd_t.GENCONFIG:
            return sss.genconfig.genconfig(buildElems);
            break;
    }
    
    return 0;
}

void usage()
{
    if (command == cmd_t.NONE) {
        writefln(
`DSSS version ` ~ DSSS_VERSION ~ `
Usage: dsss [dsss options] <command> [command options]
  DSSS Options:
    --help|-h: Display this help.
  Commands:
    build:     build all or some binaries or libraries
    clean:     clean up object files from all or some builds
    distclean: clean up all files from all or some builds
    install:   install all or some binaries or libraries
    uninstall: uninstall a specified tool or library
    installed: list installed software
    net:       Internet-based installation and package management
    genconfig: generate a config file
  Each command has its own set of options, which are not listed here. To list
  the options for a command:
    dsss <command> --help`
            );
        
    } else if (command == cmd_t.BUILD) {
        writefln(
`Usage: dsss [dsss options] build [build options] [sources, binaries or packages]
  Build Options:
    --use=<directory containing import library includes and libs>
    All other options are passed through to build and ultimately the compiler.`
            );
        
    } else if (command == cmd_t.CLEAN) {
        writefln(
`Usage: dsss [dsss options] clean [clean options] [sources, binaries or packages]
  Clean Options:
    [none yet]`
            );
        
    } else if (command == cmd_t.DISTCLEAN) {
        writefln(
`Usage: dsss [dsss options] distclean [distclean options] [sources, binaries or packages]
  Distclean Options:
    [none yet]`
            );
        
    } else if (command == cmd_t.INSTALL) {
        writefln(
`Usage: dsss [dsss options] install [install options] [sources, binaries or packages]
  Install Options:
    --prefix=<prefix>: set the install prefix`
            );
        
    } else if (command == cmd_t.UNINSTALL) {
        writefln(
`Usage: dsss [dsss options] uninstall [uninstall options] [tools or libraries]
  Uninstall Options:
    [none yet]`
            );
        
    } else if (command == cmd_t.INSTALLED) {
        writefln(
`Usage: dsss [dsss options] installed`
            );
        
    } else if (command == cmd_t.NET) {
        writefln(
`Usage: dsss [dsss options] net <net command> <package name>
  Net Commands:
    deps:    install (from the network source) dependencies of the present
             package
    install: install a package via the network source
    fetch:   fetch but do not compile or install a package
    list:    list all installable packages
    search:  find an installable package by name`
            );

        
    } else if (command == cmd_t.GENCONFIG) {
        writefln(
`Usage: dsss [dsss options] genconfig [install options] [sources, binaries or packages]
  Genconfig Options:
    [none yet]`
            );
        
    }
}
