import 'package:equatable/equatable.dart';

/// ML Kit performance mode for pose detection
enum MLKitPerformanceMode { fast, accurate }

/// Configuration for smoothing algorithms
class SmoothingConfig extends Equatable {
  /// Whether to enable smoothing
  final bool enabled;

  /// Smoothing factor (0.0 to 1.0)
  final double factor;

  /// Minimum confidence threshold for smoothing
  final double minConfidence;

  const SmoothingConfig({
    this.enabled = true,
    this.factor = 0.5,
    this.minConfidence = 0.3,
  });

  @override
  List<Object?> get props => [enabled, factor, minConfidence];

  SmoothingConfig copyWith({
    bool? enabled,
    double? factor,
    double? minConfidence,
  }) {
    return SmoothingConfig(
      enabled: enabled ?? this.enabled,
      factor: factor ?? this.factor,
      minConfidence: minConfidence ?? this.minConfidence,
    );
  }
}

/// Configuration for ML Kit pose estimation
class PoseEstimationConfig extends Equatable {
  /// ML Kit performance mode (FAST or ACCURATE)
  final MLKitPerformanceMode performanceMode;

  /// Confidence threshold for filtering keypoints
  final double minConfidence;

  /// Smoothing configuration
  final SmoothingConfig smoothing;

  /// Maximum number of poses to detect
  final int maxPoses;

  const PoseEstimationConfig({
    required this.performanceMode,
    this.minConfidence = 0.3,
    this.smoothing = const SmoothingConfig(),
    this.maxPoses = 1,
  });

  /// Fast performance mode (recommended for real-time)
  factory PoseEstimationConfig.fast() {
    return const PoseEstimationConfig(
      performanceMode: MLKitPerformanceMode.fast,
      minConfidence: 0.3,
      smoothing: SmoothingConfig(
        enabled: true,
        factor: 0.3, // Less smoothing for faster response
        minConfidence: 0.3,
      ),
      maxPoses: 1,
    );
  }

  /// Accurate performance mode (higher accuracy, slower)
  factory PoseEstimationConfig.accurate() {
    return const PoseEstimationConfig(
      performanceMode: MLKitPerformanceMode.accurate,
      minConfidence: 0.6, // Increased for better quality
      smoothing: SmoothingConfig(
        enabled: true,
        factor: 0.7, // More smoothing for stability
        minConfidence: 0.6,
      ),
      maxPoses: 1,
    );
  }

  /// Boxing training optimized configuration
  factory PoseEstimationConfig.boxingTraining() {
    return const PoseEstimationConfig(
      performanceMode:
          MLKitPerformanceMode.accurate, // Use accurate mode like Python app
      minConfidence: 0.7, // Increased for better quality detection
      smoothing: SmoothingConfig(
        enabled: true, // Enable smoothing for stable tracking
        factor: 0.6,
        minConfidence: 0.7,
      ),
      maxPoses: 1,
    );
  }

  /// Debug configuration for testing pose detection
  factory PoseEstimationConfig.debug() {
    return const PoseEstimationConfig(
      performanceMode: MLKitPerformanceMode.accurate,
      minConfidence: 0.1, // Very low threshold for debugging
      smoothing: SmoothingConfig(
        enabled: false,
        factor: 0.5,
        minConfidence: 0.1,
      ),
      maxPoses: 1,
    );
  }

  /// Form analysis configuration (higher accuracy)
  factory PoseEstimationConfig.formAnalysis() {
    return const PoseEstimationConfig(
      performanceMode: MLKitPerformanceMode.accurate,
      minConfidence: 0.6,
      smoothing: SmoothingConfig(
        enabled: true,
        factor: 0.8,
        minConfidence: 0.6,
      ),
      maxPoses: 1,
    );
  }

  /// Custom configuration for specific use cases
  factory PoseEstimationConfig.custom({
    required MLKitPerformanceMode performanceMode,
    double minConfidence = 0.3,
    SmoothingConfig? smoothing,
    int maxPoses = 1,
  }) {
    return PoseEstimationConfig(
      performanceMode: performanceMode,
      minConfidence: minConfidence,
      smoothing: smoothing ?? const SmoothingConfig(),
      maxPoses: maxPoses,
    );
  }

  /// Returns the performance category
  PerformanceCategory get performanceCategory {
    switch (performanceMode) {
      case MLKitPerformanceMode.fast:
        return PerformanceCategory.fast;
      case MLKitPerformanceMode.accurate:
        return PerformanceCategory.accurate;
    }
  }

  /// Creates a copy with updated values
  PoseEstimationConfig copyWith({
    MLKitPerformanceMode? performanceMode,
    double? minConfidence,
    SmoothingConfig? smoothing,
    int? maxPoses,
  }) {
    return PoseEstimationConfig(
      performanceMode: performanceMode ?? this.performanceMode,
      minConfidence: minConfidence ?? this.minConfidence,
      smoothing: smoothing ?? this.smoothing,
      maxPoses: maxPoses ?? this.maxPoses,
    );
  }

  /// Converts to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'performanceMode': performanceMode.name,
      'minConfidence': minConfidence,
      'smoothing': {
        'enabled': smoothing.enabled,
        'factor': smoothing.factor,
        'minConfidence': smoothing.minConfidence,
      },
      'maxPoses': maxPoses,
    };
  }

  /// Creates from a map (for deserialization)
  factory PoseEstimationConfig.fromMap(Map<String, dynamic> map) {
    return PoseEstimationConfig(
      performanceMode: MLKitPerformanceMode.values.firstWhere(
        (e) => e.name == map['performanceMode'],
        orElse: () => MLKitPerformanceMode.fast,
      ),
      minConfidence: map['minConfidence']?.toDouble() ?? 0.3,
      smoothing: SmoothingConfig(
        enabled: map['smoothing']?['enabled'] ?? true,
        factor: map['smoothing']?['factor']?.toDouble() ?? 0.5,
        minConfidence: map['smoothing']?['minConfidence']?.toDouble() ?? 0.3,
      ),
      maxPoses: map['maxPoses']?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [
    performanceMode,
    minConfidence,
    smoothing,
    maxPoses,
  ];

  @override
  String toString() {
    return 'PoseEstimationConfig(mode: $performanceMode, confidence: $minConfidence, '
        'smoothing: ${smoothing.enabled ? 'on' : 'off'})';
  }
}

/// Performance categories
enum PerformanceCategory {
  fast, // Optimized for speed
  accurate, // Optimized for accuracy
}

/// Predefined configurations for common use cases
class PoseEstimationPresets {
  /// Configuration optimized for real-time boxing training
  static PoseEstimationConfig get boxingTraining =>
      PoseEstimationConfig.boxingTraining();

  /// Configuration optimized for form analysis (higher accuracy)
  static PoseEstimationConfig get formAnalysis =>
      PoseEstimationConfig.formAnalysis();

  /// Configuration optimized for low-end devices
  static PoseEstimationConfig get lowEndDevice => PoseEstimationConfig.fast();

  /// Configuration optimized for high-end devices
  static PoseEstimationConfig get highEndDevice =>
      PoseEstimationConfig.accurate();
}

/// Preset types for easy reference
enum PoseEstimationPreset {
  boxingTraining,
  formAnalysis,
  lowEndDevice,
  highEndDevice,
}
