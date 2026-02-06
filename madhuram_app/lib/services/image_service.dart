import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Image picking and handling service
class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick a single image from gallery
  static Future<File?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? quality,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality ?? 85,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
    return null;
  }

  /// Pick a single image from camera
  static Future<File?> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? quality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality ?? 85,
        preferredCameraDevice: preferredCameraDevice,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Error picking image from camera: $e');
    }
    return null;
  }

  /// Pick multiple images from gallery
  static Future<List<File>> pickMultipleImages({
    double? maxWidth,
    double? maxHeight,
    int? quality,
    int? limit,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality ?? 85,
        limit: limit,
      );
      return images.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
    }
    return [];
  }

  /// Pick image with source selection dialog
  static Future<File?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? quality,
  }) async {
    if (source == ImageSource.camera) {
      return pickImageFromCamera(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
    } else {
      return pickImageFromGallery(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
    }
  }

  /// Get image file size
  static Future<int> getImageSize(File file) async {
    return await file.length();
  }

  /// Check if file is an image
  static bool isImageFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }
}
