import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../models/itr.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Installation Test Report page with full implementation
class ITRPageFull extends StatefulWidget {
  const ITRPageFull({super.key});
  @override
  State<ITRPageFull> createState() => _ITRPageFullState();
}

class _ITRPageFullState extends State<ITRPageFull> {
  bool _isLoading = true;
  List<ITR> _itrs = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadITRs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadITRs() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';
    
    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    
    final result = await ApiClient.getITRsByProject(projectId);
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() { _itrs = data.map((e) => ITR.fromJson(e)).toList(); _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<ITR> get _filteredITRs {
    List<ITR> result = _itrs;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((i) => i.itrRefNo.toLowerCase().contains(query) || (i.projectName?.toLowerCase().contains(query) ?? false) || (i.discipline?.toLowerCase().contains(query) ?? false)).toList();
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return ProtectedRoute(
      title: 'Installation Test Report',
      route: '/itr',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Installation Test Report', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
            const SizedBox(height: 4),
            Text('Manage installation test reports', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
          ])),
          if (!isMobile) MadButton(text: 'New ITR', icon: LucideIcons.plus, onPressed: () => _showITRDialog()),
        ]),
        const SizedBox(height: 24),
        if (!isMobile) Row(children: [
          Expanded(child: StatCard(title: 'Total ITRs', value: _itrs.length.toString(), icon: LucideIcons.clipboardCheck, iconColor: AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Pending', value: _itrs.where((i) => i.status == 'Pending').length.toString(), icon: LucideIcons.clock, iconColor: const Color(0xFFF59E0B))),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Completed', value: _itrs.where((i) => i.status == 'Completed').length.toString(), icon: LucideIcons.circleCheck, iconColor: const Color(0xFF22C55E))),
        ]),
        if (!isMobile) const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: isMobile ? double.infinity : 320, child: MadSearchInput(controller: _searchController, hintText: 'Search ITRs...', onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }), onClear: () => setState(() { _searchQuery = ''; _currentPage = 1; }))),
          SizedBox(width: 150, child: MadSelect<String>(value: _statusFilter, placeholder: 'All Status', clearable: true, options: const [MadSelectOption(value: 'Pending', label: 'Pending'), MadSelectOption(value: 'In Progress', label: 'In Progress'), MadSelectOption(value: 'Completed', label: 'Completed')], onChanged: (v) => setState(() { _statusFilter = v; _currentPage = 1; }))),
          if (isMobile) MadButton(icon: LucideIcons.plus, text: 'New', onPressed: () => _showITRDialog()),
        ]),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : _filteredITRs.isEmpty ? _buildEmptyState(isDark) : MadCard(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.3), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                child: Row(children: [
                  _buildHeaderCell('ITR Ref', flex: 1, isDark: isDark),
                  _buildHeaderCell('Project', flex: 2, isDark: isDark),
                  if (!isMobile) _buildHeaderCell('Discipline', flex: 1, isDark: isDark),
                  _buildHeaderCell('Status', flex: 1, isDark: isDark),
                  const SizedBox(width: 48),
                ]),
              ),
              Expanded(child: ListView.separated(
                itemCount: _paginatedITRs.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5)),
                itemBuilder: (context, index) => _buildTableRow(_paginatedITRs[index], isDark, isMobile),
              )),
              if (_totalPages > 1) _buildPagination(isDark),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, required bool isDark}) => Expanded(flex: flex, child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)));

  Widget _buildTableRow(ITR itr, bool isDark, bool isMobile) {
    BadgeVariant variant = itr.status == 'Completed' ? BadgeVariant.default_ : itr.status == 'In Progress' ? BadgeVariant.outline : BadgeVariant.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(children: [
        Expanded(flex: 1, child: Text(itr.itrRefNo, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
        Expanded(flex: 2, child: Text(itr.projectName ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        if (!isMobile) Expanded(flex: 1, child: itr.discipline != null ? MadBadge(text: itr.discipline!, variant: BadgeVariant.secondary) : const Text('-')),
        Expanded(flex: 1, child: MadBadge(text: itr.status ?? 'Unknown', variant: variant)),
        MadDropdownMenuButton(items: [
          MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
          MadMenuItem(label: 'Preview', icon: LucideIcons.fileText, onTap: () {}),
          MadMenuItem(label: 'Mark Complete', icon: LucideIcons.circleCheck, onTap: () {}),
          MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
        ]),
      ]),
    );
  }

  Widget _buildPagination(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5)))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Page $_currentPage of $_totalPages', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
        Row(children: [
          MadButton(icon: LucideIcons.chevronLeft, variant: ButtonVariant.outline, size: ButtonSize.sm, disabled: _currentPage == 1, onPressed: () => setState(() => _currentPage--)),
          const SizedBox(width: 8),
          MadButton(icon: LucideIcons.chevronRight, variant: ButtonVariant.outline, size: ButtonSize.sm, disabled: _currentPage >= _totalPages, onPressed: () => setState(() => _currentPage++)),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(LucideIcons.clipboardCheck, size: 64, color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3)),
      const SizedBox(height: 24),
      Text('No ITRs yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
      const SizedBox(height: 8),
      Text('Create an installation test report', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
      const SizedBox(height: 24),
      MadButton(text: 'New ITR', icon: LucideIcons.plus, onPressed: () => _showITRDialog()),
    ])));
  }

  void _showITRDialog() {
    MadFormDialog.show(
      context: context,
      title: 'New Installation Test Report',
      maxWidth: 500,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        MadInput(labelText: 'ITR Reference No', hintText: 'ITR-XXX'),
        const SizedBox(height: 16),
        MadInput(labelText: 'Project Name', hintText: 'Enter project name'),
        const SizedBox(height: 16),
        MadSelect<String>(labelText: 'Discipline', placeholder: 'Select discipline', options: const [MadSelectOption(value: 'plumbing', label: 'Plumbing'), MadSelectOption(value: 'fire', label: 'Fire Fighting'), MadSelectOption(value: 'hvac', label: 'HVAC'), MadSelectOption(value: 'electrical', label: 'Electrical')], onChanged: (v) {}),
        const SizedBox(height: 16),
        MadTextarea(labelText: 'Test Description', hintText: 'Describe the installation test...', minLines: 3),
      ]),
      actions: [
        MadButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
        MadButton(text: 'Create ITR', onPressed: () { Navigator.pop(context); _loadITRs(); }),
      ],
    );
  }
}
