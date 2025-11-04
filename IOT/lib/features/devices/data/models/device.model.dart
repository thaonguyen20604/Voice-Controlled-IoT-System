import 'package:home_automation_app/helpers/enums.dart';

class DeviceModel {
  final String id;
  final FlickyAnimatedIconOptions iconOption;
  final String label;
  bool isSelected;

   DeviceModel({
    required this.id,
    required this.iconOption,
    required this.label,
    required this.isSelected,
  });

  DeviceModel copyWith({
    FlickyAnimatedIconOptions? iconOption,
    String? label,
    bool? isSelected,
    int? outlet,
  }) {
    return DeviceModel(
      iconOption: iconOption ?? this.iconOption,
      label: label ?? this.label,
      isSelected: isSelected ?? this.isSelected,
      id: id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'iconOption': iconOption.name,
      'isSelected': isSelected,
      'id': id,
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      iconOption: FlickyAnimatedIconOptions.values
          .firstWhere((o) => o.name == json['iconOption']),
      label: json['label'],
      isSelected: json['isSelected'],
      id: json['id'],
    );
  }
}
