#!/bin/bash

BUILD_DIR="build"
RELEASE_TYPE="Debug"

[ ! -d "${BUILD_DIR}" ] && mkdir "${BUILD_DIR}"
cd build
cmake -DCMAKE_INSTALL_PREFIX=$PWD -DCMAKE_BUILD_TYPE=${RELEASE_TYPE} ..
make
cd build &> /dev/null
