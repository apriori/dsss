/**
 * Main DSSS entry location
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
import sss.uninstall;

private {
    /** Possible commands */
    enum cmd_t {
        NONE,
            BUILD,
            CLEAN,
            DISTCLEAN,
            INSTALL,
            UNINSTALL,
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
                
            } else if (arg == "genconfig") {
                commandSet = true;
                command = cmd_t.GENCONFIG;
                
            }
            
        } else if (command == cmd_t.GENCONFIG ||
                   command == cmd_t.UNINSTALL) {
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
                   command == cmd_t.DISTCLEAN) {
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
`Usage: dsss [dsss options] <command> [command options]
  DSSS Options:
    --help|-h: Display this help.
  Commands:
    build:     build all or some binaries or libraries
    clean:     clean up object files from all or some builds
    distclean: clean up all files from all or some builds
    install:   install all or some binaries or libraries
    uninstall: uninstall a specified tool or library
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
        
    } else if (command == cmd_t.GENCONFIG) {
        writefln(
`Usage: dsss [dsss options] genconfig [install options] [sources, binaries or packages]
  Genconfig Options:
    [none yet]`
            );
        
    }
}
