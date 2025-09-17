import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/pose_data.dart';
import '../models/pose_estimation_config.dart';
import '../services/model_manager.dart' as model_manager;
import '../services/pose_estimation_service.dart';
import 'pose_estimation_state.dart';

/// Events for pose estimation BLoC
abstract class PoseEstimationEvent {
  const PoseEstimationEvent();
}

/// Initialize pose estimation service
class InitializePoseEstimation extends PoseEstimationEvent {
  final PoseEstimationConfig? config;

  const InitializePoseEstimation({this.config});
}

/// Process an image for pose estimation
class ProcessImage extends PoseEstimationEvent {
  final Uint8List imageBytes;

  const ProcessImage(this.imageBytes);
}

/// Switch to a different model
class SwitchModel extends PoseEstimationEvent {
  final PoseEstimationConfig config;

  const SwitchModel(this.config);
}

/// Switch to a preset configuration
class SwitchToPreset extends PoseEstimationEvent {
  final model_manager.PoseEstimationPreset preset;

  const SwitchToPreset(this.preset);
}

/// Update configuration parameters
class UpdateConfig extends PoseEstimationEvent {
  final double? confidenceThreshold;
  final bool? useGpu;
  final int? numThreads;
  final bool? useQuantization;

  const UpdateConfig({
    this.confidenceThreshold,
    this.useGpu,
    this.numThreads,
    this.useQuantization,
  });
}

/// Dispose pose estimation service
class DisposePoseEstimation extends PoseEstimationEvent {
  const DisposePoseEstimation();
}

/// BLoC for managing pose estimation state and operations
class PoseEstimationBloc
    extends Bloc<PoseEstimationEvent, PoseEstimationState> {
  final model_manager.ModelManager _modelManager =
      model_manager.ModelManager.instance;
  final PoseEstimationService _poseService = PoseEstimationService.instance;

  StreamSubscription<PoseData>? _poseStreamSubscription;
  StreamSubscription<PoseEstimationConfig>? _modelChangeSubscription;

  PoseEstimationBloc() : super(const PoseEstimationInitial()) {
    on<InitializePoseEstimation>(_onInitialize);
    on<ProcessImage>(_onProcessImage);
    on<SwitchModel>(_onSwitchModel);
    on<SwitchToPreset>(_onSwitchToPreset);
    on<UpdateConfig>(_onUpdateConfig);
    on<DisposePoseEstimation>(_onDispose);

    _setupStreams();
  }

  /// Set up stream subscriptions
  void _setupStreams() {
    // Listen to pose estimation results
    _poseStreamSubscription = _poseService.poseStream.listen(
      (poseData) {
        if (state is PoseEstimationReady || state is PoseEstimationProcessing) {
          final currentState = state as dynamic;
          emit(
            PoseEstimationResult(
              config: currentState.config,
              poseData: poseData,
              modelInfo: _poseService.getModelInfo(),
            ),
          );
        }
      },
      onError: (error) {
        emit(
          PoseEstimationError(
            error: 'Pose estimation failed',
            details: error.toString(),
            config: _modelManager.currentConfig,
          ),
        );
      },
    );

    // Listen to model changes
    _modelChangeSubscription = _modelManager.modelChangeStream.listen(
      (config) {
        emit(
          PoseEstimationConfigUpdated(
            config: config,
            modelInfo: _poseService.getModelInfo(),
          ),
        );
      },
      onError: (error) {
        emit(
          PoseEstimationError(
            error: 'Model switch failed',
            details: error.toString(),
            config: _modelManager.currentConfig,
          ),
        );
      },
    );
  }

  /// Initialize pose estimation service
  Future<void> _onInitialize(
    InitializePoseEstimation event,
    Emitter<PoseEstimationState> emit,
  ) async {
    try {
      emit(
        const PoseEstimationLoading(message: 'Initializing pose estimation...'),
      );

      // Initialize model manager
      await _modelManager.initialize();

      // Use provided config or current config
      final config = event.config ?? _modelManager.currentConfig;
      if (config == null) {
        throw Exception('No configuration available');
      }

      // Initialize pose service if not already done
      if (!_poseService.isInitialized) {
        await _poseService.initialize(config);
      }

      emit(
        PoseEstimationReady(
          config: config,
          modelInfo: _poseService.getModelInfo(),
        ),
      );
    } catch (e) {
      debugPrint('PoseEstimationBloc: Failed to initialize: $e');
      emit(
        PoseEstimationError(
          error: 'Failed to initialize pose estimation',
          details: e.toString(),
        ),
      );
    }
  }

  /// Process an image for pose estimation
  Future<void> _onProcessImage(
    ProcessImage event,
    Emitter<PoseEstimationState> emit,
  ) async {
    try {
      if (state is! PoseEstimationReady && state is! PoseEstimationResult) {
        emit(
          const PoseEstimationError(
            error: 'Pose estimation not ready',
            details: 'Service must be initialized before processing images',
          ),
        );
        return;
      }

      final currentState = state as dynamic;
      emit(
        PoseEstimationProcessing(
          config: currentState.config,
          modelInfo: _poseService.getModelInfo(),
          lastPose: currentState is PoseEstimationResult
              ? currentState.poseData
              : null,
        ),
      );

      // Process the image
      final poseData = await _poseService.processImage(event.imageBytes);

      if (poseData != null) {
        emit(
          PoseEstimationResult(
            config: currentState.config,
            poseData: poseData,
            modelInfo: _poseService.getModelInfo(),
          ),
        );
      } else {
        emit(
          PoseEstimationError(
            error: 'No pose detected',
            details: 'The image did not contain a detectable pose',
            config: currentState.config,
          ),
        );
      }
    } catch (e) {
      debugPrint('PoseEstimationBloc: Failed to process image: $e');
      final currentState = state as dynamic;
      emit(
        PoseEstimationError(
          error: 'Failed to process image',
          details: e.toString(),
          config: currentState?.config,
        ),
      );
    }
  }

  /// Switch to a different model
  Future<void> _onSwitchModel(
    SwitchModel event,
    Emitter<PoseEstimationState> emit,
  ) async {
    try {
      final currentConfig = _modelManager.currentConfig;
      if (currentConfig != null) {
        emit(
          PoseEstimationModelSwitching(
            fromConfig: currentConfig,
            toConfig: event.config,
          ),
        );
      }

      await _modelManager.switchModel(event.config);

      emit(
        PoseEstimationReady(
          config: event.config,
          modelInfo: _poseService.getModelInfo(),
        ),
      );
    } catch (e) {
      debugPrint('PoseEstimationBloc: Failed to switch model: $e');
      emit(
        PoseEstimationError(
          error: 'Failed to switch model',
          details: e.toString(),
          config: _modelManager.currentConfig,
        ),
      );
    }
  }

  /// Switch to a preset configuration
  Future<void> _onSwitchToPreset(
    SwitchToPreset event,
    Emitter<PoseEstimationState> emit,
  ) async {
    try {
      final currentConfig = _modelManager.currentConfig;
      if (currentConfig != null) {
        emit(
          PoseEstimationModelSwitching(
            fromConfig: currentConfig,
            toConfig: currentConfig, // Will be updated by model manager
          ),
        );
      }

      await _modelManager.switchToPreset(event.preset);

      final newConfig = _modelManager.currentConfig;
      if (newConfig != null) {
        emit(
          PoseEstimationReady(
            config: newConfig,
            modelInfo: _poseService.getModelInfo(),
          ),
        );
      }
    } catch (e) {
      debugPrint('PoseEstimationBloc: Failed to switch to preset: $e');
      emit(
        PoseEstimationError(
          error: 'Failed to switch to preset',
          details: e.toString(),
          config: _modelManager.currentConfig,
        ),
      );
    }
  }

  /// Update configuration parameters
  Future<void> _onUpdateConfig(
    UpdateConfig event,
    Emitter<PoseEstimationState> emit,
  ) async {
    try {
      await _modelManager.updateConfig(
        confidenceThreshold: event.confidenceThreshold,
        useGpu: event.useGpu,
        numThreads: event.numThreads,
        useQuantization: event.useQuantization,
      );

      final config = _modelManager.currentConfig;
      if (config != null) {
        emit(
          PoseEstimationConfigUpdated(
            config: config,
            modelInfo: _poseService.getModelInfo(),
          ),
        );
      }
    } catch (e) {
      debugPrint('PoseEstimationBloc: Failed to update config: $e');
      emit(
        PoseEstimationError(
          error: 'Failed to update configuration',
          details: e.toString(),
          config: _modelManager.currentConfig,
        ),
      );
    }
  }

  /// Dispose pose estimation service
  Future<void> _onDispose(
    DisposePoseEstimation event,
    Emitter<PoseEstimationState> emit,
  ) async {
    try {
      await _poseStreamSubscription?.cancel();
      await _modelChangeSubscription?.cancel();
      await _modelManager.dispose();

      emit(const PoseEstimationDisposed());
    } catch (e) {
      debugPrint('PoseEstimationBloc: Failed to dispose: $e');
      emit(
        PoseEstimationError(
          error: 'Failed to dispose pose estimation',
          details: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _poseStreamSubscription?.cancel();
    await _modelChangeSubscription?.cancel();
    return super.close();
  }
}
