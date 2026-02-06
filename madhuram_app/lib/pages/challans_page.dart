import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../models/challan.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Delivery Challans page
class ChallansPageFull extends StatefulWidget {
  const ChallansPageFull({super.key});

  @override
  State<ChallansPageFull> createState() => _ChallansPageFullState();
}

class _ChallansPageFullState extends State<ChallansPageFull> {
  bool _isLoading = true;
  List<Challan> _challans = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChallans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChallans() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';

    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ApiClient.getChallansByProject(projectId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() {
        _challans = data.map((e) => Challan.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Challan> get _filteredChallans {
    List<Challan> result = _challans;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((c) {
        return c.challanNo.toLowerCase().contains(query) ||
            (c.vendor?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_statusFilter != null) {
      result = result.where((c) => c.status == _statusFilter).toList();
    }

    return result;
  }

  List<Challan> get _paginatedChallans {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredChallans;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredChallans.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'Delivery Challans',
      route: '/challans',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Challans',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track material deliveries and receipts',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'New Challan',
                  icon: LucideIcons.plus,
                  onPressed: () => _showChallanDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats cards
          if (!isMobile)
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Challans',
                    value: _challans.length.toString(),
                    icon: LucideIcons.truck,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Pending',
                    value: _challans.where((c) => c.status == 'Pending').length.toString(),
                    icon: LucideIcons.clock,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Received',
                    value: _challans.where((c) => c.status == 'Received').length.toString(),
                    icon: LucideIcons.packageCheck,
                    iconColor: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          if (!isMobile) const SizedBox(height: 24),

          // Search and filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 320,
                child: MadSearchInput(
                  controller: _searchController,
                  hintText: 'Search challans...',
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
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
                    MadSelectOption(value: 'In Transit', label: 'In Transit'),
                    MadSelectOption(value: 'Received', label: 'Received'),
                    MadSelectOption(value: 'Partial', label: 'Partial'),
                  ],
                  onChanged: (value) => setState(() {
                    _statusFilter = value;
                    _currentPage = 1;
                  }),
                ),
              ),
              if (isMobile)
                MadButton(
                  icon: LucideIcons.plus,
                  text: 'New',
                  onPressed: () => _showChallanDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChallans.isEmpty
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
                                  _buildHeaderCell('Challan #', flex: 1, isDark: isDark),
                                  _buildHeaderCell('Vendor', flex: 2, isDark: isDark),
                                  if (!isMobile) ...[
                                    _buildHeaderCell('Date', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Items', flex: 1, isDark: isDark),
                                  ],
                                  _buildHeaderCell('Status', flex: 1, isDark: isDark),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _paginatedChallans.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                ),
                                itemBuilder: (context, index) => _buildTableRow(_paginatedChallans[index], isDark, isMobile),
                              ),
                            ),
                            if (_totalPages > 1) _buildPagination(isDark),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, required bool isDark}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
    );
  }

  Widget _buildTableRow(Challan challan, bool isDark, bool isMobile) {
    BadgeVariant statusVariant = challan.status == 'Received' ? BadgeVariant.default_ : challan.status == 'Pending' ? BadgeVariant.secondary : BadgeVariant.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(challan.challanNo, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
          Expanded(flex: 2, child: Text(challan.vendor ?? '-')),
          if (!isMobile) ...[
            Expanded(flex: 1, child: Text(challan.date ?? '-', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground))),
            Expanded(flex: 1, child: Text('${challan.items ?? 0} items')),
          ],
          Expanded(flex: 1, child: MadBadge(text: challan.status, variant: statusVariant)),
          MadDropdownMenuButton(items: [
            MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
            MadMenuItem(label: 'Mark Received', icon: LucideIcons.packageCheck, onTap: () {}),
            MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
          ]),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredChallans.length ? _filteredChallans.length : _currentPage * _itemsPerPage} of ${_filteredChallans.length}', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
          Row(children: [
            MadButton(icon: LucideIcons.chevronLeft, variant: ButtonVariant.outline, size: ButtonSize.sm, disabled: _currentPage == 1, onPressed: () => setState(() => _currentPage--)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('$_currentPage of $_totalPages')),
            MadButton(icon: LucideIcons.chevronRight, variant: ButtonVariant.outline, size: ButtonSize.sm, disabled: _currentPage >= _totalPages, onPressed: () => setState(() => _currentPage++)),
          ]),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.truck, size: 64, color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3)),
          const SizedBox(height: 24),
          Text(_searchQuery.isEmpty ? 'No delivery challans yet' : 'No challans found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
          const SizedBox(height: 8),
          Text(_searchQuery.isEmpty ? 'Record a delivery challan to track shipments' : 'Try a different search term', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
          if (_searchQuery.isEmpty) ...[const SizedBox(height: 24), MadButton(text: 'New Challan', icon: LucideIcons.plus, onPressed: () => _showChallanDialog())],
        ]),
      ),
    );
  }

  void _showChallanDialog() {
    MadFormDialog.show(
      context: context,
      title: 'New Delivery Challan',
      maxWidth: 500,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: MadInput(labelText: 'Challan Number', hintText: 'DC-XXX')),
          const SizedBox(width: 16),
          Expanded(child: MadInput(labelText: 'Date', hintText: 'Select date')),
        ]),
        const SizedBox(height: 16),
        MadSelect<String>(labelText: 'Vendor', placeholder: 'Select vendor', searchable: true, options: const [MadSelectOption(value: 'abc', label: 'ABC Suppliers'), MadSelectOption(value: 'xyz', label: 'XYZ Traders')], onChanged: (v) {}),
        const SizedBox(height: 16),
        MadSelect<String>(labelText: 'Purchase Order', placeholder: 'Link to PO (optional)', options: const [MadSelectOption(value: 'po1', label: 'PO-001'), MadSelectOption(value: 'po2', label: 'PO-002')], onChanged: (v) {}),
        const SizedBox(height: 16),
        MadTextarea(labelText: 'Notes', hintText: 'Delivery notes...', minLines: 2),
      ]),
      actions: [
        MadButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
        MadButton(text: 'Create Challan', onPressed: () { Navigator.pop(context); _loadChallans(); }),
      ],
    );
  }
}
