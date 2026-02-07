import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../services/file_service.dart';
import '../models/mir.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../demo_data/additional_modules_demo.dart';
import '../utils/responsive.dart';

const _mirDraftKey = 'mir_draft';

/// Material Inspection Request page with tabbed interface: Upload & Extract, Manual Entry, Recent MIRs
class MIRPageFull extends StatefulWidget {
  const MIRPageFull({super.key});
  @override
  State<MIRPageFull> createState() => _MIRPageFullState();
}

class _MIRPageFullState extends State<MIRPageFull> {
  // Tabs
  int _selectedTabIndex = 0;

  // Upload & Extract
  File? _selectedPdfFile;
  bool _isExtracting = false;
  bool _isUploading = false;

  // Manual form controllers
  final _mirRefController = TextEditingController();
  final _materialCodeController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _pmcController = TextEditingController();
  final _contractorController = TextEditingController();
  final _vendorCodeController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _projectCodeController = TextEditingController();
  final _inspectionDateController = TextEditingController();
  final _inspectionTimeController = TextEditingController();
  final _clientSubmissionDateController = TextEditingController();
  final _inspectionEngineerController = TextEditingController();
  final _submittedToController = TextEditingController();

  // Discipline checkboxes (dynamic fields)
  final Set<String> _discipline = {};

  // Reference documents attached (Yes/No toggles)
  bool _refDrawing = false;
  bool _refTestCertificates = false;
  bool _refMethodStatement = false;
  bool _refChecklist = false;

  // Recent MIRs list – START WITH DEMO DATA
  bool _isLoading = true;
  List<MIR> _mirs = MIRDemo.mirs.map((e) => MIR.fromJson(e)).toList();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMIRs();
      _loadDraft();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mirRefController.dispose();
    _materialCodeController.dispose();
    _clientNameController.dispose();
    _pmcController.dispose();
    _contractorController.dispose();
    _vendorCodeController.dispose();
    _projectNameController.dispose();
    _projectCodeController.dispose();
    _inspectionDateController.dispose();
    _inspectionTimeController.dispose();
    _clientSubmissionDateController.dispose();
    _inspectionEngineerController.dispose();
    _submittedToController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_mirDraftKey);
      if (json == null) return;
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _mirRefController.text = map['mir_refrence_no'] as String? ?? '';
        _materialCodeController.text = map['material_code'] as String? ?? '';
        _clientNameController.text = map['client_name'] as String? ?? '';
        _pmcController.text = map['pmc'] as String? ?? '';
        _contractorController.text = map['contractor'] as String? ?? '';
        _vendorCodeController.text = map['vendor_code'] as String? ?? '';
        _projectNameController.text = map['project_name'] as String? ?? '';
        _projectCodeController.text = map['project_code'] as String? ?? '';
        _inspectionDateController.text = map['inspection_date'] as String? ?? '';
        _inspectionTimeController.text = map['inspection_time'] as String? ?? '';
        _clientSubmissionDateController.text = map['client_submission_date'] as String? ?? '';
        _inspectionEngineerController.text = map['inspection_engineer'] as String? ?? '';
        _submittedToController.text = map['submitted_to'] as String? ?? '';
        _discipline.clear();
        final disc = map['discipline'];
        if (disc is List) {
          for (final e in disc) {
            _discipline.add(e.toString());
          }
        }
        _refDrawing = map['ref_drawing'] == true;
        _refTestCertificates = map['ref_test_certificates'] == true;
        _refMethodStatement = map['ref_method_statement'] == true;
        _refChecklist = map['ref_checklist'] == true;
      });
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    final map = _manualFormToMap();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mirDraftKey, jsonEncode(map));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved')),
    );
  }

  Future<void> _pickDate(TextEditingController c) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) c.text = DateFormat('yyyy-MM-dd').format(date);
  }

  Map<String, dynamic> _manualFormToMap() {
    final refList = <String>[];
    if (_refDrawing) refList.add('Drawing');
    if (_refTestCertificates) refList.add('Test Certificates');
    if (_refMethodStatement) refList.add('Method Statement');
    if (_refChecklist) refList.add('Checklist');
    return {
      'mir_refrence_no': _mirRefController.text.trim(),
      'material_code': _materialCodeController.text.trim(),
      'client_name': _clientNameController.text.trim(),
      'pmc': _pmcController.text.trim(),
      'contractor': _contractorController.text.trim(),
      'vendor_code': _vendorCodeController.text.trim(),
      'project_name': _projectNameController.text.trim(),
      'project_code': _projectCodeController.text.trim(),
      'inspection_date': _inspectionDateController.text.trim(),
      'inspection_time': _inspectionTimeController.text.trim(),
      'client_submission_date': _clientSubmissionDateController.text.trim(),
      'inspection_engineer': _inspectionEngineerController.text.trim(),
      'submitted_to': _submittedToController.text.trim(),
      'discipline': _discipline.toList(),
      'ref_drawing': _refDrawing,
      'ref_test_certificates': _refTestCertificates,
      'ref_method_statement': _refMethodStatement,
      'ref_checklist': _refChecklist,
    };
  }

  Map<String, dynamic> _mirToPreviewMap(MIR mir) {
    final refs = mir.referenceDocsAttached ?? [];
    return {
      'mir_refrence_no': mir.mirRefNo,
      'material_code': mir.materialCode ?? '',
      'client_name': mir.clientName ?? '',
      'pmc': mir.pmc ?? '',
      'contractor': mir.contractor ?? '',
      'vendor_code': mir.vendorCode ?? '',
      'project_name': mir.projectName ?? '',
      'project_code': mir.projectCode ?? '',
      'inspection_date': mir.inspectionDateTime ?? '',
      'inspection_time': '',
      'client_submission_date': mir.clientSubmissionDate ?? '',
      'inspection_engineer': mir.inspectionEngineer ?? '',
      'submitted_to': mir.mirSubmittedTo ?? '',
      'discipline': const [],
      'ref_drawing': refs.any((e) => e.toLowerCase().contains('drawing')),
      'ref_test_certificates': refs.any((e) => e.toLowerCase().contains('test')),
      'ref_method_statement': refs.any((e) => e.toLowerCase().contains('method')),
      'ref_checklist': refs.any((e) => e.toLowerCase().contains('checklist')),
    };
  }

  Map<String, dynamic> _manualFormToApiPayload() {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProject?['project_id']?.toString() ??
        store.state.project.selectedProjectId ?? '';
    final refList = <String>[];
    if (_refDrawing) refList.add('Drawing');
    if (_refTestCertificates) refList.add('Test Certificates');
    if (_refMethodStatement) refList.add('Method Statement');
    if (_refChecklist) refList.add('Checklist');
    final inspectionDate = _inspectionDateController.text.trim();
    final inspectionTime = _inspectionTimeController.text.trim();
    final inspectionDateTime = inspectionDate.isNotEmpty && inspectionTime.isNotEmpty
        ? '$inspectionDate $inspectionTime'
        : (inspectionDate.isNotEmpty ? inspectionDate : inspectionTime);
    return {
      if (projectId.isNotEmpty) 'project_id': projectId,
      'mir_refrence_no': _mirRefController.text.trim(),
      'material_code': _materialCodeController.text.trim().isEmpty ? null : _materialCodeController.text.trim(),
      'client_name': _clientNameController.text.trim().isEmpty ? null : _clientNameController.text.trim(),
      'pmc': _pmcController.text.trim().isEmpty ? null : _pmcController.text.trim(),
      'contractor': _contractorController.text.trim().isEmpty ? null : _contractorController.text.trim(),
      'vendor_code': _vendorCodeController.text.trim().isEmpty ? null : _vendorCodeController.text.trim(),
      'project_name': _projectNameController.text.trim().isEmpty ? null : _projectNameController.text.trim(),
      'project_code': _projectCodeController.text.trim().isEmpty ? null : _projectCodeController.text.trim(),
      'inspection_date_time': inspectionDateTime.isEmpty ? null : inspectionDateTime,
      'client_submission_date': _clientSubmissionDateController.text.trim().isEmpty ? null : _clientSubmissionDateController.text.trim(),
      'inspection_engineer': _inspectionEngineerController.text.trim().isEmpty ? null : _inspectionEngineerController.text.trim(),
      'mir_submitted_to': _submittedToController.text.trim().isEmpty ? null : _submittedToController.text.trim(),
      'discipline': _discipline.isEmpty ? null : _discipline.toList(),
      'refrence_docs_attached': refList.isEmpty ? null : refList,
      'dynamic_field': {
        'Discipline': _discipline.toList(),
        'Inspection Engineer': _inspectionEngineerController.text.trim(),
        'MIR Submitted To': _submittedToController.text.trim(),
      },
    };
  }

  void _seedDemoMIRs() {
    debugPrint('[MIR] API unavailable – falling back to demo data');
    setState(() {
      _mirs = MIRDemo.mirs.map((e) => MIR.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadMIRs() async {
    setState(() {
      _isLoading = true;
    });
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';

    if (projectId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ApiClient.getMIRsByProject(projectId);
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'] as List;
        final loaded = data.map((e) => MIR.fromJson(e)).toList();
        if (loaded.isEmpty) {
          _seedDemoMIRs();
        } else {
          setState(() {
            _mirs = loaded;
            _isLoading = false;
          });
        }
      } else {
        _seedDemoMIRs();
      }
    } catch (e) {
      debugPrint('[MIR] API error: $e – falling back to demo data');
      if (!mounted) return;
      _seedDemoMIRs();
    }
  }

  List<MIR> get _filteredMIRs {
    List<MIR> result = _mirs;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((m) =>
              m.mirReferenceNo.toLowerCase().contains(query) ||
              (m.materialCode?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    if (_statusFilter != null) result = result.where((m) => m.status == _statusFilter).toList();
    return result;
  }

  List<MIR> get _paginatedMIRs {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredMIRs;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredMIRs.length / _itemsPerPage).ceil().clamp(1, 999999);

  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabButton(isDark, 0, 'Upload & Extract', LucideIcons.fileUp),
          _tabButton(isDark, 1, 'Manual Entry', LucideIcons.pencilLine),
          _tabButton(isDark, 2, 'Recent MIRs', LucideIcons.list),
        ],
      ),
    );
  }

  Widget _tabButton(bool isDark, int index, String label, IconData icon) {
    final selected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? (isDark ? AppTheme.darkCard : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? (isDark ? AppTheme.darkForeground : AppTheme.lightForeground) : (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? (isDark ? AppTheme.darkForeground : AppTheme.lightForeground) : (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

    return ProtectedRoute(
      title: 'Material Inspection Request',
      route: '/mir',
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
                      'Material Inspection Request',
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload, extract, or create MIRs manually',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'New MIR',
                  icon: LucideIcons.plus,
                  onPressed: () => setState(() => _selectedTabIndex = 0),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTabBar(isDark),
          const SizedBox(height: 16),
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildUploadExtractTab(isDark),
                _buildManualEntryTab(isDark, isMobile),
                _buildRecentMIRsTab(isDark, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadExtractTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MadCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload MIR PDF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a PDF file to upload as reference document. Use Extract to process the file (processing message shown for now).',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              MadButton(
                icon: LucideIcons.fileUp,
                text: 'Choose PDF file',
                variant: ButtonVariant.outline,
                onPressed: _isUploading ? null : () async {
                  final file = await FileService.pickPdfFile();
                  if (!mounted) return;
                  setState(() => _selectedPdfFile = file);
                },
              ),
              if (_selectedPdfFile != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.fileText, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedPdfFile!.path.split(RegExp(r'[/\\]')).last,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _isUploading
                            ? null
                            : () => setState(() => _selectedPdfFile = null),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  MadButton(
                    text: 'Extract',
                    icon: LucideIcons.scanSearch,
                    onPressed: _selectedPdfFile == null || _isExtracting
                        ? null
                        : () async {
                            setState(() => _isExtracting = true);
                            await Future.delayed(const Duration(seconds: 2));
                            if (!mounted) return;
                            setState(() => _isExtracting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Extraction in progress. Backend processing will be integrated.')),
                            );
                          },
                  ),
                  const SizedBox(width: 12),
                  MadButton(
                    text: _isUploading ? 'Uploading...' : 'Upload reference doc',
                    icon: LucideIcons.upload,
                    onPressed: _selectedPdfFile == null || _isUploading
                        ? null
                        : () async {
                            setState(() => _isUploading = true);
                            final result = await ApiClient.uploadMIRFile(_selectedPdfFile!);
                            if (!mounted) return;
                            setState(() => _isUploading = false);
                            if (result['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Uploaded: ${result['data']?['filePath'] ?? 'OK'}')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Upload failed: ${result['error'] ?? 'Unknown error'}')),
                              );
                            }
                          },
                  ),
                ],
              ),
              if (_isExtracting) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing extraction...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryTab(bool isDark, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MadCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(isDark, 'Basic Information'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _mirRefController, labelText: 'MIR Reference No', hintText: 'MIR-XXX')),
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _materialCodeController, labelText: 'Material Code', hintText: 'Material code')),
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _clientNameController, labelText: 'Client Name', hintText: 'Client name')),
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _pmcController, labelText: 'PMC (Project Management Consultant)', hintText: 'PMC')),
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _contractorController, labelText: 'Contractor', hintText: 'Contractor')),
                ],
              ),
              const SizedBox(height: 32),
              _sectionTitle(isDark, 'Request Submission'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _vendorCodeController, labelText: 'Vendor Code', hintText: 'Vendor code')),
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _projectNameController, labelText: 'Project Name / Code', hintText: 'Project name')),
                  SizedBox(
                    width: isMobile ? double.infinity : 280,
                    child: MadInput(
                      controller: _inspectionDateController,
                      labelText: 'Inspection Date',
                      hintText: 'YYYY-MM-DD',
                      suffix: IconButton(
                        icon: const Icon(LucideIcons.calendar, size: 20),
                        onPressed: () => _pickDate(_inspectionDateController),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _inspectionTimeController, labelText: 'Inspection Time', hintText: 'HH:mm')),
                  SizedBox(
                    width: isMobile ? double.infinity : 280,
                    child: MadInput(
                      controller: _clientSubmissionDateController,
                      labelText: 'Client Submission Date',
                      hintText: 'YYYY-MM-DD',
                      suffix: IconButton(
                        icon: const Icon(LucideIcons.calendar, size: 20),
                        onPressed: () => _pickDate(_clientSubmissionDateController),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _inspectionEngineerController, labelText: 'Inspection Engineer Name', hintText: 'Name')),
                  SizedBox(width: isMobile ? double.infinity : 280, child: MadInput(controller: _submittedToController, labelText: 'Submitted To', hintText: 'Submitted to')),
                ],
              ),
              const SizedBox(height: 32),
              _sectionTitle(isDark, 'Discipline'),
              const SizedBox(height: 12),
              MadCheckboxGroup<String>(
                label: 'Select disciplines',
                values: _discipline,
                onChanged: (v) => setState(() => _discipline
                  ..clear()
                  ..addAll(v)),
                direction: Axis.horizontal,
                spacing: 16,
                options: const [
                  MadCheckboxOption(value: 'Plumbing', label: 'Plumbing'),
                  MadCheckboxOption(value: 'Fire Fighting', label: 'Fire Fighting'),
                  MadCheckboxOption(value: 'HVAC', label: 'HVAC'),
                  MadCheckboxOption(value: 'Electrical', label: 'Electrical'),
                  MadCheckboxOption(value: 'Civil', label: 'Civil'),
                ],
              ),
              const SizedBox(height: 32),
              _sectionTitle(isDark, 'Reference Documents Attached'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  MadSwitch(label: 'Drawing', value: _refDrawing, onChanged: (v) => setState(() => _refDrawing = v)),
                  MadSwitch(label: 'Test Certificates', value: _refTestCertificates, onChanged: (v) => setState(() => _refTestCertificates = v)),
                  MadSwitch(label: 'Method Statement', value: _refMethodStatement, onChanged: (v) => setState(() => _refMethodStatement = v)),
                  MadSwitch(label: 'Checklist', value: _refChecklist, onChanged: (v) => setState(() => _refChecklist = v)),
                ],
              ),
              const SizedBox(height: 32),
              _sectionTitle(isDark, 'Actions'),
              const SizedBox(height: 16),
              Row(
                children: [
                  MadButton(
                    text: 'Save Draft',
                    icon: LucideIcons.save,
                    variant: ButtonVariant.outline,
                    onPressed: _saveDraft,
                  ),
                  const SizedBox(width: 12),
                  MadButton(
                    text: 'Preview',
                    icon: LucideIcons.eye,
                    variant: ButtonVariant.outline,
                    onPressed: () => _showMIRPreview(_manualFormToMap()),
                  ),
                  const SizedBox(width: 12),
                  MadButton(
                    text: 'Submit MIR',
                    icon: LucideIcons.send,
                    onPressed: () => _submitMIRFromForm(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(bool isDark, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
      ),
    );
  }

  void _showMIRPreview(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final refList = <String>[];
    if (data['ref_drawing'] == true) refList.add('Drawing');
    if (data['ref_test_certificates'] == true) refList.add('Test Certificates');
    if (data['ref_method_statement'] == true) refList.add('Method Statement');
    if (data['ref_checklist'] == true) refList.add('Checklist');
    final discipline = data['discipline'];
    final disciplineList = discipline is List ? discipline.map((e) => e.toString()).toList() : <String>[];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MIR Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _previewSection(isDark, 'Basic Information', {
                        'MIR Reference No': data['mir_refrence_no']?.toString() ?? '-',
                        'Material Code': data['material_code']?.toString() ?? '-',
                        'Client Name': data['client_name']?.toString() ?? '-',
                        'PMC': data['pmc']?.toString() ?? '-',
                        'Contractor': data['contractor']?.toString() ?? '-',
                      }),
                      const SizedBox(height: 20),
                      _previewSection(isDark, 'Request Submission', {
                        'Vendor Code': data['vendor_code']?.toString() ?? '-',
                        'Project Name / Code': data['project_name']?.toString() ?? '-',
                        'Inspection Date': data['inspection_date']?.toString() ?? '-',
                        'Inspection Time': data['inspection_time']?.toString() ?? '-',
                        'Client Submission Date': data['client_submission_date']?.toString() ?? '-',
                        'Inspection Engineer': data['inspection_engineer']?.toString() ?? '-',
                        'Submitted To': data['submitted_to']?.toString() ?? '-',
                      }),
                      const SizedBox(height: 20),
                      _previewSection(isDark, 'Discipline', {
                        'Selected': disciplineList.isEmpty ? '-' : disciplineList.join(', '),
                      }),
                      const SizedBox(height: 20),
                      _previewSection(isDark, 'Reference Documents Attached', {
                        'Attached': refList.isEmpty ? 'None' : refList.join(', '),
                      }),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MadButton(
                      text: 'Edit',
                      variant: ButtonVariant.outline,
                      icon: LucideIcons.pencil,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(width: 12),
                    MadButton(
                      text: 'Submit',
                      icon: LucideIcons.send,
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _submitMIRFromForm();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewSection(bool isDark, String title, Map<String, String> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        ...rows.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    e.key,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitMIRFromForm() async {
    final payload = _manualFormToApiPayload();
    if ((payload['mir_refrence_no'] as String?).toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter MIR Reference No')),
      );
      return;
    }
    final result = await ApiClient.createMIR(payload);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MIR submitted successfully')));
      _loadMIRs();
      setState(() => _selectedTabIndex = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: ${result['error'] ?? 'Unknown error'}')),
      );
    }
  }

  Widget _buildRecentMIRsTab(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile)
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total MIRs',
                  value: _mirs.length.toString(),
                  icon: LucideIcons.fileSearch,
                  iconColor: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Pending',
                  value: _mirs.where((m) => m.status == 'Pending').length.toString(),
                  icon: LucideIcons.clock,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Approved',
                  value: _mirs.where((m) => m.status == 'Approved').length.toString(),
                  icon: LucideIcons.circleCheck,
                  iconColor: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        if (!isMobile) const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : 320,
              child: MadSearchInput(
                controller: _searchController,
                hintText: 'Search MIRs...',
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _currentPage = 1;
                }),
                onClear: () => setState(() {
                  _searchQuery = '';
                  _currentPage = 1;
                }),
              ),
            ),
            SizedBox(
              width: 150,
              child: MadSelect<String>(
                value: _statusFilter,
                placeholder: 'All Status',
                clearable: true,
                options: const [
                  MadSelectOption(value: 'Pending', label: 'Pending'),
                  MadSelectOption(value: 'Approved', label: 'Approved'),
                  MadSelectOption(value: 'Rejected', label: 'Rejected'),
                ],
                onChanged: (v) => setState(() {
                  _statusFilter = v;
                  _currentPage = 1;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredMIRs.isEmpty
                  ? _buildEmptyState(isDark)
                  : MadCard(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.3),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                _buildHeaderCell('MIR Ref', flex: 1, isDark: isDark),
                                _buildHeaderCell('Material', flex: 2, isDark: isDark),
                                if (!isMobile) _buildHeaderCell('Client', flex: 1, isDark: isDark),
                                _buildHeaderCell('Status', flex: 1, isDark: isDark),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _paginatedMIRs.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                              ),
                              itemBuilder: (context, index) => _buildTableRow(_paginatedMIRs[index], isDark, isMobile),
                            ),
                          ),
                          if (_totalPages > 1) _buildPagination(isDark),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, required bool isDark}) => Expanded(
        flex: flex,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
          ),
        ),
      );

  Widget _buildTableRow(MIR mir, bool isDark, bool isMobile) {
    BadgeVariant variant = mir.status == 'Approved'
        ? BadgeVariant.default_
        : mir.status == 'Rejected'
            ? BadgeVariant.destructive
            : BadgeVariant.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(mir.mirReferenceNo, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis, maxLines: 1)),
          Expanded(flex: 2, child: Text(mir.materialCode ?? '-', style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1)),
          if (!isMobile) Expanded(flex: 1, child: Text(mir.clientName ?? '-')),
          Expanded(flex: 1, child: MadBadge(text: mir.status ?? 'Unknown', variant: variant)),
          MadDropdownMenuButton(
            items: [
              MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () => _showMIRDetails(mir)),
              MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () => _showEditMIRDialog(mir)),
              MadMenuItem(label: 'Preview', icon: LucideIcons.fileText, onTap: () => _showMIRPreview(_mirToPreviewMap(mir))),
              if (mir.status == 'Pending') ...[
                MadMenuItem(label: 'Approve', icon: LucideIcons.circleCheck, onTap: () => _approveMIR(mir)),
                MadMenuItem(label: 'Reject', icon: LucideIcons.circleX, destructive: true, onTap: () => _rejectMIR(mir)),
              ],
              MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () => _showDeleteMIRConfirmation(mir)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_currentPage of $_totalPages',
            style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
          ),
          Row(
            children: [
              MadButton(
                icon: LucideIcons.chevronLeft,
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                disabled: _currentPage == 1,
                onPressed: () => setState(() => _currentPage--),
              ),
              const SizedBox(width: 8),
              MadButton(
                icon: LucideIcons.chevronRight,
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                disabled: _currentPage >= _totalPages,
                onPressed: () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.fileSearch,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No MIRs yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a material inspection request via Upload & Extract or Manual Entry',
              style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            MadButton(
              text: 'Go to Manual Entry',
              icon: LucideIcons.pencilLine,
              onPressed: () => setState(() => _selectedTabIndex = 1),
            ),
          ],
        ),
      ),
    );
  }

  void _showMIRDetails(MIR mir) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mir.mirReferenceNo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow(isDark, 'MIR Reference No', mir.mirReferenceNo),
                      _detailRow(isDark, 'Material Code', mir.materialCode ?? '-'),
                      _detailRow(isDark, 'Client Name', mir.clientName ?? '-'),
                      _detailRow(isDark, 'Status', mir.status ?? '-'),
                      _detailRow(isDark, 'PMC', mir.pmc ?? '-'),
                      _detailRow(isDark, 'Contractor', mir.contractor ?? '-'),
                      _detailRow(isDark, 'Vendor Code', mir.vendorCode ?? '-'),
                      _detailRow(isDark, 'Project Name', mir.projectName ?? '-'),
                      _detailRow(isDark, 'Project Code', mir.projectCode ?? '-'),
                      _detailRow(isDark, 'Inspection Date/Time', mir.inspectionDateTime ?? '-'),
                      _detailRow(isDark, 'Client Submission Date', mir.clientSubmissionDate ?? '-'),
                      _detailRow(isDark, 'Inspection Engineer', mir.inspectionEngineer ?? '-'),
                      _detailRow(isDark, 'Submitted To', mir.mirSubmittedTo ?? '-'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showEditMIRDialog(MIR mir) {
    final mirRefController = TextEditingController(text: mir.mirRefNo);
    final materialCodeController = TextEditingController(text: mir.materialCode ?? '');
    final clientNameController = TextEditingController(text: mir.clientName ?? '');
    String? selectedStatus = mir.status;

    MadFormDialog.show(
      context: context,
      title: 'Edit MIR',
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadInput(controller: mirRefController, labelText: 'MIR Reference No', hintText: 'MIR-XXX'),
          const SizedBox(height: 16),
          MadInput(controller: materialCodeController, labelText: 'Material Code', hintText: 'Material code'),
          const SizedBox(height: 16),
          MadInput(controller: clientNameController, labelText: 'Client Name', hintText: 'Client name'),
          const SizedBox(height: 16),
          MadSelect<String>(
            labelText: 'Status',
            value: selectedStatus,
            placeholder: 'Select status',
            options: const [
              MadSelectOption(value: 'Pending', label: 'Pending'),
              MadSelectOption(value: 'Approved', label: 'Approved'),
              MadSelectOption(value: 'Rejected', label: 'Rejected'),
            ],
            onChanged: (value) => selectedStatus = value,
          ),
        ],
      ),
      actions: [
        MadButton(
          text: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () {
            mirRefController.dispose();
            materialCodeController.dispose();
            clientNameController.dispose();
            Navigator.pop(context);
          },
        ),
        MadButton(
          text: 'Save',
          onPressed: () async {
            final data = <String, dynamic>{
              'mir_refrence_no': mirRefController.text.trim(),
              'material_code': materialCodeController.text.trim().isEmpty ? null : materialCodeController.text.trim(),
              'client_name': clientNameController.text.trim().isEmpty ? null : clientNameController.text.trim(),
              'status': selectedStatus ?? mir.status,
            };
            mirRefController.dispose();
            materialCodeController.dispose();
            clientNameController.dispose();
            Navigator.pop(context);
            final result = await ApiClient.updateMIR(mir.id, data);
            if (!mounted) return;
            if (result['success'] == true) _loadMIRs();
          },
        ),
      ],
    );
  }

  void _showDeleteMIRConfirmation(MIR mir) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        title: const Text('Delete MIR'),
        content: Text('Are you sure you want to delete "${mir.mirReferenceNo}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiClient.deleteMIR(mir.id);
              if (!mounted) return;
              if (result['success'] == true) _loadMIRs();
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveMIR(MIR mir) async {
    final result = await ApiClient.updateMIR(mir.id, {'status': 'Approved'});
    if (!mounted) return;
    if (result['success'] == true) _loadMIRs();
  }

  Future<void> _rejectMIR(MIR mir) async {
    final result = await ApiClient.updateMIR(mir.id, {'status': 'Rejected'});
    if (!mounted) return;
    if (result['success'] == true) _loadMIRs();
  }
}
