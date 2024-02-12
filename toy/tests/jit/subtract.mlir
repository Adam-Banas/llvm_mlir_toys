toy.func @main() {
  %0 = toy.constant dense<[[1.000000e+00, 2.000000e+00, 3.000000e+00], [4.000000e+00, 5.000000e+00, 6.000000e+00]]> : tensor<2x3xf64>
  %2 = toy.transpose(%0 : tensor<2x3xf64>) to tensor<3x2xf64>
  %3 = toy.mul %2, %2 : tensor<3x2xf64>
  %4 = toy.sub %3, %2 : tensor<3x2xf64>
  toy.print %4 : tensor<3x2xf64>
  toy.return
}

// Regardless of optimizations, only result values should be printed in the console
// CHECK:      0.0
// CHECK-SAME: 12.0
// CHECK-NEXT: 2.0
// CHECK-SAME: 20.0
// CHECK-NEXT: 6.0
// CHECK-SAME: 30.0

// OPT:      0.0
// OPT-SAME: 12.0
// OPT-NEXT: 2.0
// OPT-SAME: 20.0
// OPT-NEXT: 6.0
// OPT-SAME: 30.0