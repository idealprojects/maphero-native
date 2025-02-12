#!/bin/bash -l

source /opt/rh/gcc-toolset-11/enable

set -e
set -x

export CCACHE_DIR="$GITHUB_WORKSPACE/.ccache"
export PATH="$QT_ROOT_DIR/bin:$PATH"

mkdir build && cd build
qt-cmake ../source/ \
  -G Ninja \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
  -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
  -DMH_WITH_QT=ON \
  -DMH_QT_IGNORE_ICU=OFF
ninja
