import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../components/layout/main_layout.dart';
import '../components/ui/components.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class VendorPriceListCreatePage extends StatefulWidget {
  final String vendorId;
  final String? projectId;

  const VendorPriceListCreatePage({
    super.key,
    required this.vendorId,
    this.projectId,
  });

  @override
  State<VendorPriceListCreatePage> createState() =>
      _VendorPriceListCreatePageState();
}

class _VendorPriceListCreatePageState extends State<VendorPriceListCreatePage> {
  static const List<String> _statusValues = ['active', 'inactive', 'archived'];

  final TextEditingController _versionNameController = TextEditingController();
  final TextEditingController _filenameController = TextEditingController();
  final TextEditingController _filePathController = TextEditingController();

  String _status = 'active';
  bool _uploading = false;
  bool _creating = false;
  File? _selectedFile;

  List<Map<String, String>> _items = [_emptyItem()];

  static Map<String, String> _emptyItem() => {
    'items_name': '',
    'hsn_code': '',
    'item_code': '',
    'category': '',
    'product_name': '',
    'size_inch': '',
    'size_mm': '',
    'price_per_pic': '',
    'discount_price': '',
    'net_price': '',
  };

  @override
  void dispose() {
    _versionNameController.dispose();
    _filenameController.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  String _toTitle(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String? _resolveFilePath(Map<String, dynamic>? data) {
    if (data == null) return null;
    final direct = data['file_path'] ?? data['path'] ?? data['url'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }
    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      final nestedPath =
          nested['file_path'] ??
          nested['path'] ??
          nested['url'] ??
          nested['filePath'];
      if (nestedPath != null && nestedPath.toString().trim().isNotEmpty) {
        return nestedPath.toString();
      }
    }
    return null;
  }

  Future<void> _pickAndUploadFile() async {
    final picked = await FilePicker.platform.pickFiles(withData: false);
    if (picked == null || picked.files.isEmpty) return;

    final filePath = picked.files.first.path;
    if (filePath == null || filePath.isEmpty) return;

    final file = File(filePath);
    setState(() {
      _selectedFile = file;
      _uploading = true;
    });

    final uploadResult = await ApiClient.uploadVendorPriceListFile(file);
    if (!mounted) return;

    if (uploadResult['success'] == true) {
      final resultData = uploadResult['data'] is Map<String, dynamic>
          ? uploadResult['data'] as Map<String, dynamic>
          : null;
      final resolvedPath = _resolveFilePath(resultData) ?? '';
      final resolvedName = (resultData?['filename'] ?? '').toString();
      setState(() {
        _filenameController.text = resolvedName;
        _filePathController.text = resolvedPath;
      });
      showToast(context, 'Upload successful');
    } else {
      showToast(
        context,
        uploadResult['error']?.toString() ?? 'Upload failed',
        variant: ToastVariant.error,
      );
    }

    if (mounted) {
      setState(() {
        _uploading = false;
      });
    }
  }

  void _addItemRow() {
    setState(() {
      _items = [..._items, _emptyItem()];
    });
  }

  void _removeItemRow(int index) {
    if (_items.length == 1) return;
    setState(() {
      _items = _items
          .asMap()
          .entries
          .where((entry) => entry.key != index)
          .map((entry) => entry.value)
          .toList();
    });
  }

  void _updateItem(int index, String key, String value) {
    final next = [..._items];
    next[index] = {...next[index], key: value};
    setState(() {
      _items = next;
    });
  }

  Future<void> _createPriceList() async {
    final versionName = _versionNameController.text.trim();
    if (versionName.isEmpty) {
      showToast(
        context,
        'Version Name is required',
        variant: ToastVariant.error,
      );
      return;
    }

    setState(() {
      _creating = true;
    });

    final payload = <String, dynamic>{
      'vendor_id': int.tryParse(widget.vendorId) ?? widget.vendorId,
      'version_name': versionName,
      'status': _status,
      if (_filenameController.text.trim().isNotEmpty)
        'filename': _filenameController.text.trim(),
      if (_filePathController.text.trim().isNotEmpty)
        'file_path': _filePathController.text.trim(),
      'items': _items,
    };

    final result = await ApiClient.createVendorPriceList(payload);
    if (!mounted) return;

    if (result['success'] == true) {
      showToast(context, 'Price list created');
      Navigator.pop(context, true);
    } else {
      showToast(
        context,
        result['error']?.toString() ?? 'Create failed',
        variant: ToastVariant.error,
      );
    }

    if (mounted) {
      setState(() {
        _creating = false;
      });
    }
  }

  Widget _buildItemCard(int index, bool isDark) {
    final row = _items[index];
    final itemNumber = index + 1;

    Widget field(
      String key,
      String label, {
      TextInputType keyboardType = TextInputType.text,
    }) {
      return SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('item-$index-$key'),
              initialValue: row[key] ?? '',
              keyboardType: keyboardType,
              onChanged: (value) => _updateItem(index, key, value),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Item $itemNumber',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                MadButton(
                  text: 'Remove',
                  icon: LucideIcons.trash2,
                  variant: ButtonVariant.destructive,
                  size: ButtonSize.sm,
                  disabled: _items.length == 1,
                  onPressed: () => _removeItemRow(index),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                field('items_name', 'Item Name'),
                field('product_name', 'Product Name'),
                field('category', 'Category'),
                field('item_code', 'Item Code'),
                field('hsn_code', 'HSN Code'),
                field('size_inch', 'Size (Inch)'),
                field('size_mm', 'Size (MM)'),
                field(
                  'price_per_pic',
                  'Price Per Piece',
                  keyboardType: TextInputType.number,
                ),
                field(
                  'discount_price',
                  'Discount Price',
                  keyboardType: TextInputType.number,
                ),
                field(
                  'net_price',
                  'Net Price',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ProtectedRoute(
      title: 'Create Price List',
      route: '/vendors',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MadButton(
                text: 'Back to Price Lists',
                icon: LucideIcons.arrowLeft,
                variant: ButtonVariant.outline,
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Create Price List',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a new vendor price list with optional file upload.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkMutedForeground
                  : AppTheme.lightMutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 240,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vendor ID',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(widget.vendorId),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 320,
                            child: MadInput(
                              labelText: 'Version Name *',
                              controller: _versionNameController,
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: _statusValues
                                  .map(
                                    (status) => DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(_toTitle(status)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _status = value ?? 'active';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload File',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Drag and drop equivalent flow: choose a file to upload.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkMutedForeground
                                  : AppTheme.lightMutedForeground,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              MadButton(
                                text: _uploading
                                    ? 'Uploading...'
                                    : 'Choose File',
                                icon: LucideIcons.upload,
                                variant: ButtonVariant.outline,
                                loading: _uploading,
                                onPressed: _uploading
                                    ? null
                                    : _pickAndUploadFile,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedFile?.path.split('/').last ??
                                      'No file selected',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.darkMutedForeground
                                        : AppTheme.lightMutedForeground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              SizedBox(
                                width: 320,
                                child: MadInput(
                                  labelText: 'File Name',
                                  controller: _filenameController,
                                ),
                              ),
                              SizedBox(
                                width: 520,
                                child: MadInput(
                                  labelText: 'File Path',
                                  controller: _filePathController,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Manual Item Entry',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              MadButton(
                                text: 'Add Item',
                                icon: LucideIcons.plus,
                                variant: ButtonVariant.outline,
                                size: ButtonSize.sm,
                                onPressed: _addItemRow,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Total items: ${_items.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkMutedForeground
                                  : AppTheme.lightMutedForeground,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._items.asMap().entries.map(
                            (entry) => _buildItemCard(entry.key, isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MadButton(
                        text: 'Cancel',
                        variant: ButtonVariant.outline,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      MadButton(
                        text: _creating ? 'Creating...' : 'Create Price List',
                        loading: _creating,
                        onPressed: _creating ? null : _createPriceList,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
