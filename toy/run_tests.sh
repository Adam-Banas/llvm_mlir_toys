set -e

# Configuration
BUILD_DIR=build

# Tests
echo "Checking basic.toy..."
$BUILD_DIR/bin/toyc tests/basic.toy -emit=mlir 2>&1 | FileCheck tests/basic.toy

echo "Checking subtract.toy..."
$BUILD_DIR/bin/toyc tests/subtract.toy -emit=mlir 2>&1 | FileCheck tests/subtract.toy

# Success
echo -e "\e[32mAll tests passed successfully!\e[0m"