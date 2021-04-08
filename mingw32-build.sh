#!/bin/sh
#
# Build script for cross compiling and packaging SQLite
# ODBC drivers and tools for Win32 using MinGW and NSIS.
# Tested on Fedora Core 3/5/8, Debian Etch, RHEL 5/6
#
# Cross toolchain and NSIS for Linux/i386/x86_64 can be fetched from
#  http://www.ch-werner.de/xtools/crossmingw64-0.3-1.i386.rpm
#  http://www.ch-werner.de/xtools/crossmingw64-0.3-1.x86_64.rpm
#  http://www.ch-werner.de/xtools/nsis-2.37-1.i386.rpm
# or
#  http://www.ch-werner.de/xtools/crossmingw64-0.3.i386.tar.bz2
#  http://www.ch-werner.de/xtools/crossmingw64-0.3.x86_64.tar.bz2
#  http://www.ch-werner.de/xtools/nsis-2.37-1_i386.tar.gz

# Some aspects of the build process can be controlled by shell variables:
#
#  SQLITE_DLLS=1     build and package drivers with SQLite 2/3 DLLs
#  SQLITE_DLLS=2     build drivers with refs to SQLite 2/3 DLLs
#                    SQLite3 driver can use System.Data.SQlite.dll

set -e

VER3=3.32.3
VER3X=3320300
VERZ=1.2.8

if test -f "$WITH_SEE" ; then
    export SEEEXT=see
    ADD_NSIS="$ADD_NSIS -DWITH_SEE=$SEEEXT"
    if test "$SQLITE_DLLS" = "2" ; then
	SQLITE_DLLS=1
    fi
fi

if test "$SQLITE_DLLS" = "2" ; then
    # turn on -DSQLITE_DYNLOAD in sqlite3odbc.c
    export ADD_CFLAGS="-DWITHOUT_SHELL=1 -DWITH_SQLITE_DLLS=2"
    ADD_NSIS="$ADD_NSIS -DWITHOUT_SQLITE3_EXE"
elif test -n "$SQLITE_DLLS" ; then
    export ADD_CFLAGS="-DWITHOUT_SHELL=1 -DWITH_SQLITE_DLLS=1"
    export SQLITE3_DLL="-Lsqlite3 -lsqlite3"
    export SQLITE3_EXE="sqlite3.exe"
    ADD_NSIS="$ADD_NSIS -DWITH_SQLITE_DLLS"
else
    export SQLITE3_A10N_O="sqlite3a10n.o"
    export SQLITE3_EXE="sqlite3.exe"
fi

echo "=================="
echo "Preparing zlib ..."
echo "=================="
test -r zlib-${VERZ}.tar.gz || \
    wget -c http://zlib.net/fossils/zlib-${VERZ}.tar.gz || exit 1
rm -rf zlib
rm -rf zlib-${VERZ}
tar xzf zlib-${VERZ}.tar.gz
ln -sf zlib-${VERZ} zlib

echo "====================="
echo "Preparing sqlite3 ..."
echo "====================="
test -r sqlite-src-${VER3X}.zip || \
    wget -c http://www.sqlite.org/2020/sqlite-src-${VER3X}.zip \
      --no-check-certificate
test -r sqlite-src-${VER3X}.zip || exit 1

rm -rf sqlite3
rm -rf sqlite-src-${VER3X}
unzip sqlite-src-${VER3X}.zip
ln -sf sqlite-src-${VER3X} sqlite3

test -r sqlite3/tool/mkshellc.tcl && \
  sed -i -e 's/ rb/ r/g' sqlite3/tool/mkshellc.tcl

# appendText name clash in sqlite3 shell
perl -pi -e 's/appendText/shAppendText/g' sqlite3/src/shell.c.in
perl -pi -e 's/^SRC =/SRC +=/' sqlite3/main.mk

test -r sqlite3/src/shell.c.in &&
  ( cd sqlite3/src ; tclsh ../tool/mkshellc.tcl > shell.c )

# same but new module libshell.c
cp -p sqlite3/src/shell.c sqlite3/src/libshell.c

test "$VER3" = "3.22.0" -o "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && patch sqlite3/src/os_win.h <<'EOD'
--- sqlite3.orig/src/os_win.h       2018-01-22 19:57:25.000000000 +0100
+++ sqlite3/src/os_win.h    2018-02-21 21:13:46.000000000 +0100
@@ -22,8 +22,9 @@
 
 #ifdef __CYGWIN__
 # include <sys/cygwin.h>
-# include <errno.h> /* amalgamator: dontcache */
 #endif
+#include <sys/stat.h> /* amalgamator: dontcache */
+#include <errno.h> /* amalgamator: dontcache */
 
 /*
 ** Determine if we are dealing with Windows NT.
EOD

test "$VER3" = "3.13.0" -o "$VER3" = "3.14.0" -o "$VER3" = "3.14.1" \
  -o "$VER3" = "3.15.0" -o "$VER3" = "3.15.1" -o "$VER3" = "3.15.2" \
  -o "$VER3" = "3.19.3" -o "$VER3" = "3.22.0" -o "$VER3" = "3.32.2" \
  -o "$VER3" = "3.32.3" \
  && patch sqlite3/src/libshell.c <<'EOD'
--- sqlite3.orig/src/libshell.c.orig	2016-05-18 13:06:59.000000000 +0200
+++ sqlite3/src/libshell.c	2016-06-04 17:02:05.000000000 +0200
@@ -53,6 +53,10 @@
 #include <ctype.h>
 #include <stdarg.h>
 
+#ifdef _WIN32
+#include <windows.h>
+#endif
+
 #if !defined(_WIN32) && !defined(WIN32)
 # include <signal.h>
 # if !defined(__RTP__) && !defined(_WRS_KERNEL)
@@ -5195,20 +5199,9 @@
   return argv[i];
 }
 
-#ifndef SQLITE_SHELL_IS_UTF8
-#  if (defined(_WIN32) || defined(WIN32)) && defined(_MSC_VER)
-#    define SQLITE_SHELL_IS_UTF8          (0)
-#  else
-#    define SQLITE_SHELL_IS_UTF8          (1)
-#  endif
-#endif
+#define SQLITE_SHELL_IS_UTF8          (1)
 
-#if SQLITE_SHELL_IS_UTF8
-int SQLITE_CDECL main(int argc, char **argv){
-#else
-int SQLITE_CDECL wmain(int argc, wchar_t **wargv){
-  char **argv;
-#endif
+int sqlite3_main(int argc, char **argv){
   char *zErrMsg = 0;
   ShellState data;
   const char *zInitFile = 0;
@@ -5375,6 +5368,19 @@
     }
   }
   if( data.zDbFilename==0 ){
+#if defined(_WIN32) && !defined(__TINYC__)
+    static OPENFILENAME ofn;
+    static char zDbFn[1024];
+    ofn.lStructSize = sizeof(ofn);
+    ofn.lpstrFile = (LPTSTR) zDbFn;
+    ofn.nMaxFile = sizeof(zDbFn);
+    ofn.Flags = OFN_PATHMUSTEXIST | OFN_EXPLORER | OFN_NOCHANGEDIR;
+    if ( GetOpenFileName(&ofn) ){
+      data.zDbFilename = zDbFn;
+    }
+  }
+  if( data.zDbFilename==0 ){
+#endif
 #ifndef SQLITE_OMIT_MEMORYDB
     data.zDbFilename = ":memory:";
     warnInmemoryDb = argc==1;
EOD

rm -f sqlite3/src/minshell.c
touch sqlite3/src/minshell.c
patch sqlite3/src/minshell.c <<'EOD'
--- sqlite3.orig/src/minshell.c  2007-01-10 18:46:47.000000000 +0100
+++ sqlite3/src/minshell.c  2007-01-10 18:46:47.000000000 +0100
@@ -0,0 +1,20 @@
+/*
+** 2001 September 15
+**
+** The author disclaims copyright to this source code.  In place of
+** a legal notice, here is a blessing:
+**
+**    May you do good and not evil.
+**    May you find forgiveness for yourself and forgive others.
+**    May you share freely, never taking more than you give.
+**
+*************************************************************************
+** This file contains code to implement the "sqlite" command line
+** utility for accessing SQLite databases.
+*/
+
+int sqlite3_main(int argc, char **argv);
+
+int main(int argc, char **argv){
+  return sqlite3_main(argc, argv);
+}
EOD

# amalgamation: add libshell.c 
test "$VER3" != "3.5.6" && test -r sqlite3/tool/mksqlite3c.tcl && \
  patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/tool/mksqlite3c.tcl	2007-04-02 14:20:10.000000000 +0200
+++ sqlite3/tool/mksqlite3c.tcl	2007-04-03 09:42:03.000000000 +0200
@@ -194,6 +194,7 @@
    where.c
 
    parse.c
+   libshell.c

    tokenize.c
    complete.c
EOD


test "$VER3" = "3.8.8" -o "$VER3" = "3.8.9" -o "$VER3" = "3.8.10" \
  -o "$VER3" = "3.8.11" -o "$VER3" = "3.9.0" -o "$VER3" = "3.9.1" \
  -o "$VER3" = "3.9.2" -o "$VER3" = "3.10.0" -o "$VER3" = "3.10.2" \
  -o "$VER3" = "3.12.2" -o "$VER3" = "3.13.0" -o "$VER3" = "3.14.0" \
  -o "$VER3" = "3.14.1" -o "$VER3" = "3.15.0" -o "$VER3" = "3.15.1" \
  -o "$VER3" = "3.15.2" -o "$VER3" = "3.19.3" -o "$VER3" = "3.22.0" \
  -o "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/src/tclsqlite.c    2015-01-16 14:47:26.000000000 +0100
+++ sqlite3/src/tclsqlite.c 2015-01-19 17:56:26.517386413 +0100
@@ -29,6 +29,7 @@
 /*
 ** If requested, include the SQLite compiler options file for MSVC.
 */
+#ifndef NO_TCL     /* Omit this whole file if TCL is unavailable */
 #if defined(INCLUDE_MSVC_H)
 #include "msvc.h"
 #endif
@@ -3888,3 +3889,5 @@
   return 0;
 }
 #endif /* TCLSH */
+
+#endif /* !defined(NO_TCL) */
EOD

# missing windows.h for DWORD, HANDLE in threads.c
test "$VER3" = "3.8.7" -o "$VER3" = "3.8.8" -o "$VER3" = "3.8.9" \
  -o "$VER3" = "3.8.10" -o "$VER3" = "3.8.11" -o "$VER3" = "3.9.0" \
  -o "$VER3" = "3.9.1" -o "$VER3" = "3.9.2" -o "$VER3" = "3.10.0" \
  -o "$VER3" = "3.10.2" -o "$VER3" = "3.12.2" -o "$VER3" = "3.13.0" \
  -o "$VER3" = "3.14.0" -o "$VER3" = "3.14.1" -o "$VER3" = "3.15.0" \
  -o "$VER3" = "3.15.1" -o "$VER3" = "3.15.2" -o "$VER3" = "3.19.3" \
  -o "$VER3" = "3.22.0" -o "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/src/threads.c      2014-10-17 13:38:27.000000000 +0200
+++ sqlite3/src/threads.c   2014-10-26 13:40:26.000000000 +0100
@@ -101,6 +101,7 @@
 #if SQLITE_OS_WIN && !SQLITE_OS_WINCE && !SQLITE_OS_WINRT && SQLITE_THREADSAFE>0
 
 #define SQLITE_THREADS_IMPLEMENTED 1  /* Prevent the single-thread code below */
+#include <windows.h>
 #include <process.h>
 
 /* A running thread */
EOD

test "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && perl -pi -e 's/ rb\]/ r\]/g' sqlite3/tool/mkopcodec.tcl \
      sqlite3/tool/mkccode.tcl

echo "========================"
echo "Cleanup before build ..."
echo "========================"
make -f Makefile.mingw32 clean
make -C sqlite3 -f ../mf-sqlite3.mingw32 clean

echo "================="
echo "Building zlib ..."
echo "================="

make -C zlib -f ../mf-zlib.mingw32 all

echo "====================="
echo "Building SQLite 3 ..."
echo "====================="

test -r sqlite3/tool/mksqlite3c.tcl && \
  make -C sqlite3 -f ../mf-sqlite3.mingw32 sqlite3.c

if test -r sqlite3/sqlite3.c -a -f "$WITH_SEE" ; then
    cat sqlite3/sqlite3.c "$WITH_SEE" >sqlite3.c
    ADD_CFLAGS="$ADD_CFLAGS -DSQLITE_HAS_CODEC=1"
    ADD_CFLAGS="$ADD_CFLAGS -DSQLITE_ACTIVATION_KEY=\\\"$SEE_KEY\\\""
    ADD_CFLAGS="$ADD_CFLAGS -DSEEEXT=\\\"$SEEEXT\\\""
    ADD_CFLAGS="$ADD_CFLAGS -DSQLITE_API=static -DWIN32=1 -DNDEBUG=1 -DNO_TCL"
    ADD_CFLAGS="$ADD_CFLAGS -DTHREADSAFE=1"
    ADD_CFLAGS="$ADD_CFLAGS -DSQLITE_DLL=1 -DSQLITE_THREADSAFE=1"
    ADD_CFLAGS="$ADD_CFLAGS -DSQLITE_OS_WIN=1 -DSQLITE_ASCII=1"
    ADD_CFLAGS="$ADD_CFLAGS -DSQLITE_SOUNDEX=1"
    ADD_CFLAGS="$ADD_CFLAGS -DSQLITE_ENABLE_COLUMN_METADATA=1"
    ADD_CFLAGS="$ADD_CFLAGS -DWITHOUT_SHELL=1"
    export ADD_CFLAGS
    ADD_NSIS="$ADD_NSIS -DWITHOUT_SQLITE3_EXE"
    unset SQLITE3_A10N_O
    unset SQLITE3_EXE
fi
test "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && patch sqlite3/sqlite3.c <<'EOD'
--- sqlite3.c.orig	2020-06-12 06:16:37.000000000 +0200
+++ sqlite3.c	2020-06-12 07:34:44.000000000 +0200
@@ -158596,7 +158596,7 @@
 #  define SQLITE_OMIT_POPEN 1
 # else
 #  include <io.h>
-/* #  include <fcntl.h> */
+#  include <fcntl.h>
 #  define isatty(h) _isatty(h)
 #  ifndef access
 #   define access(f,m) _access((f),(m))
EOD

echo "==============================="
echo "Building ODBC drivers and utils"
echo "==============================="
make -f Makefile.mingw32 all_no2

echo "======================="
echo "Cleanup after build ..."
echo "======================="
mv sqlite3/sqlite3.c sqlite3/sqlite3.amalg
make -C sqlite3 -f ../mf-sqlite3.mingw32 clean
rm -f sqlite3/sqlite3.exe
mv sqlite3/sqlite3.amalg sqlite3/sqlite3.c

echo "==========================="
echo "Creating NSIS installer ..."
echo "==========================="
cp -p README readme.txt
unix2dos < license.terms > license.txt || todos < license.terms > license.txt
makensis $ADD_NSIS sqlite3odbc_w32.nsi
