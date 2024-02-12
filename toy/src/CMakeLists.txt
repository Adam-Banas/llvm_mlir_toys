set(LLVM_LINK_COMPONENTS
  Core
  Support
  nativecodegen
  OrcJIT
  )

set(LLVM_TARGET_DEFINITIONS mlir/ToyCombine.td)
mlir_tablegen(ToyCombine.inc -gen-rewriters)
add_public_tablegen_target(ToyCombineIncGen)

include_directories(${TOY_BINARY_DIR}/src)

add_llvm_executable(toyc
    toyc.cpp
    parser/AST.cpp
    mlir/Dialect.cpp
    mlir/LowerToAffineLoops.cpp
    mlir/LowerToLLVM.cpp
    mlir/MLIRGen.cpp
    mlir/ShapeInferencePass.cpp
    mlir/ToyCombine.cpp

  DEPENDS
    ToyOpsIncGen
    ToyShapeInferenceInterfaceIncGen
    ToyCombineIncGen
)

llvm_update_compile_flags(toyc)
get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)
get_property(extension_libs GLOBAL PROPERTY MLIR_EXTENSION_LIBS)
target_link_libraries(toyc
  PRIVATE
    ${dialect_libs}
    ${conversion_libs}
    ${extension_libs}
    MLIRAnalysis
    MLIRBuiltinToLLVMIRTranslation
    MLIRCallInterfaces
    MLIRCastInterfaces
    MLIRExecutionEngine
    MLIRFunctionInterfaces
    MLIRIR
    MLIRLLVMCommonConversion
    MLIRLLVMDialect
    MLIRLLVMToLLVMIRTranslation
    MLIRMemRefDialect
    MLIRParser
    MLIRPass
    MLIRSideEffectInterfaces
    MLIRSupport
    MLIRTargetLLVMIRExport
    MLIRTransforms
)

mlir_check_link_libraries(toyc)
