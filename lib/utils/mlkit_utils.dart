import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class MLKitUtils {
  static InputImage? inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    try {
      // 1. Calculate rotation
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;

      var rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      if (rotation == null) return null;

      // 2. Format & Bytes conversion
      if (Platform.isAndroid) {
        // Android Google ML Kit requires NV21 format for fromBytes
        final Uint8List nv21Bytes = _convertToNV21(image);

        return InputImage.fromBytes(
          bytes: nv21Bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      } else {
        // iOS: BGRA8888
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error converting CameraImage to InputImage: $e');
      return null;
    }
  }

  /// Converts standard Android CameraImage (YUV_420_888 or NV21) into clean contiguous NV21 buffer
  static Uint8List _convertToNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;

    // If camera already produced single-plane NV21
    if (image.planes.length == 1) {
      return image.planes[0].bytes;
    }

    // Standard 3-plane YUV420 on Android Camera2
    final int uvSize = ySize ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    // 1. Copy Y Plane (Plane 0)
    final Plane yPlane = image.planes[0];
    final Uint8List yBytes = yPlane.bytes;
    final int yRowStride = yPlane.bytesPerRow;

    if (yRowStride == width) {
      nv21.setRange(0, ySize, yBytes);
    } else {
      int nvIndex = 0;
      for (int row = 0; row < height; row++) {
        final int srcStart = row * yRowStride;
        nv21.setRange(nvIndex, nvIndex + width, yBytes.sublist(srcStart, srcStart + width));
        nvIndex += width;
      }
    }

    // 2. Interleave V and U into VU (NV21 requires V followed by U)
    if (image.planes.length >= 3) {
      final Plane uPlane = image.planes[1];
      final Plane vPlane = image.planes[2];
      final Uint8List uBytes = uPlane.bytes;
      final Uint8List vBytes = vPlane.bytes;

      final int uvRowStride = uPlane.bytesPerRow;
      final int pixelStride = uPlane.bytesPerPixel ?? 1;

      int nvIndex = ySize;
      final int uvHeight = height ~/ 2;
      final int uvWidth = width ~/ 2;

      for (int row = 0; row < uvHeight; row++) {
        final int rowStart = row * uvRowStride;
        for (int col = 0; col < uvWidth; col++) {
          final int bufIndex = rowStart + (col * pixelStride);
          if (bufIndex < vBytes.length && bufIndex < uBytes.length && nvIndex + 1 < nv21.length) {
            nv21[nvIndex++] = vBytes[bufIndex]; // V first
            nv21[nvIndex++] = uBytes[bufIndex]; // U second
          }
        }
      }
    }

    return nv21;
  }

  static final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
}
