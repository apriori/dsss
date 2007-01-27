
// Component to read configuration
// Copyright (c) 2007  Gregor Richards
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt
// or any later version.
// See the included readme.txt for details.

#ifndef CONFIG_H
#define CONFIG_H

#include <map>
#include <string>

typedef std::map<std::string, std::string> Config;

extern Config masterConfig;

extern std::string compileFlags;
extern std::string linkFlags;

// Read a configuration file
void readConfig(char *argvz, const std::string &profile);

// Read from a command
int readCommand(std::string cmd, char *buf, int len);

// Add a flag, with a default
void addFlag(std::string &to, const std::string &flag, const std::string &def,
             const std::string &inp = "", const std::string &out = "");

// Add a library to linkFlags
void linkLibrary(const std::string &name);

#endif
