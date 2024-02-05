set -e

# Configuration
LLVM_BUILD_DIR="/home/adam/projects/compilers/llvm-project/build"
LLVM_INSTALL_DIR=/usr/local

# Commands
mkdir build && cd build
cmake -G Ninja .. -DMLIR_DIR=$LLVM_INSTALL_DIR/lib/cmake/mlir -DLLVM_EXTERNAL_LIT=$LLVM_BUILD_DIR/bin/llvm-lit
cmake --build .
