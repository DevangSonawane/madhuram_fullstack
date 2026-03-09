import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/layout/main_layout.dart';
import '../components/ui/components.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class SampleCreatePage extends StatefulWidget {
  final String initialProjectId;

  const SampleCreatePage({super.key, this.initialProjectId = ''});

  @override
  State<SampleCreatePage> createState() => _SampleCreatePageState();
}

class _SampleCreatePageState extends State<SampleCreatePage> {
  bool _saving = false;
  String _projectId = '';
  final TextEditingController _projectIdController = TextEditingController();
  List<String> _uploadFilePaths = [];
  String _selectedUploadedFile = '';
  String _itemFieldKey = '';
  String _itemFieldValue = '';
  int? _itemFieldRowIndex;

  final Map<String, dynamic> _createForm = {
    'building_name': '',
    'site_name': '',
    'work_done': '',
    'sample_file': '',
    'location': {'floor': '', 'block': '', 'wing': '', 'coordinates': ''},
    'item_description': [
      {
        'sr_no': '',
        'description': '',
        'quantity': '',
        'value': '',
        'add_fields': [],
      },
    ],
    'add_fields': [],
  };

  @override
  void initState() {
    super.initState();
    _projectId = widget.initialProjectId;
    _projectIdController.text = _projectId;
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    super.dispose();
  }

  Future<void> _uploadSampleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final files = <File>[];
    for (final f in result.files) {
      if (f.path != null) files.add(File(f.path!));
    }
    if (files.isEmpty) return;

    final res = await ApiClient.uploadSampleFiles(files);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'] as Map?;
      final filePaths =
          (data?['filePaths'] as List?)?.map((e) => e.toString()).toList() ??
          [];
      setState(() {
        _uploadFilePaths = filePaths;
        if (filePaths.isNotEmpty) {
          _selectedUploadedFile = filePaths.first;
          _createForm['sample_file'] = filePaths.first;
        }
      });
      showToast(context, 'Uploaded ${filePaths.length} file(s)');
    } else {
      showToast(
        context,
        res['error']?.toString() ?? 'Upload failed',
        variant: ToastVariant.error,
      );
    }
  }

  Future<void> _saveSample() async {
    final projectId = _projectIdController.text.trim();
    if (projectId.isEmpty) {
      showToast(context, 'Select a project first', variant: ToastVariant.error);
      return;
    }
    setState(() => _saving = true);
    final payload = Map<String, dynamic>.from(_createForm);
    payload['project_id'] = projectId;
    final res = await ApiClient.createSample(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['success'] == true) {
      showToast(context, 'Sample created');
      Navigator.pop(context, true);
    } else {
      showToast(
        context,
        res['error']?.toString() ?? 'Create failed',
        variant: ToastVariant.error,
      );
    }
  }

  void _removeItemField(int rowIndex, int fieldIndex) {
    final items = List<Map<String, dynamic>>.from(
      _createForm['item_description'] as List,
    );
    if (rowIndex < 0 || rowIndex >= items.length) return;
    final item = Map<String, dynamic>.from(items[rowIndex]);
    final fields = List<Map<String, dynamic>>.from(
      item['add_fields'] as List? ?? [],
    );
    if (fieldIndex < 0 || fieldIndex >= fields.length) return;
    fields.removeAt(fieldIndex);
    item['add_fields'] = fields;
    items[rowIndex] = item;
    setState(() => _createForm['item_description'] = items);
  }

  Future<void> _openAttachmentPreview() async {
    if (_selectedUploadedFile.trim().isEmpty) return;
    final uri = Uri.parse(
      ApiClient.getApiFileUrl(_selectedUploadedFile.trim()),
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      showToast(
        context,
        'Could not open attachment',
        variant: ToastVariant.error,
      );
    }
  }

  void _openItemFieldDialog(int rowIndex) {
    _itemFieldRowIndex = rowIndex;
    _itemFieldKey = '';
    _itemFieldValue = '';
    MadFormDialog.show(
      context: context,
      title: 'Add Item Field',
      maxWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadInput(labelText: 'Key', onChanged: (v) => _itemFieldKey = v),
          const SizedBox(height: 12),
          MadInput(labelText: 'Value', onChanged: (v) => _itemFieldValue = v),
        ],
      ),
      actions: [
        MadButton(
          text: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        MadButton(
          text: 'Add',
          onPressed: () {
            final key = _itemFieldKey.trim();
            final value = _itemFieldValue.trim();
            if (key.isEmpty || value.isEmpty || _itemFieldRowIndex == null) {
              showToast(
                context,
                'Enter both key and value',
                variant: ToastVariant.error,
              );
              return;
            }
            final items = List<Map<String, dynamic>>.from(
              _createForm['item_description'] as List,
            );
            final item = Map<String, dynamic>.from(items[_itemFieldRowIndex!]);
            final fields = List<Map<String, dynamic>>.from(
              item['add_fields'] as List? ?? [],
            );
            fields.add({'key': key, 'value': value});
            item['add_fields'] = fields;
            items[_itemFieldRowIndex!] = item;
            setState(() => _createForm['item_description'] = items);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;
    final location = Map<String, dynamic>.from(_createForm['location'] as Map);
    final items = List<Map<String, dynamic>>.from(
      _createForm['item_description'] as List,
    );
    final additional = List<Map<String, dynamic>>.from(
      _createForm['add_fields'] as List,
    );

    return ProtectedRoute(
      title: 'Create Sample',
      route: '/samples/create',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Sample',
                  style: TextStyle(
                    fontSize: responsive.value(
                      mobile: 22,
                      tablet: 26,
                      desktop: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.darkForeground
                        : AppTheme.lightForeground,
                  ),
                ),
                MadButton(
                  text: 'Back',
                  icon: LucideIcons.arrowLeft,
                  variant: ButtonVariant.outline,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MadCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile) ...[
                      MadInput(
                        labelText: 'Project ID',
                        hintText: 'Enter project id',
                        controller: _projectIdController,
                        onChanged: (v) => _projectId = v,
                      ),
                      const SizedBox(height: 12),
                      MadInput(
                        labelText: 'Building name',
                        hintText: 'Building A',
                        onChanged: (v) => _createForm['building_name'] = v,
                      ),
                      const SizedBox(height: 12),
                      MadInput(
                        labelText: 'Site name',
                        hintText: 'Site 1',
                        onChanged: (v) => _createForm['site_name'] = v,
                      ),
                      const SizedBox(height: 12),
                      MadInput(
                        labelText: 'Work done',
                        hintText: 'CPVC',
                        onChanged: (v) => _createForm['work_done'] = v,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: MadInput(
                              labelText: 'Project ID',
                              hintText: 'Enter project id',
                              controller: _projectIdController,
                              onChanged: (v) => _projectId = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MadInput(
                              labelText: 'Building name',
                              hintText: 'Building A',
                              onChanged: (v) =>
                                  _createForm['building_name'] = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MadInput(
                              labelText: 'Site name',
                              hintText: 'Site 1',
                              onChanged: (v) => _createForm['site_name'] = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MadInput(
                              labelText: 'Work done',
                              hintText: 'CPVC',
                              onChanged: (v) => _createForm['work_done'] = v,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (isMobile) ...[
                      MadInput(
                        labelText: 'Floor',
                        onChanged: (v) {
                          location['floor'] = v;
                          _createForm['location'] = location;
                        },
                      ),
                      const SizedBox(height: 12),
                      MadInput(
                        labelText: 'Block',
                        onChanged: (v) {
                          location['block'] = v;
                          _createForm['location'] = location;
                        },
                      ),
                      const SizedBox(height: 12),
                      MadInput(
                        labelText: 'Wing',
                        onChanged: (v) {
                          location['wing'] = v;
                          _createForm['location'] = location;
                        },
                      ),
                      const SizedBox(height: 12),
                      MadInput(
                        labelText: 'Coordinates',
                        onChanged: (v) {
                          location['coordinates'] = v;
                          _createForm['location'] = location;
                        },
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: MadInput(
                              labelText: 'Floor',
                              onChanged: (v) {
                                location['floor'] = v;
                                _createForm['location'] = location;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MadInput(
                              labelText: 'Block',
                              onChanged: (v) {
                                location['block'] = v;
                                _createForm['location'] = location;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MadInput(
                              labelText: 'Wing',
                              onChanged: (v) {
                                location['wing'] = v;
                                _createForm['location'] = location;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MadInput(
                              labelText: 'Coordinates',
                              onChanged: (v) {
                                location['coordinates'] = v;
                                _createForm['location'] = location;
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MadSelect<String>(
                            value: _selectedUploadedFile.isEmpty
                                ? null
                                : _selectedUploadedFile,
                            placeholder: _uploadFilePaths.isEmpty
                                ? 'Upload files first'
                                : 'Select uploaded file',
                            options: _uploadFilePaths
                                .map((e) => MadSelectOption(value: e, label: e))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedUploadedFile = v ?? '';
                                _createForm['sample_file'] =
                                    _selectedUploadedFile;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        MadButton(
                          text: 'Upload',
                          icon: LucideIcons.upload,
                          variant: ButtonVariant.outline,
                          onPressed: _uploadSampleFiles,
                        ),
                        const SizedBox(width: 8),
                        MadButton(
                          text: 'Preview',
                          icon: LucideIcons.eye,
                          variant: ButtonVariant.outline,
                          onPressed: _selectedUploadedFile.isEmpty
                              ? null
                              : _openAttachmentPreview,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Item Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkForeground
                            : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MadCard(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: MadInput(
                                        labelText: 'Sr No',
                                        onChanged: (v) {
                                          items[i]['sr_no'] = v;
                                          _createForm['item_description'] =
                                              items;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: MadInput(
                                        labelText: 'Qty',
                                        onChanged: (v) {
                                          items[i]['quantity'] = v;
                                          _createForm['item_description'] =
                                              items;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: MadInput(
                                        labelText: 'Value',
                                        onChanged: (v) {
                                          items[i]['value'] = v;
                                          _createForm['item_description'] =
                                              items;
                                        },
                                      ),
                                    ),
                                    if (items.length > 1) ...[
                                      const SizedBox(width: 12),
                                      MadButton(
                                        icon: LucideIcons.trash2,
                                        variant: ButtonVariant.outline,
                                        size: ButtonSize.sm,
                                        onPressed: () {
                                          setState(() {
                                            items.removeAt(i);
                                            _createForm['item_description'] =
                                                items;
                                          });
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                MadTextarea(
                                  labelText: 'Description',
                                  minLines: 2,
                                  onChanged: (v) {
                                    items[i]['description'] = v;
                                    _createForm['item_description'] = items;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: MadButton(
                                    text: 'Add Item Field',
                                    icon: LucideIcons.plus,
                                    size: ButtonSize.sm,
                                    variant: ButtonVariant.outline,
                                    onPressed: () => _openItemFieldDialog(i),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (
                                      int fieldIndex = 0;
                                      fieldIndex <
                                          (items[i]['add_fields'] as List? ??
                                                  [])
                                              .length;
                                      fieldIndex++
                                    )
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MadBadge(
                                            text:
                                                '${(items[i]['add_fields'] as List)[fieldIndex]['key'] ?? ''}: ${(items[i]['add_fields'] as List)[fieldIndex]['value'] ?? ''}',
                                            variant: BadgeVariant.outline,
                                          ),
                                          const SizedBox(width: 4),
                                          MadButton(
                                            icon: LucideIcons.x,
                                            size: ButtonSize.sm,
                                            variant: ButtonVariant.outline,
                                            onPressed: () =>
                                                _removeItemField(i, fieldIndex),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    MadButton(
                      text: 'Add Item',
                      icon: LucideIcons.plus,
                      variant: ButtonVariant.outline,
                      onPressed: () {
                        setState(() {
                          items.add({
                            'sr_no': '',
                            'description': '',
                            'quantity': '',
                            'value': '',
                            'add_fields': [],
                          });
                          _createForm['item_description'] = items;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Additional Fields',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkForeground
                            : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < additional.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: MadInput(
                                labelText: 'Key',
                                onChanged: (v) {
                                  additional[i]['key'] = v;
                                  _createForm['add_fields'] = additional;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MadInput(
                                labelText: 'Value',
                                onChanged: (v) {
                                  additional[i]['value'] = v;
                                  _createForm['add_fields'] = additional;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            MadButton(
                              icon: LucideIcons.trash2,
                              size: ButtonSize.sm,
                              variant: ButtonVariant.outline,
                              onPressed: () {
                                setState(() {
                                  additional.removeAt(i);
                                  _createForm['add_fields'] = additional;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    MadButton(
                      text: 'Add Field',
                      icon: LucideIcons.plus,
                      variant: ButtonVariant.outline,
                      onPressed: () {
                        setState(() {
                          additional.add({'key': '', 'value': ''});
                          _createForm['add_fields'] = additional;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        MadButton(
                          text: _saving ? 'Saving...' : 'Save Sample',
                          icon: LucideIcons.save,
                          onPressed: _saving ? null : _saveSample,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
