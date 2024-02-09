toy.func @main() {
  %0 = toy.constant dense<[[1.000000e+00, 2.000000e+00, 3.000000e+00], [4.000000e+00, 5.000000e+00, 6.000000e+00]]> : tensor<2x3xf64>
  %2 = toy.transpose(%0 : tensor<2x3xf64>) to tensor<3x2xf64>
  %3 = toy.mul %2, %2 : tensor<3x2xf64>
  toy.print %3 : tensor<3x2xf64>
  toy.return
}

// CHECK-LABEL: func @main()
// CHECK:         [[VAL_0:%.*]] = memref.alloc() : memref<3x2xf64>
// CHECK:         [[VAL_1:%.*]] = memref.alloc() : memref<3x2xf64>
// CHECK:         [[VAL_2:%.*]] = memref.alloc() : memref<2x3xf64>
// CHECK:         [[VAL_3:%.*]] = arith.constant 0 : index
// CHECK:         [[VAL_4:%.*]] = arith.constant 1 : index
// CHECK:         [[VAL_5:%.*]] = arith.constant 2 : index
// CHECK:         [[VAL_6:%.*]] = arith.constant 1.000000e+00 : f64
// CHECK:         affine.store [[VAL_6]], [[VAL_2]][[[VAL_3]], [[VAL_3]]] : memref<2x3xf64>
// CHECK:         [[VAL_7:%.*]] = arith.constant 2.000000e+00 : f64
// CHECK:         affine.store [[VAL_7]], [[VAL_2]][[[VAL_3]], [[VAL_4]]] : memref<2x3xf64>
// CHECK:         [[VAL_8:%.*]] = arith.constant 3.000000e+00 : f64
// CHECK:         affine.store [[VAL_8]], [[VAL_2]][[[VAL_3]], [[VAL_5]]] : memref<2x3xf64>
// CHECK:         [[VAL_9:%.*]] = arith.constant 4.000000e+00 : f64
// CHECK:         affine.store [[VAL_9]], [[VAL_2]][[[VAL_4]], [[VAL_3]]] : memref<2x3xf64>
// CHECK:         [[VAL_10:%.*]] = arith.constant 5.000000e+00 : f64
// CHECK:         affine.store [[VAL_10]], [[VAL_2]][[[VAL_4]], [[VAL_4]]] : memref<2x3xf64>
// CHECK:         [[VAL_11:%.*]] = arith.constant 6.000000e+00 : f64
// CHECK:         affine.store [[VAL_11]], [[VAL_2]][[[VAL_4]], [[VAL_5]]] : memref<2x3xf64>
// CHECK:         affine.for [[VAL_12:%.*]] = 0 to 3 {
// CHECK:           affine.for [[VAL_13:%.*]] = 0 to 2 {
// CHECK:             [[VAL_14:%.*]] = affine.load [[VAL_2]]{{\[}}[[VAL_13]], [[VAL_12]]] : memref<2x3xf64>
// CHECK:             affine.store [[VAL_14]], [[VAL_1]]{{\[}}[[VAL_12]], [[VAL_13]]] : memref<3x2xf64>
// CHECK:         affine.for [[VAL_12:%.*]] = 0 to 3 {
// CHECK:           affine.for [[VAL_13:%.*]] = 0 to 2 {
// CHECK:             [[VAL_14:%.*]] = affine.load [[VAL_1]]{{\[}}[[VAL_12]], [[VAL_13]]] : memref<3x2xf64>
// CHECK:             [[VAL_15:%.*]] = affine.load [[VAL_1]]{{\[}}[[VAL_12]], [[VAL_13]]] : memref<3x2xf64>
// CHECK:             [[VAL_16:%.*]] = arith.mulf [[VAL_14]], [[VAL_15]] : f64
// CHECK:             affine.store [[VAL_16]], [[VAL_0]]{{\[}}[[VAL_12]], [[VAL_13]]] : memref<3x2xf64>
// CHECK:         toy.print [[VAL_0]] : memref<3x2xf64>
// CHECK:         memref.dealloc [[VAL_2]] : memref<2x3xf64>
// CHECK:         memref.dealloc [[VAL_1]] : memref<3x2xf64>
// CHECK:         memref.dealloc [[VAL_0]] : memref<3x2xf64>
// CHECK:         toy.return