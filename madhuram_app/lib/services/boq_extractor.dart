import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';

/// BOQ Item extracted from PDF
class ExtractedBOQItem {
  final String itemNo;
  final String description;
  final String unit;
  final String quantity;
  final String category;

  const ExtractedBOQItem({
    required this.itemNo,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.category,
  });

  Map<String, dynamic> toTableRow(int index) {
    final qty = double.tryParse(quantity.replaceAll(',', '')) ?? 0;
    return {
      'id': index + 1,
      'category': category.isNotEmpty ? category : 'General',
      'item_code': itemNo.isNotEmpty ? 'BOQ-$itemNo' : 'BOQ-${index + 1}',
      'description': description,
      'unit': unit.isNotEmpty ? unit : 'Nos',
      'quantity': qty,
      'rate': 0.0,
      'amount': 0.0,
      'floor': 'All',
    };
  }
}

/// Result of BOQ extraction
class BOQExtractionResult {
  final List<ExtractedBOQItem> items;
  final String projectName;
  final String? error;

  const BOQExtractionResult({
    this.items = const [],
    this.projectName = '',
    this.error,
  });

  bool get success => error == null && items.isNotEmpty;
  int get itemCount => items.length;
}

/// Service for extracting BOQ data from PDFs
class BOQExtractor {
  // Skip patterns for header/footer lines
  static final List<RegExp> _skipPatterns = [
    RegExp(r'^OAKWOOD\s+BUILDING|^Item\s*$|^Nos\.\s*Description|^Page\s+No\.', caseSensitive: false),
    RegExp(r'^--\s+\d+\s+of\s+\d+|^SCHEDULE\s+OF\s+QUANTITIES', caseSensitive: false),
    RegExp(r'^Note:\s*$|^[ivxIVX]+\.\s|^[A-Z]\)\s'),
    RegExp('^TOTAL\\s*:\\s*["\']?[A-G]["\']?\\s*CARRIED\\s+TO\\s+SUMMARY', caseSensitive: false),
    RegExp(r'^Description\s+Unit\s+(Qty|Total|Tower)', caseSensitive: false),
  ];

  // Section header pattern (A., B., C., etc.)
  static final RegExp _sectionPattern = RegExp(r'^([A-G])\.\s+(.+)$');
  
  // Unit+Quantity only pattern
  static final RegExp _unitQtyPattern = RegExp(
    r'^(Nos|RM|Cum|Sft|Job|Mtr|Sqm|Kg|Ltr|Set|Pair|Each|Pcs)\.?\s*([\d,]+\.?\d*)\s*$',
    caseSensitive: false,
  );
  
  // Same line pattern: item_no description unit qty
  static final RegExp _sameLinePattern = RegExp(
    r'^(\d+(?:\.\d+)*)\s+(.+?)\s+(Nos|RM|Cum|Sft|Job|Mtr|Sqm|Kg|Ltr|Set|Pair|Each|Pcs)\.?\s*([\d,]+\.?\d*)\s*$',
    caseSensitive: false,
  );
  
  // Item start pattern
  static final RegExp _itemStartPattern = RegExp(r'^(\d+(?:\.\d+)*)\s+');
  
  // Project name patterns
  static final RegExp _projectNamePattern = RegExp(
    r'OAKWOOD\s+BUILDING|BUILDING\s+AT\s+KALYAN|PROJECT\s*[:\-]\s*(.+)',
    caseSensitive: false,
  );

  /// Pick and extract BOQ from a PDF file
  static Future<BOQExtractionResult> pickAndExtract() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return const BOQExtractionResult(error: 'No file selected');
      }

      final file = result.files.first;
      
      if (file.bytes == null && file.path == null) {
        return const BOQExtractionResult(error: 'Could not read file');
      }

      Uint8List bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (!kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        return const BOQExtractionResult(error: 'Could not read file data');
      }

      return await extractFromBytes(bytes);
    } catch (e) {
      return BOQExtractionResult(error: 'Error picking file: $e');
    }
  }

  /// Extract BOQ from PDF bytes
  static Future<BOQExtractionResult> extractFromBytes(Uint8List bytes) async {
    try {
      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Extract text from all pages
      final StringBuffer textBuffer = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final String pageText = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        textBuffer.writeln(pageText);
      }
      
      document.dispose();
      
      final rawText = textBuffer.toString();
      
      if (rawText.trim().isEmpty) {
        return const BOQExtractionResult(
          error: 'No text found in PDF. The PDF might be image-based or scanned.',
        );
      }
      
      return extractFromText(rawText);
    } catch (e) {
      return BOQExtractionResult(error: 'Error reading PDF: $e');
    }
  }

  /// Extract BOQ items from raw text
  static BOQExtractionResult extractFromText(String rawText) {
    final List<ExtractedBOQItem> items = [];
    String projectName = '';
    String category = '';
    List<String> buffer = [];

    if (rawText.isEmpty) {
      return const BOQExtractionResult(error: 'No text to extract');
    }

    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    void flush() {
      buffer = [];
    }

    bool shouldSkip(String line) {
      if (line.isEmpty) return true;
      return _skipPatterns.any((pattern) => pattern.hasMatch(line));
    }

    for (final line in lines) {
      // Try to find project name
      if (projectName.isEmpty) {
        final projectMatch = _projectNamePattern.firstMatch(line);
        if (projectMatch != null) {
          projectName = projectMatch.group(1) ?? line.substring(0, line.length > 120 ? 120 : line.length).trim();
        }
      }

      if (shouldSkip(line)) continue;

      // Check for section header
      final sectionMatch = _sectionPattern.firstMatch(line);
      if (sectionMatch != null) {
        flush();
        category = sectionMatch.group(2)!
            .replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '')
            .trim();
        if (category.length > 80) category = category.substring(0, 80);
        continue;
      }

      // Check for unit+qty only line
      final uqMatch = _unitQtyPattern.firstMatch(line);
      if (uqMatch != null) {
        if (buffer.isNotEmpty) {
          String desc = buffer.join(' ').trim();
          String itemNo = '';
          
          final firstMatch = _itemStartPattern.firstMatch(desc);
          if (firstMatch != null) {
            itemNo = firstMatch.group(1) ?? '';
            desc = desc.substring(firstMatch.group(0)!.length).trim();
          }
          
          if (desc.isNotEmpty && desc.length <= 1000) {
            items.add(ExtractedBOQItem(
              itemNo: itemNo,
              description: desc,
              unit: uqMatch.group(1)!,
              quantity: uqMatch.group(2)!.replaceAll(',', ''),
              category: category,
            ));
          }
          buffer = [];
        }
        continue;
      }

      // Check for same-line item
      final slMatch = _sameLinePattern.firstMatch(line);
      if (slMatch != null) {
        flush();
        items.add(ExtractedBOQItem(
          itemNo: slMatch.group(1)!.trim(),
          description: slMatch.group(2)!.trim(),
          unit: slMatch.group(3)!.trim(),
          quantity: slMatch.group(4)!.replaceAll(',', ''),
          category: category,
        ));
        continue;
      }

      // Check for item start
      if (_itemStartPattern.hasMatch(line)) {
        flush();
        buffer = [line];
        continue;
      }

      // Continue building buffer
      if (buffer.isNotEmpty) {
        buffer.add(line);
      }
    }

    flush();

    if (items.isEmpty) {
      return const BOQExtractionResult(
        error: 'No BOQ items found in the PDF. The format may not be supported.',
      );
    }

    return BOQExtractionResult(
      items: items,
      projectName: projectName,
    );
  }

  /// Convert extracted items to table format
  static List<Map<String, dynamic>> mapToTableRows(List<ExtractedBOQItem> items, {int baseId = 0}) {
    return items.asMap().entries.map((entry) {
      return entry.value.toTableRow(baseId + entry.key);
    }).toList();
  }
}
