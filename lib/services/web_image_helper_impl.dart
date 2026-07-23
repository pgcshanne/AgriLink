// Web-native image picker using HTML <input type="file">
// This works on iPhone Safari, Android Chrome, and all browsers.
// It bypasses the Flutter image_picker plugin channel (which is not supported on web).
import 'dart:async';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebImageResult {
  final Uint8List bytes;
  final String name;
  WebImageResult({required this.bytes, required this.name});
}

/// Picks an image using a native browser file input.
/// Returns both bytes and original filename.
Future<Uint8List?> pickWebImage({bool useCamera = false}) async {
  final res = await pickWebImageResult(useCamera: useCamera);
  return res?.bytes;
}

Future<WebImageResult?> pickWebImageResult({bool useCamera = false}) {
  final completer = Completer<WebImageResult?>();
  bool resolved = false;

  final input = html.FileUploadInputElement();
  input.accept = 'image/*';
  if (useCamera) {
    input.setAttribute('capture', 'environment');
  }

  input.onChange.listen((event) {
    if (resolved) return;
    final file = input.files?.first;
    if (file == null) {
      resolved = true;
      completer.complete(null);
      return;
    }
    final fileName = file.name;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      if (resolved) return;
      resolved = true;
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(WebImageResult(bytes: Uint8List.view(result), name: fileName));
      } else if (result is Uint8List) {
        completer.complete(WebImageResult(bytes: result, name: fileName));
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) {
      if (!resolved) {
        resolved = true;
        completer.complete(null);
      }
    });
  });

  // Append to body, click, then remove
  html.document.body!.append(input);
  input.click();
  Future.delayed(const Duration(milliseconds: 200), () {
    if (input.parentNode != null) input.remove();
  });

  return completer.future;
}

