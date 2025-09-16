import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/preset_category.dart';
import '../models/timer_config.dart';
import '../models/timer_mode.dart';
import '../models/timer_preset.dart';

/// Service for managing timer preset storage
class PresetStorageService {
  static final PresetStorageService _instance =
      PresetStorageService._internal();
  factory PresetStorageService() => _instance;
  PresetStorageService._internal();

  static const String _presetsKey = 'timer_presets';

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _createDefaultPresetsIfNeeded();
  }

  /// Get all presets
  Future<List<TimerPreset>> getAllPresets() async {
    await _ensureInitialized();

    final presetsJson = _prefs!.getStringList(_presetsKey) ?? [];
    final presets = <TimerPreset>[];

    for (final jsonString in presetsJson) {
      try {
        final preset = TimerPreset.fromJsonString(jsonString);
        if (preset.isValid()) {
          presets.add(preset);
        }
      } catch (e) {
        print('Error loading preset: $e');
      }
    }

    return presets;
  }

  /// Get presets by category
  Future<List<TimerPreset>> getPresetsByCategory(
    PresetCategory category,
  ) async {
    final allPresets = await getAllPresets();
    return allPresets.where((preset) => preset.category == category).toList();
  }

  /// Get recently used presets
  Future<List<TimerPreset>> getRecentlyUsedPresets({int limit = 5}) async {
    final allPresets = await getAllPresets();
    final recentlyUsed =
        allPresets.where((preset) => preset.lastUsed != null).toList()
          ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));

    return recentlyUsed.take(limit).toList();
  }

  /// Get a specific preset by ID
  Future<TimerPreset?> getPresetById(String id) async {
    final allPresets = await getAllPresets();
    try {
      return allPresets.firstWhere((preset) => preset.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save a preset
  Future<bool> savePreset(TimerPreset preset) async {
    await _ensureInitialized();

    if (!preset.isValid()) {
      print('Cannot save invalid preset: ${preset.getValidationErrors()}');
      return false;
    }

    try {
      final allPresets = await getAllPresets();

      // Remove existing preset with same ID
      allPresets.removeWhere((p) => p.id == preset.id);

      // Add the new preset
      allPresets.add(preset);

      // Save to storage
      final presetsJson = allPresets.map((p) => p.toJsonString()).toList();
      return await _prefs!.setStringList(_presetsKey, presetsJson);
    } catch (e) {
      print('Error saving preset: $e');
      return false;
    }
  }

  /// Delete a preset
  Future<bool> deletePreset(String id) async {
    await _ensureInitialized();

    try {
      final allPresets = await getAllPresets();
      allPresets.removeWhere((preset) => preset.id == id);

      final presetsJson = allPresets.map((p) => p.toJsonString()).toList();
      return await _prefs!.setStringList(_presetsKey, presetsJson);
    } catch (e) {
      print('Error deleting preset: $e');
      return false;
    }
  }

  /// Mark a preset as used
  Future<bool> markPresetAsUsed(String id) async {
    final preset = await getPresetById(id);
    if (preset == null) return false;

    final updatedPreset = preset.markAsUsed();
    return await savePreset(updatedPreset);
  }

  /// Create default presets if they don't exist
  Future<void> _createDefaultPresetsIfNeeded() async {
    final existingPresets = await getAllPresets();
    if (existingPresets.isNotEmpty) return;

    final defaultPresets = _createDefaultPresets();

    for (final preset in defaultPresets) {
      await savePreset(preset);
    }

    print('Created ${defaultPresets.length} default presets');
  }

  /// Create default presets
  List<TimerPreset> _createDefaultPresets() {
    final now = DateTime.now();

    return [
      // Beginner presets
      TimerPreset(
        id: 'beginner_short',
        name: 'Short Rounds',
        description: 'Quick 30-second rounds for beginners',
        category: PresetCategory.beginner,
        timerConfig: TimerConfig(
          mode: TimerMode.round,
          workDuration: const Duration(seconds: 30),
          restDuration: const Duration(seconds: 30),
          rounds: 3,
          warningDuration: const Duration(seconds: 5),
        ),
        createdAt: now,
        isDefault: true,
      ),

      TimerPreset(
        id: 'beginner_medium',
        name: 'Medium Rounds',
        description: '45-second work periods for building endurance',
        category: PresetCategory.beginner,
        timerConfig: TimerConfig(
          mode: TimerMode.round,
          workDuration: const Duration(seconds: 45),
          restDuration: const Duration(seconds: 30),
          rounds: 4,
          warningDuration: const Duration(seconds: 5),
        ),
        createdAt: now,
        isDefault: true,
      ),

      // Intermediate presets
      TimerPreset(
        id: 'intermediate_standard',
        name: 'Standard Training',
        description: 'Classic 45s work, 15s rest intervals',
        category: PresetCategory.intermediate,
        timerConfig: TimerConfig(
          mode: TimerMode.round,
          workDuration: const Duration(seconds: 45),
          restDuration: const Duration(seconds: 15),
          rounds: 5,
          warningDuration: const Duration(seconds: 10),
        ),
        createdAt: now,
        isDefault: true,
      ),

      TimerPreset(
        id: 'intermediate_hiit',
        name: 'HIIT Training',
        description: 'High-intensity interval training',
        category: PresetCategory.intermediate,
        timerConfig: TimerConfig(
          mode: TimerMode.interval,
          workDuration: const Duration(seconds: 30),
          restDuration: const Duration(seconds: 10),
          rounds: 8,
          warningDuration: const Duration(seconds: 5),
        ),
        createdAt: now,
        isDefault: true,
      ),

      // Advanced presets
      TimerPreset(
        id: 'advanced_long',
        name: 'Long Rounds',
        description: 'Challenging 60-second work periods',
        category: PresetCategory.advanced,
        timerConfig: TimerConfig(
          mode: TimerMode.round,
          workDuration: const Duration(minutes: 1),
          restDuration: const Duration(seconds: 30),
          rounds: 8,
          warningDuration: const Duration(seconds: 10),
        ),
        createdAt: now,
        isDefault: true,
      ),

      TimerPreset(
        id: 'advanced_tabata',
        name: 'Tabata Protocol',
        description: 'Classic Tabata: 20s work, 10s rest',
        category: PresetCategory.advanced,
        timerConfig: TimerConfig(
          mode: TimerMode.tabata,
          workDuration: const Duration(seconds: 20),
          restDuration: const Duration(seconds: 10),
          rounds: 8,
          warningDuration: const Duration(seconds: 3),
        ),
        createdAt: now,
        isDefault: true,
      ),

      TimerPreset(
        id: 'advanced_marathon',
        name: 'Marathon Training',
        description: 'Extended 2-minute work periods',
        category: PresetCategory.advanced,
        timerConfig: TimerConfig(
          mode: TimerMode.round,
          workDuration: const Duration(minutes: 2),
          restDuration: const Duration(minutes: 1),
          rounds: 5,
          warningDuration: const Duration(seconds: 15),
        ),
        createdAt: now,
        isDefault: true,
      ),
    ];
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  /// Clear all presets (for testing)
  Future<bool> clearAllPresets() async {
    await _ensureInitialized();
    return await _prefs!.remove(_presetsKey);
  }

  /// Export presets as JSON string
  Future<String> exportPresets() async {
    final presets = await getAllPresets();
    final presetsJson = presets.map((p) => p.toJson()).toList();
    return jsonEncode(presetsJson);
  }

  /// Import presets from JSON string
  Future<bool> importPresets(String jsonString) async {
    try {
      final List<dynamic> presetsJson = jsonDecode(jsonString);
      final presets = presetsJson
          .map((json) => TimerPreset.fromJson(json as Map<String, dynamic>))
          .where((preset) => preset.isValid())
          .toList();

      for (final preset in presets) {
        await savePreset(preset);
      }

      return true;
    } catch (e) {
      print('Error importing presets: $e');
      return false;
    }
  }
}
