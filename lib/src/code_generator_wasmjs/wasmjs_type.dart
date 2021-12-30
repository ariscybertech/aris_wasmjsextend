import 'package:ffigen/src/code_generator/binding.dart';
import 'package:ffigen/src/code_generator/func.dart';
import 'package:ffigen/src/code_generator/type.dart';
import 'package:ffigen/src/code_generator/writer.dart';

import 'wasmjs_writer.dart';

bool isJsBigInt(SupportedNativeType nativeType) {
  switch (nativeType) {
    case SupportedNativeType.Int64:
    case SupportedNativeType.Uint64:
      return true;
    default:
      return false;
  }
}

extension WasmJsType on Type {
  String getWasmJsDartType(Writer w) {
    switch (broadType) {
      case BroadType.NativeType:
        return getDartType(w);
      case BroadType.Pointer:
        return 'Pointer<${child!.getWasmJsCType(w)}>';
      case BroadType.Compound:
      case BroadType.Enum:
      case BroadType.NativeFunction:
      case BroadType.IncompleteArray:
      case BroadType.ConstantArray:
      case BroadType.Boolean:
      case BroadType.Handle:
      case BroadType.FunctionType:
      case BroadType.Typealias:
      case BroadType.Unimplemented:
        return getDartType(w);
    }
  }

  String getWasmJsLookupDartType(WasmJsWriter w) {
    switch (broadType) {
      case BroadType.NativeType:
        return isJsBigInt(nativeType!) ? w.jsBigInt : getDartType(w);
      case BroadType.Pointer:
        return Type.nativeType(SupportedNativeType.Int32).getDartType(w);
      case BroadType.Compound:
      case BroadType.Enum:
      case BroadType.NativeFunction:
      case BroadType.IncompleteArray:
      case BroadType.ConstantArray:
      case BroadType.Boolean:
      case BroadType.Handle:
      case BroadType.FunctionType:
      case BroadType.Typealias:
      case BroadType.Unimplemented:
        return getDartType(w);
    }
  }

  String getWasmJsCType(Writer w) {
    switch (broadType) {
      case BroadType.NativeType:
        return Type.primitives[nativeType!]!.c;
      case BroadType.Pointer:
        return 'Pointer<${child!.getWasmJsCType(w)}>';
      case BroadType.Compound:
        return compound!.name;
      case BroadType.Enum:
        return Type.primitives[Type.enumNativeType]!.c;
      case BroadType.NativeFunction:
        return 'NativeFunction<${nativeFunc!.type.getWasmJsCType(w)}>';
      case BroadType
          .IncompleteArray: // Array parameters are treated as Pointers in C.
        return 'Pointer<${child!.getWasmJsCType(w)}>';
      case BroadType
          .ConstantArray: // Array parameters are treated as Pointers in C.
        return 'Pointer<${child!.getWasmJsCType(w)}>';
      case BroadType.Boolean: // Booleans are treated as uint8.
        return Type.primitives[SupportedNativeType.Uint8]!.c;
      case BroadType.Handle:
        return 'Handle';
      case BroadType.FunctionType:
        // TODO(thlorenz): override this?
        return functionType!.getCType(w);
      case BroadType.Typealias:
        return typealias!.name;
      case BroadType.Unimplemented:
        throw UnimplementedError('C type unknown for ${broadType.toString()}');
    }
  }

  String getWasmJsParameterResolution(Writer w) {
    switch (broadType) {
      case BroadType.Pointer:
        return '.address';
      case BroadType.NativeType:
        return isJsBigInt(nativeType!) ? '.toString()' : '';
      case BroadType.Compound:
      case BroadType.Enum:
      case BroadType.NativeFunction:
      case BroadType.IncompleteArray:
      case BroadType.ConstantArray:
        return '';
      case BroadType.Boolean:
        return w.dartBool ? '? 1 : 0' : '';
      case BroadType.Handle:
      case BroadType.FunctionType:
      case BroadType.Typealias:
      case BroadType.Unimplemented:
        return '';
    }
  }

  String getWasmJsReturnWrapOpen(WasmJsWriter w) {
    switch (broadType) {
      case BroadType.Pointer:
        return 'Pointer.fromAddress(${child!.getWasmJsCType(w)}(';
      case BroadType.NativeType:
        return isJsBigInt(nativeType!) ? '${w.jsBigIntToInt}(' : '';
      case BroadType.Compound:
      case BroadType.Enum:
      case BroadType.NativeFunction:
      case BroadType.IncompleteArray:
      case BroadType.ConstantArray:
      case BroadType.Boolean:
      case BroadType.Handle:
      case BroadType.FunctionType:
      case BroadType.Typealias:
      case BroadType.Unimplemented:
        return '';
    }
  }

  String getWasmJsReturnWrapClose(Writer w) {
    switch (broadType) {
      case BroadType.Pointer:
        return '),),';
      case BroadType.NativeType:
        return isJsBigInt(nativeType!) ? '),' : '';
      case BroadType.Compound:
      case BroadType.Enum:
      case BroadType.NativeFunction:
      case BroadType.IncompleteArray:
      case BroadType.ConstantArray:
        return '';
      case BroadType.Boolean:
        return w.dartBool ? ' != 0' : '';
      case BroadType.Handle:
      case BroadType.FunctionType:
      case BroadType.Typealias:
      case BroadType.Unimplemented:
        return '';
    }
  }
}

class WasmJsFunctionType {
  final Type returnType;
  final List<Parameter> parameters;

  WasmJsFunctionType({
    required this.returnType,
    required this.parameters,
  });

  String getDartType(WasmJsWriter w, {bool writeArgumentNames = true}) {
    final sb = StringBuffer();

    // Write return Type.
    sb.write(returnType.getDartType(w));

    // Write Function.
    sb.write(' Function(');
    sb.write(parameters.map<String>((p) {
      return '${p.type.getWasmJsDartType(w)} ${writeArgumentNames ? p.name : ""}';
    }).join(', '));
    sb.write(')');

    return sb.toString();
  }

  void addDependencies(Set<Binding> dependencies) {
    // TODO(thlorenz): causes structs we added as WasmJsStruct to be added again as Struc
    // returnType.addDependencies(dependencies);
    // for (final p in parameters) {
    //   p.type.addDependencies(dependencies);
    // }
  }
}
