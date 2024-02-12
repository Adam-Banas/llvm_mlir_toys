toy.func @main() {
  %0 = toy.constant dense<[[1.000000e+00, 2.000000e+00, 3.000000e+00], [4.000000e+00, 5.000000e+00, 6.000000e+00]]> : tensor<2x3xf64>
  %2 = toy.transpose(%0 : tensor<2x3xf64>) to tensor<3x2xf64>
  %3 = toy.mul %2, %2 : tensor<3x2xf64>
  %4 = toy.add %3, %2 : tensor<3x2xf64>
  toy.print %4 : tensor<3x2xf64>
  toy.return
}

// This test is intentionally left almost empty, we don't want to verify the conversion
// between 'core' mlir dialects (e.g. affine, arith) and LLVM.
// There are only two things we want to verify:
// 1) That the conversion to LLVM is functional,
// 2) That the print operation (i.e. the only toy operation left after partial
//    conversion to core MLIR dialects) was converted to llvm call of printf
// CHECK-LABEL: llvm.func @main()
// CHECK:       llvm.call @printf(
