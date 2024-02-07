set -e

# Configuration
BUILD_DIR=build

declare -A files_and_flags
files_and_flags=(
    ["basic"]=""
    ["subtract"]=""
    ["transpose_sequence"]="-opt"
    ["redundant_reshapes"]="-opt"
    ["inlined_functions"]="-opt -inline"
    ["shape_inference"]="-opt -inline"
    ["functions_shapes_cse_integration"]="-opt -inline"
)

# Tests
for file in "${!files_and_flags[@]}"
do
    flag="${files_and_flags[$file]}"

    echo "Checking $file.toy..."
    $BUILD_DIR/bin/toyc tests/$file.toy -emit=mlir $flag 2>&1 | FileCheck tests/$file.toy
done

# Success
echo -e "\e[32mAll tests passed successfully!\e[0m"
