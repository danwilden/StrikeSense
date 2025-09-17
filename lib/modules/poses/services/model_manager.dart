import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pose_estimation_config.dart';
import 'pose_estimation_service.dart';

/// Manages different pose estimation models and configurations
class ModelManager {
  static ModelManager? _instance;
  static ModelManager get instance => _instance ??= ModelManager._();

  ModelManager._();

  final PoseEstimationService _poseService = PoseEstimationService.instance;
  final String _configKey = 'pose_estimation_config';

  PoseEstimationConfig? _currentConfig;
  bool _isInitialized = false;

  /// Stream controller for model changes
  final StreamController<PoseEstimationConfig> _modelChangeController =
      StreamController<PoseEstimationConfig>.broadcast();

  /// Stream of model configuration changes
  Stream<PoseEstimationConfig> get modelChangeStream =>
      _modelChangeController.stream;

  /// Returns the current model configuration
  PoseEstimationConfig? get currentConfig => _currentConfig;

  /// Returns true if the manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the model manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('ModelManager: Initializing...');

      // Load saved configuration or use default
      await _loadSavedConfig();

      // Initialize the pose service with the loaded config
      if (_currentConfig != null) {
        await _poseService.initialize(_currentConfig!);
      }

      _isInitialized = true;
      debugPrint(
        'ModelManager: Initialized with ${_currentConfig?.performanceMode.name ?? 'default'}',
      );
    } catch (e) {
      debugPrint('ModelManager: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Load saved configuration from SharedPreferences
  Future<void> _loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson != null) {
        // Parse saved configuration - convert string values to proper types
        final rawMap = Uri.splitQueryString(configJson);
        final configMap = <String, dynamic>{};

        // Convert string values to proper types
        for (final entry in rawMap.entries) {
          final key = entry.key;
          final value = entry.value;

          switch (key) {
            case 'performanceMode':
              configMap[key] = value;
              break;
            case 'minConfidence':
              configMap[key] = double.tryParse(value) ?? 0.3;
              break;
            case 'maxPoses':
              configMap[key] = int.tryParse(value) ?? 1;
              break;
            case 'smoothing':
              // Handle nested smoothing config
              if (value.startsWith('{') && value.endsWith('}')) {
                // Parse nested JSON-like structure
                try {
                  final smoothingMap = <String, dynamic>{};
                  final smoothingStr = value.substring(1, value.length - 1);
                  final smoothingPairs = smoothingStr.split(',');
                  for (final pair in smoothingPairs) {
                    final parts = pair.split(':');
                    if (parts.length == 2) {
                      final subKey = parts[0].trim();
                      final subValue = parts[1].trim();
                      switch (subKey) {
                        case 'enabled':
                          smoothingMap[subKey] = subValue == 'true';
                          break;
                        case 'factor':
                        case 'minConfidence':
                          smoothingMap[subKey] =
                              double.tryParse(subValue) ?? 0.5;
                          break;
                      }
                    }
                  }
                  configMap[key] = smoothingMap;
                } catch (e) {
                  // Fallback to default smoothing
                  configMap[key] = {
                    'enabled': true,
                    'factor': 0.5,
                    'minConfidence': 0.3,
                  };
                }
              }
              break;
            default:
              configMap[key] = value;
          }
        }

        _currentConfig = PoseEstimationConfig.fromMap(configMap);
        debugPrint(
          'ModelManager: Loaded saved config: ${_currentConfig!.performanceMode.name}',
        );
      } else {
        // Use default configuration
        _currentConfig = PoseEstimationConfig.fast();
        debugPrint(
          'ModelManager: Using default config: ${_currentConfig!.performanceMode.name}',
        );
      }
    } catch (e) {
      debugPrint('ModelManager: Failed to load saved config: $e');
      // Fallback to default
      _currentConfig = PoseEstimationConfig.fast();
    }
  }

  /// Save configuration to SharedPreferences
  Future<void> _saveConfig(PoseEstimationConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configMap = config.toMap();
      final configJson = Uri(
        queryParameters: configMap.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      ).query;

      await prefs.setString(_configKey, configJson);
      debugPrint('ModelManager: Saved config: ${config.performanceMode.name}');
    } catch (e) {
      debugPrint('ModelManager: Failed to save config: $e');
    }
  }

  /// Switch to a different model configuration
  Future<void> switchModel(PoseEstimationConfig newConfig) async {
    if (!_isInitialized) {
      throw Exception('ModelManager not initialized');
    }

    // Check if we're already using the same configuration
    if (_currentConfig?.performanceMode == newConfig.performanceMode &&
        _currentConfig?.minConfidence == newConfig.minConfidence) {
      debugPrint(
        'ModelManager: Already using ${newConfig.performanceMode.name} configuration',
      );
      return;
    }

    try {
      debugPrint(
        'ModelManager: Switching to ${newConfig.performanceMode.name}...',
      );

      // Initialize the pose service with new config
      await _poseService.switchModel(newConfig);

      // Update current config
      _currentConfig = newConfig;

      // Save the new configuration
      await _saveConfig(newConfig);

      // Notify listeners
      _modelChangeController.add(newConfig);

      debugPrint(
        'ModelManager: Successfully switched to ${newConfig.performanceMode.name}',
      );
    } catch (e) {
      debugPrint('ModelManager: Failed to switch model: $e');
      rethrow;
    }
  }

  /// Switch to MoveNet Lightning model
  Future<void> switchToMoveNetLightning() async {
    await switchModel(PoseEstimationConfig.fast());
  }

  /// Switch to BlazePose Lite model
  Future<void> switchToBlazePoseLite() async {
    await switchModel(PoseEstimationConfig.accurate());
  }

  /// Switch to BlazePose Full model
  Future<void> switchToBlazePoseFull() async {
    await switchModel(PoseEstimationConfig.accurate());
  }

  /// Switch to a preset configuration
  Future<void> switchToPreset(PoseEstimationPreset preset) async {
    PoseEstimationConfig config;

    switch (preset) {
      case PoseEstimationPreset.boxingTraining:
        config = PoseEstimationPresets.boxingTraining;
        break;
      case PoseEstimationPreset.formAnalysis:
        config = PoseEstimationPresets.formAnalysis;
        break;
      case PoseEstimationPreset.lowEndDevice:
        config = PoseEstimationPresets.lowEndDevice;
        break;
      case PoseEstimationPreset.highEndDevice:
        config = PoseEstimationPresets.highEndDevice;
        break;
    }

    await switchModel(config);
  }

  /// Update configuration parameters
  Future<void> updateConfig({
    double? confidenceThreshold,
    bool? useGpu,
    int? numThreads,
    bool? useQuantization,
  }) async {
    if (_currentConfig == null) {
      throw Exception('No current configuration');
    }

    final updatedConfig = _currentConfig!.copyWith(
      minConfidence: confidenceThreshold,
    );

    await switchModel(updatedConfig);
  }

  /// Get available model configurations
  List<PoseEstimationConfig> getAvailableModels() {
    return [
      PoseEstimationConfig.fast(),
      PoseEstimationConfig.accurate(),
      PoseEstimationConfig.boxingTraining(),
      PoseEstimationConfig.formAnalysis(),
    ];
  }

  /// Get available preset configurations
  List<Map<String, dynamic>> getAvailablePresets() {
    return [
      {
        'name': 'Fast Mode',
        'description': 'Optimized for real-time performance',
        'preset': PoseEstimationPreset.lowEndDevice,
        'config': PoseEstimationConfig.fast(),
      },
      {
        'name': 'Accurate Mode',
        'description': 'Higher accuracy for detailed analysis',
        'preset': PoseEstimationPreset.highEndDevice,
        'config': PoseEstimationConfig.accurate(),
      },
      {
        'name': 'Boxing Training',
        'description': 'Optimized for real-time boxing training',
        'preset': PoseEstimationPreset.boxingTraining,
        'config': PoseEstimationConfig.boxingTraining(),
      },
      {
        'name': 'Form Analysis',
        'description': 'Higher accuracy for form analysis',
        'preset': PoseEstimationPreset.formAnalysis,
        'config': PoseEstimationConfig.formAnalysis(),
      },
    ];
  }

  /// Get model information
  Map<String, dynamic> getModelInfo() {
    return {
      'currentConfig': _currentConfig?.toMap(),
      'isInitialized': _isInitialized,
      'poseServiceInfo': _poseService.getModelInfo(),
      'availableModels': getAvailableModels().map((c) => c.toMap()).toList(),
      'availablePresets': getAvailablePresets(),
    };
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'modelManager': {
        'isInitialized': _isInitialized,
        'currentModel': _currentConfig?.performanceMode.name,
        'hasActiveStream': !_modelChangeController.isClosed,
      },
      'poseService': _poseService.getPerformanceStats(),
    };
  }

  /// Dispose the model manager
  Future<void> dispose() async {
    await _modelChangeController.close();
    await _poseService.dispose();
    _isInitialized = false;
    _currentConfig = null;
    debugPrint('ModelManager: Disposed');
  }
}

/// Preset configurations for different use cases
enum PoseEstimationPreset {
  boxingTraining,
  formAnalysis,
  lowEndDevice,
  highEndDevice,
}
