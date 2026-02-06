import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// File handling service for picking, saving, and sharing files
class FileService {
  /// Pick a single file
  static Future<File?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  /// Pick multiple files
  static Future<List<File>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );
      if (result != null) {
        return result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      }
    } catch (e) {
      print('Error picking files: $e');
    }
    return [];
  }

  /// Pick an Excel file
  static Future<File?> pickExcelFile() async {
    return pickFile(allowedExtensions: ['xlsx', 'xls']);
  }

  /// Pick a PDF file
  static Future<File?> pickPdfFile() async {
    return pickFile(allowedExtensions: ['pdf']);
  }

  /// Pick an image file
  static Future<File?> pickImageFile() async {
    return pickFile(type: FileType.image);
  }

  /// Get app documents directory
  static Future<Directory> getDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get temporary directory
  static Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  /// Save bytes to a file in documents directory
  static Future<File?> saveFile({
    required String filename,
    required List<int> bytes,
    String? subfolder,
  }) async {
    try {
      final dir = await getDocumentsDirectory();
      final path = subfolder != null
          ? '${dir.path}/$subfolder/$filename'
          : '${dir.path}/$filename';
      
      // Ensure directory exists
      final file = File(path);
      await file.parent.create(recursive: true);
      
      return await file.writeAsBytes(bytes);
    } catch (e) {
      print('Error saving file: $e');
    }
    return null;
  }

  /// Save bytes to a file with user choosing location
  static Future<String?> saveFileAs({
    required String filename,
    required List<int> bytes,
  }) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save file as',
        fileName: filename,
      );
      if (path != null) {
        final file = File(path);
        await file.writeAsBytes(bytes);
        return path;
      }
    } catch (e) {
      print('Error saving file: $e');
    }
    return null;
  }

  /// Share a file
  static Future<void> shareFile(File file, {String? subject}) async {
    try {
      await Share.shareXFiles([XFile(file.path)], subject: subject);
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  /// Share multiple files
  static Future<void> shareFiles(List<File> files, {String? subject}) async {
    try {
      await Share.shareXFiles(
        files.map((f) => XFile(f.path)).toList(),
        subject: subject,
      );
    } catch (e) {
      print('Error sharing files: $e');
    }
  }

  /// Delete a file
  static Future<bool> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
    return false;
  }

  /// Get file size formatted
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
