set(LLVM_LINK_COMPONENTS
  Support
  )

add_llvm_executable(toyc
  toyc.cpp
  parser/AST.cpp
  mlir/Dialect.cpp
  mlir/MLIRGen.cpp
  mlir/ToyCombine.cpp

  DEPENDS
  ToyOpsIncGen
  )

llvm_update_compile_flags(toyc)
target_link_libraries(toyc
  PRIVATE
  MLIRAnalysis
  MLIRFunctionInterfaces
  MLIRIR
  MLIRParser
  MLIRSideEffectInterfaces
  MLIRTransforms
  )

mlir_check_link_libraries(toyc)
