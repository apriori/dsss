%if %{?_with_dmd:1}%{!?_with_dmd:0}
%define with_dmd 1
%define with_gdc 0
%else
%define with_dmd 0
%define with_gdc 1
%endif

Summary: D Shared Software System
Name: dsss
Version: 0.74
Release: 0%{?dist}
Group: Development/Tools
License: MIT
URL: http://dsource.org/projects/dsss/

Source: http://svn.dsource.org/projects/dsss/downloads/%{version}/%{name}-%{version}.tar.bz2
BuildRoot: %{_tmppath}/%{name}-%{version}-root
%if %{with_dmd}
BuildRequires: dmd
%endif
%if %{with_gdc}
BuildRequires: gdc
%endif
Requires: rebuild = %{version}, curl

# Spec file written by Anders F Bjorklund <afb@users.sourceforge.net>

%description
DSSS, the D Shared Software System, is a tool to ease the building,
installation, configuration and acquisition of D software.

%package devel
Summary: Build tool for D - development files
Group: Development/Tools

%description devel
Allows you to use DSSS libraries in your own dsss.conf D programs.

%package -n rebuild
Version: %{version}
Summary: Build tool for D
Group: Development/Tools
License: Artistic or GPL

%description -n rebuild
Rebuild is a tool for building D software.
It is based on the frontend to the DMD D compiler.

Essentially, for any D source file given, rebuild finds all
dependencies, and compiles them all into the target. 

%prep
%setup -q
%if %{with_dmd}
ln -s Makefile.dmd.posix Makefile
%endif
%if %{with_gdc}
ln -s Makefile.gdc.posix Makefile
%endif

%build
make CXXFLAGS="$RPM_OPT_FLAGS"

%install
rm -rf $RPM_BUILD_ROOT
make install PREFIX="$RPM_BUILD_ROOT%{_prefix}"
mv $RPM_BUILD_ROOT%{_prefix}/etc $RPM_BUILD_ROOT%{_sysconfdir} || :
rm -rf $RPM_BUILD_ROOT%{_prefix}/share/doc

%clean
rm -rf $RPM_BUILD_ROOT

%files
%doc docs/*
%defattr(-,root,root)
%{_bindir}/dsss
%{_mandir}/man1/dsss.1*
%dir %{_datadir}/dsss
%{_datadir}/dsss/dsss_lib_test.d
%dir %{_datadir}/dsss/manifest
%{_datadir}/dsss/manifest/*.manifest
%dir %{_datadir}/dsss/sources
%config %{_datadir}/dsss/sources/*
%{_datadir}/dsss/candydoc.tar.gz
%dir %{_sysconfdir}/dsss
%config %{_sysconfdir}/dsss/*

%files devel
%{_includedir}/d/*
%{_libdir}/*.a

%files -n rebuild
%doc rebuild/README rebuild/readme.txt
%doc rebuild/artistic.txt rebuild/gpl.txt
%{_bindir}/rebuild
%{_bindir}/rerun
%{_bindir}/rebuild_choosedc
%{_mandir}/man1/rebuild.1*
%{_mandir}/man1/rerun.1*
%{_mandir}/man1/rebuild_choosedc.1*
%dir %{_datadir}/rebuild
%{_datadir}/rebuild/testtango.d
%dir %{_sysconfdir}/rebuild
%config %{_sysconfdir}/rebuild/*
%{_prefix}/lib/dymoduleinit.d
