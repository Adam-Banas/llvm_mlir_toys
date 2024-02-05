set -e

# Configuration
LLVM_BUILD_DIR="/home/adam/projects/compilers/llvm-project/build"
LLVM_INSTALL_DIR=/usr/local

# Commands
mkdir build && cd build
cmake -G Ninja .. -DMLIR_DIR=$PREFIX/lib/cmake/mlir -DLLVM_EXTERNAL_LIT=$BUILD_DIR/bin/llvm-lit
cmake --build . --target check-standalone
