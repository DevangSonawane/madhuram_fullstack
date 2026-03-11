import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum UploadSourceOption { camera, gallery, files }

/// File handling service for picking, saving, and sharing files
class FileService {
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<UploadSourceOption?> _showUploadSourcePicker(
    BuildContext context,
  ) async {
    return showDialog<UploadSourceOption>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select Source'),
          contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.of(
                  dialogContext,
                ).pop(UploadSourceOption.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(
                  dialogContext,
                ).pop(UploadSourceOption.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: const Text('Files'),
                onTap: () => Navigator.of(
                  dialogContext,
                ).pop(UploadSourceOption.files),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pick one file after source selection (Camera / Gallery / Files).
  static Future<File?> pickFileWithSource({
    required BuildContext context,
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    UploadSourceOption? source;
    try {
      source = await _showUploadSourcePicker(context);
    } catch (e) {
      // Fallback so upload tap never becomes a no-op if source UI fails.
      return pickFile(allowedExtensions: allowedExtensions, type: type);
    }
    if (source == null) return null;

    try {
      if (source == UploadSourceOption.files) {
        return pickFile(allowedExtensions: allowedExtensions, type: type);
      }

      final image = await _imagePicker.pickImage(
        source: source == UploadSourceOption.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('Error picking file with source: $e');
      return null;
    }
  }

  /// Pick multiple files after source selection.
  /// Camera/Gallery returns a single image as a one-item list.
  static Future<List<File>> pickMultipleFilesWithSource({
    required BuildContext context,
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    UploadSourceOption? source;
    try {
      source = await _showUploadSourcePicker(context);
    } catch (e) {
      return pickMultipleFiles(allowedExtensions: allowedExtensions, type: type);
    }
    if (source == null) return [];

    try {
      if (source == UploadSourceOption.files) {
        return pickMultipleFiles(
          allowedExtensions: allowedExtensions,
          type: type,
        );
      }

      final image = await _imagePicker.pickImage(
        source: source == UploadSourceOption.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return [];
      return [File(image.path)];
    } catch (e) {
      print('Error picking multiple files with source: $e');
      return [];
    }
  }

  /// Pick a single file
  static Future<File?> pickFile({
    BuildContext? context,
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    if (context != null) {
      return pickFileWithSource(
        context: context,
        allowedExtensions: allowedExtensions,
        type: type,
      );
    }
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
    BuildContext? context,
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    if (context != null) {
      return pickMultipleFilesWithSource(
        context: context,
        allowedExtensions: allowedExtensions,
        type: type,
      );
    }
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
  static Future<File?> pickExcelFile({BuildContext? context}) async {
    return pickFile(context: context, allowedExtensions: ['xlsx', 'xls']);
  }

  /// Pick a PDF file
  static Future<File?> pickPdfFile({BuildContext? context}) async {
    return pickFile(context: context, allowedExtensions: ['pdf']);
  }

  /// Pick an image file
  static Future<File?> pickImageFile({BuildContext? context}) async {
    return pickFile(context: context, type: FileType.image);
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
