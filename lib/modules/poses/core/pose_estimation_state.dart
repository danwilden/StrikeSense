import 'package:equatable/equatable.dart';
import '../models/pose_data.dart';
import '../models/pose_estimation_config.dart';

/// Base state for pose estimation
abstract class PoseEstimationState extends Equatable {
  const PoseEstimationState();

  @override
  List<Object?> get props => [];
}

/// Initial state when pose estimation is not yet initialized
class PoseEstimationInitial extends PoseEstimationState {
  const PoseEstimationInitial();
}

/// State when pose estimation service is loading/initializing
class PoseEstimationLoading extends PoseEstimationState {
  final String message;

  const PoseEstimationLoading({this.message = 'Loading pose estimation...'});

  @override
  List<Object?> get props => [message];
}

/// State when pose estimation service is ready and initialized
class PoseEstimationReady extends PoseEstimationState {
  final PoseEstimationConfig config;
  final Map<String, dynamic> modelInfo;

  const PoseEstimationReady({required this.config, required this.modelInfo});

  @override
  List<Object?> get props => [config, modelInfo];
}

/// State when pose estimation is actively processing
class PoseEstimationProcessing extends PoseEstimationState {
  final PoseEstimationConfig config;
  final Map<String, dynamic> modelInfo;
  final PoseData? lastPose;

  const PoseEstimationProcessing({
    required this.config,
    required this.modelInfo,
    this.lastPose,
  });

  @override
  List<Object?> get props => [config, modelInfo, lastPose];
}

/// State when pose estimation has produced results
class PoseEstimationResult extends PoseEstimationState {
  final PoseEstimationConfig config;
  final PoseData poseData;
  final Map<String, dynamic> modelInfo;

  const PoseEstimationResult({
    required this.config,
    required this.poseData,
    required this.modelInfo,
  });

  @override
  List<Object?> get props => [config, poseData, modelInfo];
}

/// State when pose estimation encounters an error
class PoseEstimationError extends PoseEstimationState {
  final String error;
  final String? details;
  final PoseEstimationConfig? config;

  const PoseEstimationError({required this.error, this.details, this.config});

  @override
  List<Object?> get props => [error, details, config];
}

/// State when pose estimation service is disposed
class PoseEstimationDisposed extends PoseEstimationState {
  const PoseEstimationDisposed();
}

/// State for model switching
class PoseEstimationModelSwitching extends PoseEstimationState {
  final PoseEstimationConfig fromConfig;
  final PoseEstimationConfig toConfig;

  const PoseEstimationModelSwitching({
    required this.fromConfig,
    required this.toConfig,
  });

  @override
  List<Object?> get props => [fromConfig, toConfig];
}

/// State for configuration updates
class PoseEstimationConfigUpdated extends PoseEstimationState {
  final PoseEstimationConfig config;
  final Map<String, dynamic> modelInfo;

  const PoseEstimationConfigUpdated({
    required this.config,
    required this.modelInfo,
  });

  @override
  List<Object?> get props => [config, modelInfo];
}
