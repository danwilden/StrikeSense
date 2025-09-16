/// Categories for organizing timer presets
enum PresetCategory {
  beginner,
  intermediate,
  advanced,
  custom,
  recentlyUsed;

  /// Display name for the category
  String get displayName {
    switch (this) {
      case PresetCategory.beginner:
        return 'Beginner';
      case PresetCategory.intermediate:
        return 'Intermediate';
      case PresetCategory.advanced:
        return 'Advanced';
      case PresetCategory.custom:
        return 'Custom';
      case PresetCategory.recentlyUsed:
        return 'Recently Used';
    }
  }

  /// Description for the category
  String get description {
    switch (this) {
      case PresetCategory.beginner:
        return 'Easy workouts for beginners';
      case PresetCategory.intermediate:
        return 'Moderate intensity training';
      case PresetCategory.advanced:
        return 'High intensity advanced workouts';
      case PresetCategory.custom:
        return 'Your custom timer configurations';
      case PresetCategory.recentlyUsed:
        return 'Recently used presets';
    }
  }

  /// Icon for the category
  String get iconName {
    switch (this) {
      case PresetCategory.beginner:
        return '🌱';
      case PresetCategory.intermediate:
        return '💪';
      case PresetCategory.advanced:
        return '🔥';
      case PresetCategory.custom:
        return '⚙️';
      case PresetCategory.recentlyUsed:
        return '🕒';
    }
  }

  /// Color for the category
  int get colorValue {
    switch (this) {
      case PresetCategory.beginner:
        return 0xFF4CAF50; // Green
      case PresetCategory.intermediate:
        return 0xFF2196F3; // Blue
      case PresetCategory.advanced:
        return 0xFFFF5722; // Orange
      case PresetCategory.custom:
        return 0xFF9C27B0; // Purple
      case PresetCategory.recentlyUsed:
        return 0xFF607D8B; // Blue Grey
    }
  }
}
