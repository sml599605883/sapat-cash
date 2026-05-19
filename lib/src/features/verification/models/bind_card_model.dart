import '../../../core/json/json.dart';
import 'personal_information_model.dart';

class BindCardModel {
  const BindCardModel({
    required this.sections,
    required this.hint,
    required this.bottomHint,
  });

  factory BindCardModel.fromJson(dynamic raw) {
    final json = raw is Json ? raw : Json(raw);
    final rawSections = json['fretsome'].listValue;
    final sections = rawSections
        .asMap()
        .entries
        .map((entry) => BindCardSection.fromJson(entry.value, entry.key))
        .toList(growable: false);
    return BindCardModel(
      sections: sections,
      hint: json['perfectionisms'].stringOrNull?.trim() ?? '',
      bottomHint: json['trainability'].stringOrNull?.trim() ?? '',
    );
  }

  final List<BindCardSection> sections;
  final String hint;
  final String bottomHint;
}

class BindCardSection {
  const BindCardSection({
    required this.title,
    required this.typeValue,
    required this.fields,
  });

  factory BindCardSection.fromJson(dynamic raw, int sectionIndex) {
    final json = raw is Json ? raw : Json(raw);
    final rawFields = json['fretsome'].listValue;
    final fields = rawFields
        .asMap()
        .entries
        .map(
          (entry) => _bindFieldFromJson(
            entry.value,
            sectionIndex: sectionIndex,
            fieldIndex: entry.key,
          ),
        )
        .toList(growable: false);
    return BindCardSection(
      title: json['interdiffusions'].stringOrNull?.trim() ?? '',
      typeValue: json['refortification'].stringOrNull?.trim() ?? '',
      fields: fields,
    );
  }

  final String title;
  final String typeValue;
  final List<PersonalInformationField> fields;
}

PersonalInformationField _bindFieldFromJson(
  dynamic raw, {
  required int sectionIndex,
  required int fieldIndex,
}) {
  final json = raw is Json ? raw : Json(raw);
  return PersonalInformationField(
    id: ((sectionIndex + 1) * 1000) + fieldIndex + 1,
    title: json['interdiffusions'].stringOrNull?.trim() ?? '',
    placeholder: json['equilibration'].stringOrNull?.trim() ?? '',
    keyName: json['alligators'].stringOrNull?.trim() ?? '',
    inputType: json['puritan'].stringOrNull?.trim() ?? '',
    isNumberKeyboard: json['flagellum'].intOrNull == 1,
    options: json['temporalize'].listValue
        .map((item) => PersonalInformationOption.fromJson(item))
        .toList(growable: false),
    isOptional: json['literalnesses'].intOrNull == 1,
    isCertified: json['subversions'].intOrNull == 1,
    certifiedText: json['kowtowing'].stringOrNull?.trim() ?? '',
    isDisabled: json['intellections'].intOrNull == 1,
    value: json['naturalization'].stringOrNull?.trim() ?? '',
    chemical: json['chemical'].intOrNull ?? 0,
    borderlands: json['borderlands'].stringOrNull?.trim() ?? '',
  );
}
