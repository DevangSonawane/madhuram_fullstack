import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';

/// Floor-wise configuration row (matches React Samples floor config)
class FloorConfig {
  final String floor;
  String config;
  int qty;
  final String unit;
  String status; // Locked | Draft

  FloorConfig({
    required this.floor,
    required this.config,
    required this.qty,
    required this.unit,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'floor': floor,
        'config': config,
        'qty': qty,
        'unit': unit,
        'status': status,
      };

  static FloorConfig fromJson(Map<String, dynamic> json) {
    return FloorConfig(
      floor: json['floor'] as String? ?? '',
      config: json['config'] as String? ?? '',
      qty: (json['qty'] is int) ? json['qty'] as int : int.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      unit: json['unit'] as String? ?? 'Points',
      status: json['status'] as String? ?? 'Draft',
    );
  }
}

/// Samples & Configuration page - floor plan upload, floor-wise config (matches React Samples.jsx)
class SamplesPageFull extends StatefulWidget {
  const SamplesPageFull({super.key});

  @override
  State<SamplesPageFull> createState() => _SamplesPageFullState();
}

class _SamplesPageFullState extends State<SamplesPageFull> {
  static const String _prefKey = 'samples_floor_config';

  static final List<FloorConfig> _initialFloorData = [
    FloorConfig(floor: 'Ground', config: 'CPVC 20mm - 5 points', qty: 5, unit: 'Points', status: 'Locked'),
    FloorConfig(floor: '1st', config: 'CPVC 25mm - 8 points', qty: 8, unit: 'Points', status: 'Draft'),
    FloorConfig(floor: '2nd', config: 'CPVC 20mm - 6 points', qty: 6, unit: 'Points', status: 'Draft'),
    FloorConfig(floor: '3rd', config: 'CPVC 32mm - 4 points', qty: 4, unit: 'Points', status: 'Locked'),
  ];

  String _workTypeFilter = 'CPVC'; // CPVC | Suspended
  List<FloorConfig> _floorConfigs = List.from(_initialFloorData);
  PlatformFile? _uploadedFile;
  bool _isExtracting = false;

  List<FloorConfig> get _filteredConfigs {
    // Filter by work type if needed (both types show same floor config in simplified version)
    return _floorConfigs;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _uploadedFile = result.files.single;
    });
  }

  void _extractPlaceholder() {
    setState(() => _isExtracting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isExtracting = false);
        showToast(context, 'Extraction placeholder – PDF extraction would run here');
      }
    });
  }

  void _toggleLock(FloorConfig row) {
    setState(() {
      final idx = _floorConfigs.indexWhere((e) => e.floor == row.floor);
      if (idx >= 0) {
        _floorConfigs[idx].status = _floorConfigs[idx].status == 'Locked' ? 'Draft' : 'Locked';
      }
    });
  }

  void _editRow(FloorConfig row) {
    final configCtrl = TextEditingController(text: row.config);
    final qtyCtrl = TextEditingController(text: row.qty.toString());

    MadFormDialog.show(
      context: context,
      title: 'Edit Configuration',
      maxWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MadInput(labelText: 'Floor', controller: TextEditingController(text: row.floor), enabled: false),
          const SizedBox(height: 16),
          MadInput(
            labelText: 'Configuration',
            controller: configCtrl,
          ),
          const SizedBox(height: 16),
          MadInput(
            labelText: 'Qty',
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          MadInput(labelText: 'Unit', controller: TextEditingController(text: row.unit), enabled: false),
        ],
      ),
      actions: [
        MadButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
        MadButton(
          text: 'Save',
          onPressed: () {
            setState(() {
              final idx = _floorConfigs.indexWhere((e) => e.floor == row.floor);
              if (idx >= 0) {
                _floorConfigs[idx].config = configCtrl.text;
                _floorConfigs[idx].qty = int.tryParse(qtyCtrl.text) ?? _floorConfigs[idx].qty;
              }
            });
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _exportToExcel() {
    showToast(context, 'Export to Excel – placeholder (data would be exported here)');
  }

  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _floorConfigs.map((e) => e.toJson()).toList();
      await prefs.setString(_prefKey, jsonEncode(list));
      if (mounted) showToast(context, 'Configuration saved successfully');
    } catch (_) {
      if (mounted) showToast(context, 'Failed to save configuration', variant: ToastVariant.error);
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        setState(() {
          _floorConfigs = list.map((e) => FloorConfig.fromJson(e)).toList();
        });
        if (mounted) showToast(context, 'Configuration loaded');
      } else {
        if (mounted) showToast(context, 'No saved configuration found');
      }
    } catch (_) {
      if (mounted) showToast(context, 'Failed to load configuration', variant: ToastVariant.error);
    }
  }

  void _showDiagramViewer() {
    MadDialog.show(
      context: context,
      title: 'Diagram Viewer',
      description: 'Extracted data would appear here',
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Diagram viewer – extracted data would appear here',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
            ),
          ),
        ),
      ),
      actions: [MadButton(text: 'Close', onPressed: () => Navigator.pop(context))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

    return ProtectedRoute(
      title: 'Samples & Configuration',
      route: '/samples',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Samples & Configuration',
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Floor plan upload and floor-wise configuration',
                      style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Wrap(
                  spacing: 8,
                  children: [
                    MadButton(
                      text: 'View Diagrams',
                      icon: LucideIcons.eye,
                      variant: ButtonVariant.outline,
                      onPressed: _showDiagramViewer,
                    ),
                    MadButton(
                      text: 'Export to Excel',
                      icon: LucideIcons.fileSpreadsheet,
                      variant: ButtonVariant.outline,
                      onPressed: _exportToExcel,
                    ),
                    MadButton(
                      text: 'Save Configuration',
                      icon: LucideIcons.save,
                      onPressed: _saveConfiguration,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),

          MadCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
                  ),
                  const SizedBox(height: 8),
                  MadTabsList(
                    tabs: const ['CPVC', 'Suspended'],
                    selectedTab: _workTypeFilter,
                    onTabChanged: (v) => setState(() => _workTypeFilter = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          MadCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Floor Plan Upload',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload PDF or image for floor plan. Extract to pull data from PDF.',
                    style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      MadButton(
                        text: 'Upload',
                        icon: LucideIcons.upload,
                        variant: ButtonVariant.outline,
                        onPressed: _pickFile,
                      ),
                      const SizedBox(width: 12),
                      if (_uploadedFile != null)
                        Expanded(
                          child: Text(
                            _uploadedFile!.name,
                            style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(width: 12),
                      MadButton(
                        text: 'Extract',
                        icon: _isExtracting ? null : LucideIcons.fileSearch,
                        onPressed: _uploadedFile != null && !_isExtracting ? _extractPlaceholder : null,
                        loading: _isExtracting,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Floor-wise Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
              ),
              if (isMobile)
                Row(
                  children: [
                    MadButton(text: 'View Diagrams', icon: LucideIcons.eye, variant: ButtonVariant.outline, size: ButtonSize.sm, onPressed: _showDiagramViewer),
                    const SizedBox(width: 8),
                    MadButton(text: 'Export', icon: LucideIcons.fileSpreadsheet, variant: ButtonVariant.outline, size: ButtonSize.sm, onPressed: _exportToExcel),
                    const SizedBox(width: 8),
                    MadButton(text: 'Save', icon: LucideIcons.save, size: ButtonSize.sm, onPressed: _saveConfiguration),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: MadCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        _buildHeaderCell('Floor', flex: 1, isDark: isDark),
                        _buildHeaderCell('Configuration', flex: 2, isDark: isDark),
                        _buildHeaderCell('Qty', flex: 1, isDark: isDark),
                        _buildHeaderCell('Unit', flex: 1, isDark: isDark),
                        _buildHeaderCell('Status', flex: 1, isDark: isDark),
                        if (!isMobile) _buildHeaderCell('Lock/Unlock', flex: 1, isDark: isDark),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _filteredConfigs.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5)),
                      itemBuilder: (context, index) {
                        final row = _filteredConfigs[index];
                        return _buildConfigRow(row, isDark, isMobile);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          MadButton(
            text: 'Load Saved Configuration',
            variant: ButtonVariant.outline,
            icon: LucideIcons.folderOpen,
            onPressed: _loadConfiguration,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, required bool isDark}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
      ),
    );
  }

  Widget _buildConfigRow(FloorConfig row, bool isDark, bool isMobile) {
    final isLocked = row.status == 'Locked';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(row.floor, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(row.config, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 1, child: Text('${row.qty}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 1, child: Text(row.unit, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground), overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 1,
            child: MadBadge(
              text: row.status,
              variant: isLocked ? BadgeVariant.default_ : BadgeVariant.outline,
            ),
          ),
          if (!isMobile)
            Expanded(
              flex: 1,
              child: MadSwitch(
                value: isLocked,
                onChanged: (v) => _toggleLock(row),
              ),
            ),
          MadButton(
            size: ButtonSize.sm,
            variant: ButtonVariant.outline,
            icon: LucideIcons.pencil,
            onPressed: () => _editRow(row),
          ),
        ],
      ),
    );
  }
}
