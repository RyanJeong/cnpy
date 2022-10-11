#!/bin/bash

NUM_CORE=$(grep processor /proc/cpuinfo | awk '{field=$NF};END{print field+1}')
WORKING_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

# zlib
ZLIB_VERSION_MAJOR=1
ZLIB_VERSION_MINOR=2
ZLIB_VERSION_PATCH=11
ZLIB="zlib-\
$ZLIB_VERSION_MAJOR"."\
$ZLIB_VERSION_MINOR"."\
$ZLIB_VERSION_PATCH"
ZLIB_FILENAME=$WORKING_DIR/$ZLIB.tar.gz
ZLIB_FOLDER=$WORKING_DIR/$ZLIB
ZLIB_URL="https://github.com/madler/zlib/archive/refs/tags/v\
$ZLIB_VERSION_MAJOR"."\
$ZLIB_VERSION_MINOR"."\
$ZLIB_VERSION_PATCH".tar.gz

if [ ! -f "$ZLIB_FILENAME" ]; then
  wget -q $ZLIB_URL -O $ZLIB_FILENAME
fi

if [ ! -d $ZLIB_FOLDER ]; then
  mkdir -p $ZLIB_FOLDER
  tar -xf $ZLIB_FILENAME -C $ZLIB_FOLDER --strip-components 1
fi
cd $ZLIB_FOLDER
if [ "$1" = "aarch64-linux-gnu" ]; then
  CC=aarch64-linux-gnu-gcc \
    LDSHARED=aarch64-linux-gnu-gcc \
    CPP="aarch64-linux-gnu-gcc -E" \
    AR=aarch64-linux-gnu-ar \
    RANLIB=aarch64-linux-gnu-ranlib \
    ./configure --static -prefix=$ZLIB_FOLDER
else
  CFLAGS="-O3 -D_LARGEFILE64_SOURCE=1 -DHAVE_HIDDEN -fPIC" \
    ./configure --static -prefix=$ZLIB_FOLDER
fi
make clean
make
make install

# cnpy
cd $WORKING_DIR
git clone https://github.com/rogersce/cnpy
CNPY_FOLDER=$WORKING_DIR/cnpy
cd $CNPY_FOLDER
CNPY_BUILD=$CNPY_FOLDER/cnpy_build
mkdir -p $CNPY_BUILD
cd $CNPY_BUILD
cmake ../ \
  -DCMAKE_INSTALL_PREFIX=$WORKING_DIR \
  -DZLIB_LIBRARY=$ZLIB_FOLDER/lib/libz.a \
  -DZLIB_INCLUDE_DIR=$ZLIB_FOLDER/include \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
make clean
make
make install

