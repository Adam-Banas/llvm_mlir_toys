set -e

# Configuration
llvm_project_root="/home/adam/projects/compilers/llvm-project"
build_root="build"
build_include="$build_root/include"

# 
llvm_build_root=$llvm_project_root/build
mlir_src_root=$llvm_project_root/mlir
mlir_include_path=${mlir_src_root}/include
td_filepath=include/toy/Ops.td

# actual commands to generate four files
mlir-tblgen -gen-dialect-decls $td_filepath -I $mlir_include_path \
> $build_include/Dialect.h.inc
echo Generated file: $build_include/Dialect.h.inc

mlir-tblgen -gen-dialect-defs $td_filepath -I $mlir_include_path \
> $build_include/Dialect.cpp.inc
echo Generated file: $build_include/Dialect.cpp.inc

mlir-tblgen -gen-op-decls $td_filepath -I $mlir_include_path \
> $build_include/Ops.h.inc
echo Generated file: $build_include/Ops.h.inc

mlir-tblgen -gen-op-defs $td_filepath -I $mlir_include_path \
> $build_include/Ops.cpp.inc
echo Generated file: $build_include/Ops.cpp.inc


