import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:file_picker/file_picker.dart';

Future<bool> saveJsonFile(String jsonString, String fileName) async {
  final bytes = utf8.encode(jsonString);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return true;
}

Future<void> shareJsonFile(String jsonString, String fileName) async {
  // Try using navigator.share if supported on the browser
  try {
    final jsNavigator = web.window.navigator;
    if (jsNavigator.hasProperty('share'.toJS).toDart) {
      final bytes = utf8.encode(jsonString);
      final file = web.File([bytes.toJS].toJS, fileName, web.FilePropertyBag(type: 'application/json'));
      final shareData = {
        'title': 'The Lounge Backup',
        'text': 'The Lounge Backup JSON',
        'files': [file],
      }.jsify();
      await (jsNavigator.callMethod<JSPromise>('share'.toJS, shareData)).toDart;
      return;
    }
  } catch (_) {
    // Fallback on error or lack of support
  }
  await saveJsonFile(jsonString, fileName);
}

/// ANLY-SHARE-1: sibling to [saveJsonFile], same download-anchor pattern,
/// for the [shareImageFile] fallback when `navigator.share` isn't
/// available/supported.
Future<bool> saveImageFile(Uint8List pngBytes, String fileName) async {
  final blob = web.Blob([pngBytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return true;
}

/// ANLY-SHARE-1: sibling to [shareJsonFile], same platform-split pattern,
/// for sharing a rendered PNG (e.g. the Analytics summary card) instead of
/// a JSON backup.
Future<void> shareImageFile(Uint8List pngBytes, String fileName) async {
  try {
    final jsNavigator = web.window.navigator;
    if (jsNavigator.hasProperty('share'.toJS).toDart) {
      final file = web.File([pngBytes.toJS].toJS, fileName, web.FilePropertyBag(type: 'image/png'));
      final shareData = {
        'title': 'The Lounge Analytics',
        'text': 'My watching habits, from The Lounge',
        'files': [file],
      }.jsify();
      await (jsNavigator.callMethod<JSPromise>('share'.toJS, shareData)).toDart;
      return;
    }
  } catch (_) {
    // Fallback on error or lack of support
  }
  await saveImageFile(pngBytes, fileName);
}

Future<String?> pickJsonFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
  }
  return null;
}
