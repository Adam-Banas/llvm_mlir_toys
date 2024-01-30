# Usage:
# 1. Build toy compiler (i.e. run ./build.sh)
# 2. Run this script. You should see 'All tests passed!'
#
# Additionally, object file 'custom_op.o' has been created.

set -e

./toy -f custom_op.toy -o custom_op.o
clang++ test_custom_op.cpp custom_op*.o -o test_custom_op
./test_custom_op <<< "2.0 6.0 4.5"