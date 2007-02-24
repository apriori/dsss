
// Component to parse and generate response files
// Copyright (c) 2007  Gregor Richards
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt
// or any later version.
// See the included readme.txt for details.

#ifndef RESPONSE_H
#define RESPONSE_H

void dupArgs(int *argc, char ***argv);

void parseResponseFile(int *argc, char ***argv, char *rf, int argnum);

int systemResponse(const char *cmd, const char *rflag, const char *rfile);

#endif
