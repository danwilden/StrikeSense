import 'dart:convert';

import 'preset_category.dart';
import 'timer_config.dart';

/// Data model for timer presets
class TimerPreset {
  final String id;
  final String name;
  final String description;
  final PresetCategory category;
  final TimerConfig timerConfig;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final bool isDefault;

  const TimerPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.timerConfig,
    required this.createdAt,
    this.lastUsed,
    this.isDefault = false,
  });

  /// Create a copy of this preset with updated fields
  TimerPreset copyWith({
    String? id,
    String? name,
    String? description,
    PresetCategory? category,
    TimerConfig? timerConfig,
    DateTime? createdAt,
    DateTime? lastUsed,
    bool? isDefault,
  }) {
    return TimerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      timerConfig: timerConfig ?? this.timerConfig,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Mark this preset as used (updates lastUsed timestamp)
  TimerPreset markAsUsed() {
    return copyWith(lastUsed: DateTime.now());
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'timerConfig': timerConfig.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  /// Create from JSON
  factory TimerPreset.fromJson(Map<String, dynamic> json) {
    return TimerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: PresetCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PresetCategory.custom,
      ),
      timerConfig: TimerConfig.fromJson(
        json['timerConfig'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory TimerPreset.fromJsonString(String jsonString) {
    return TimerPreset.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Validate the preset configuration
  bool isValid() {
    try {
      // Check basic fields
      if (id.isEmpty || name.isEmpty) return false;

      // Validate timer config
      if (!timerConfig.isValid()) return false;

      // Check category
      if (!PresetCategory.values.contains(category)) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get validation errors
  List<String> getValidationErrors() {
    final errors = <String>[];

    if (id.isEmpty) errors.add('ID cannot be empty');
    if (name.isEmpty) errors.add('Name cannot be empty');
    if (description.isEmpty) errors.add('Description cannot be empty');

    // Validate timer config
    final configErrors = timerConfig.getValidationErrors();
    errors.addAll(configErrors);

    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerPreset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TimerPreset(id: $id, name: $name, category: $category)';
  }
}
