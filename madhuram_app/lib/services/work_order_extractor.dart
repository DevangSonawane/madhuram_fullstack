import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class WorkOrderExtractionResult {
  final String projectName;
  final String clientName;
  final String location;
  final String startDate;
  final String estimateValue;
  final String woNumber;
  final String? error;

  const WorkOrderExtractionResult({
    this.projectName = '',
    this.clientName = '',
    this.location = '',
    this.startDate = '',
    this.estimateValue = '',
    this.woNumber = '',
    this.error,
  });

  bool get success => error == null;
}

class WorkOrderExtractor {
  static final RegExp _projectNamePattern = RegExp(r'project\s*name\s*[:\-]\s*(.+)', caseSensitive: false);
  static final RegExp _clientPattern = RegExp(r'(client|customer)\s*(name)?\s*[:\-]\s*(.+)', caseSensitive: false);
  static final RegExp _locationPattern = RegExp(r'(location|site)\s*[:\-]\s*(.+)', caseSensitive: false);
  static final RegExp _startDatePattern = RegExp(
    r'(start\s*date|date)\s*[:\-]\s*([0-9]{1,2}[\/\-.][0-9]{1,2}[\/\-.][0-9]{2,4})',
    caseSensitive: false,
  );
  static final RegExp _woPattern = RegExp(r'(wo|work\s*order)\s*(no|number)?\s*[:\-]\s*([A-Za-z0-9\-\/]+)', caseSensitive: false);
  static final RegExp _valuePattern = RegExp(
    r'(estimate|estimated|value|amount)\s*(value|amount)?\s*[:\-]\s*([₹$]?\s*[\d,]+(?:\.\d+)?)',
    caseSensitive: false,
  );

  static Future<WorkOrderExtractionResult> extractFromFile(File file, {int maxPages = 5}) async {
    try {
      final bytes = await file.readAsBytes();
      return extractFromBytes(bytes, maxPages: maxPages);
    } catch (e) {
      return WorkOrderExtractionResult(error: 'Failed to read file: $e');
    }
  }

  static Future<WorkOrderExtractionResult> extractFromBytes(Uint8List bytes, {int maxPages = 5}) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      final int end = pageCount < maxPages ? pageCount : maxPages;

      final buffer = StringBuffer();
      for (int i = 0; i < end; i++) {
        final pageText = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        buffer.writeln(pageText);
      }
      document.dispose();

      final rawText = buffer.toString();
      if (rawText.trim().isEmpty) {
        return const WorkOrderExtractionResult(
          error: 'No text found in PDF. The PDF may be image-based or scanned.',
        );
      }
      return extractFromText(rawText);
    } catch (e) {
      return WorkOrderExtractionResult(error: 'Error reading PDF: $e');
    }
  }

  static WorkOrderExtractionResult extractFromText(String rawText) {
    String projectName = '';
    String clientName = '';
    String location = '';
    String startDate = '';
    String estimateValue = '';
    String woNumber = '';

    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final line in lines) {
      if (projectName.isEmpty) {
        final m = _projectNamePattern.firstMatch(line);
        if (m != null) projectName = m.group(1)?.trim() ?? '';
      }
      if (clientName.isEmpty) {
        final m = _clientPattern.firstMatch(line);
        if (m != null) clientName = m.group(3)?.trim() ?? '';
      }
      if (location.isEmpty) {
        final m = _locationPattern.firstMatch(line);
        if (m != null) location = m.group(2)?.trim() ?? '';
      }
      if (startDate.isEmpty) {
        final m = _startDatePattern.firstMatch(line);
        if (m != null) startDate = _normalizeDate(m.group(2)?.trim() ?? '');
      }
      if (woNumber.isEmpty) {
        final m = _woPattern.firstMatch(line);
        if (m != null) woNumber = m.group(3)?.trim() ?? '';
      }
      if (estimateValue.isEmpty) {
        final m = _valuePattern.firstMatch(line);
        if (m != null) estimateValue = (m.group(3) ?? '').trim();
      }
    }

    return WorkOrderExtractionResult(
      projectName: projectName,
      clientName: clientName,
      location: location,
      startDate: startDate,
      estimateValue: estimateValue,
      woNumber: woNumber,
    );
  }

  static String _normalizeDate(String input) {
    final parts = input.split(RegExp(r'[\/\-.]'));
    if (parts.length != 3) return input;
    int? d = int.tryParse(parts[0]);
    int? m = int.tryParse(parts[1]);
    int? y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return input;
    if (y < 100) y += 2000;
    final dd = d.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$y-$mm-$dd';
  }
}
