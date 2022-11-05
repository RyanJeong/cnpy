#!/bin/bash

NUM_CORE=$(grep processor /proc/cpuinfo | awk '{field=$NF};END{print field+1}')
WORKING_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

# protobuf
PROTOBUF_VERSION_MAJOR=3
PROTOBUF_VERSION_MINOR=18
PROTOBUF_VERSION_PATCH=1
PROTOBUF="protobuf-\
$PROTOBUF_VERSION_MAJOR"."\
$PROTOBUF_VERSION_MINOR"."\
$PROTOBUF_VERSION_PATCH"
PROTOBUF_FILENAME=$WORKING_DIR/$PROTOBUF.zip
PROTOBUF_FOLDER=$WORKING_DIR/$PROTOBUF
PROTOBUF_URL="https://github.com/protocolbuffers/protobuf/releases/download/v\
$PROTOBUF_VERSION_MAJOR"."\
$PROTOBUF_VERSION_MINOR"."\
$PROTOBUF_VERSION_PATCH"/protoc-"\
$PROTOBUF_VERSION_MAJOR"."\
$PROTOBUF_VERSION_MINOR"."\
$PROTOBUF_VERSION_PATCH"-linux-x86_64.zip

if [ ! -f "$PROTOBUF_FILENAME" ]; then
  wget -q $PROTOBUF_URL -O $PROTOBUF_FILENAME
fi

if [ ! -d $PROTOBUF_FOLDER ]; then
  mkdir -p $PROTOBUF_FOLDER
  unzip -q $PROTOBUF_FILENAME -d $PROTOBUF_FOLDER
fi

# onnxruntime
ONNXRUNTIME_FOLDER=$WORKING_DIR/onnxruntime
ONNXRUNTIME_VERSION=v1.12.0
if [ ! -d $ONNXRUNTIME_FOLDER ]; then
  git clone git@github.com:microsoft/onnxruntime.git -b $ONNXRUNTIME_VERSION
fi
cd $ONNXRUNTIME_FOLDER

git checkout $ONNXRUNTIME_VERSION
git submodule sync
git submodule update --init --recursive

# error: def process_ifs(lines: Iterable[str], onnx_ml: bool) -> Iterable[str]:
# You MUST explicitly modify the Python version you are using for your environment to avoid this error
#
# $ python3 --version
# Python 3.6.9
cp $WORKING_DIR/onnx_hotfix $ONNXRUNTIME_FOLDER/cmake/external/onnx/CMakeLists.txt

ONNXRUNTIME_BUILD=$ONNXRUNTIME_FOLDER/onnxruntime_build
mkdir -p $ONNXRUNTIME_BUILD
cd $ONNXRUNTIME_BUILD
make clean
if [ "$1" = "onnxruntime-shared-library" ]; then
  cmake ../cmake -G"Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX=$WORKING_DIR \
    -DCMAKE_BUILD_TYPE=Release \
    -DONNX_CUSTOM_PROTOC_EXECUTABLE=$PROTOBUF_FOLDER/bin/protoc \
    -DCMAKE_TOOLCHAIN_FILE=$WORKING_DIR/tool.cmake \
    -Donnxruntime_BUILD_SHARED_LIB=ON
  cmake --build . \
    --config Release \
    --target install \
    -- -j$NUM_CORE
else
  cp $WORKING_DIR/merge.mri $ONNXRUNTIME_BUILD
  AR=aarch64-linux-gnu-ar
  cmake ../cmake -G"Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX=$WORKING_DIR \
    -DCMAKE_BUILD_TYPE=Release \
    -DONNX_CUSTOM_PROTOC_EXECUTABLE=$PROTOBUF_FOLDER/bin/protoc \
    -DCMAKE_TOOLCHAIN_FILE=$WORKING_DIR/tool.cmake
  make -j$NUM_CORE
  make install
  $AR -M < ./merge.mri
  cp $ONNXRUNTIME_BUILD/libonnxruntime.a $WORKING_DIR/lib
fi

