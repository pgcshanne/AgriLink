// Conditional export: uses HTML-based picker on web, stub on all other platforms.
export 'web_image_helper_stub.dart'
    if (dart.library.html) 'web_image_helper_impl.dart';
