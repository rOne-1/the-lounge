import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> saveJsonFile(String jsonString, String fileName) async {
  final bytes = utf8.encode(jsonString);
  final path = await FilePicker.saveFile(
    dialogTitle: 'Save Backup',
    fileName: fileName,
    bytes: bytes,
  );
  return path != null && path.isNotEmpty;
}

Future<void> shareJsonFile(String jsonString, String fileName) async {
  final xFile = XFile.fromData(
    utf8.encode(jsonString),
    mimeType: 'application/json',
    name: fileName,
  );
  await SharePlus.instance.share(
    ShareParams(
      files: [xFile],
      fileNameOverrides: [fileName],
      subject: 'The Lounge Backup',
    ),
  );
}

/// ANLY-SHARE-1: sibling to [shareJsonFile], same platform-split pattern,
/// for sharing a rendered PNG (e.g. the Analytics summary card) instead of
/// a JSON backup.
Future<void> shareImageFile(Uint8List pngBytes, String fileName) async {
  final xFile = XFile.fromData(
    pngBytes,
    mimeType: 'image/png',
    name: fileName,
  );
  await SharePlus.instance.share(
    ShareParams(
      files: [xFile],
      fileNameOverrides: [fileName],
      subject: 'The Lounge Analytics',
    ),
  );
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
    } else if (file.path != null) {
      final ioFile = File(file.path!);
      return await ioFile.readAsString();
    }
  }
  return null;
}
