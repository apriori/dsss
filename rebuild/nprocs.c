#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <unistd.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

int nprocs()
{
#if defined(_WIN32)
    SYSTEM_INFO info;
    GetSystemInfo(&info);
    return info.dwNumberOfProcessors;

#elif defined(_SC_NPROCESSORS_ONLN)
    int nprocs = sysconf(_SC_NPROCESSORS_ONLN);
    if (nprocs < 1) return 1;
    return nprocs;

#else
    return 1;

#endif
}
