// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';

Future<void> saveJsonFile(String jsonString, String fileName) async {
  final bytes = utf8.encode(jsonString);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> shareJsonFile(String jsonString, String fileName) async {
  // Try using navigator.share if supported on the browser
  try {
    final jsNavigator = html.window.navigator as dynamic;
    if (jsNavigator.share != null) {
      await jsNavigator.share({
        'title': 'The Lounge Backup',
        'text': 'The Lounge Backup JSON',
        'files': [
          html.File([jsonString], fileName, {'type': 'application/json'})
        ],
      });
      return;
    }
  } catch (_) {
    // Fallback on error or lack of support
  }
  await saveJsonFile(jsonString, fileName);
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
