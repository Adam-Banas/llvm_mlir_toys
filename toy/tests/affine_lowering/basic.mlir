toy.func @main() {
  %0 = toy.constant dense<[[1.000000e+00, 2.000000e+00, 3.000000e+00], [4.000000e+00, 5.000000e+00, 6.000000e+00]]> : tensor<2x3xf64>
  %2 = toy.transpose(%0 : tensor<2x3xf64>) to tensor<3x2xf64>
  %3 = toy.mul %2, %2 : tensor<3x2xf64>
  %4 = toy.add %3, %2 : tensor<3x2xf64>
  toy.print %4 : tensor<3x2xf64>
  toy.return
}

// CHECK-LABEL: func @main()
// CHECK:         [[VAL_7:%.*]] = arith.constant 6.000000e+00 : f64
// CHECK:         [[VAL_8:%.*]] = arith.constant 5.000000e+00 : f64
// CHECK:         [[VAL_9:%.*]] = arith.constant 4.000000e+00 : f64
// CHECK:         [[VAL_10:%.*]] = arith.constant 3.000000e+00 : f64
// CHECK:         [[VAL_11:%.*]] = arith.constant 2.000000e+00 : f64
// CHECK:         [[VAL_12:%.*]] = arith.constant 1.000000e+00 : f64
// CHECK:         [[VAL_0:%.*]] = memref.alloc() : memref<3x2xf64>
// CHECK:         [[VAL_1:%.*]] = memref.alloc() : memref<3x2xf64>
// CHECK:         [[VAL_2:%.*]] = memref.alloc() : memref<3x2xf64>
// CHECK:         [[VAL_3:%.*]] = memref.alloc() : memref<2x3xf64>
// CHECK:         affine.store [[VAL_12]], [[VAL_3]][0, 0] : memref<2x3xf64>
// CHECK:         affine.store [[VAL_11]], [[VAL_3]][0, 1] : memref<2x3xf64>
// CHECK:         affine.store [[VAL_10]], [[VAL_3]][0, 2] : memref<2x3xf64>
// CHECK:         affine.store [[VAL_9]], [[VAL_3]][1, 0] : memref<2x3xf64>
// CHECK:         affine.store [[VAL_8]], [[VAL_3]][1, 1] : memref<2x3xf64>
// CHECK:         affine.store [[VAL_7]], [[VAL_3]][1, 2] : memref<2x3xf64>
// CHECK:         affine.for [[VAL_13:%.*]] = 0 to 3 {
// CHECK:           affine.for [[VAL_14:%.*]] = 0 to 2 {
// CHECK:             [[VAL_15:%.*]] = affine.load [[VAL_3]]{{\[}}[[VAL_14]], [[VAL_13]]] : memref<2x3xf64>
// CHECK:             affine.store [[VAL_15]], [[VAL_2]]{{\[}}[[VAL_13]], [[VAL_14]]] : memref<3x2xf64>
// CHECK:         affine.for [[VAL_13:%.*]] = 0 to 3 {
// CHECK:           affine.for [[VAL_14:%.*]] = 0 to 2 {
// CHECK:             [[VAL_15:%.*]] = affine.load [[VAL_2]]{{\[}}[[VAL_13]], [[VAL_14]]] : memref<3x2xf64>
// CHECK:             [[VAL_17:%.*]] = arith.mulf [[VAL_15]], [[VAL_15]] : f64
// CHECK:             affine.store [[VAL_17]], [[VAL_1]]{{\[}}[[VAL_13]], [[VAL_14]]] : memref<3x2xf64>
// CHECK:         affine.for [[VAL_13:%.*]] = 0 to 3 {
// CHECK:           affine.for [[VAL_14:%.*]] = 0 to 2 {
// CHECK:             [[VAL_15:%.*]] = affine.load [[VAL_1]]{{\[}}[[VAL_13]], [[VAL_14]]] : memref<3x2xf64>
// CHECK:             [[VAL_16:%.*]] = affine.load [[VAL_2]]{{\[}}[[VAL_13]], [[VAL_14]]] : memref<3x2xf64>
// CHECK:             [[VAL_17:%.*]] = arith.addf [[VAL_15]], [[VAL_16]] : f64
// CHECK:             affine.store [[VAL_17]], [[VAL_0]]{{\[}}[[VAL_13]], [[VAL_14]]] : memref<3x2xf64>
// CHECK:         toy.print [[VAL_0]] : memref<3x2xf64>
// CHECK:         memref.dealloc [[VAL_3]] : memref<2x3xf64>
// CHECK:         memref.dealloc [[VAL_2]] : memref<3x2xf64>
// CHECK:         memref.dealloc [[VAL_1]] : memref<3x2xf64>
// CHECK:         memref.dealloc [[VAL_0]] : memref<3x2xf64>

// OPT-LABEL: func @main()
// OPT:         [[VAL_0:%.*]] = arith.constant 6.000000e+00 : f64
// OPT:         [[VAL_1:%.*]] = arith.constant 5.000000e+00 : f64
// OPT:         [[VAL_2:%.*]] = arith.constant 4.000000e+00 : f64
// OPT:         [[VAL_3:%.*]] = arith.constant 3.000000e+00 : f64
// OPT:         [[VAL_4:%.*]] = arith.constant 2.000000e+00 : f64
// OPT:         [[VAL_5:%.*]] = arith.constant 1.000000e+00 : f64
// OPT:         [[VAL_6:%.*]] = memref.alloc() : memref<3x2xf64>
// OPT:         [[VAL_7:%.*]] = memref.alloc() : memref<2x3xf64>
// OPT:         affine.store [[VAL_5]], [[VAL_7]][0, 0] : memref<2x3xf64>
// OPT:         affine.store [[VAL_4]], [[VAL_7]][0, 1] : memref<2x3xf64>
// OPT:         affine.store [[VAL_3]], [[VAL_7]][0, 2] : memref<2x3xf64>
// OPT:         affine.store [[VAL_2]], [[VAL_7]][1, 0] : memref<2x3xf64>
// OPT:         affine.store [[VAL_1]], [[VAL_7]][1, 1] : memref<2x3xf64>
// OPT:         affine.store [[VAL_0]], [[VAL_7]][1, 2] : memref<2x3xf64>
// OPT:         affine.for [[VAL_8:%.*]] = 0 to 3 {
// OPT:           affine.for [[VAL_9:%.*]] = 0 to 2 {
// OPT:             [[VAL_10:%.*]] = affine.load [[VAL_7]]{{\[}}[[VAL_9]], [[VAL_8]]] : memref<2x3xf64>
// OPT:             [[VAL_11:%.*]] = arith.mulf [[VAL_10]], [[VAL_10]] : f64
// OPT:             [[VAL_12:%.*]] = arith.addf [[VAL_11]], [[VAL_10]] : f64
// OPT:             affine.store [[VAL_12]], [[VAL_6]]{{\[}}[[VAL_8]], [[VAL_9]]] : memref<3x2xf64>
// OPT:         toy.print [[VAL_6]] : memref<3x2xf64>
// OPT:         memref.dealloc [[VAL_7]] : memref<2x3xf64>
// OPT:         memref.dealloc [[VAL_6]] : memref<3x2xf64>
