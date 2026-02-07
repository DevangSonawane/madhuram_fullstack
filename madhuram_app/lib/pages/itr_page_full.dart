import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../models/itr.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';
import '../utils/error_handler.dart';
import '../demo_data/additional_modules_demo.dart';

const String _itrDraftKey = 'itr_manual_entry_draft';

/// Installation Test Report page with tabbed interface: Upload & Extract, Manual Entry, Recent ITRs
class ITRPageFull extends StatefulWidget {
  const ITRPageFull({super.key});
  @override
  State<ITRPageFull> createState() => _ITRPageFullState();
}

class _ITRPageFullState extends State<ITRPageFull> {
  // START WITH DEMO DATA – never show blank
  bool _isLoading = true;
  List<ITR> _itrs = ITRDemo.itrs.map((e) => ITR.fromJson(e)).toList();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  // Upload & Extract tab
  PlatformFile? _selectedFile;
  bool _isExtracting = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Try real API in background; demo data already visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadITRs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _seedDemoITRs() {
    debugPrint('[ITR] API unavailable – falling back to demo data');
    setState(() {
      _itrs = ITRDemo.itrs.map((e) => ITR.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadITRs() async {
    setState(() {
      _isLoading = true;
    });
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProject?['project_id']?.toString() ??
        store.state.project.selectedProjectId ?? '';

    if (projectId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ApiClient.getITRsByProject(projectId);
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'] as List;
        final loaded = data.map((e) => ITR.fromJson(e)).toList();
        if (loaded.isEmpty) {
          _seedDemoITRs();
        } else {
          setState(() {
            _itrs = loaded;
            _isLoading = false;
          });
        }
      } else {
        _seedDemoITRs();
      }
    } catch (e) {
      debugPrint('[ITR] API error: $e – falling back to demo data');
      if (!mounted) return;
      _seedDemoITRs();
    }
  }

  List<ITR> get _filteredITRs {
    List<ITR> result = _itrs;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((i) =>
              i.itrRefNo.toLowerCase().contains(query) ||
              (i.projectName?.toLowerCase().contains(query) ?? false) ||
              (i.discipline?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    if (_statusFilter != null) result = result.where((i) => i.status == _statusFilter).toList();
    return result;
  }

  List<ITR> get _paginatedITRs {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredITRs;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredITRs.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

    return StoreConnector<AppState, String?>(
      converter: (store) =>
          store.state.project.selectedProject?['project_id']?.toString() ??
          store.state.project.selectedProjectId,
      builder: (context, projectId) {
        return ProtectedRoute(
          title: 'Installation Test Report',
          route: '/itr',
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
                          'Installation Test Report',
                          style: TextStyle(
                            fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage installation test reports',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: MadTabs(
                  defaultTab: 'recent',
                  tabs: [
                    MadTabItem(
                      id: 'upload',
                      label: 'Upload & Extract',
                      icon: LucideIcons.upload,
                      content: _buildUploadExtractTab(isDark),
                    ),
                    MadTabItem(
                      id: 'manual',
                      label: 'Manual Entry',
                      icon: LucideIcons.filePenLine,
                      content: _buildManualEntryTab(isDark, projectId),
                    ),
                    MadTabItem(
                      id: 'recent',
                      label: 'Recent ITRs',
                      icon: LucideIcons.clipboardList,
                      content: _buildRecentITRsTab(isDark, isMobile),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                'Upload & Extract',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a PDF, XLSX or CSV file to extract ITR data.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              MadButton(
                text: 'Choose File',
                icon: LucideIcons.fileUp,
                variant: ButtonVariant.outline,
                onPressed: _isExtracting || _isUploading ? null : _pickFile,
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.fileText, size: 20, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    onPressed: (_selectedFile == null || _isExtracting || _isUploading) ? null : _runExtract,
                  ),
                  const SizedBox(width: 12),
                  MadButton(
                    text: 'Upload',
                    icon: LucideIcons.upload,
                    variant: ButtonVariant.secondary,
                    onPressed: (_selectedFile == null || _isExtracting || _isUploading) ? null : _runUpload,
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Extracting data...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
              if (_isUploading) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Uploading...',
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xlsx', 'xls', 'csv'],
      allowMultiple: false,
    );
    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = result.files.single);
    }
  }

  Future<void> _runExtract() async {
    if (_selectedFile == null) return;
    setState(() => _isExtracting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isExtracting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Extraction is not implemented yet. Use Manual Entry or upload file.')),
    );
  }

  Future<void> _runUpload() async {
    if (_selectedFile == null) return;
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isUploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload of "${_selectedFile!.name}" would be sent to server. API integration can be added when endpoint is ready.')),
    );
  }

  Widget _buildManualEntryTab(bool isDark, String? projectId) {
    return _ITRManualEntryForm(
      projectId: projectId ?? '',
      isDark: isDark,
      onPreview: _showITRPreview,
      onSubmit: _submitITR,
    );
  }

  void _showITRPreview(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ITR Preview',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildPreviewContent(data, isDark, Responsive(ctx).isMobile),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MadButton(text: 'Edit', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
                    const SizedBox(width: 12),
                    MadButton(
                      text: 'Submit',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _submitITR(data);
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

  Widget _buildPreviewContent(Map<String, dynamic> data, bool isDark, bool isMobile) {
    final textStyle = TextStyle(fontSize: 13, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground);
    final valueStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);

    Widget section(String title, List<Widget> rows) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
          const SizedBox(height: 8),
          ...rows,
          const SizedBox(height: 16),
        ],
      );
    }

    Widget row(String label, dynamic value) {
      final v = value?.toString() ?? '-';
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: isMobile ? 100 : 140, child: Text(label, style: textStyle)),
            Expanded(child: Text(v, style: valueStyle, overflow: TextOverflow.ellipsis, maxLines: 1)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('Header', [
          row('ITR Reference No', data['itr_ref_no']),
          row('Project Name', data['project_name']),
          row('Discipline', data['discipline']),
          row('Client/Employer', data['client_employer']),
          row('Contractor', data['contractor']),
        ]),
        section('Location', [
          row('Tower/Block', data['tower_block']),
          row('Floor', data['floor']),
          row('Grid', data['grid']),
          row('Room/Area', data['room_area']),
        ]),
        section('Contractor Part', [
          row('PMC Engineer', data['pmc_engineer']),
          row('Vendor Code', data['vendor_code']),
          row('Material Code', data['material_code']),
          row('Description of Works', data['description_of_works']),
        ]),
        section('Measurement', [
          row('Previous Quantity', data['previous_quantity']),
          row('Current Quantity', data['current_quantity']),
          row('Cumulative Quantity', data['cumulative_quantity']),
        ]),
        section('Clearances', [
          row('MEP Clearance', data['mep_clearance']),
          row('Surveyor Clearance', data['surveyor_clearance']),
          row('Interface Clearance', data['interface_clearance']),
        ]),
        section('Contractor Manager', [
          row('Ready for Inspection', data['ready_for_inspection'] == true ? 'Yes' : 'No'),
          row('Contractor Manager Name', data['contractor_manager_name']),
          row('Date', data['contractor_manager_date']),
        ]),
        section('Lodha/PMC', [
          row('Comments', data['comments']),
          row('Result Code', data['result_code']),
          row('Engineer Name', data['engineer_name']),
          row('Date', data['engineer_date']),
        ]),
      ],
    );
  }

  Future<void> _submitITR(Map<String, dynamic> formData) async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProject?['project_id']?.toString() ??
        store.state.project.selectedProjectId ?? '';

    final data = <String, dynamic>{
      'project_id': projectId,
      'itr_ref_no': formData['itr_ref_no']?.toString().trim() ?? '',
      'project_name': formData['project_name']?.toString().trim(),
      'discipline': formData['discipline']?.toString(),
      'client_employer': formData['client_employer']?.toString().trim(),
      'contractor': formData['contractor']?.toString().trim(),
      'pmc_engineer': formData['pmc_engineer']?.toString().trim(),
      'vendor_code': formData['vendor_code']?.toString().trim(),
      'material_code': formData['material_code']?.toString().trim(),
      'status': 'Pending',
    };
    if (formData['description_of_works'] != null) data['contractor_part'] = {'description_of_works': formData['description_of_works']};
    if (formData['comments'] != null || formData['result_code'] != null) {
      data['lodha_pmc'] = {
        'comments': formData['comments']?.toString(),
        'result_code': formData['result_code']?.toString(),
        'engineer_name': formData['engineer_name']?.toString(),
        'engineer_date': formData['engineer_date']?.toString(),
      };
    }

    final result = await ApiClient.createITR(data);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ITR submitted successfully.')));
      _loadITRs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result['message'] ?? result['error'] ?? 'Failed to submit ITR').toString())),
      );
    }
  }

  Widget _buildRecentITRsTab(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile)
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total ITRs',
                  value: _itrs.length.toString(),
                  icon: LucideIcons.clipboardCheck,
                  iconColor: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Pending',
                  value: _itrs.where((i) => i.status == 'Pending').length.toString(),
                  icon: LucideIcons.clock,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Completed',
                  value: _itrs.where((i) => i.status == 'Completed').length.toString(),
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
                hintText: 'Search ITRs...',
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
                  MadSelectOption(value: 'In Progress', label: 'In Progress'),
                  MadSelectOption(value: 'Completed', label: 'Completed'),
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
              : _filteredITRs.isEmpty
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
                                _buildHeaderCell('ITR Ref', flex: 1, isDark: isDark),
                                _buildHeaderCell('Project', flex: 2, isDark: isDark),
                                if (!isMobile) _buildHeaderCell('Discipline', flex: 1, isDark: isDark),
                                _buildHeaderCell('Status', flex: 1, isDark: isDark),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _paginatedITRs.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                              ),
                              itemBuilder: (context, index) => _buildTableRow(_paginatedITRs[index], isDark, isMobile),
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

  Widget _buildTableRow(ITR itr, bool isDark, bool isMobile) {
    BadgeVariant variant = itr.status == 'Completed'
        ? BadgeVariant.default_
        : itr.status == 'In Progress'
            ? BadgeVariant.outline
            : BadgeVariant.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(itr.itrRefNo, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis, maxLines: 1)),
          Expanded(flex: 2, child: Text(itr.projectName ?? '-', style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1)),
          if (!isMobile)
            Expanded(
              flex: 1,
              child: itr.discipline != null ? MadBadge(text: itr.discipline!, variant: BadgeVariant.secondary) : const Text('-'),
            ),
          Expanded(flex: 1, child: MadBadge(text: itr.status ?? 'Unknown', variant: variant)),
          MadDropdownMenuButton(
            items: [
              MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () => _showITRDetails(itr)),
              MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () => _showEditITRDialog(itr)),
              MadMenuItem(label: 'Preview', icon: LucideIcons.fileText, onTap: () {}),
              MadMenuItem(label: 'Mark Complete', icon: LucideIcons.circleCheck, onTap: () => _markITRComplete(itr)),
              MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () => _showDeleteITRConfirmation(itr)),
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
              LucideIcons.clipboardCheck,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No ITRs yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an installation test report via Upload & Extract or Manual Entry',
              style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showITRDetails(ITR itr) {
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
                    Text(itr.itrRefNo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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
                      _itrDetailRow(isDark, 'ITR Reference No', itr.itrRefNo),
                      _itrDetailRow(isDark, 'Project Name', itr.projectName ?? '-'),
                      _itrDetailRow(isDark, 'Discipline', itr.discipline ?? '-'),
                      _itrDetailRow(isDark, 'Status', itr.status ?? '-'),
                      _itrDetailRow(isDark, 'Client / Employer', itr.clientEmployer ?? '-'),
                      _itrDetailRow(isDark, 'Contractor', itr.contractor ?? '-'),
                      _itrDetailRow(isDark, 'PMC Engineer', itr.pmcEngineer ?? '-'),
                      _itrDetailRow(isDark, 'Vendor Code', itr.vendorCode ?? '-'),
                      _itrDetailRow(isDark, 'Material Code', itr.materialCode ?? '-'),
                      _itrDetailRow(isDark, 'Inspection Date/Time', itr.inspectionDateTime ?? '-'),
                      _itrDetailRow(isDark, 'WIR/ITR Submission Date', itr.wirItrSubmissionDateTime ?? '-'),
                      _itrDetailRow(isDark, 'Submitted To', itr.submittedTo ?? '-'),
                      _itrDetailRow(isDark, 'Submitted By', itr.submittedBy ?? '-'),
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

  Widget _itrDetailRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showEditITRDialog(ITR itr) {
    final itrRefController = TextEditingController(text: itr.itrRefNo);
    final projectNameController = TextEditingController(text: itr.projectName ?? '');
    String? selectedDiscipline = itr.discipline;
    String? selectedStatus = itr.status;

    MadFormDialog.show(
      context: context,
      title: 'Edit ITR',
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadInput(controller: itrRefController, labelText: 'ITR Reference No', hintText: 'ITR-XXX'),
          const SizedBox(height: 16),
          MadInput(controller: projectNameController, labelText: 'Project Name', hintText: 'Project name'),
          const SizedBox(height: 16),
          MadSelect<String>(
            labelText: 'Discipline',
            value: selectedDiscipline,
            placeholder: 'Select discipline',
            options: const [
              MadSelectOption(value: 'Plumbing', label: 'Plumbing'),
              MadSelectOption(value: 'Fire Fighting', label: 'Fire Fighting'),
              MadSelectOption(value: 'HVAC', label: 'HVAC'),
              MadSelectOption(value: 'Electrical', label: 'Electrical'),
              MadSelectOption(value: 'Civil', label: 'Civil'),
              MadSelectOption(value: 'Structural', label: 'Structural'),
            ],
            onChanged: (value) => selectedDiscipline = value,
          ),
          const SizedBox(height: 16),
          MadSelect<String>(
            labelText: 'Status',
            value: selectedStatus,
            placeholder: 'Select status',
            options: const [
              MadSelectOption(value: 'Pending', label: 'Pending'),
              MadSelectOption(value: 'In Progress', label: 'In Progress'),
              MadSelectOption(value: 'Completed', label: 'Completed'),
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
            itrRefController.dispose();
            projectNameController.dispose();
            Navigator.pop(context);
          },
        ),
        MadButton(
          text: 'Save',
          onPressed: () async {
            final data = <String, dynamic>{
              'itr_ref_no': itrRefController.text.trim(),
              'project_name': projectNameController.text.trim().isEmpty ? null : projectNameController.text.trim(),
              'discipline': selectedDiscipline,
              'status': selectedStatus ?? itr.status,
            };
            itrRefController.dispose();
            projectNameController.dispose();
            Navigator.pop(context);
            final result = await ApiClient.updateITR(itr.id, data);
            if (!mounted) return;
            if (result['success'] == true) _loadITRs();
          },
        ),
      ],
    );
  }

  void _showDeleteITRConfirmation(ITR itr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        title: const Text('Delete ITR'),
        content: Text('Are you sure you want to delete "${itr.itrRefNo}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiClient.deleteITR(itr.id);
              if (!mounted) return;
              if (result['success'] == true) _loadITRs();
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _markITRComplete(ITR itr) async {
    final result = await ApiClient.updateITR(itr.id, {'status': 'Completed'});
    if (!mounted) return;
    if (result['success'] == true) _loadITRs();
  }
}

/// Manual entry form for ITR - all sections from React ITR.jsx
class _ITRManualEntryForm extends StatefulWidget {
  final String projectId;
  final bool isDark;
  final void Function(Map<String, dynamic>) onPreview;
  final void Function(Map<String, dynamic>) onSubmit;

  const _ITRManualEntryForm({
    required this.projectId,
    required this.isDark,
    required this.onPreview,
    required this.onSubmit,
  });

  @override
  State<_ITRManualEntryForm> createState() => _ITRManualEntryFormState();
}

class _ITRManualEntryFormState extends State<_ITRManualEntryForm> {
  final _formKey = GlobalKey<FormState>();

  final _itrRefController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _clientEmployerController = TextEditingController();
  final _contractorController = TextEditingController();
  final _towerBlockController = TextEditingController();
  final _floorController = TextEditingController();
  final _gridController = TextEditingController();
  final _roomAreaController = TextEditingController();
  final _pmcEngineerController = TextEditingController();
  final _vendorCodeController = TextEditingController();
  final _materialCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prevQtyController = TextEditingController();
  final _currentQtyController = TextEditingController();
  final _cumulativeQtyController = TextEditingController();
  final _contractorManagerNameController = TextEditingController();
  final _contractorManagerDateController = TextEditingController();
  final _commentsController = TextEditingController();
  final _engineerNameController = TextEditingController();
  final _engineerDateController = TextEditingController();

  String? _discipline;
  String? _drawingAttach;
  String? _testCertAttach;
  String? _methodStatementAttach;
  String? _checklistAttach;
  String? _jointMeasurementAttach;
  String? _mepClearance;
  String? _surveyorClearance;
  String? _interfaceClearance;
  bool _readyForInspection = false;
  String? _resultCode;

  static const List<MadSelectOption<String>> _disciplineOptions = [
    MadSelectOption(value: 'Plumbing', label: 'Plumbing'),
    MadSelectOption(value: 'Fire Fighting', label: 'Fire Fighting'),
    MadSelectOption(value: 'HVAC', label: 'HVAC'),
    MadSelectOption(value: 'Electrical', label: 'Electrical'),
    MadSelectOption(value: 'Civil', label: 'Civil'),
  ];

  static const List<MadSelectOption<String>> _yesNoNaOptions = [
    MadSelectOption(value: 'Yes', label: 'Yes'),
    MadSelectOption(value: 'No', label: 'No'),
    MadSelectOption(value: 'NA', label: 'NA'),
  ];

  static const List<MadSelectOption<String>> _resultCodeOptions = [
    MadSelectOption(value: 'A', label: 'A - Accepted'),
    MadSelectOption(value: 'B', label: 'B - Conditionally Accepted'),
    MadSelectOption(value: 'C', label: 'C - Rejected'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoadDraft());
  }

  Future<void> _tryLoadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_itrDraftKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = _decodeDraft(raw);
      if (decoded.isEmpty) return;
      setState(() {
        _itrRefController.text = decoded['itr_ref_no']?.toString() ?? '';
        _projectNameController.text = decoded['project_name']?.toString() ?? '';
        _clientEmployerController.text = decoded['client_employer']?.toString() ?? '';
        _contractorController.text = decoded['contractor']?.toString() ?? '';
        _towerBlockController.text = decoded['tower_block']?.toString() ?? '';
        _floorController.text = decoded['floor']?.toString() ?? '';
        _gridController.text = decoded['grid']?.toString() ?? '';
        _roomAreaController.text = decoded['room_area']?.toString() ?? '';
        _pmcEngineerController.text = decoded['pmc_engineer']?.toString() ?? '';
        _vendorCodeController.text = decoded['vendor_code']?.toString() ?? '';
        _materialCodeController.text = decoded['material_code']?.toString() ?? '';
        _descriptionController.text = decoded['description_of_works']?.toString() ?? '';
        _prevQtyController.text = decoded['previous_quantity']?.toString() ?? '';
        _currentQtyController.text = decoded['current_quantity']?.toString() ?? '';
        _cumulativeQtyController.text = decoded['cumulative_quantity']?.toString() ?? '';
        _contractorManagerNameController.text = decoded['contractor_manager_name']?.toString() ?? '';
        _contractorManagerDateController.text = decoded['contractor_manager_date']?.toString() ?? '';
        _commentsController.text = decoded['comments']?.toString() ?? '';
        _engineerNameController.text = decoded['engineer_name']?.toString() ?? '';
        _engineerDateController.text = decoded['engineer_date']?.toString() ?? '';
        _discipline = decoded['discipline']?.toString();
        _drawingAttach = decoded['drawing_attachment']?.toString();
        _testCertAttach = decoded['test_certificates_attachment']?.toString();
        _methodStatementAttach = decoded['method_statement_attachment']?.toString();
        _checklistAttach = decoded['checklist_attachment']?.toString();
        _jointMeasurementAttach = decoded['joint_measurement_attachment']?.toString();
        _mepClearance = decoded['mep_clearance']?.toString();
        _surveyorClearance = decoded['surveyor_clearance']?.toString();
        _interfaceClearance = decoded['interface_clearance']?.toString();
        _readyForInspection = decoded['ready_for_inspection'] == true || decoded['ready_for_inspection'] == 'true';
        _resultCode = decoded['result_code']?.toString();
      });
    } catch (_) {}
  }

  Map<String, dynamic> _decodeDraft(String raw) {
    final out = <String, dynamic>{};
    final parts = raw.split(';;');
    for (final p in parts) {
      if (p.isEmpty) continue;
      final idx = p.indexOf('::');
      if (idx == -1) continue;
      final key = p.substring(0, idx);
      final value = p.substring(idx + 2);
      if (value.isNotEmpty) out[key] = value;
    }
    return out;
  }

  @override
  void dispose() {
    _itrRefController.dispose();
    _projectNameController.dispose();
    _clientEmployerController.dispose();
    _contractorController.dispose();
    _towerBlockController.dispose();
    _floorController.dispose();
    _gridController.dispose();
    _roomAreaController.dispose();
    _pmcEngineerController.dispose();
    _vendorCodeController.dispose();
    _materialCodeController.dispose();
    _descriptionController.dispose();
    _prevQtyController.dispose();
    _currentQtyController.dispose();
    _cumulativeQtyController.dispose();
    _contractorManagerNameController.dispose();
    _contractorManagerDateController.dispose();
    _commentsController.dispose();
    _engineerNameController.dispose();
    _engineerDateController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _collectData() {
    return {
      'itr_ref_no': _itrRefController.text.trim(),
      'project_name': _projectNameController.text.trim(),
      'discipline': _discipline,
      'client_employer': _clientEmployerController.text.trim(),
      'contractor': _contractorController.text.trim(),
      'tower_block': _towerBlockController.text.trim(),
      'floor': _floorController.text.trim(),
      'grid': _gridController.text.trim(),
      'room_area': _roomAreaController.text.trim(),
      'pmc_engineer': _pmcEngineerController.text.trim(),
      'vendor_code': _vendorCodeController.text.trim(),
      'material_code': _materialCodeController.text.trim(),
      'description_of_works': _descriptionController.text.trim(),
      'previous_quantity': _prevQtyController.text.trim(),
      'current_quantity': _currentQtyController.text.trim(),
      'cumulative_quantity': _cumulativeQtyController.text.trim(),
      'drawing_attachment': _drawingAttach,
      'test_certificates_attachment': _testCertAttach,
      'method_statement_attachment': _methodStatementAttach,
      'checklist_attachment': _checklistAttach,
      'joint_measurement_attachment': _jointMeasurementAttach,
      'mep_clearance': _mepClearance,
      'surveyor_clearance': _surveyorClearance,
      'interface_clearance': _interfaceClearance,
      'ready_for_inspection': _readyForInspection,
      'contractor_manager_name': _contractorManagerNameController.text.trim(),
      'contractor_manager_date': _contractorManagerDateController.text.trim(),
      'comments': _commentsController.text.trim(),
      'result_code': _resultCode,
      'engineer_name': _engineerNameController.text.trim(),
      'engineer_date': _engineerDateController.text.trim(),
    };
  }

  Future<void> _saveDraft() async {
    final data = _collectData();
    try {
      final prefs = await SharedPreferences.getInstance();
      final parts = <String>[];
      for (final e in data.entries) {
        if (e.value != null && e.value.toString().isNotEmpty) parts.add('${e.key}::${e.value}');
      }
      await prefs.setString(_itrDraftKey, parts.join(';;'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MadCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Header', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                    const SizedBox(height: 16),
                    MadInput(controller: _itrRefController, labelText: 'ITR Reference No', hintText: 'ITR-XXX'),
                    const SizedBox(height: 16),
                    MadInput(controller: _projectNameController, labelText: 'Project Name', hintText: 'Enter project name'),
                    const SizedBox(height: 16),
                    MadSelect<String>(labelText: 'Discipline', value: _discipline, placeholder: 'Select discipline', options: _disciplineOptions, onChanged: (v) => setState(() => _discipline = v)),
                    const SizedBox(height: 16),
                    MadInput(controller: _clientEmployerController, labelText: 'Client/Employer', hintText: 'Client or employer name'),
                    const SizedBox(height: 16),
                    MadInput(controller: _contractorController, labelText: 'Contractor', hintText: 'Contractor name'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            MadCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                    const SizedBox(height: 16),
                    MadInput(controller: _towerBlockController, labelText: 'Tower/Block', hintText: 'Tower or block'),
                    const SizedBox(height: 16),
                    MadInput(controller: _floorController, labelText: 'Floor', hintText: 'Floor'),
                    const SizedBox(height: 16),
                    MadInput(controller: _gridController, labelText: 'Grid', hintText: 'Grid'),
                    const SizedBox(height: 16),
                    MadInput(controller: _roomAreaController, labelText: 'Room/Area', hintText: 'Room or area'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            MadCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contractor Part', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                    const SizedBox(height: 16),
                    MadInput(controller: _pmcEngineerController, labelText: 'PMC Engineer', hintText: 'PMC engineer name'),
                    const SizedBox(height: 16),
                    MadInput(controller: _vendorCodeController, labelText: 'Vendor Code', hintText: 'Vendor code'),
                    const SizedBox(height: 16),
                    MadInput(controller: _materialCodeController, labelText: 'Material Code', hintText: 'Material code'),
                    const SizedBox(height: 16),
                    MadTextarea(controller: _descriptionController, labelText: 'Description of Works', hintText: 'Describe the works...', minLines: 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            MadCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Measurement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                    const SizedBox(height: 16),
                    MadInput(controller: _prevQtyController, labelText: 'Previous Quantity', hintText: '0', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    MadInput(controller: _currentQtyController, labelText: 'Current Quantity', hintText: '0', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    MadInput(controller: _cumulativeQtyController, labelText: 'Cumulative Quantity', hintText: '0', keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            MadCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attachments (Yes/No/NA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                    const SizedBox(height: 16),
                    MadSelect<String>(labelText: 'Drawing', value: _drawingAttach, placeholder: 'Select', options: _yesNoNaOptions, onChanged: (v) => setState(() => _drawingAttach = v)),
                    const SizedBox(height: 12),
                    MadSelect<String>(labelText: 'Test Certificates', value: _testCertAttach, placeholder: 'Select', options: _yesNoNaOptions, onChanged: (v) => setState(() => _testCertAttach = v)),
                    const SizedBox(height: 12),
                    MadSelect<String>(labelText: 'Method Statement', value: _methodStatementAttach, placeholder: 'Select', options: _yesNoNaOptions, onChanged: (v) => setState(() => _methodStatementAttach = v)),
                    const SizedBox(height: 12),
                    MadSelect<String>(labelText: 'Checklist', value: _checklistAttach, placeholder: 'Select', options: _yesNoNaOptions, onChanged: (v) => setState(() => _checklistAttach = v)),
                    const SizedBox(height: 12),
                    MadSelect<String>(labelText: 'Joint Measurement Sheet', value: _jointMeasurementAttach, placeholder: 'Select', options: _yesNoNaOptions, onChanged: (v) => setState(() => _jointMeasurementAttach = v)),
                    const SizedBox(height: 20),
                    Text('Clearances', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                    const SizedBox(height: 12),
                    MadSelect<String>(labelText: 'MEP Clearance', value: _mepClearance, placeholder: 'Select', options: _yesNoNaOptions, onChanged: (v) => setState(() => _mepClearance = v)),
                    const SizedBox(height: 12),
                    MadSelect<String>(labelText: 'Surveyor Clearance', value: _surveyorClearance, placeholder: 'Select', options: _yesNoNaOptions, onChanged: (v) => setState(() => _surveyorClearance = v)),
                    const SizedBox(height: 12),
                    MadSelect<String>(labelText: 'Interface Clearance', value: _interfaceClearance, placeholder: 'Select', options: _yesNoNaOptions, onChanged: (v) => setState(() => _interfaceClearance = v)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            MadCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contractor Manager Readiness', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                    const SizedBox(height: 16),
                    MadSwitch(label: 'Ready for Inspection', value: _readyForInspection, onChanged: (v) => setState(() => _readyForInspection = v)),
                    const SizedBox(height: 16),
                    MadInput(controller: _contractorManagerNameController, labelText: 'Contractor Manager Name', hintText: 'Name'),
                    const SizedBox(height: 16),
                    MadInput(controller: _contractorManagerDateController, labelText: 'Date and Signature', hintText: 'Date'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            MadCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lodha/PMC Part', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                    const SizedBox(height: 16),
                    MadTextarea(controller: _commentsController, labelText: 'Comments', hintText: 'Comments...', minLines: 3),
                    const SizedBox(height: 16),
                    MadSelect<String>(labelText: 'Result Code', value: _resultCode, placeholder: 'Select result', options: _resultCodeOptions, onChanged: (v) => setState(() => _resultCode = v)),
                    const SizedBox(height: 16),
                    MadInput(controller: _engineerNameController, labelText: 'Engineer Name', hintText: 'Engineer name'),
                    const SizedBox(height: 16),
                    MadInput(controller: _engineerDateController, labelText: 'Date', hintText: 'Date'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                MadButton(text: 'Save Draft', variant: ButtonVariant.outline, icon: LucideIcons.save, onPressed: _saveDraft),
                const SizedBox(width: 12),
                MadButton(text: 'Preview', variant: ButtonVariant.secondary, icon: LucideIcons.eye, onPressed: () => widget.onPreview(_collectData())),
                const SizedBox(width: 12),
                MadButton(text: 'Submit ITR', icon: LucideIcons.send, onPressed: () => widget.onSubmit(_collectData())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
