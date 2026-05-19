import 'dart:math';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/material.dart';
import '../models/workout_state.dart';

class PoseService {
  PoseDetector? _poseDetector;
  bool _isProcessing = false;

  // ── Initialize ML Kit Pose Detector ───────────────
  void init() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
  }

  // ── Process each camera frame ─────────────────────
  Future<void> processFrame(
    CameraImage image,
    CameraDescription camera,
    WorkoutState state,
  ) async {
    if (_isProcessing || _poseDetector == null) return;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image, camera);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isEmpty) {
        state.updateAngles(detected: false);
        _isProcessing = false;
        return;
      }

      final pose = poses.first;
      _analyzePushUp(pose, state);
    } catch (e) {
      debugPrint('Pose detection error: $e');
    }

    _isProcessing = false;
  }

  // ── Build InputImage from CameraImage ─────────────
  InputImage? _buildInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final rotation = _getRotation(camera.sensorOrientation);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    // Concatenate all planes to construct a complete image buffer (fixes Android tracking)
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  InputImageRotation _getRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:   return InputImageRotation.rotation0deg;
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation90deg;
    }
  }

  // ── Analyze landmarks for push-up counting ────────
  void _analyzePushUp(Pose pose, WorkoutState state) {
    final lm = pose.landmarks;

    final lShoulder = lm[PoseLandmarkType.leftShoulder];
    final lElbow    = lm[PoseLandmarkType.leftElbow];
    final lWrist    = lm[PoseLandmarkType.leftWrist];
    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    final rElbow    = lm[PoseLandmarkType.rightElbow];
    final rWrist    = lm[PoseLandmarkType.rightWrist];

    const minConf = 0.5;

    final leftOk = _visible(lShoulder, minConf) &&
                   _visible(lElbow, minConf) &&
                   _visible(lWrist, minConf);
    final rightOk = _visible(rShoulder, minConf) &&
                    _visible(rElbow, minConf) &&
                    _visible(rWrist, minConf);

    if (!leftOk && !rightOk) {
      state.updateAngles(detected: false);
      return;
    }

    double? leftAngle;
    double? rightAngle;

    if (leftOk) {
      leftAngle = _calcAngle(lShoulder!, lElbow!, lWrist!);
    }
    if (rightOk) {
      rightAngle = _calcAngle(rShoulder!, rElbow!, rWrist!);
    }

    state.updateAngles(
      left: leftAngle,
      right: rightAngle,
      detected: true,
    );
  }

  // ── Check landmark visibility ─────────────────────
  bool _visible(PoseLandmark? lm, double threshold) {
    if (lm == null) return false;
    return (lm.likelihood) >= threshold;
  }

  // ── Calculate joint angle (degrees) ──────────────
  double _calcAngle(
    PoseLandmark a, // shoulder
    PoseLandmark b, // elbow
    PoseLandmark c, // wrist
  ) {
    final radians = atan2(c.y - b.y, c.x - b.x)
                  - atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180 / pi).abs();
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  // ── Cleanup ───────────────────────────────────────
  void dispose() {
    _poseDetector?.close();
    _poseDetector = null;
  }
}
