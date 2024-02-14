toy.func @main() {
  %0 = toy.constant dense<[[1.000000e+00, 2.000000e+00, 3.000000e+00], [4.000000e+00, 5.000000e+00, 6.000000e+00]]> : tensor<2x3xf64>
  %1 = toy.constant dense<[[1.000000e+00, 2.000000e+00, 3.000000e+00, 4.000000e+00], [5.000000e+00, 6.000000e+00, 7.000000e+00, 8.000000e+00], [9.000000e+00, 1.000000e+01, 1.100000e+01, 1.200000e+01]]> : tensor<3x4xf64>
  %2 = toy.matmul %0, %1 : (tensor<2x3xf64>, tensor<3x4xf64>) -> tensor<2x4xf64>
  %3 = toy.transpose(%2 : tensor<2x4xf64>) to tensor<4x2xf64>
  toy.print %3 : tensor<4x2xf64>
  toy.return
}

// Regardless of optimizations, only result values should be printed in the console
// CHECK:      38.0
// CHECK-SAME: 83.0
// CHECK-NEXT: 44.0
// CHECK-SAME: 98.0
// CHECK-NEXT: 50.0
// CHECK-SAME: 113.0
// CHECK-NEXT: 56.0
// CHECK-SAME: 128.0

// OPT:      38.0
// OPT-SAME: 83.0
// OPT-NEXT: 44.0
// OPT-SAME: 98.0
// OPT-NEXT: 50.0
// OPT-SAME: 113.0
// OPT-NEXT: 56.0
// OPT-SAME: 128.0
