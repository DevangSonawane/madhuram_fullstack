import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';

/// Material Entry Report model
class MER {
  final String id;
  final String merNo;
  final String material;
  final double quantity;
  final String unit;
  final String? vendor;
  final String? challanNo;
  final String? date;
  final String status;

  const MER({required this.id, required this.merNo, required this.material, required this.quantity, required this.unit, this.vendor, this.challanNo, this.date, this.status = 'Pending'});
}

/// Material Entry Report page
class MERPageFull extends StatefulWidget {
  const MERPageFull({super.key});
  @override
  State<MERPageFull> createState() => _MERPageFullState();
}

class _MERPageFullState extends State<MERPageFull> {
  bool _isLoading = false;
  List<MER> _entries = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _entries = [
        MER(id: '1', merNo: 'MER-001', material: 'Cement OPC 53', quantity: 500, unit: 'Bags', vendor: 'ABC Suppliers', challanNo: 'DC-001', date: '2024-01-20', status: 'Verified'),
        MER(id: '2', merNo: 'MER-002', material: 'PVC Pipe 4"', quantity: 200, unit: 'Meters', vendor: 'XYZ Traders', challanNo: 'DC-002', date: '2024-01-22', status: 'Pending'),
      ];
      _isLoading = false;
    });
  }

  List<MER> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    final query = _searchQuery.toLowerCase();
    return _entries.where((e) => e.merNo.toLowerCase().contains(query) || e.material.toLowerCase().contains(query)).toList();
  }

  List<MER> get _paginatedEntries {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredEntries;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredEntries.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

    return ProtectedRoute(
      title: 'Material Entry Report',
      route: '/mer',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Material Entry Report', style: TextStyle(fontSize: responsive.value<double>(mobile: 22, tablet: 26, desktop: 28), fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
            const SizedBox(height: 4),
            Text('Record and verify material entries', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground), overflow: TextOverflow.ellipsis, maxLines: 1),
          ])),
          if (!isMobile) MadButton(text: 'New Entry', icon: LucideIcons.plus, onPressed: () => _showEntryDialog()),
        ]),
        const SizedBox(height: 24),
        if (!isMobile) Row(children: [
          Expanded(child: StatCard(title: 'Total Entries', value: _entries.length.toString(), icon: LucideIcons.clipboardList, iconColor: AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Pending', value: _entries.where((e) => e.status == 'Pending').length.toString(), icon: LucideIcons.clock, iconColor: const Color(0xFFF59E0B))),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Verified', value: _entries.where((e) => e.status == 'Verified').length.toString(), icon: LucideIcons.circleCheck, iconColor: const Color(0xFF22C55E))),
        ]),
        if (!isMobile) const SizedBox(height: 24),
        Row(children: [
          Expanded(child: MadSearchInput(controller: _searchController, hintText: 'Search entries...', onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }), onClear: () => setState(() { _searchQuery = ''; _currentPage = 1; }))),
          if (isMobile) ...[const SizedBox(width: 12), MadButton(icon: LucideIcons.plus, size: ButtonSize.icon, onPressed: () => _showEntryDialog())],
        ]),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : _filteredEntries.isEmpty ? _buildEmptyState(isDark) : MadCard(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withValues(alpha: 0.3), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                child: Row(children: [
                  _buildHeaderCell('MER #', flex: 1, isDark: isDark),
                  _buildHeaderCell('Material', flex: 2, isDark: isDark),
                  if (!isMobile) ...[_buildHeaderCell('Quantity', flex: 1, isDark: isDark), _buildHeaderCell('Challan', flex: 1, isDark: isDark)],
                  _buildHeaderCell('Status', flex: 1, isDark: isDark),
                  const SizedBox(width: 48),
                ]),
              ),
              Expanded(child: ListView.separated(
                itemCount: _paginatedEntries.length,
                separatorBuilder: (_, _2) => Divider(height: 1, color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.5)),
                itemBuilder: (context, index) => _buildTableRow(_paginatedEntries[index], isDark, isMobile),
              )),
              if (_totalPages > 1) _buildPagination(isDark),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, required bool isDark}) => Expanded(flex: flex, child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)));

  Widget _buildTableRow(MER entry, bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(children: [
        Expanded(flex: 1, child: Text(entry.merNo, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.material, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          if (isMobile) Text('${entry.quantity} ${entry.unit}', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
        ])),
        if (!isMobile) ...[
          Expanded(flex: 1, child: Text('${entry.quantity.toStringAsFixed(0)} ${entry.unit}', overflow: TextOverflow.ellipsis)),
          Expanded(flex: 1, child: Text(entry.challanNo ?? '-', overflow: TextOverflow.ellipsis)),
        ],
        Expanded(flex: 1, child: MadBadge(text: entry.status, variant: entry.status == 'Verified' ? BadgeVariant.default_ : BadgeVariant.secondary)),
        MadDropdownMenuButton(items: [
          MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
          MadMenuItem(label: 'Verify', icon: LucideIcons.circleCheck, onTap: () {}),
          MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
        ]),
      ]),
    );
  }

  Widget _buildPagination(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.5)))),
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
      Icon(LucideIcons.clipboardList, size: 64, color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withValues(alpha: 0.3)),
      const SizedBox(height: 24),
      Text('No material entries yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
      const SizedBox(height: 8),
      Text('Record material entries as they arrive', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
      const SizedBox(height: 24),
      MadButton(text: 'New Entry', icon: LucideIcons.plus, onPressed: () => _showEntryDialog()),
    ])));
  }

  void _showEntryDialog() {
    MadFormDialog.show(
      context: context,
      title: 'New Material Entry',
      maxWidth: 500,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        MadSelect<String>(labelText: 'Material', placeholder: 'Select material', searchable: true, options: const [MadSelectOption(value: 'cement', label: 'Cement OPC 53'), MadSelectOption(value: 'pvc', label: 'PVC Pipe 4"')], onChanged: (v) {}),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: MadInput(labelText: 'Quantity', hintText: '0', keyboardType: TextInputType.number)),
          const SizedBox(width: 16),
          Expanded(child: MadSelect<String>(labelText: 'Unit', placeholder: 'Select', options: const [MadSelectOption(value: 'bags', label: 'Bags'), MadSelectOption(value: 'meters', label: 'Meters')], onChanged: (v) {})),
        ]),
        const SizedBox(height: 16),
        MadSelect<String>(labelText: 'Challan Reference', placeholder: 'Link to challan (optional)', options: const [MadSelectOption(value: 'dc1', label: 'DC-001'), MadSelectOption(value: 'dc2', label: 'DC-002')], onChanged: (v) {}),
        const SizedBox(height: 16),
        MadTextarea(labelText: 'Remarks', hintText: 'Any observations...', minLines: 2),
      ]),
      actions: [
        MadButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
        MadButton(text: 'Record Entry', onPressed: () { Navigator.pop(context); _loadEntries(); }),
      ],
    );
  }
}
