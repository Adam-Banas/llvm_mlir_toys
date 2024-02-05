# A standalone example of Toy language

A standalone example of Toy language, by following MLIR Toy tutorial and combining it with standalone example (llvm-project/mlir/examples/standalone).

# Building - Component Build

Change paths in build.sh and run it.

**Note**: Make sure to pass `-DLLVM_INSTALL_UTILS=ON` when building LLVM with CMake in order to install `FileCheck` to the chosen installation prefix. Check mlir/examples/standalone for more information.