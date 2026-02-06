import 'dart:io';
import 'package:excel/excel.dart';
import 'file_service.dart';

/// Excel file handling service
class ExcelService {
  /// Create a new Excel workbook
  static Excel createWorkbook() {
    return Excel.createExcel();
  }

  /// Read an Excel file
  static Future<Excel?> readExcelFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return Excel.decodeBytes(bytes);
    } catch (e) {
      print('Error reading Excel file: $e');
    }
    return null;
  }

  /// Import Excel from file picker
  static Future<Excel?> importExcel() async {
    final file = await FileService.pickExcelFile();
    if (file != null) {
      return readExcelFile(file);
    }
    return null;
  }

  /// Save Excel workbook to file
  static Future<File?> saveExcel(Excel excel, String filename) async {
    try {
      final bytes = excel.encode();
      if (bytes != null) {
        return await FileService.saveFile(
          filename: filename.endsWith('.xlsx') ? filename : '$filename.xlsx',
          bytes: bytes,
          subfolder: 'exports',
        );
      }
    } catch (e) {
      print('Error saving Excel: $e');
    }
    return null;
  }

  /// Export Excel with save dialog
  static Future<String?> exportExcel(Excel excel, String filename) async {
    try {
      final bytes = excel.encode();
      if (bytes != null) {
        return await FileService.saveFileAs(
          filename: filename.endsWith('.xlsx') ? filename : '$filename.xlsx',
          bytes: bytes,
        );
      }
    } catch (e) {
      print('Error exporting Excel: $e');
    }
    return null;
  }

  /// Share Excel file
  static Future<void> shareExcel(Excel excel, String filename) async {
    try {
      final bytes = excel.encode();
      if (bytes != null) {
        final file = await FileService.saveFile(
          filename: filename.endsWith('.xlsx') ? filename : '$filename.xlsx',
          bytes: bytes,
          subfolder: 'temp',
        );
        if (file != null) {
          await FileService.shareFile(file, subject: filename);
        }
      }
    } catch (e) {
      print('Error sharing Excel: $e');
    }
  }

  /// Add header row with styling
  static void addHeaderRow(Sheet sheet, List<String> headers, {int rowIndex = 0}) {
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E5E7EB'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }
  }

  /// Add data row
  static void addDataRow(Sheet sheet, List<dynamic> values, int rowIndex) {
    for (int i = 0; i < values.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      final value = values[i];
      if (value is num) {
        cell.value = DoubleCellValue(value.toDouble());
      } else if (value is DateTime) {
        cell.value = DateCellValue(year: value.year, month: value.month, day: value.day);
      } else {
        cell.value = TextCellValue(value?.toString() ?? '');
      }
    }
  }

  /// Set column widths
  static void setColumnWidths(Sheet sheet, List<double> widths) {
    for (int i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  /// Export BOQ to Excel
  static Future<Excel> exportBOQToExcel({
    required String projectName,
    required List<Map<String, dynamic>> items,
  }) async {
    final excel = createWorkbook();
    final sheet = excel['BOQ'];

    // Title
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Bill of Quantities - $projectName');
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));

    // Headers
    addHeaderRow(sheet, ['S.No', 'Item Code', 'Description', 'Unit', 'Quantity', 'Rate', 'Amount'], rowIndex: 2);
    setColumnWidths(sheet, [8, 15, 40, 10, 12, 15, 18]);

    // Data
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      addDataRow(sheet, [
        i + 1,
        item['item_code'] ?? '',
        item['description'] ?? '',
        item['unit'] ?? '',
        item['quantity'] ?? 0,
        item['rate'] ?? 0,
        item['amount'] ?? (item['quantity'] ?? 0) * (item['rate'] ?? 0),
      ], i + 3);
    }

    // Total row
    final totalRow = items.length + 3;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow)).value = TextCellValue('Total:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow)).cellStyle = CellStyle(bold: true);
    
    final totalAmount = items.fold<num>(0, (sum, item) => sum + (item['amount'] ?? (item['quantity'] ?? 0) * (item['rate'] ?? 0)));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRow)).value = DoubleCellValue(totalAmount.toDouble());
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRow)).cellStyle = CellStyle(bold: true);

    // Remove default Sheet1
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel;
  }

  /// Export Materials to Excel
  static Future<Excel> exportMaterialsToExcel({
    required String projectName,
    required List<Map<String, dynamic>> materials,
  }) async {
    final excel = createWorkbook();
    final sheet = excel['Materials'];

    // Title
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Materials List - $projectName');
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));

    // Headers
    addHeaderRow(sheet, ['S.No', 'Material Code', 'Name', 'Category', 'Unit', 'Stock'], rowIndex: 2);
    setColumnWidths(sheet, [8, 15, 35, 20, 10, 12]);

    // Data
    for (int i = 0; i < materials.length; i++) {
      final mat = materials[i];
      addDataRow(sheet, [
        i + 1,
        mat['material_code'] ?? '',
        mat['name'] ?? '',
        mat['category'] ?? '',
        mat['unit'] ?? '',
        mat['stock'] ?? 0,
      ], i + 3);
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel;
  }

  /// Export Purchase Orders to Excel
  static Future<Excel> exportPurchaseOrdersToExcel({
    required String projectName,
    required List<Map<String, dynamic>> orders,
  }) async {
    final excel = createWorkbook();
    final sheet = excel['Purchase Orders'];

    // Title
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Purchase Orders - $projectName');
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));

    // Headers
    addHeaderRow(sheet, ['S.No', 'PO Number', 'Vendor', 'Date', 'Amount', 'Status', 'Items'], rowIndex: 2);
    setColumnWidths(sheet, [8, 15, 30, 15, 18, 12, 10]);

    // Data
    for (int i = 0; i < orders.length; i++) {
      final po = orders[i];
      addDataRow(sheet, [
        i + 1,
        po['po_number'] ?? '',
        po['vendor_name'] ?? '',
        po['date'] ?? '',
        po['total_amount'] ?? 0,
        po['status'] ?? '',
        po['items_count'] ?? 0,
      ], i + 3);
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel;
  }

  /// Import BOQ from Excel
  static List<Map<String, dynamic>>? parseBOQFromExcel(Excel excel) {
    try {
      final sheet = excel.tables.values.first;
      if (sheet.rows.length < 2) return null;

      final items = <Map<String, dynamic>>[];
      
      // Find header row (look for 'Description' or 'Item')
      int headerRow = 0;
      for (int i = 0; i < sheet.rows.length && i < 5; i++) {
        final row = sheet.rows[i];
        for (final cell in row) {
          if (cell?.value?.toString().toLowerCase().contains('description') == true ||
              cell?.value?.toString().toLowerCase().contains('item') == true) {
            headerRow = i;
            break;
          }
        }
      }

      // Map column indices
      final headers = <int, String>{};
      final headerRowData = sheet.rows[headerRow];
      for (int i = 0; i < headerRowData.length; i++) {
        final value = headerRowData[i]?.value?.toString().toLowerCase() ?? '';
        if (value.contains('code')) headers[i] = 'item_code';
        else if (value.contains('desc')) headers[i] = 'description';
        else if (value.contains('unit')) headers[i] = 'unit';
        else if (value.contains('qty') || value.contains('quantity')) headers[i] = 'quantity';
        else if (value.contains('rate') || value.contains('price')) headers[i] = 'rate';
        else if (value.contains('amount') || value.contains('total')) headers[i] = 'amount';
      }

      // Parse data rows
      for (int i = headerRow + 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.every((cell) => cell?.value == null)) continue;

        final item = <String, dynamic>{};
        for (final entry in headers.entries) {
          final cell = row.length > entry.key ? row[entry.key] : null;
          final value = cell?.value;
          if (entry.value == 'quantity' || entry.value == 'rate' || entry.value == 'amount') {
            item[entry.value] = value is num ? value : double.tryParse(value?.toString() ?? '') ?? 0;
          } else {
            item[entry.value] = value?.toString() ?? '';
          }
        }
        
        if (item.isNotEmpty && (item['description']?.toString().isNotEmpty == true)) {
          items.add(item);
        }
      }

      return items.isEmpty ? null : items;
    } catch (e) {
      print('Error parsing BOQ Excel: $e');
    }
    return null;
  }
}
