import 'package:ffigen/src/code_generator.dart';
import 'package:ffigen/src/code_generator/binding_string.dart';
import 'package:ffigen/src/code_generator/writer.dart';

class WasmJsStruc extends Compound {
  WasmJsStruc(Struc struc)
      : super(
          usr: struc.usr,
          originalName: struc.originalName,
          name: struc.name,
          dartDoc: struc.dartDoc,
          isInComplete: struc.isInComplete,
          members: struc.members,
          pack: struc.pack,
          compoundType: struc.compoundType,
        ) {
    assert(isOpaque, 'wasmjs bindings only opaque structs at this point');
  }

  @override
  void addDependencies(Set<Binding> dependencies) {
    if (dependencies.contains(this)) return;
    dependencies.add(this);
  }

  @override
  BindingString toBindingString(Writer w) {
    final s = StringBuffer();
    final enclosingClassName = name;

    s.writeln('class $enclosingClassName extends Opaque {');
    s.writeln('  $enclosingClassName(int address) : super(address);');
    s.writeln('}');

    return BindingString(type: BindingStringType.struc, string: s.toString());
  }
}
