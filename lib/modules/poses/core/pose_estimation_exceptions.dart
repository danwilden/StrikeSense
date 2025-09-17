/// Custom exceptions for pose estimation operations
class PoseEstimationException implements Exception {
  final String message;
  final PoseEstimationErrorType errorType;
  final dynamic originalError;

  const PoseEstimationException(
    this.message,
    this.errorType, {
    this.originalError,
  });

  @override
  String toString() {
    return 'PoseEstimationException($errorType): $message${originalError != null ? ' (Original: $originalError)' : ''}';
  }
}

/// Types of pose estimation errors
enum PoseEstimationErrorType {
  /// Model file not found
  modelNotFound,

  /// Model file is invalid or corrupted
  invalidModel,

  /// Model loading failed
  modelLoadFailed,

  /// Model loading timed out
  modelLoadTimeout,

  /// Invalid configuration parameters
  invalidConfig,

  /// Service not initialized
  notInitialized,

  /// Service already loading
  alreadyLoading,

  /// Image processing failed
  imageProcessingFailed,

  /// Inference failed
  inferenceFailed,

  /// GPU delegate failed
  gpuDelegateFailed,

  /// Memory allocation failed
  memoryAllocationFailed,

  /// Thread configuration failed
  threadConfigFailed,

  /// Unknown error
  unknown,
}

/// Extension to provide user-friendly error messages
extension PoseEstimationErrorMessages on PoseEstimationErrorType {
  String get userMessage {
    switch (this) {
      case PoseEstimationErrorType.modelNotFound:
        return 'The pose estimation model could not be found. Please check if the model file exists.';
      case PoseEstimationErrorType.invalidModel:
        return 'The pose estimation model file is corrupted or invalid.';
      case PoseEstimationErrorType.modelLoadFailed:
        return 'Failed to load the pose estimation model. Please try again.';
      case PoseEstimationErrorType.modelLoadTimeout:
        return 'Model loading is taking too long. Please check your device performance.';
      case PoseEstimationErrorType.invalidConfig:
        return 'Invalid configuration parameters. Please check your settings.';
      case PoseEstimationErrorType.notInitialized:
        return 'Pose estimation service is not initialized. Please initialize it first.';
      case PoseEstimationErrorType.alreadyLoading:
        return 'Pose estimation service is already loading a model. Please wait.';
      case PoseEstimationErrorType.imageProcessingFailed:
        return 'Failed to process the image for pose estimation.';
      case PoseEstimationErrorType.inferenceFailed:
        return 'Pose estimation inference failed. Please try again.';
      case PoseEstimationErrorType.gpuDelegateFailed:
        return 'GPU acceleration failed. Falling back to CPU processing.';
      case PoseEstimationErrorType.memoryAllocationFailed:
        return 'Insufficient memory to run pose estimation.';
      case PoseEstimationErrorType.threadConfigFailed:
        return 'Failed to configure processing threads.';
      case PoseEstimationErrorType.unknown:
        return 'An unknown error occurred during pose estimation.';
    }
  }

  /// Returns true if the error is recoverable
  bool get isRecoverable {
    switch (this) {
      case PoseEstimationErrorType.modelLoadTimeout:
      case PoseEstimationErrorType.gpuDelegateFailed:
      case PoseEstimationErrorType.inferenceFailed:
        return true;
      case PoseEstimationErrorType.modelNotFound:
      case PoseEstimationErrorType.invalidModel:
      case PoseEstimationErrorType.invalidConfig:
      case PoseEstimationErrorType.memoryAllocationFailed:
        return false;
      default:
        return true;
    }
  }

  /// Returns the suggested action for the error
  String get suggestedAction {
    switch (this) {
      case PoseEstimationErrorType.modelNotFound:
        return 'Check if the model file is properly included in the app assets.';
      case PoseEstimationErrorType.invalidModel:
        return 'Re-download or reinstall the model file.';
      case PoseEstimationErrorType.modelLoadFailed:
        return 'Restart the app and try again.';
      case PoseEstimationErrorType.modelLoadTimeout:
        return 'Close other apps to free up device resources.';
      case PoseEstimationErrorType.invalidConfig:
        return 'Reset to default configuration settings.';
      case PoseEstimationErrorType.notInitialized:
        return 'Initialize the pose estimation service before use.';
      case PoseEstimationErrorType.alreadyLoading:
        return 'Wait for the current loading operation to complete.';
      case PoseEstimationErrorType.imageProcessingFailed:
        return 'Try with a different image or check image format.';
      case PoseEstimationErrorType.inferenceFailed:
        return 'Restart the pose estimation service.';
      case PoseEstimationErrorType.gpuDelegateFailed:
        return 'Continue with CPU processing (may be slower).';
      case PoseEstimationErrorType.memoryAllocationFailed:
        return 'Close other apps or restart the device.';
      case PoseEstimationErrorType.threadConfigFailed:
        return 'Use default thread configuration.';
      case PoseEstimationErrorType.unknown:
        return 'Restart the app and try again.';
    }
  }
}
