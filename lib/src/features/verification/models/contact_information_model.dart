import '../../../core/json/json.dart';
import 'personal_information_model.dart';

class ContactInformationModel {
  const ContactInformationModel({required this.groups, required this.hint});

  ContactInformationModel copyWith({
    List<ContactInformationGroup>? groups,
    String? hint,
  }) {
    return ContactInformationModel(
      groups: groups ?? this.groups,
      hint: hint ?? this.hint,
    );
  }

  factory ContactInformationModel.fromJson(dynamic raw) {
    final json = raw is Json ? raw : Json(raw);
    final rawGroups = json['rheumatologist']['noniron'].listValue;
    if (rawGroups.isNotEmpty) {
      final groups = rawGroups
          .asMap()
          .entries
          .map(
            (entry) => ContactInformationGroup.fromJson(entry.value, entry.key),
          )
          .where((item) => item.hasAnyField)
          .toList(growable: false);
      if (groups.isNotEmpty) {
        return ContactInformationModel(
          groups: groups,
          hint: json['perfectionisms'].stringOrNull?.trim() ?? '',
        );
      }
    }

    final flatFields = json['fretsome'].listValue
        .map((item) => PersonalInformationField.fromJson(item))
        .toList(growable: false);
    return ContactInformationModel(
      groups: _buildGroupsFromFields(flatFields),
      hint: json['perfectionisms'].stringOrNull?.trim() ?? '',
    );
  }

  final List<ContactInformationGroup> groups;
  final String hint;

  static List<ContactInformationGroup> _buildGroupsFromFields(
    List<PersonalInformationField> fields,
  ) {
    if (fields.isEmpty) {
      return const <ContactInformationGroup>[];
    }

    final groups = <ContactInformationGroup>[];
    for (var index = 0; index < fields.length; index += 3) {
      final chunk = fields.skip(index).take(3).toList(growable: false);
      if (chunk.isEmpty) {
        continue;
      }

      PersonalInformationField? relationshipField;
      PersonalInformationField? nameField;
      PersonalInformationField? phoneField;

      for (final field in chunk) {
        if (field.isSelectField && relationshipField == null) {
          relationshipField = field;
          continue;
        }
        if (nameField == null) {
          nameField = field;
          continue;
        }
        phoneField ??= field;
      }

      groups.add(
        ContactInformationGroup(
          index: groups.length + 1,
          title: 'Relationship with Emergency Contacts - ${groups.length + 1}',
          groupKey: '',
          relationshipField: relationshipField,
          nameField: nameField,
          phoneField: phoneField,
        ),
      );
    }
    return groups;
  }
}

class ContactInformationGroup {
  const ContactInformationGroup({
    required this.index,
    required this.title,
    required this.groupKey,
    required this.relationshipField,
    required this.nameField,
    required this.phoneField,
  });

  ContactInformationGroup copyWith({
    int? index,
    String? title,
    String? groupKey,
    PersonalInformationField? relationshipField,
    PersonalInformationField? nameField,
    PersonalInformationField? phoneField,
  }) {
    return ContactInformationGroup(
      index: index ?? this.index,
      title: title ?? this.title,
      groupKey: groupKey ?? this.groupKey,
      relationshipField: relationshipField ?? this.relationshipField,
      nameField: nameField ?? this.nameField,
      phoneField: phoneField ?? this.phoneField,
    );
  }

  factory ContactInformationGroup.fromJson(dynamic raw, int index) {
    final json = raw is Json ? raw : Json(raw);
    final options = json['maintop'].listValue
        .map((item) => PersonalInformationOption.fromJson(item))
        .toList(growable: false);
    final groupIndex = index + 1;
    final groupKey = json['paramagnetisms'].stringOrNull?.trim() ?? '';

    final relationshipField = PersonalInformationField(
      id: groupIndex * 10 + 1,
      title: 'Relationship',
      placeholder: 'Please select',
      keyName: 'criticise',
      inputType: 'Phosphene',
      isNumberKeyboard: false,
      options: options,
      isOptional: false,
      isCertified: false,
      certifiedText: '',
      isDisabled: false,
      value: json['criticise'].stringOrNull?.trim() ?? '',
      chemical: 0,
      borderlands: '',
    );
    final nameField = PersonalInformationField(
      id: groupIndex * 10 + 2,
      title: 'Contact Information',
      placeholder: 'Name',
      keyName: 'fornices',
      inputType: 'EstreatingAbuzz',
      isNumberKeyboard: false,
      options: const <PersonalInformationOption>[],
      isOptional: false,
      isCertified: false,
      certifiedText: '',
      isDisabled: false,
      value: json['fornices'].stringOrNull?.trim() ?? '',
      chemical: 0,
      borderlands: '',
    );
    final phoneField = PersonalInformationField(
      id: groupIndex * 10 + 3,
      title: 'Contact Information',
      placeholder: 'Phone Number',
      keyName: 'robust',
      inputType: 'EstreatingAbuzz',
      isNumberKeyboard: true,
      options: const <PersonalInformationOption>[],
      isOptional: false,
      isCertified: false,
      certifiedText: '',
      isDisabled: false,
      value: json['robust'].stringOrNull?.trim() ?? '',
      chemical: 0,
      borderlands: '',
    );

    return ContactInformationGroup(
      index: groupIndex,
      title: 'Relationship with Emergency Contacts - $groupIndex',
      groupKey: groupKey,
      relationshipField: relationshipField,
      nameField: nameField,
      phoneField: phoneField,
    );
  }

  final int index;
  final String title;
  final String groupKey;
  final PersonalInformationField? relationshipField;
  final PersonalInformationField? nameField;
  final PersonalInformationField? phoneField;

  bool get hasAnyField =>
      relationshipField != null || nameField != null || phoneField != null;
}
