import 'package:freezed/src/templates/concrete_template.dart';
import 'package:freezed/src/templates/parameter_template.dart';
import 'package:meta/meta.dart';

import '../freezed_generator.dart';

class CopyWith {
  CopyWith({
    @required this.clonedClassName,
    @required this.genericsDefinition,
    @required this.genericsParameter,
    @required this.allProperties,
    @required this.cloneableProperties,
    this.parent,
  });

  static String interfaceNameFrom(String name) {
    if (name.startsWith('_')) {
      return '_\$${name.substring(1)}CopyWith';
    }
    return '\$${name}CopyWith';
  }

  final String clonedClassName;
  final GenericsDefinitionTemplate genericsDefinition;
  final GenericsParameterTemplate genericsParameter;
  final List<Property> allProperties;
  final List<CloneableProperty> cloneableProperties;
  final CopyWith parent;

  String get interface {
    var implements = _hasSuperClass
        ? 'implements ${parent._abstractClassName}${genericsParameter.append('\$Res')}'
        : '';
    return '''
abstract class $_abstractClassName${genericsDefinition.append('\$Res')} $implements {
  factory $_abstractClassName($clonedClassName$genericsParameter value, \$Res Function($clonedClassName$genericsParameter) then) = $_implClassName${genericsParameter.append('\$Res')};
${_copyWithPrototype('call')}

${_abstractDeepCopyMethods().join()}
}''';
  }

  bool get _hasSuperClass {
    return parent != null && parent.allProperties.isNotEmpty;
  }

  String commonContreteImpl(
    List<Getter> commonProperties,
  ) {
    var copyWith = '';

    if (allProperties.isNotEmpty) {
      final prototype = _concreteCopyWithPrototype(
        properties: allProperties,
        methodName: 'call',
      );

      final body = _copyWithMethodBody(
        parametersTemplate: ParametersTemplate(
          [],
          namedParameters: commonProperties.map((e) {
            return Parameter(
              decorators: e.decorators,
              name: e.name,
              showDefaultValue: false,
              isRequired: false,
              defaultValueSource: '',
              nullable: e.nullable,
              type: e.type,
            );
          }).toList(),
        ),
        returnType: '_value.copyWith',
      );

      copyWith = '@override $prototype $body';
    }

    return '''
class $_implClassName${genericsDefinition.append('\$Res')} implements $_abstractClassName${genericsParameter.append('\$Res')} {
  $_implClassName(this._value, this._then);

  final $clonedClassName$genericsParameter _value;
  // ignore: unused_field
  final \$Res Function($clonedClassName$genericsParameter) _then;

$copyWith
${_deepCopyMethods().join()}
}
''';
  }

  Iterable<String> _abstractDeepCopyMethods() sync* {
    for (final cloneableProperty in cloneableProperties) {
      var leading = '';
      if (_hasSuperClass &&
          parent.cloneableProperties
              .any((c) => c.name == cloneableProperty.name)) {
        leading = '@override ';
      }

      yield '$leading${_clonerInterfaceFor(cloneableProperty)} get ${cloneableProperty.name};';
    }
  }

  String _copyWithPrototype(String methodName) {
    if (allProperties.isEmpty) return '';

    return _copyWithProtypeFor(
      methodName: methodName,
      properties: allProperties,
    );
  }

  String _copyWithProtypeFor({
    @required String methodName,
    @required List<Property> properties,
  }) {
    final parameters = properties.map((p) {
      return '${p.decorators.join()} ${p.type} ${p.name}';
    }).join(',');

    return _maybeOverride('''
\$Res $methodName({
$parameters
});
''');
  }

  String get abstractCopyWithGetter {
    if (allProperties.isEmpty) return '';
    return _maybeOverride(
      '$_abstractClassName${genericsParameter.append('$clonedClassName$genericsParameter')} get copyWith;',
    );
  }

  String get concreteCopyWithGetter {
    if (allProperties.isEmpty) return '';
    return '''
@override
$_abstractClassName${genericsParameter.append('$clonedClassName$genericsParameter')} get copyWith => $_implClassName${genericsParameter.append('$clonedClassName$genericsParameter')}(this, _\$identity);
''';
  }

  String _copyWithMethod(ParametersTemplate parametersTemplate) {
    if (allProperties.isEmpty) return '';

    final prototype = _concreteCopyWithPrototype(
      properties: allProperties,
      methodName: 'call',
    );

    final body = _copyWithMethodBody(
      parametersTemplate: parametersTemplate,
      returnType: '$clonedClassName$genericsParameter',
    );

    return '@override $prototype $body';
  }

  String _copyWithMethodBody({
    String accessor = '_value',
    @required ParametersTemplate parametersTemplate,
    @required String returnType,
  }) {
    String parameterToValue(Parameter p) {
      var ternary = '${p.name} == freezed ? $accessor.${p.name} : ${p.name}';
      if (p.type != 'Object' && p.type != null) {
        ternary = '$ternary as ${p.type}';
      }
      return '$ternary,';
    }

    final constructorParameters = StringBuffer()
      ..writeAll(
        [
          ...parametersTemplate.requiredPositionalParameters,
          ...parametersTemplate.optionalPositionalParameters,
        ].map<String>(parameterToValue),
      )
      ..writeAll(
        parametersTemplate.namedParameters.map<String>(
          (p) {
            return '${p.name}: ${parameterToValue(p)}';
          },
        ),
      );

    return '''{
  return _then($returnType(
$constructorParameters
  ));
}''';
  }

  String _concreteCopyWithPrototype({
    @required List<Property> properties,
    @required String methodName,
  }) {
    final parameters = properties.map((p) {
      return 'Object ${p.name} = freezed,';
    }).join();

    return '\$Res $methodName({$parameters})';
  }

  String get _implClassName => '_${_abstractClassName}Impl';

  /// The implementation of the callable class that contains both the copyWith
  /// and the cloneable properties.
  String concreteImpl(ParametersTemplate parametersTemplate) {
    return '''
class $_implClassName${genericsDefinition.append('\$Res')} extends ${parent._implClassName}${genericsParameter.append('\$Res')} implements $_abstractClassName${genericsParameter.append('\$Res')} {
  $_implClassName($clonedClassName$genericsParameter _value, \$Res Function($clonedClassName$genericsParameter) _then)
      : super(_value, (v) => _then(v as $clonedClassName$genericsParameter));

@override
$clonedClassName$genericsParameter get _value => super._value as $clonedClassName$genericsParameter;

${_copyWithMethod(parametersTemplate)}

${_deepCopyMethods().join()}
}''';
  }

  Iterable<String> _deepCopyMethods() sync* {
    final toGenerateProperties = parent == null
        ? cloneableProperties
        : cloneableProperties.where((property) {
            return !parent.cloneableProperties
                .any((p) => p.name == property.name);
          });

    for (final cloneableProperty in toGenerateProperties) {
      yield '''
@override
${_clonerInterfaceFor(cloneableProperty)} get ${cloneableProperty.name} {
  if (_value.${cloneableProperty.name} == null) {
    return null;
  }
  return ${_clonerInterfaceFor(cloneableProperty)}(_value.${cloneableProperty.name}, (value) {
    return _then(_value.copyWith(${cloneableProperty.name}:  value));
  });
}''';
    }
  }

  String _clonerInterfaceFor(CloneableProperty cloneableProperty) {
    final name = interfaceNameFrom(cloneableProperty.associatedData.name);
    return '$name${cloneableProperty.genericParameters.append('\$Res')}';
  }

  String _maybeOverride(String res) {
    return _hasSuperClass ? '@override $res' : res;
  }

  String get _abstractClassName => interfaceNameFrom(clonedClassName);
}
