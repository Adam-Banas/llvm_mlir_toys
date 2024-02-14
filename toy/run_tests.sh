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
    ["matmul"]=""
    ["matmul-OPT"]="-opt"
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
    ["matmul"]=""
    ["basic-OPT"]="-opt"
    ["subtract-OPT"]="-opt"
)

declare -A llvm_dialect_files_and_flags
llvm_dialect_files_and_flags=(
    ["basic"]=""
    ["subtract"]=""
    ["basic-OPT"]="-opt"
    ["subtract-OPT"]="-opt"
)

declare -A llvm_files_and_flags
llvm_files_and_flags=(
    ["basic"]=""
    ["subtract"]=""
    ["basic-OPT"]="-opt"
    ["subtract-OPT"]="-opt"
)

declare -A jit_files_and_flags
jit_files_and_flags=(
    ["basic"]=""
    ["subtract"]=""
    ["matmul"]=""
    ["basic-OPT"]="-opt"
    ["subtract-OPT"]="-opt"
    ["matmul-OPT"]="-opt"
)

# Common function
check_mlir_files() {
    local -n _files_and_flags=$1
    local _file_dir=$2
    local _file_extension=$3
    local _emit_flag=$4

    for file in "${!_files_and_flags[@]}"
    do
        local flag="${_files_and_flags[$file]}"

        # This emulates C++ multimap
        IFS="-" read -r file postfix <<< "$file"
        
        local fc_flag=""
        if [[ -n "${postfix}" ]]; then
            fc_flag="--check-prefix=${postfix}"
        fi

        file=$_file_dir/$file.$_file_extension
        echo "Checking $file..."
        ${BUILD_DIR}/bin/toyc $file -emit=$_emit_flag $flag 2>&1 \
          | FileCheck $file $fc_flag
    done
}

# MLIR Tests
check_mlir_files mlir_files_and_flags "tests" "toy" "mlir" 

# Lowering to affine tests
check_mlir_files affine_mlir_files_and_flags "tests/affine_lowering" \
"mlir" "mlir-affine"

# Lowering to 'LLVM dialect' (i.e. MLIR dialect for LLVM code)
check_mlir_files llvm_dialect_files_and_flags "tests/llvm_dialect_lowering" \
"mlir" "mlir-llvm"

# Getting out of MLIR - lowering to actual LLVM
check_mlir_files llvm_files_and_flags "tests/llvm_lowering" "mlir" "llvm"

# Actual code generation using JIT
check_mlir_files jit_files_and_flags "tests/jit" "mlir" "jit"

# Success
echo -e "\e[32mAll tests passed successfully!\e[0m"
