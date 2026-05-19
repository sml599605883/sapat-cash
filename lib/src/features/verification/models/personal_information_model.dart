import '../../../core/json/json.dart';

class PersonalInformationModel {
  const PersonalInformationModel({required this.fields, required this.hint});

  factory PersonalInformationModel.fromJson(dynamic raw) {
    final json = raw is Json ? raw : Json(raw);
    final fields = json['fretsome'].listValue
        .map((item) => PersonalInformationField.fromJson(item))
        .toList(growable: false);
    return PersonalInformationModel(
      fields: fields,
      hint: json['perfectionisms'].stringOrNull?.trim() ?? '',
    );
  }

  final List<PersonalInformationField> fields;
  final String hint;
}

class PersonalInformationField {
  const PersonalInformationField({
    required this.id,
    required this.title,
    required this.placeholder,
    required this.keyName,
    required this.inputType,
    required this.isNumberKeyboard,
    required this.options,
    required this.isOptional,
    required this.isCertified,
    required this.certifiedText,
    required this.isDisabled,
    required this.value,
    required this.chemical,
    required this.borderlands,
  });

  factory PersonalInformationField.fromJson(dynamic raw) {
    final json = raw is Json ? raw : Json(raw);
    return PersonalInformationField(
      id: json['braciole'].intOrNull ?? 0,
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

  final int id;
  final String title;
  final String placeholder;
  final String keyName;
  final String inputType;
  final bool isNumberKeyboard;
  final List<PersonalInformationOption> options;
  final bool isOptional;
  final bool isCertified;
  final String certifiedText;
  final bool isDisabled;
  final String value;
  final int chemical;
  final String borderlands;

  bool get isSelectField => inputType == 'Phosphene';

  bool get isInputField => inputType == 'EstreatingAbuzz';

  bool get isAddressField => inputType == 'UncannyDovekies';
}

class PersonalInformationOption {
  const PersonalInformationOption({
    required this.label,
    required this.value,
    required this.logo,
    required this.status,
    required this.text,
    required this.options,
  });

  factory PersonalInformationOption.fromJson(dynamic raw) {
    final json = raw is Json ? raw : Json(raw);
    return PersonalInformationOption(
      label: json['fornices'].stringOrNull?.trim() ?? '',
      value: json['refortification'].stringOrNull?.trim() ?? '',
      logo: json['dragomen'].stringOrNull?.trim() ?? '',
      status: json['subversions'].stringOrNull?.trim() ?? '',
      text: json['subconsciously'].stringOrNull?.trim() ?? '',
      options: json['temporalize'].listValue
          .map((item) => PersonalInformationOption.fromJson(item))
          .toList(growable: false),
    );
  }

  final String label;
  final String value;
  final String logo; // dragomen
  final String status; // subversions
  final String text; // subconsciously
  final List<PersonalInformationOption> options;
}
