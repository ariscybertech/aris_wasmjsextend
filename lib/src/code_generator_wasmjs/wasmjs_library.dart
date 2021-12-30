import 'package:ffigen/src/code_generator/binding.dart';
import 'package:ffigen/src/code_generator/library.dart';
import 'package:ffigen/src/config_provider/config_types.dart';

import 'wasmjs_writer.dart';

class WasmJsLibrary extends Library {
  late WasmJsWriter _writer;

  @override
  WasmJsWriter get writer => _writer;

  WasmJsLibrary({
    required String name,
    String? description,
    required List<Binding> bindings,
    String? header,
    bool dartBool = true,
    bool sort = false,
    StructPackingOverride? packingOverride,
  }) : super(
            name: name,
            description: description,
            bindings: bindings,
            header: header,
            dartBool: dartBool,
            sort: sort,
            packingOverride: packingOverride) {
    // Separate bindings which require lookup.
    final lookUpBindings = this.bindings.whereType<LookUpBinding>().toList();
    final noLookUpBindings =
        this.bindings.whereType<NoLookUpBinding>().toList();

    _writer = WasmJsWriter(
      lookUpBindings: lookUpBindings,
      noLookUpBindings: noLookUpBindings,
      className: name,
      classDocComment: description,
      header: header,
      dartBool: dartBool,
    );
  }
}
