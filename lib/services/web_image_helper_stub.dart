// Stub for non-web platforms (Android, iOS native, desktop).
// On these platforms, image_picker handles everything natively.
import 'dart:typed_data';

class WebImageResult {
  final Uint8List bytes;
  final String name;
  WebImageResult({required this.bytes, required this.name});
}

/// Not used on non-web platforms — returns null as a no-op stub.
Future<Uint8List?> pickWebImage({bool useCamera = false}) async => null;
Future<WebImageResult?> pickWebImageResult({bool useCamera = false}) async => null;

