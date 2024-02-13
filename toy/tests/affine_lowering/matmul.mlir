toy.func @main() {
    %0 = toy.constant dense<[[1.000000e+00, 2.000000e+00, 3.000000e+00], [4.000000e+00, 5.000000e+00, 6.000000e+00]]> : tensor<2x3xf64>
    %1 = toy.constant dense<[[1.000000e+00, 2.000000e+00, 3.000000e+00, 4.000000e+00], [5.000000e+00, 6.000000e+00, 7.000000e+00, 8.000000e+00], [9.000000e+00, 1.000000e+01, 1.100000e+01, 1.200000e+01]]> : tensor<3x4xf64>
    %2 = toy.matmul %0, %1 : (tensor<2x3xf64>, tensor<3x4xf64>) -> tensor<2x4xf64>
    %3 = toy.transpose(%2 : tensor<2x4xf64>) to tensor<4x2xf64>
    toy.print %3 : tensor<4x2xf64>
    toy.return
}

// CHECK-LABEL: func @main()