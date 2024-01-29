# Usage:
# 1. Build toy compiler (i.e. run ./build.sh)
# 2. Run this script. You should see 'All tests passed!'
#
# Additionally, object file 'statistics.o' has been created.

set -e

./toy -f statistics.toy -o statistics.o
clang++ test_statistics.cpp statistics.o -o test_statistics
./test_statistics <<< "5.5 6.0"