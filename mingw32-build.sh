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
test -r extension-functions.c ||
    wget -O extension-functions.c -c \
      'http://www.sqlite.org/contrib/download/extension-functions.c?get=25' \
      --no-check-certificate
if test -r extension-functions.c ; then
  cp extension-functions.c extfunc.c
  patch < extfunc.patch
fi
test -r extfunc.c || exit 1

rm -f sqlite3
rm -rf sqlite-src-${VER3X}
unzip sqlite-src-${VER3X}.zip
ln -sf sqlite-src-${VER3X} sqlite3

test -r sqlite3/tool/mkshellc.tcl && \
  sed -i -e 's/ rb/ r/g' sqlite3/tool/mkshellc.tcl

# appendText name clash in sqlite3 shell
test "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && perl -pi -e 's/appendText/shAppendText/g' sqlite3/src/shell.c.in

test -r sqlite3/src/shell.c.in &&
  ( cd sqlite3/src ; tclsh ../tool/mkshellc.tcl > shell.c )

patch sqlite3/main.mk <<'EOD'
--- sqlite3.orig/main.mk        2007-03-31 14:32:21.000000000 +0200
+++ sqlite3/main.mk     2007-04-02 11:04:50.000000000 +0200
@@ -67,7 +67,7 @@

 # All of the source code files.
 #
-SRC = \
+SRC += \
   $(TOP)/src/alter.c \
   $(TOP)/src/analyze.c \
   $(TOP)/src/attach.c \
EOD


# same but new module libshell.c
cp -p sqlite3/src/shell.c sqlite3/src/libshell.c
test "$VER3" != "3.7.14" -a "$VER3" != "3.7.14.1" -a "$VER3" != "3.7.15" \
  -a "$VER3" != "3.7.15.1" -a "$VER3" != "3.7.15.2" -a "$VER3" != "3.7.16" \
  -a "$VER3" != "3.7.16.1" -a "$VER3" != "3.7.16.2" -a "$VER3" != "3.7.17" \
  -a "$VER3" != "3.8.0" -a "$VER3" != "3.8.1" -a "$VER3" != "3.8.2" \
  -a "$VER3" != "3.8.3" -a "$VER3" != "3.8.4" -a "$VER3" != "3.8.4.1" \
  -a "$VER3" != "3.8.4.2" -a "$VER3" != "3.8.5" -a "$VER3" != "3.8.6" \
  -a "$VER3" != "3.8.7" -a "$VER3" != "3.8.8" -a "$VER3" != "3.8.9" \
  -a "$VER3" != "3.8.10" -a "$VER3" != "3.8.11" -a "$VER3" != "3.9.0" \
  -a "$VER3" != "3.9.1" -a "$VER3" != "3.9.2" -a "$VER3" != "3.10.0" \
  -a "$VER3" != "3.10.2" -a "$VER3" != "3.12.2" -a "$VER3" != "3.13.0" \
  -a "$VER3" != "3.14.0" -a "$VER3" != "3.14.1" -a "$VER3" != "3.15.0" \
  -a "$VER3" != "3.15.1" -a "$VER3" != "3.15.2" -a "$VER3" != "3.19.3" \
  -a "$VER3" != "3.22.0" -a "$VER3" != "3.32.2" -a "$VER3" != "3.32.3" \
  && patch sqlite3/src/libshell.c <<'EOD'
--- sqlite3.orig/src/libshell.c  2007-01-08 23:40:05.000000000 +0100
+++ sqlite3/src/libshell.c  2007-01-10 18:35:43.000000000 +0100
@@ -21,6 +21,10 @@
 #include <ctype.h>
 #include <stdarg.h>

+#ifdef _WIN32
+# include <windows.h>
+#endif
+
 #if !defined(_WIN32) && !defined(WIN32) && !defined(__OS2__)
 # include <signal.h>
 # include <pwd.h>
@@ -1774,7 +1778,7 @@
   strcpy(continuePrompt,"   ...> ");
 }
 
-int main(int argc, char **argv){
+int sqlite3_main(int argc, char **argv){
   char *zErrMsg = 0;
   struct callback_data data;
   const char *zInitFile = 0;
@@ -1816,6 +1820,17 @@
   if( i<argc ){
     data.zDbFilename = argv[i++];
   }else{
+#if defined(_WIN32) && !defined(__TINYC__)
+    static OPENFILENAME ofn;
+    static char zDbFn[1024];
+    ofn.lStructSize = sizeof(ofn);
+    ofn.lpstrFile = (LPTSTR) zDbFn;
+    ofn.nMaxFile = sizeof(zDbFn);
+    ofn.Flags = OFN_PATHMUSTEXIST | OFN_EXPLORER | OFN_NOCHANGEDIR;
+    if( GetOpenFileName(&ofn) ){
+      data.zDbFilename = zDbFn;
+    } else
+#endif
 #ifndef SQLITE_OMIT_MEMORYDB
     data.zDbFilename = ":memory:";
 #else
EOD

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
test "$VER3" = "3.5.6" && test -r sqlite3/tool/mksqlite3c.tcl && \
  patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/tool/mksqlite3c.tcl	2007-04-02 14:20:10.000000000 +0200
+++ sqlite3/tool/mksqlite3c.tcl	2007-04-03 09:42:03.000000000 +0200
@@ -200,6 +200,7 @@
 
    main.c

+   libshell.c
    fts3.c
    fts3_hash.c
    fts3_porter.c
EOD

# patch: parse foreign key constraints on virtual tables
test "$VER3" != "3.6.15" -a "$VER3" != "3.6.16" -a "$VER3" != "3.6.17" \
  -a "$VER3" != "3.6.18" -a "$VER3" != "3.6.19" -a "$VER3" != "3.6.20" \
  -a "$VER3" != "3.6.21" -a "$VER3" != "3.6.22" -a "$VER3" != "3.6.23" \
  -a "$VER3" != "3.6.23.1" -a "$VER3" != "3.7.0" -a "$VER3" != "3.7.0.1" \
  -a "$VER3" != "3.7.1" -a "$VER3" != "3.7.2" -a "$VER3" != "3.7.3" \
  -a "$VER3" != "3.7.4" -a "$VER3" != "3.7.5" -a "$VER3" != "3.7.6" \
  -a "$VER3" != "3.7.6.1" -a "$VER3" != "3.7.6.2" -a "$VER3" != "3.7.6.3" \
  -a "$VER3" != "3.7.7" -a "$VER3" != "3.7.7.1" -a "$VER3" != "3.7.8" \
  -a "$VER3" != "3.7.9" -a "$VER3" != "3.7.10" -a "$VER3" != "3.7.11" \
  -a "$VER3" != "3.7.12" -a "$VER3" != "3.7.12.1" -a "$VER3" != "3.7.13" \
  -a "$VER3" != "3.7.14" -a "$VER3" != "3.7.14.1" -a "$VER3" != "3.7.15" \
  -a "$VER3" != "3.7.15.1" -a "$VER3" != "3.7.15.2" -a "$VER3" != "3.7.16" \
  -a "$VER3" != "3.7.16.1" -a "$VER3" != "3.7.16.2" -a "$VER3" != "3.7.17" \
  -a "$VER3" != "3.8.0" -a "$VER3" != "3.8.1" -a "$VER3" != "3.8.2" \
  -a "$VER3" != "3.8.3" -a "$VER3" != "3.8.4" -a "$VER3" != "3.8.4.1" \
  -a "$VER3" != "3.8.4.2" -a "$VER3" != "3.8.5" -a "$VER3" != "3.8.6" \
  -a "$VER3" != "3.8.7" -a "$VER3" != "3.8.8" -a "$VER3" != "3.8.9" \
  -a "$VER3" != "3.8.10" -a "$VER3" != "3.8.11" -a "$VER3" != "3.9.0" \
  -a "$VER3" != "3.9.1" -a "$VER3" != "3.9.2" -a "$VER3" != "3.10.0" \
  -a "$VER3" != "3.10.2" -a "$VER3" != "3.12.2" -a "$VER3" != "3.13.0" \
  -a "$VER3" != "3.14.0" -a "$VER3" != "3.14.1" -a "$VER3" != "3.15.0" \
  -a "$VER3" != "3.15.1" -a "$VER3" != "3.15.2" -a "$VER3" != "3.19.3" \
  -a "$VER3" != "3.22.0" -a "$VER3" != "3.32.2" -a "$VER3" != "3.32.3" \
  && patch -d sqlite3 -p1 <<'EOD'
diff -u sqlite3.orig/src/build.c sqlite3/src/build.c
--- sqlite3.orig/src/build.c	2007-01-09 14:53:04.000000000 +0100
+++ sqlite3/src/build.c	2007-01-30 08:14:41.000000000 +0100
@@ -2063,7 +2063,7 @@
   char *z;
 
   assert( pTo!=0 );
-  if( p==0 || pParse->nErr || IN_DECLARE_VTAB ) goto fk_end;
+  if( p==0 || pParse->nErr ) goto fk_end;
   if( pFromCol==0 ){
     int iCol = p->nCol-1;
     if( iCol<0 ) goto fk_end;
diff -u sqlite3.orig/src/pragma.c sqlite3/src/pragma.c
--- sqlite3.orig/src/pragma.c	2007-01-27 03:24:56.000000000 +0100
+++ sqlite3/src/pragma.c	2007-01-30 09:19:30.000000000 +0100
@@ -589,6 +589,9 @@
     pTab = sqlite3FindTable(db, zRight, zDb);
     if( pTab ){
       v = sqlite3GetVdbe(pParse);
+#ifndef SQLITE_OMIT_VIRTUAL_TABLE
+      if( pTab->pVtab ) sqlite3ViewGetColumnNames(pParse, pTab);
+#endif
       pFK = pTab->pFKey;
       if( pFK ){
         int i = 0; 
diff -u sqlite3.orig/src/vtab.c sqlite3/src/vtab.c
--- sqlite3.orig/src/vtab.c	2007-01-09 15:01:14.000000000 +0100
+++ sqlite3/src/vtab.c	2007-01-30 08:23:22.000000000 +0100
@@ -540,6 +540,9 @@
   int rc = SQLITE_OK;
   Table *pTab = db->pVTab;
   char *zErr = 0;
+#ifndef SQLITE_OMIT_FOREIGN_KEYS
+  FKey *pFKey;
+#endif
 
   sqlite3_mutex_enter(db->mutex);
   pTab = db->pVTab;
@@ -568,6 +571,15 @@
   }
   sParse.declareVtab = 0;
 
+#ifndef SQLITE_OMIT_FOREIGN_KEYS
+  assert( pTab->pFKey==0 );
+  pTab->pFKey = sParse.pNewTable->pFKey;
+  sParse.pNewTable->pFKey = 0;
+  for(pFKey=pTab->pFKey; pFKey; pFKey=pFKey->pNextFrom){
+    pFKey->pFrom=pTab;
+  }
+#endif
+
   if( sParse.pVdbe ){
     sqlite3VdbeFinalize(sParse.pVdbe);
   }
EOD

# patch: re-enable NO_TCL in tclsqlite.c (3.3.15)
test "$VER3" != "3.8.8" -a "$VER3" != "3.8.9" -a "$VER3" != "3.8.10" \
  -a "$VER3" != "3.8.11" -a "$VER3" != "3.9.0" -a "$VER3" != "3.9.1" \
  -a "$VER3" != "3.9.2" -a "$VER3" != "3.10.0" -a "$VER3" != "3.10.2" \
  -a "$VER3" != "3.12.2" -a "$VER3" != "3.13.0" -a "$VER3" != "3.14.0" \
  -a "$VER3" != "3.14.1" -a "$VER3" != "3.15.0" -a "$VER3" != "3.15.1" \
  -a "$VER3" != "3.15.2" -a "$VER3" != "3.19.3" -a "$VER3" != "3.22.0" \
  -a "$VER3" != "3.32.2" -a "$VER3" != "3.32.3" \
  && patch -d sqlite3 -p1 <<'EOD'
diff -u sqlite3.orig/src/tclsqlite.c sqlite3/src/tclsqlite.c
--- sqlite3.orig/src/tclsqlite.c	2007-04-06 17:02:14.000000000 +0200
+++ sqlite3/src/tclsqlite.c	2007-04-10 07:47:49.000000000 +0200
@@ -14,6 +14,7 @@
 **
 ** $Id: mingw-cross-build.sh,v 1.109 2020/06/20 11:55:37 chw Exp chw $
 */
+#ifndef NO_TCL     /* Omit this whole file if TCL is unavailable */
 #include "tcl.h"
 
 /*
@@ -2264,3 +2265,5 @@
   return 0;
 }
 #endif /* TCLSH */
+
+#endif /* !defined(NO_TCL) */
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

# patch: Win32 locking and pager unlock, for SQLite3 >= 3.5.4 && <= 3.6.10
true || patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/src/os_win.c       2007-12-13 22:38:58.000000000 +0100
+++ sqlite3/src/os_win.c    2008-01-18 10:01:48.000000000 +0100
@@ -855,8 +855,8 @@
   ** the PENDING_LOCK byte is temporary.
   */
   newLocktype = pFile->locktype;
-  if( pFile->locktype==NO_LOCK
-   || (locktype==EXCLUSIVE_LOCK && pFile->locktype==RESERVED_LOCK)
+  if( locktype==SHARED_LOCK
+   || (locktype==EXCLUSIVE_LOCK && pFile->locktype<PENDING_LOCK)
   ){
     int cnt = 3;
     while( cnt-->0 && (res = LockFile(pFile->h, PENDING_BYTE, 0, 1, 0))==0 ){
@@ -907,7 +907,18 @@
       newLocktype = EXCLUSIVE_LOCK;
     }else{
       OSTRACE2("error-code = %d\n", GetLastError());
-      getReadLock(pFile);
+      if( !getReadLock(pFile) ){
+        /* This should never happen.  We should always be able to
+        ** reacquire the read lock */
+        OSTRACE1("could not re-get a SHARED lock.\n");
+        if( newLocktype==PENDING_LOCK || pFile->locktype==PENDING_LOCK ){
+          UnlockFile(pFile->h, PENDING_BYTE, 0, 1, 0);
+        }
+        if( pFile->locktype==RESERVED_LOCK ){
+          UnlockFile(pFile->h, RESERVED_BYTE, 0, 1, 0);
+        }
+        newLocktype = NO_LOCK;
+      }
     }
   }
 
@@ -982,6 +993,7 @@
       /* This should never happen.  We should always be able to
       ** reacquire the read lock */
       rc = SQLITE_IOERR_UNLOCK;
+      locktype = NO_LOCK;
     }
   }
   if( type>=RESERVED_LOCK ){
EOD

# patch: Win32 locking and pager unlock, for SQLite3 >= 3.6.11 && < 3.7.0
true || patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/src/os_win.c    2009-02-15 14:07:09.000000000 +0100
+++ sqlite3/src/os_win.c    2009-02-20 16:39:48.000000000 +0100
@@ -922,7 +922,7 @@
   newLocktype = pFile->locktype;
   if(   (pFile->locktype==NO_LOCK)
      || (   (locktype==EXCLUSIVE_LOCK)
-         && (pFile->locktype==RESERVED_LOCK))
+         && (pFile->locktype<RESERVED_LOCK))
   ){
     int cnt = 3;
     while( cnt-->0 && (res = LockFile(pFile->h, PENDING_BYTE, 0, 1, 0))==0 ){
@@ -981,7 +981,18 @@
     }else{
       error = GetLastError();
       OSTRACE2("error-code = %d\n", error);
-      getReadLock(pFile);
+      if( !getReadLock(pFile) ){
+        /* This should never happen.  We should always be able to
+        ** reacquire the read lock */
+        OSTRACE1("could not re-get a SHARED lock.\n");
+        if( newLocktype==PENDING_LOCK || pFile->locktype==PENDING_LOCK ){
+          UnlockFile(pFile->h, PENDING_BYTE, 0, 1, 0);
+        }
+        if( pFile->locktype==RESERVED_LOCK ){
+          UnlockFile(pFile->h, RESERVED_BYTE, 0, 1, 0);
+        }
+        newLocktype = NO_LOCK;
+      }
     }
   }
 
@@ -1057,6 +1068,7 @@
       /* This should never happen.  We should always be able to
       ** reacquire the read lock */
       rc = SQLITE_IOERR_UNLOCK;
+      locktype = NO_LOCK;
     }
   }
   if( type>=RESERVED_LOCK ){
EOD

patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/ext/fts3/fts3_porter.c  2008-02-01 16:40:34.000000000 +0100
+++ sqlite3/ext/fts3/fts3_porter.c       2008-03-16 11:34:50.000000000 +0100
@@ -31,6 +31,11 @@
 #include <string.h>
 #include <ctype.h>
 
+#include "sqlite3ext.h"
+#ifndef SQLITE_CORE
+extern const sqlite3_api_routines *sqlite3_api;
+#endif
+
 #include "fts3_tokenizer.h"
 
 /*
--- sqlite3.orig/ext/fts3/fts3_tokenizer1.c      2007-11-23 18:31:18.000000000 +0100
+++ sqlite3/ext/fts3/fts3_tokenizer1.c   2008-03-16 11:35:37.000000000 +0100
@@ -31,6 +31,11 @@
 #include <string.h>
 #include <ctype.h>
 
+#include "sqlite3ext.h"
+#ifndef SQLITE_CORE
+extern const sqlite3_api_routines *sqlite3_api;
+#endif
+
 #include "fts3_tokenizer.h"
 
 typedef struct simple_tokenizer {
EOD





# patch: fix rtree to be loadable as extension module
test "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && perl -pi -e 's/sqlite3_rtree_init/sqlite3_extension_init/g' \
    sqlite3/ext/rtree/rtree.c

# patch: .read shell command
test "$VER3" = "3.7.6.1" -o "$VER3" = "3.7.6.2" -o "$VER3" = "3.7.6.3" \
  -o "$VER3" = "3.7.7" -o "$VER3" = "3.7.7.1" -o "$VER3" = "3.7.8" \
  -o "$VER3" = "3.7.9" -o "$VER3" = "3.7.10" -o "$VER3" = "3.7.11" \
  -o "$VER3" = "3.7.12" -o "$VER3" = "3.7.12.1" -o "$VER3" = "3.7.13" \
  -o "$VER3" = "3.7.14" -o "$VER3" = "3.7.14.1" \
  && patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/src/shell.c	2011-05-19 15:34:57.000000000 +0200
+++ sqlite3/src/shell.c	2011-06-09 13:36:13.000000000 +0200
@@ -1957,6 +1957,7 @@
     }else{
       rc = process_input(p, alt);
       fclose(alt);
+      if( rc ) rc = 1;
     }
   }else
 
EOD

# patch: FTS3 for 3.7.7 plus missing APIs in sqlite3ext.h/loadext.c
test "$VER3" = "3.7.7" -o "$VER3" = "3.7.7.1" -o "$VER3" = "3.7.8" \
  -o "$VER3" = "3.7.9" -o "$VER3" = "3.7.10" -o "$VER3" = "3.7.11" \
  -o "$VER3" = "3.7.12" -o "$VER3" = "3.7.12.1" -o "$VER3" = "3.7.13" \
  -o "$VER3" = "3.7.14" -o "$VER3" = "3.7.14.1" -o "$VER3" = "3.7.15" \
  -o "$VER3" = "3.7.15.1" -o "$VER3" = "3.7.15.2" -o "$VER3" = "3.7.16" \
  -o "$VER3" = "3.7.16.1" -o "$VER3" = "3.7.16.2" -o "$VER3" = "3.7.17" \
  -o "$VER3" = "3.8.0" -o "$VER3" = "3.8.1" -o "$VER3" = "3.8.2" \
  -o "$VER3" = "3.8.3" -o "$VER3" = "3.8.4" -o "$VER3" = "3.8.4.1" \
  -o "$VER3" = "3.8.4.2" -o "$VER3" = "3.8.5" -o "$VER3" = "3.8.6" \
  -o "$VER3" = "3.8.7" -o "$VER3" = "3.8.8" -o "$VER3" = "3.8.9" \
  -o "$VER3" = "3.8.10" -o "$VER3" = "3.8.11" -o "$VER3" = "3.9.0" \
  -o "$VER3" = "3.9.1" -o "$VER3" = "3.9.2" -o "$VER3" = "3.10.0" \
  -o "$VER3" = "3.10.2" -o "$VER3" = "3.12.2" -o "$VER3" = "3.13.0" \
  -o "$VER3" = "3.14.0" -o "$VER3" = "3.14.1" -o "$VER3" = "3.15.0" \
  -o "$VER3" = "3.15.1" -o "$VER3" = "3.15.2" -o "$VER3" = "3.19.3" \
  -o "$VER3" = "3.22.0" -o "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/ext/fts3/fts3_aux.c	2011-06-24 09:06:08.000000000 +0200
+++ sqlite3/ext/fts3/fts3_aux.c	2011-06-25 06:44:08.000000000 +0200
@@ -14,6 +14,10 @@
 #include "fts3Int.h"
 #if !defined(SQLITE_CORE) || defined(SQLITE_ENABLE_FTS3)
 
+#include "sqlite3ext.h"
+#ifndef SQLITE_CORE
+extern const sqlite3_api_routines *sqlite3_api;
+#endif
 #include <string.h>
 #include <assert.h>
 
EOD

test "$VER3" = "3.7.8" -o "$VER3" = "3.7.9" -o "$VER3" = "3.7.10" \
  -o "$VER3" = "3.7.11" -o "$VER3" = "3.7.12" -o "$VER3" = "3.7.12.1" \
  -o "$VER3" = "3.7.13" -o "$VER3" = "3.7.14" -o "$VER3" = "3.7.14.1" \
  -o "$VER3" = "3.7.15" -o "$VER3" = "3.7.15.1" -o "$VER3" = "3.7.15.2" \
  -o "$VER3" = "3.7.16" -o "$VER3" = "3.7.16.1" -o "$VER3" = "3.7.16.2" \
  -o "$VER3" = "3.7.17" -o "$VER3" = "3.8.0" -o "$VER3" = "3.8.1" \
  -o "$VER3" = "3.8.2" -o "$VER3" = "3.8.3" -o "$VER3" = "3.8.4" \
  -o "$VER3" = "3.8.4.1" -o "$VER3" = "3.8.4.2" -o "$VER3" = "3.8.5" \
  -o "$VER3" = "3.8.6" -o "$VER3" = "3.8.7" -o "$VER3" = "3.8.8" \
  -o "$VER3" = "3.8.9" -o "$VER3" = "3.8.10" -o "$VER3" = "3.8.11" \
  -o "$VER3" = "3.9.0" -o "$VER3" = "3.9.1" -o "$VER3" = "3.9.2" \
  -o "$VER3" = "3.10.0" -o "$VER3" = "3.10.2" -o "$VER3" = "3.12.2" \
  -o "$VER3" = "3.13.0" -o "$VER3" = "3.14.0" -o "$VER3" = "3.14.1" \
  -o "$VER3" = "3.15.0" -o "$VER3" = "3.15.1" -o "$VER3" = "3.15.2" \
  -o "$VER3" = "3.19.3" -o "$VER3" = "3.22.0" -o "$VER3" = "3.32.2" \
  -o "$VER3" = "3.32.3" \
  && patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/ext/fts3/fts3.c	2011-09-19 20:46:52.000000000 +0200
+++ sqlite3/ext/fts3/fts3.c	2011-09-20 09:47:40.000000000 +0200
@@ -295,10 +295,6 @@
 #include "fts3Int.h"
 #if !defined(SQLITE_CORE) || defined(SQLITE_ENABLE_FTS3)
 
-#if defined(SQLITE_ENABLE_FTS3) && !defined(SQLITE_CORE)
-# define SQLITE_CORE 1
-#endif
-
 #include <assert.h>
 #include <stdlib.h>
 #include <stddef.h>
@@ -4826,7 +4822,7 @@
   }
 }
 
-#if !SQLITE_CORE
+#ifndef SQLITE_CORE
 /*
 ** Initialize API pointer table, if required.
 */
EOD

test "$VER3" = "3.7.7" -o "$VER3" = "3.7.7.1" -o "$VER3" = "3.7.8" \
  -o "$VER3" = "3.7.9" -o "$VER3" = "3.7.10" -o "$VER3" = "3.7.11" \
  -o "$VER3" = "3.7.12" -o "$VER3" = "3.7.12.1" -o "$VER3" = "3.7.13" \
  -o "$VER3" = "3.7.14" -o "$VER3" = "3.7.14.1" -o "$VER3" = "3.7.15" \
  -o "$VER3" = "3.7.15.1" -o "$VER3" = "3.7.15.2" -o "$VER3" = "3.7.16" \
  -o "$VER3" = "3.7.16.1" -o "$VER3" = "3.7.16.2" -o "$VER3" = "3.7.17" \
  -o "$VER3" = "3.8.0" -o "$VER3" = "3.8.1" -o "$VER3" = "3.8.2" \
  -o "$VER3" = "3.8.3" -o "$VER3" = "3.8.4" -o "$VER3" = "3.8.4.1" \
  -o "$VER3" = "3.8.4.2" -o "$VER3" = "3.8.5" -o "$VER3" = "3.8.6" \
  -o "$VER3" = "3.8.7" -o "$VER3" = "3.8.8" -o "$VER3" = "3.8.9" \
  -o "$VER3" = "3.8.10" -o "$VER3" = "3.8.11" -o "$VER3" = "3.9.0" \
  -o "$VER3" = "3.9.1" -o "$VER3" = "3.9.2" -o "$VER3" = "3.10.0" \
  -o "$VER3" = "3.10.2" -o "$VER3" = "3.12.2" -o "$VER3" = "3.13.0" \
  -o "$VER3" = "3.14.0" -o "$VER3" = "3.14.1" -o "$VER3" = "3.15.0" \
  -o "$VER3" = "3.15.1" -o "$VER3" = "3.15.2" -o "$VER3" = "3.19.3" \
  -o "$VER3" = "3.22.0" -o "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/ext/fts3/fts3_expr.c	2011-06-24 09:06:08.000000000 +0200
+++ sqlite3/ext/fts3/fts3_expr.c	2011-06-25 06:47:00.000000000 +0200
@@ -18,6 +18,11 @@
 #include "fts3Int.h"
 #if !defined(SQLITE_CORE) || defined(SQLITE_ENABLE_FTS3)
 
+#include "sqlite3ext.h"
+#ifndef SQLITE_CORE
+extern const sqlite3_api_routines *sqlite3_api;
+#endif
+
 /*
 ** By default, this module parses the legacy syntax that has been 
 ** traditionally used by fts3. Or, if SQLITE_ENABLE_FTS3_PARENTHESIS
--- sqlite3.orig/ext/fts3/fts3_snippet.c	2011-06-24 09:06:08.000000000 +0200
+++ sqlite3/ext/fts3/fts3_snippet.c	2011-06-25 06:45:47.000000000 +0200
@@ -13,7 +13,10 @@
 
 #include "fts3Int.h"
 #if !defined(SQLITE_CORE) || defined(SQLITE_ENABLE_FTS3)
-
+#include "sqlite3ext.h"
+#ifndef SQLITE_CORE
+extern const sqlite3_api_routines *sqlite3_api;
+#endif
 #include <string.h>
 #include <assert.h>
 
EOD

test "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/src/loadext.c	2020-06-04 16:01:10.000000000 +0200
+++ sqlite3/src/loadext.c	2020-06-12 05:47:05.000000000 +0200
@@ -591,7 +591,8 @@
     memcpy(zAltEntry, "sqlite3_", 8);
     for(iFile=ncFile-1; iFile>=0 && !DirSep(zFile[iFile]); iFile--){}
     iFile++;
-    if( sqlite3_strnicmp(zFile+iFile, "lib", 3)==0 ) iFile += 3;
+    if( sqlite3_strnicmp(zFile+iFile, "sqlite3_mod", 12)==0 ) iFile += 12;
+    else if( sqlite3_strnicmp(zFile+iFile, "lib", 3)==0 ) iFile += 3;
     for(iEntry=8; (c = zFile[iFile])!=0 && c!='.'; iFile++){
       if( sqlite3Isalpha(c) ){
         zAltEntry[iEntry++] = (char)sqlite3UpperToLower[(unsigned)c];
EOD

# revert FTS3 initializer name, would work when sqlite3_fts_init
test "$VER3" = "3.8.2" -o "$VER3" = "3.8.3" -o "$VER3" = "3.8.4" \
  -o "$VER3" = "3.8.4.1" -o "$VER3" = "3.8.4.2" -o "$VER3" = "3.8.5" \
  -o "$VER3" = "3.8.6" -o "$VER3" = "3.8.7" -o "$VER3" = "3.8.8" \
  -o "$VER3" = "3.8.9" -o "$VER3" = "3.8.10" -o "$VER3" = "3.8.11" \
  -o "$VER3" = "3.9.0" -o "$VER3" = "3.9.1" -o "$VER3" = "3.9.2" \
  -o "$VER3" = "3.10.0" -o "$VER3" = "3.10.2" -o "$VER3" = "3.12.2" \
  -o "$VER3" = "3.13.0" -o "$VER3" = "3.14.0" -o "$VER3" = "3.14.1" \
  -o "$VER3" = "3.15.0" -o "$VER3" = "3.15.1" -o "$VER3" = "3.15.2" \
  -o "$VER3" = "3.19.3" -o "$VER3" = "3.22.0" -o "$VER3" = "3.32.2" \
  -o "$VER3" = "3.32.3" \
  && patch -d sqlite3 -p1 <<'EOD'
--- sqlite3.orig/ext/fts3/fts3.c      2014-03-26 10:26:28.000000000 +0100
+++ sqlite3/ext/fts3/fts3.c  2014-03-26 16:54:39.000000000 +0100
@@ -5747,7 +5747,7 @@
 #ifdef _WIN32
 __declspec(dllexport)
 #endif
-int sqlite3_fts3_init(
+int sqlite3_extension_init(
   sqlite3 *db, 
   char **pzErrMsg,
   const sqlite3_api_routines *pApi
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

# tcl8.4 compatibility for mkfts5c.tcl
test "$VER3" = "3.9.0" -o "$VER3" = "3.9.1" -o "$VER3" = "3.9.2" \
  -o "$VER3" = "3.10.0" -o "$VER3" = "3.10.2" -o "$VER3" = "3.12.2" \
  -o "$VER3" = "3.13.0" -o "$VER3" = "3.14.0" -o "$VER3" = "3.14.1" \
  -o "$VER3" = "3.15.0" -o "$VER3" = "3.15.1" -o "$VER3" = "3.15.2" \
  -o "$VER3" = "3.19.3" -o "$VER3" = "3.22.0" -o "$VER3" = "3.32.2" \
  -o "$VER3" = "3.32.3" \
  && patch sqlite3/ext/fts5/tool/mkfts5c.tcl <<'EOD'
--- mkfts5c.tcl.orig	2015-10-14 14:53:26.000000000 +0200
+++ mkfts5c.tcl	2015-10-15 08:19:25.000000000 +0200
@@ -60,7 +60,8 @@
 
   set L [split [readfile [file join $top manifest]]] 
   set date [lindex $L [expr [lsearch -exact $L D]+1]]
-  set date [string range $date 0 [string last . $date]-1]
+  set dend [expr [string last . $date]-1]
+  set date [string range $date 0 $dend]
   set date [string map {T { }} $date]
 
   return "fts5: $date $uuid"
EOD

test "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && perl -pi -e 's/ rb\]/ r\]/g' sqlite3/tool/mkopcodec.tcl \
      sqlite3/tool/mkccode.tcl

echo "========================"
echo "Cleanup before build ..."
echo "========================"
make -f Makefile.mingw32 clean
make -C sqlite3 -f ../mf-sqlite3.mingw32 clean
make -C sqlite3 -f ../mf-sqlite3fts.mingw32 clean
make -C sqlite3 -f ../mf-sqlite3rtree.mingw32 clean
make -f mf-sqlite3extfunc.mingw32 clean

echo "================="
echo "Building zlib ..."
echo "================="

make -C zlib -f ../mf-zlib.mingw32 all

echo "====================="
echo "Building SQLite 3 ..."
echo "====================="
make -C sqlite3 -f ../mf-sqlite3.mingw32 all
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
# rtree using internal core func
test "$VER3" = "3.32.2" -o "$VER3" = "3.32.3" \
  && patch sqlite3/ext/rtree/rtree.c <<'EOD'
--- rtree.c.orig	2020-06-04 16:01:10.000000000 +0200
+++ rtree.c	2020-06-12 11:51:49.000000000 +0200
@@ -62,7 +62,6 @@
 #else
   #include "sqlite3.h"
 #endif
-int sqlite3GetToken(const unsigned char*,int*); /* In the SQLite core */
 
 #ifndef SQLITE_AMALGAMATION
 #include "sqlite3rtree.h"
@@ -3667,8 +3666,7 @@
 ** Return the length of a token
 */
 static int rtreeTokenLength(const char *z){
-  int dummy = 0;
-  return sqlite3GetToken((const unsigned char*)z,&dummy);
+  return strlen(z);
 }
 
 /* 
EOD
if test -n "$SQLITE_DLLS" ; then
    make -C sqlite3 -f ../mf-sqlite3.mingw32 sqlite3.dll
fi

echo "==============================="
echo "Building ODBC drivers and utils"
echo "==============================="
make -f Makefile.mingw32 all_no2
make -f Makefile.mingw32 sqlite3odbc${SEEEXT}nw.dll

echo "==================================="
echo "Building SQLite3 FTS extensions ..."
echo "==================================="
make -C sqlite3 -f ../mf-sqlite3fts.mingw32 clean all
mv sqlite3/sqlite3_mod_fts*.dll .

echo "====================================="
echo "Building SQLite3 rtree extensions ..."
echo "====================================="
make -C sqlite3 -f ../mf-sqlite3rtree.mingw32 clean all
mv sqlite3/sqlite3_mod_rtree.dll .

echo "========================================"
echo "Building SQLite3 extension functions ..."
echo "========================================"
make -f mf-sqlite3extfunc.mingw32 clean all

echo "======================="
echo "Cleanup after build ..."
echo "======================="
mv sqlite3/sqlite3.c sqlite3/sqlite3.amalg
make -C sqlite3 -f ../mf-sqlite3.mingw32 clean
rm -f sqlite3/sqlite3.exe
make -C sqlite3 -f ../mf-sqlite3fts.mingw32 clean
make -C sqlite3 -f ../mf-sqlite3rtree.mingw32 clean
mv sqlite3/sqlite3.amalg sqlite3/sqlite3.c
make -f mf-sqlite3extfunc.mingw32 semiclean

echo "==========================="
echo "Creating NSIS installer ..."
echo "==========================="
cp -p README readme.txt
unix2dos < license.terms > license.txt || todos < license.terms > license.txt
makensis $ADD_NSIS sqlite3odbc.nsi
