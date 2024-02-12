toy.func @main() {
  %0 = toy.constant dense<[[1.000000e+00, 2.000000e+00, 3.000000e+00], [4.000000e+00, 5.000000e+00, 6.000000e+00]]> : tensor<2x3xf64>
  %2 = toy.transpose(%0 : tensor<2x3xf64>) to tensor<3x2xf64>
  %3 = toy.mul %2, %2 : tensor<3x2xf64>
  %4 = toy.sub %3, %2 : tensor<3x2xf64>
  toy.print %4 : tensor<3x2xf64>
  toy.return
}


// Not optimized version: Should find printf with pointer to function
// CHECK-LABEL: define void @main()
// CHECK: @printf(ptr

// Optimized version: Because of constant folding, inlining and other optimizations,
// only print statements with concrete values should be visible
// OPT-LABEL: define void @main()
// OPT: @printf
// OPT-SAME: 0.000000e+00
// OPT: @printf
// OPT-SAME: 1.200000e+01
// OPT: @printf
// OPT-SAME: 2.000000e+00
// OPT: @printf
// OPT-SAME: 2.000000e+01
// OPT: @printf
// OPT-SAME: 6.000000e+00
// OPT: @printf
// OPT-SAME: 3.000000e+01