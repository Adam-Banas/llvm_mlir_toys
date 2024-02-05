set -e

# Configuration
BUILD_DIR=build

# Tests
for file in basic subtract transpose_sequence
do
    echo "Checking $file.toy..."
    $BUILD_DIR/bin/toyc tests/$file.toy -emit=mlir 2>&1 -opt | FileCheck tests/$file.toy
done

# Success
echo -e "\e[32mAll tests passed successfully!\e[0m"
