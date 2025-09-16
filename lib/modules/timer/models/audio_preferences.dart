import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_manager.dart';

/// Audio preferences and settings for the timer
class AudioPreferences {
  final double masterVolume;
  final bool isMuted;
  final bool allowBackgroundAudio;
  final bool enableMusicMixing;
  final bool enableAudioDucking;
  final Map<AudioCueType, bool> cueEnabledStates;
  final Map<AudioCueType, double> cueVolumes;

  const AudioPreferences({
    this.masterVolume = 1.0,
    this.isMuted = false,
    this.allowBackgroundAudio = true,
    this.enableMusicMixing = true,
    this.enableAudioDucking = true,
    this.cueEnabledStates = const {},
    this.cueVolumes = const {},
  });

  /// Create a copy with updated values
  AudioPreferences copyWith({
    double? masterVolume,
    bool? isMuted,
    bool? allowBackgroundAudio,
    bool? enableMusicMixing,
    bool? enableAudioDucking,
    Map<AudioCueType, bool>? cueEnabledStates,
    Map<AudioCueType, double>? cueVolumes,
  }) {
    return AudioPreferences(
      masterVolume: masterVolume ?? this.masterVolume,
      isMuted: isMuted ?? this.isMuted,
      allowBackgroundAudio: allowBackgroundAudio ?? this.allowBackgroundAudio,
      enableMusicMixing: enableMusicMixing ?? this.enableMusicMixing,
      enableAudioDucking: enableAudioDucking ?? this.enableAudioDucking,
      cueEnabledStates: cueEnabledStates ?? this.cueEnabledStates,
      cueVolumes: cueVolumes ?? this.cueVolumes,
    );
  }

  /// Check if a specific audio cue is enabled
  bool isCueEnabled(AudioCueType cueType) {
    return cueEnabledStates[cueType] ?? true; // Default to enabled
  }

  /// Get volume for a specific audio cue
  double getCueVolume(AudioCueType cueType) {
    return cueVolumes[cueType] ?? 1.0; // Default to full volume
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'masterVolume': masterVolume,
      'isMuted': isMuted,
      'allowBackgroundAudio': allowBackgroundAudio,
      'enableMusicMixing': enableMusicMixing,
      'enableAudioDucking': enableAudioDucking,
      'cueEnabledStates': cueEnabledStates.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'cueVolumes': cueVolumes.map((key, value) => MapEntry(key.name, value)),
    };
  }

  /// Create from JSON
  factory AudioPreferences.fromJson(Map<String, dynamic> json) {
    return AudioPreferences(
      masterVolume: (json['masterVolume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
      allowBackgroundAudio: json['allowBackgroundAudio'] as bool? ?? true,
      enableMusicMixing: json['enableMusicMixing'] as bool? ?? true,
      enableAudioDucking: json['enableAudioDucking'] as bool? ?? true,
      cueEnabledStates:
          (json['cueEnabledStates'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              AudioCueType.values.firstWhere((e) => e.name == key),
              value as bool,
            ),
          ) ??
          {},
      cueVolumes:
          (json['cueVolumes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              AudioCueType.values.firstWhere((e) => e.name == key),
              (value as num).toDouble(),
            ),
          ) ??
          {},
    );
  }
}

/// Service for managing audio preferences persistence
class AudioPreferencesService {
  static const String _prefsKey = 'audio_preferences';
  static final AudioPreferencesService _instance =
      AudioPreferencesService._internal();
  factory AudioPreferencesService() => _instance;
  AudioPreferencesService._internal();

  AudioPreferences _preferences = const AudioPreferences();
  SharedPreferences? _prefs;

  /// Initialize the preferences service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
  }

  /// Get current audio preferences
  AudioPreferences get preferences => _preferences;

  /// Update audio preferences
  Future<void> updatePreferences(AudioPreferences preferences) async {
    _preferences = preferences;
    await _savePreferences();
  }

  /// Update master volume
  Future<void> setMasterVolume(double volume) async {
    _preferences = _preferences.copyWith(masterVolume: volume);
    await _savePreferences();
  }

  /// Update mute state
  Future<void> setMuted(bool muted) async {
    _preferences = _preferences.copyWith(isMuted: muted);
    await _savePreferences();
  }

  /// Update cue enabled state
  Future<void> setCueEnabled(AudioCueType cueType, bool enabled) async {
    final newStates = Map<AudioCueType, bool>.from(
      _preferences.cueEnabledStates,
    );
    newStates[cueType] = enabled;
    _preferences = _preferences.copyWith(cueEnabledStates: newStates);
    await _savePreferences();
  }

  /// Update cue volume
  Future<void> setCueVolume(AudioCueType cueType, double volume) async {
    final newVolumes = Map<AudioCueType, double>.from(_preferences.cueVolumes);
    newVolumes[cueType] = volume;
    _preferences = _preferences.copyWith(cueVolumes: newVolumes);
    await _savePreferences();
  }

  /// Reset to default preferences
  Future<void> resetToDefaults() async {
    _preferences = const AudioPreferences();
    await _savePreferences();
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    if (_prefs == null) return;

    final jsonString = _prefs!.getString(_prefsKey);
    if (jsonString != null) {
      try {
        final json = Map<String, dynamic>.from(
          Uri.splitQueryString(jsonString),
        );
        _preferences = AudioPreferences.fromJson(json);
      } catch (e) {
        // If loading fails, use defaults
        _preferences = const AudioPreferences();
      }
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    if (_prefs == null) return;

    final json = _preferences.toJson();
    final jsonString = Uri(
      queryParameters: json.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    ).query;

    await _prefs!.setString(_prefsKey, jsonString);
  }
}
