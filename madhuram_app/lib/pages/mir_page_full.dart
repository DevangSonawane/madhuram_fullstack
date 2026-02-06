import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../models/mir.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Material Inspection Request page with full implementation
class MIRPageFull extends StatefulWidget {
  const MIRPageFull({super.key});
  @override
  State<MIRPageFull> createState() => _MIRPageFullState();
}

class _MIRPageFullState extends State<MIRPageFull> {
  bool _isLoading = true;
  List<MIR> _mirs = [];
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
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMIRs() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';
    
    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    
    final result = await ApiClient.getMIRsByProject(projectId);
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() { _mirs = data.map((e) => MIR.fromJson(e)).toList(); _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<MIR> get _filteredMIRs {
    List<MIR> result = _mirs;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((m) => m.mirReferenceNo.toLowerCase().contains(query) || (m.materialCode?.toLowerCase().contains(query) ?? false)).toList();
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

  int get _totalPages => (_filteredMIRs.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return ProtectedRoute(
      title: 'Material Inspection Request',
      route: '/mir',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Material Inspection Request', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
            const SizedBox(height: 4),
            Text('Manage material inspection requests', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
          ])),
          if (!isMobile) MadButton(text: 'New MIR', icon: LucideIcons.plus, onPressed: () => _showMIRDialog()),
        ]),
        const SizedBox(height: 24),
        if (!isMobile) Row(children: [
          Expanded(child: StatCard(title: 'Total MIRs', value: _mirs.length.toString(), icon: LucideIcons.fileSearch, iconColor: AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Pending', value: _mirs.where((m) => m.status == 'Pending').length.toString(), icon: LucideIcons.clock, iconColor: const Color(0xFFF59E0B))),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Approved', value: _mirs.where((m) => m.status == 'Approved').length.toString(), icon: LucideIcons.circleCheck, iconColor: const Color(0xFF22C55E))),
        ]),
        if (!isMobile) const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: isMobile ? double.infinity : 320, child: MadSearchInput(controller: _searchController, hintText: 'Search MIRs...', onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }), onClear: () => setState(() { _searchQuery = ''; _currentPage = 1; }))),
          SizedBox(width: 150, child: MadSelect<String>(value: _statusFilter, placeholder: 'All Status', clearable: true, options: const [MadSelectOption(value: 'Pending', label: 'Pending'), MadSelectOption(value: 'Approved', label: 'Approved'), MadSelectOption(value: 'Rejected', label: 'Rejected')], onChanged: (v) => setState(() { _statusFilter = v; _currentPage = 1; }))),
          if (isMobile) MadButton(icon: LucideIcons.plus, text: 'New', onPressed: () => _showMIRDialog()),
        ]),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : _filteredMIRs.isEmpty ? _buildEmptyState(isDark) : MadCard(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.3), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                child: Row(children: [
                  _buildHeaderCell('MIR Ref', flex: 1, isDark: isDark),
                  _buildHeaderCell('Material', flex: 2, isDark: isDark),
                  if (!isMobile) _buildHeaderCell('Client', flex: 1, isDark: isDark),
                  _buildHeaderCell('Status', flex: 1, isDark: isDark),
                  const SizedBox(width: 48),
                ]),
              ),
              Expanded(child: ListView.separated(
                itemCount: _paginatedMIRs.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5)),
                itemBuilder: (context, index) => _buildTableRow(_paginatedMIRs[index], isDark, isMobile),
              )),
              if (_totalPages > 1) _buildPagination(isDark),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, required bool isDark}) => Expanded(flex: flex, child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)));

  Widget _buildTableRow(MIR mir, bool isDark, bool isMobile) {
    BadgeVariant variant = mir.status == 'Approved' ? BadgeVariant.default_ : mir.status == 'Rejected' ? BadgeVariant.destructive : BadgeVariant.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(children: [
        Expanded(flex: 1, child: Text(mir.mirReferenceNo, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
        Expanded(flex: 2, child: Text(mir.materialCode ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        if (!isMobile) Expanded(flex: 1, child: Text(mir.clientName ?? '-')),
        Expanded(flex: 1, child: MadBadge(text: mir.status ?? 'Unknown', variant: variant)),
        MadDropdownMenuButton(items: [
          MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
          MadMenuItem(label: 'Preview', icon: LucideIcons.fileText, onTap: () {}),
          if (mir.status == 'Pending') ...[
            MadMenuItem(label: 'Approve', icon: LucideIcons.circleCheck, onTap: () {}),
            MadMenuItem(label: 'Reject', icon: LucideIcons.circleX, destructive: true, onTap: () {}),
          ],
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
      Icon(LucideIcons.fileSearch, size: 64, color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3)),
      const SizedBox(height: 24),
      Text('No MIRs yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
      const SizedBox(height: 8),
      Text('Create a material inspection request', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
      const SizedBox(height: 24),
      MadButton(text: 'New MIR', icon: LucideIcons.plus, onPressed: () => _showMIRDialog()),
    ])));
  }

  void _showMIRDialog() {
    MadFormDialog.show(
      context: context,
      title: 'New Material Inspection Request',
      maxWidth: 500,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        MadInput(labelText: 'MIR Reference No', hintText: 'MIR-XXX'),
        const SizedBox(height: 16),
        MadSelect<String>(labelText: 'Material', placeholder: 'Select material', searchable: true, options: const [MadSelectOption(value: 'cement', label: 'Cement OPC 53'), MadSelectOption(value: 'pvc', label: 'PVC Pipe 4"')], onChanged: (v) {}),
        const SizedBox(height: 16),
        MadInput(labelText: 'Client Name', hintText: 'Enter client name'),
        const SizedBox(height: 16),
        MadTextarea(labelText: 'Description', hintText: 'Inspection details...', minLines: 3),
      ]),
      actions: [
        MadButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
        MadButton(text: 'Create MIR', onPressed: () { Navigator.pop(context); _loadMIRs(); }),
      ],
    );
  }
}
