import 'package:ffigen/src/code_generator.dart';
import 'package:ffigen/src/code_generator/binding_string.dart';
import 'package:ffigen/src/code_generator/utils.dart';
import 'package:ffigen/src/code_generator/writer.dart';

import 'wasmjs_type.dart';
import 'wasmjs_writer.dart';

class WasmJsFunc extends LookUpBinding {
  final Func _func;

  late final WasmJsFunctionType functionType;
  bool get exposeSymbolAddress => _func.exposeSymbolAddress;
  bool get exposeFunctionTypedefs => _func.exposeFunctionTypedefs;

  WasmJsFunc(this._func)
      : super(
            usr: _func.usr,
            originalName: _func.originalName,
            name: _func.name,
            dartDoc: _func.dartDoc) {
    functionType = WasmJsFunctionType(
        returnType: _func.functionType.returnType,
        parameters: _func.functionType.parameters);
  }

  @override
  void addDependencies(Set<Binding> dependencies) {
    if (dependencies.contains(this)) return;

    dependencies.add(this);
    functionType.addDependencies(dependencies);
    if (exposeFunctionTypedefs) {
      _func.exposedCFunctionTypealias!.addDependencies(dependencies);
      _func.exposedDartFunctionTypealias!.addDependencies(dependencies);
    }
  }

  @override
  // ignore: avoid_renaming_method_parameters
  BindingString toBindingString(Writer writer) {
    assert(
      writer is WasmJsWriter,
      'WasmJsFunc should only be used with WasmJsWriter',
    );

    final w = writer as WasmJsWriter;
    final s = StringBuffer();
    final enclosingFuncName = name;
    final funcVarName = w.wrapperLevelUniqueNamer.makeUnique('_$name');

    if (dartDoc != null) {
      s.write(makeDartDoc(dartDoc!));
    }
    // Resolve name conflicts in function parameter names.
    final paramNamer = UniqueNamer({});
    for (final p in functionType.parameters) {
      p.name = paramNamer.makeUnique(p.name);
    }

    // -----------------
    // Enclosing Function
    // -----------------

    final returnType = (w.dartBool &&
            functionType.returnType.getBaseTypealiasType().broadType ==
                BroadType.Boolean)
        ? 'bool'
        : functionType.returnType.getWasmJsDartType(w);
    s.write('$returnType $enclosingFuncName(\n');

    // Input params
    for (final p in functionType.parameters) {
      if (w.dartBool &&
          p.type.getBaseTypealiasType().broadType == BroadType.Boolean) {
        // Use bool parameter type in enclosing function.
        s.write('  bool ${p.name},\n');
      } else {
        s.write('  ${p.type.getWasmJsDartType(w)} ${p.name},\n');
      }
    }

    // Function body
    final returnOpen = functionType.returnType.getWasmJsReturnWrapOpen(w);
    final returnClose = functionType.returnType.getWasmJsReturnWrapClose(w);
    s.write(') {\n');

    s.write('return $returnOpen$funcVarName');

    s.write('(\n');
    for (final p in functionType.parameters) {
      final resolution = p.type.getWasmJsParameterResolution(w);
      s.write('    ${p.name}$resolution,\n');
    }
    s.write('$returnClose);\n');
    s.write('}\n');

    // -----------------
    // Enclosed Function
    // -----------------
    s.write(
        'late final ${functionType.returnType.getWasmJsLookupDartType(w)} Function(');
    for (final p in functionType.parameters) {
      s.write('${p.type.getWasmJsLookupDartType(w)},\n');
    }
    s.write(") $funcVarName = _lookup('$enclosingFuncName');\n");

    return BindingString(type: BindingStringType.func, string: s.toString());
  }
}
