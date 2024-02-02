# Usage: emit_mlir.sh [filename]

set -e

INPUT_FILE=$1
if [ -z "$INPUT_FILE" ]; then INPUT_FILE='codegen.toy'; fi

MLIR_BUILD_PATH="../../llvm-project/build"

$MLIR_BUILD_PATH/bin/toyc-ch2 -emit=mlir -mlir-print-debuginfo $INPUT_FILE
