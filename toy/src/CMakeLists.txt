set(LLVM_LINK_COMPONENTS
  Support
  )

set(LLVM_TARGET_DEFINITIONS mlir/ToyCombine.td)
mlir_tablegen(ToyCombine.inc -gen-rewriters)
add_public_tablegen_target(ToyCombineIncGen)

include_directories(${TOY_BINARY_DIR}/src)

add_llvm_executable(toyc
  toyc.cpp
  parser/AST.cpp
  mlir/Dialect.cpp
  mlir/MLIRGen.cpp
  mlir/ToyCombine.cpp

  DEPENDS
  ToyOpsIncGen
  ToyCombineIncGen
  )

llvm_update_compile_flags(toyc)
target_link_libraries(toyc
  PRIVATE
  MLIRAnalysis
  MLIRCastInterfaces
  MLIRCallInterfaces
  MLIRFunctionInterfaces
  MLIRIR
  MLIRParser
  MLIRPass
  MLIRSideEffectInterfaces
  MLIRTransforms
  )

mlir_check_link_libraries(toyc)
