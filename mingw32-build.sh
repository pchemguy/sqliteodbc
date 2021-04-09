#!/bin/sh
#

set -e

echo "====================="
echo "Preparing sqlite3 ..."
echo "====================="

wget -c https://www.sqlite.org/src/tarball/sqlite.tar.gz?r=release \
      --no-check-certificate -O sqlite.tar.gz

OPTS="
-DSQLITE_DQS=0 
-DSQLITE_LIKE_DOESNT_MATCH_BLOBS 
-DSQLITE_MAX_EXPR_DEPTH=0 
-DSQLITE_OMIT_DEPRECATED 
-DSQLITE_DEFAULT_FOREIGN_KEYS=1 
-DSQLITE_DEFAULT_SYNCHRONOUS=1 
-DSQLITE_ENABLE_COLUMN_METADATA 
-DSQLITE_ENABLE_DBPAGE_VTAB 
-DSQLITE_ENABLE_DBSTAT_VTAB 
-DSQLITE_ENABLE_EXPLAIN_COMMENTS 
-DSQLITE_ENABLE_FTS3_PARENTHESIS 
-DSQLITE_ENABLE_FTS3_TOKENIZER 
-DSQLITE_ENABLE_QPSG 
-DSQLITE_ENABLE_RBU 
-DSQLITE_ENABLE_ICU 
-DSQLITE_ENABLE_STMTVTAB 
-DSQLITE_ENABLE_STAT4
-DSQLITE_SOUNDEX 
"

test -r sqlite3/configure || tar xzf sqlite.tar.gz 
test -r sqlite3/configure || mv sqlite sqlite3
cd sqlite3

test -r Makefile || ./configure \
  --enable-all \
  --enable-fts3 \
  --enable-memsys5 \
  --enable-update-limit \
  --with-tcl="${MINGW_PREFIX}/lib/tcl8"

make sqlite3.c
#"OPTS=$OPTS"
echo "=================================================="
exit




#VER=`sqlite3 -version | awk '{split($0, ver, " "); split(ver[1], v, "."); print(v[1] v[2] "0" v[3] "00")}'`
#wget -c https://sqlite.org/2021/sqlite-amalgamation-${VER}.zip \
#      --no-check-certificate -O sqlite3.zip
#rm -rf sqlite3
#rm -rf sqlite-amalgamation-${VER}
#unzip sqlite3.zip
#mv "sqlite-amalgamation-${VER}" sqlite3

#echo "======================================================="
#echo "Append shell.c entry point declaration to sqlite3.h ..."
#echo "======================================================="
#
#cat >>sqlite3/sqlite3.h <<'EOD'
#/************** Begin of libshell.h *************************************/
##ifndef LIBSHELL_H
##define LIBSHELL_H
#  
#int sqlite3_main(int argc, char **argv);
#
##endif /* LIBSHELL_H */
#/************** End of libshell.h ***************************************/
#EOD


#echo "============================================================="
#echo "Adjust names of the entry point and appendText in shell.c ..."
#echo "============================================================="
#
#sed -e 's/^int SQLITE_CDECL main/int SQLITE_CDECL sqlite3_main/;' \
#    -e 's/appendText/shAppendText/g;' \
#    -i ./sqlite3/shell.c


exit
echo "==============================="
echo "Building ODBC drivers and utils"
echo "==============================="
make -f Makefile.mingw32 all_no2

echo "==========================="
echo "Creating NSIS installer ..."
echo "==========================="
cp -p README readme.txt
unix2dos < license.terms > license.txt || todos < license.terms > license.txt
makensis $ADD_NSIS sqlite3odbc_w32.nsi
