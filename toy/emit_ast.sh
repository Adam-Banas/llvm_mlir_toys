# Usage: emit_ast.sh [filename]

set -e

INPUT_FILE=$1
if [ -z "$INPUT_FILE" ]; then INPUT_FILE='ast.toy'; fi

MLIR_BUILD_PATH="../../llvm-project/build"

$MLIR_BUILD_PATH/bin/toyc-ch1 -emit=ast $INPUT_FILE
