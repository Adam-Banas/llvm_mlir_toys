//===- Dialect.cpp - Toy IR Dialect registration in MLIR ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the dialect for the Toy IR: custom type parsing and
// operation verification.
//
//===----------------------------------------------------------------------===//

#include "toy/Dialect.h"

#include "mlir/IR/Attributes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Location.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/OperationSupport.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Interfaces/CallInterfaces.h"
#include "mlir/Interfaces/FunctionImplementation.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Support/LogicalResult.h"
#include "mlir/Transforms/InliningUtils.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Casting.h"
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <mlir/IR/BuiltinAttributes.h>
#include <mlir/IR/Operation.h>
#include <string>

using namespace mlir;
using namespace mlir::toy;

#include "toy/Dialect.cpp.inc"

//===----------------------------------------------------------------------===//
// ToyInlinerInterface
//===----------------------------------------------------------------------===//

/// This class defines the interface for handling inlining with Toy operations.
/// We simplify inherit from the base interface class and override
/// the necessary methods.
struct ToyInlinerInterface : public DialectInlinerInterface {
  using DialectInlinerInterface::DialectInlinerInterface;

  //===--------------------------------------------------------------------===//
  // Analysis Hooks
  //===--------------------------------------------------------------------===//

  /// This hook checks to see if the given callable operation is legal to inline
  /// into the given call. For Toy this hook can simply return true, as the Toy
  /// Call operation is always inlinable.
  bool isLegalToInline(Operation *call, Operation *callable,
                       bool wouldBeCloned) const final {
    return true;
  }

  /// This hook checks to see if the given operation is legal to inline into the
  /// given region. For Toy this hook can simply return true, as all Toy
  /// operations are inlinable.
  bool isLegalToInline(Operation *, Region *, bool,
                       IRMapping &) const final {
    return true;
  }

  /// This hook cheks if the given 'src' region can be inlined into the 'dest'
  /// region. The regions here are the bodies of the callable functions. For
  /// Toy, any function can be inlined, so we simply return true.
  bool isLegalToInline(Region *dest, Region *src, bool wouldBeCloned,
                       IRMapping &valueMapping) const final {
    return true;
  }

  //===--------------------------------------------------------------------===//
  // Transformation Hooks
  //===--------------------------------------------------------------------===//

  /// This hook is called when a terminator operation has been inlined. The only
  /// terminator that we have in the Toy dialect is the return
  /// operation(toy.return). We handle the return by replacing the values
  /// previously returned by the call operation with the operands of the
  /// return.
  void handleTerminator(Operation *op, ValueRange valuesToRepl) const final {
    // Only "toy.return" needs to be handled here.
    auto returnOp = cast<ReturnOp>(op);

    // Replace the values directly with the return operands.
    assert(returnOp.getNumOperands() == valuesToRepl.size());
    for (const auto &it : llvm::enumerate(returnOp.getOperands()))
      valuesToRepl[it.index()].replaceAllUsesWith(it.value());
  }

  /// Attempts to materialize a conversion for a type mismatch between a call
  /// from this dialect, and a callable region. This method should generate an
  /// operation that takes 'input' as the only operand, and produces a single
  /// result of 'resultType'. If a conversion can not be generated, nullptr
  /// should be returned.
  Operation *materializeCallConversion(OpBuilder &builder, Value input,
                                       Type resultType,
                                       Location conversionLoc) const final {
    return builder.create<CastOp>(conversionLoc, resultType, input);
  }
};

//===----------------------------------------------------------------------===//
// ToyDialect
//===----------------------------------------------------------------------===//

/// Dialect initialization, the instance will be owned by the context. This is
/// the point of registration of types and operations for the dialect.
void ToyDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "toy/Ops.cpp.inc"
      >();
  addInterfaces<ToyInlinerInterface>();
}

//===----------------------------------------------------------------------===//
// Toy Operations
//===----------------------------------------------------------------------===//

/// A generalized parser for binary operations. This parses the different forms
/// of 'printBinaryOp' below.
static mlir::ParseResult parseBinaryOp(mlir::OpAsmParser &parser,
                                       mlir::OperationState &result) {
  SmallVector<mlir::OpAsmParser::UnresolvedOperand, 2> operands;
  SMLoc operandsLoc = parser.getCurrentLocation();
  Type type;
  if (parser.parseOperandList(operands, /*requiredOperandCount=*/2) ||
      parser.parseOptionalAttrDict(result.attributes) ||
      parser.parseColonType(type))
    return mlir::failure();

  // If the type is a function type, it contains the input and result types of
  // this operation.
  if (FunctionType funcType = llvm::dyn_cast<FunctionType>(type)) {
    if (parser.resolveOperands(operands, funcType.getInputs(), operandsLoc,
                               result.operands))
      return mlir::failure();
    result.addTypes(funcType.getResults());
    return mlir::success();
  }

  // Otherwise, the parsed type is the type of both operands and results.
  if (parser.resolveOperands(operands, type, result.operands))
    return mlir::failure();
  result.addTypes(type);
  return mlir::success();
}

/// A generalized printer for binary operations. It prints in two different
/// forms depending on if all of the types match.
static void printBinaryOp(mlir::OpAsmPrinter &printer, mlir::Operation *op) {
  printer << " " << op->getOperands();
  printer.printOptionalAttrDict(op->getAttrs());
  printer << " : ";

  // If all of the types are the same, print the type directly.
  Type resultType = *op->result_type_begin();
  if (llvm::all_of(op->getOperandTypes(),
                   [=](Type type) { return type == resultType; })) {
    printer << resultType;
    return;
  }

  // Otherwise, print a functional type.
  printer.printFunctionalType(op->getOperandTypes(), op->getResultTypes());
}

//===----------------------------------------------------------------------===//
// ConstantOp
//===----------------------------------------------------------------------===//

/// Build a constant operation.
/// The builder is passed as an argument, so is the state that this method is
/// expected to fill in order to build the operation.
void ConstantOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                       double value) {
  auto dataType = RankedTensorType::get({}, builder.getF64Type());
  auto dataAttribute = DenseElementsAttr::get(dataType, value);
  ConstantOp::build(builder, state, dataType, dataAttribute);
}

/// The 'OpAsmParser' class provides a collection of methods for parsing
/// various punctuation, as well as attributes, operands, types, etc. Each of
/// these methods returns a `ParseResult`. This class is a wrapper around
/// `LogicalResult` that can be converted to a boolean `true` value on failure,
/// or `false` on success. This allows for easily chaining together a set of
/// parser rules. These rules are used to populate an `mlir::OperationState`
/// similarly to the `build` methods described above.
mlir::ParseResult ConstantOp::parse(mlir::OpAsmParser &parser,
                                    mlir::OperationState &result) {
  mlir::DenseElementsAttr value;
  if (parser.parseOptionalAttrDict(result.attributes) ||
      parser.parseAttribute(value, "value", result.attributes))
    return failure();

  result.addTypes(value.getType());
  return success();
}

/// The 'OpAsmPrinter' class is a stream that allows for formatting
/// strings, attributes, operands, types, etc.
void ConstantOp::print(mlir::OpAsmPrinter &printer) {
  printer << " ";
  printer.printOptionalAttrDict((*this)->getAttrs(), /*elidedAttrs=*/{"value"});
  printer << getValue();
}

/// Verifier for the constant operation. This corresponds to the
/// `let hasVerifier = 1` in the op definition.
mlir::LogicalResult ConstantOp::verify() {
  // If the return type of the constant is not an unranked tensor, the shape
  // must match the shape of the attribute holding the data.
  auto resultType = llvm::dyn_cast<mlir::RankedTensorType>(getResult().getType());
  if (!resultType)
    return success();

  // Check that the rank of the attribute type matches the rank of the constant
  // result type.
  auto attrType = llvm::cast<mlir::RankedTensorType>(getValue().getType());
  if (attrType.getRank() != resultType.getRank()) {
    return emitOpError("return type must match the one of the attached value "
                       "attribute: ")
           << attrType.getRank() << " != " << resultType.getRank();
  }

  // Check that each of the dimensions match between the two types.
  for (int dim = 0, dimE = attrType.getRank(); dim < dimE; ++dim) {
    if (attrType.getShape()[dim] != resultType.getShape()[dim]) {
      return emitOpError(
                 "return type shape mismatches its attribute at dimension ")
             << dim << ": " << attrType.getShape()[dim]
             << " != " << resultType.getShape()[dim];
    }
  }
  return mlir::success();
}

//===----------------------------------------------------------------------===//
// AddOp
//===----------------------------------------------------------------------===//

void AddOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                  mlir::Value lhs, mlir::Value rhs) {
  state.addTypes(UnrankedTensorType::get(builder.getF64Type()));
  state.addOperands({lhs, rhs});
}

mlir::ParseResult AddOp::parse(mlir::OpAsmParser &parser,
                               mlir::OperationState &result) {
  return parseBinaryOp(parser, result);
}

void AddOp::print(mlir::OpAsmPrinter &p) { printBinaryOp(p, *this); }

/// Infer the output shape of the SubOp, this is required by the shape
/// inference interface.
void AddOp::inferShapes() {
  getResult().setType(getRhs().getType());
}

//===----------------------------------------------------------------------===//
// SubOp
//===----------------------------------------------------------------------===//

void SubOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                  mlir::Value lhs, mlir::Value rhs) {
  state.addTypes(UnrankedTensorType::get(builder.getF64Type()));
  state.addOperands({lhs, rhs});
}

mlir::ParseResult SubOp::parse(mlir::OpAsmParser &parser,
                               mlir::OperationState &result) {
  return parseBinaryOp(parser, result);
}

void SubOp::print(mlir::OpAsmPrinter &p) { printBinaryOp(p, *this); }

/// Infer the output shape of the SubOp, this is required by the shape
/// inference interface.
void SubOp::inferShapes() {
  getResult().setType(getRhs().getType());
}

//===----------------------------------------------------------------------===//
// MatMulOp
//===----------------------------------------------------------------------===//

void MatMulOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                     mlir::Value A, mlir::Value B) {
  state.addTypes(UnrankedTensorType::get(builder.getF64Type()));
  state.addOperands({A, B});
}

mlir::ParseResult MatMulOp::parse(mlir::OpAsmParser &parser,
                                  mlir::OperationState &result) {
  return parseBinaryOp(parser, result);
}

void MatMulOp::print(mlir::OpAsmPrinter &p) { printBinaryOp(p, *this); }

mlir::LogicalResult MatMulOp::verify() {
  auto aInputType = llvm::dyn_cast<RankedTensorType>(getA().getType());
  auto bInputType = llvm::dyn_cast<RankedTensorType>(getB().getType());
  auto resultType = llvm::dyn_cast<RankedTensorType>(getType());

  // TODO: Not sure when this scenario can happen, I took it from TransposeOp::verify
  if (!aInputType || !bInputType || !resultType)
    return mlir::success();

  auto aInputShape = aInputType.getShape();
  auto bInputShape = bInputType.getShape();
  auto resultShape = resultType.getShape();

  // A, B and result should be second rank tensors
  if (aInputShape.size() != 2 || bInputShape.size() != 2 || resultShape.size() != 2) {
    return emitError() 
      << "Expected matmul input and output tensors to be second-rank (two-dimensional)";
  }

  // A's inner dim should match B's outer dim
  if (aInputShape[1] != bInputShape[0]) {
    return emitError()
           << "Dimension mismatch for matmul";
  }

  // Verify result shape
  if (aInputShape[0] != resultShape[0]
      || bInputShape[1] != resultShape[1]) {
    return emitError()
           << "Wrong matmul result shape";
  }

  return mlir::success();
}

/// Infer the output shape of the TransposeOp, this is required by the shape
/// inference interface.
void MatMulOp::inferShapes() {
  auto aArrayTy = llvm::cast<RankedTensorType>(getA().getType());
  if (aArrayTy.getShape().size() != 2) {
    emitError() << "Infering shapes of matmul of tensor rank " << aArrayTy.getShape().size() << " not implemented!";
  }
  auto bArrayTy = llvm::cast<RankedTensorType>(getB().getType());
  if (bArrayTy.getShape().size() != 2) {
    emitError() << "Infering shapes of matmul of tensor rank " << bArrayTy.getShape().size() << " not implemented!";
  }

  SmallVector<int64_t, 2> dims = {aArrayTy.getShape()[0], bArrayTy.getShape()[1]};
  getResult().setType(RankedTensorType::get(dims, aArrayTy.getElementType()));
}

//===----------------------------------------------------------------------===//
// CastOp
//===----------------------------------------------------------------------===//

/// Infer the output shape of the CastOp, this is required by the shape
/// inference interface.
void CastOp::inferShapes() { getResult().setType(getInput().getType()); }

/// Returns true if the given set of input and result types are compatible with
/// this cast operation. This is required by the `CastOpInterface` to verify
/// this operation and provide other additional utilities.
bool CastOp::areCastCompatible(TypeRange inputs, TypeRange outputs) {
  if (inputs.size() != 1 || outputs.size() != 1)
    return false;
  // The inputs must be Tensors with the same element type.
  TensorType input = llvm::dyn_cast<TensorType>(inputs.front());
  TensorType output = llvm::dyn_cast<TensorType>(outputs.front());
  if (!input || !output || input.getElementType() != output.getElementType())
    return false;
  // The shape is required to match if both types are ranked.
  return !input.hasRank() || !output.hasRank() || input == output;
}

//===----------------------------------------------------------------------===//
// FunctionalLinearOp
//===----------------------------------------------------------------------===//

void FunctionalLinearOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                  mlir::Value input, mlir::Value weight, mlir::Value bias) {
  state.addTypes(UnrankedTensorType::get(builder.getF64Type()));
  state.addOperands({input, weight, bias});
}

mlir::ParseResult FunctionalLinearOp::parse(mlir::OpAsmParser &parser,
                               mlir::OperationState &result) {
  return failure();
}

void FunctionalLinearOp::print(mlir::OpAsmPrinter &p) { p << "Parsing FunctionalLinearOp not implemented"; }


//===----------------------------------------------------------------------===//
// GenericCallOp
//===----------------------------------------------------------------------===//

void GenericCallOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                          StringRef callee, ArrayRef<mlir::Value> arguments) {
  // Generic call always returns an unranked Tensor initially.
  state.addTypes(UnrankedTensorType::get(builder.getF64Type()));
  state.addOperands(arguments);
  state.addAttribute("callee",
                     mlir::SymbolRefAttr::get(builder.getContext(), callee));
}

/// Return the callee of the generic call operation, this is required by the
/// call interface.
::mlir::CallInterfaceCallable GenericCallOp::getCallableForCallee() {
  return (*this)->getAttrOfType<SymbolRefAttr>("callee");
}

/// Set the callee for the generic call operation, this is required by the call
/// interface.
void GenericCallOp::setCalleeFromCallable(::mlir::CallInterfaceCallable callee) {
  (*this)->setAttr("callee", callee.get<SymbolRefAttr>());
}

/// Get the argument operands to the called function, this is required by the
/// call interface.
::mlir::Operation::operand_range GenericCallOp::getArgOperands() {
  return getInputs();
}

/// Get the argument operands to the called function as a mutable range, this is
/// required by the call interface.
MutableOperandRange GenericCallOp::getArgOperandsMutable() {
  return getInputsMutable();
}

//===----------------------------------------------------------------------===//
// FuncOp
//===----------------------------------------------------------------------===//

void FuncOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                   llvm::StringRef name, mlir::FunctionType type,
                   llvm::ArrayRef<mlir::NamedAttribute> attrs) {
  // FunctionOpInterface provides a convenient `build` method that will populate
  // the state of our FuncOp, and create an entry block.
  buildWithEntryBlock(builder, state, name, type, attrs, type.getInputs());
}

mlir::ParseResult FuncOp::parse(mlir::OpAsmParser &parser,
                                mlir::OperationState &result) {
  // Dispatch to the FunctionOpInterface provided utility method that parses the
  // function operation.
  auto buildFuncType =
      [](mlir::Builder &builder, llvm::ArrayRef<mlir::Type> argTypes,
         llvm::ArrayRef<mlir::Type> results,
         mlir::function_interface_impl::VariadicFlag,
         std::string &) { return builder.getFunctionType(argTypes, results); };

  return mlir::function_interface_impl::parseFunctionOp(
      parser, result, /*allowVariadic=*/false,
      getFunctionTypeAttrName(result.name), buildFuncType,
      getArgAttrsAttrName(result.name), getResAttrsAttrName(result.name));
}

void FuncOp::print(mlir::OpAsmPrinter &p) {
  // Dispatch to the FunctionOpInterface provided utility method that prints the
  // function operation.
  mlir::function_interface_impl::printFunctionOp(
      p, *this, /*isVariadic=*/false, getFunctionTypeAttrName(),
      getArgAttrsAttrName(), getResAttrsAttrName());
}

//===----------------------------------------------------------------------===//
// MulOp
//===----------------------------------------------------------------------===//

void MulOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                  mlir::Value lhs, mlir::Value rhs) {
  state.addTypes(UnrankedTensorType::get(builder.getF64Type()));
  state.addOperands({lhs, rhs});
}

mlir::ParseResult MulOp::parse(mlir::OpAsmParser &parser,
                               mlir::OperationState &result) {
  return parseBinaryOp(parser, result);
}

void MulOp::print(mlir::OpAsmPrinter &p) { printBinaryOp(p, *this); }

/// Infer the output shape of the MulOp, this is required by the shape inference
/// interface.
void MulOp::inferShapes() {
  // NOTE: Both RHS and LHS should have the same types, hence it doesn't matter which type we'll get
  assert(getRhs().getType() == getLhs().getType());
  getResult().setType(getRhs().getType());
}

//===----------------------------------------------------------------------===//
// ReturnOp
//===----------------------------------------------------------------------===//

mlir::LogicalResult ReturnOp::verify() {
  // We know that the parent operation is a function, because of the 'HasParent'
  // trait attached to the operation definition.
  auto function = cast<FuncOp>((*this)->getParentOp());

  /// ReturnOps can only have a single optional operand.
  if (getNumOperands() > 1)
    return emitOpError() << "expects at most 1 return operand";

  // The operand number and types must match the function signature.
  const auto &results = function.getFunctionType().getResults();
  if (getNumOperands() != results.size())
    return emitOpError() << "does not return the same number of values ("
                         << getNumOperands() << ") as the enclosing function ("
                         << results.size() << ")";

  // If the operation does not have an input, we are done.
  if (!hasOperand())
    return mlir::success();

  auto inputType = *operand_type_begin();
  auto resultType = results.front();

  // Check that the result type of the function matches the operand type.
  if (inputType == resultType || llvm::isa<mlir::UnrankedTensorType>(inputType) ||
      llvm::isa<mlir::UnrankedTensorType>(resultType))
    return mlir::success();

  return emitError() << "type of return operand (" << inputType
                     << ") doesn't match function result type (" << resultType
                     << ")";
}

//===----------------------------------------------------------------------===//
// TransposeOp
//===----------------------------------------------------------------------===//

void TransposeOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                        mlir::Value value) {
  state.addTypes(UnrankedTensorType::get(builder.getF64Type()));
  state.addOperands(value);
}

mlir::LogicalResult TransposeOp::verify() {
  auto inputType = llvm::dyn_cast<RankedTensorType>(getOperand().getType());
  auto resultType = llvm::dyn_cast<RankedTensorType>(getType());
  if (!inputType || !resultType)
    return mlir::success();

  auto inputShape = inputType.getShape();
  if (!std::equal(inputShape.begin(), inputShape.end(),
                  resultType.getShape().rbegin())) {
    return emitError()
           << "expected result shape to be a transpose of the input";
  }
  return mlir::success();
}

/// Infer the output shape of the TransposeOp, this is required by the shape
/// inference interface.
void TransposeOp::inferShapes() {
  auto arrayTy = llvm::cast<RankedTensorType>(getInp().getType());
  if (arrayTy.getShape().size() != 2) {
    emitError() << "Infering shapes of transpose of tensor rank " << arrayTy.getShape().size() << " not implemented!";
  }
  SmallVector<int64_t, 2> dims = {arrayTy.getShape()[1], arrayTy.getShape()[0]};
  getResult().setType(RankedTensorType::get(dims, arrayTy.getElementType()));
}

//===----------------------------------------------------------------------===//
// TableGen'd op method definitions
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "toy/Ops.cpp.inc"
