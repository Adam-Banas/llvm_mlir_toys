# Usage: emit_mlir.sh [filename]

set -e

INPUT_FILE=$1
if [ -z "$INPUT_FILE" ]; then INPUT_FILE='tests/codegen.toy'; fi

BUILD_DIR="build"

$BUILD_DIR/bin/toyc -emit=mlir -opt -mlir-print-debuginfo $INPUT_FILE
