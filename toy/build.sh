set -e

# Configuration
LLVM_BUILD_DIR="/home/adam/projects/compilers/llvm-project/build"
LLVM_INSTALL_DIR=/usr/local

# Commands
mkdir build && cd build
cmake -G Ninja .. \
-D CMAKE_C_COMPILER=clang -D CMAKE_CXX_COMPILER=clang++ -D CMAKE_CXX_STANDARD=17 \
-DMLIR_DIR=$LLVM_INSTALL_DIR/lib/cmake/mlir -DLLVM_EXTERNAL_LIT=$LLVM_BUILD_DIR/bin/llvm-lit \
-DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
-DCMAKE_CXX_FLAGS="-g"
cmake --build .
