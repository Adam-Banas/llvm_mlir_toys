set -e

# Handle args
if [[ $1 == "-v" ]] || [[ $1 == "--verbose" ]]; then
    set -x
fi

# Configuration
BUILD_DIR=build

declare -A mlir_files_and_flags
mlir_files_and_flags=(
    ["basic"]=""
    ["subtract"]=""
    ["transpose_sequence"]="-opt -no-shape-inference"
    ["redundant_reshapes"]="-opt -no-shape-inference"
    ["inlined_functions"]="-opt -inline"
    ["shape_inference"]="-opt -inline"
    ["functions_shapes_cse_integration"]="-opt -inline"
)

declare -A affine_mlir_files_and_flags
affine_mlir_files_and_flags=(
    ["basic"]=""
    ["subtract"]=""
    ["basic-OPT"]="-opt"
    ["subtract-OPT"]="-opt"
)

# MLIR Tests
for file in "${!mlir_files_and_flags[@]}"
do
    flag="${mlir_files_and_flags[$file]}"

    echo "Checking $file.toy..."
    $BUILD_DIR/bin/toyc tests/$file.toy -emit=mlir $flag 2>&1 | FileCheck tests/$file.toy
done

# Lowering to affine tests
for file in "${!affine_mlir_files_and_flags[@]}"
do
    flag="${affine_mlir_files_and_flags[$file]}"

    # This emulates C++ multimap
    IFS="-" read -r file postfix <<< "$file"
    
    fc_flag=""
    if [[ -n "${postfix}" ]]; then
        fc_flag="--check-prefix=${postfix}"
    fi

    echo "Checking $file.mlir..."
    $BUILD_DIR/bin/toyc tests/affine_lowering/$file.mlir -emit=mlir-affine $flag 2>&1 \
      | FileCheck tests/affine_lowering/$file.mlir $fc_flag
done

# Success
echo -e "\e[32mAll tests passed successfully!\e[0m"
