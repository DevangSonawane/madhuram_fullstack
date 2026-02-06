import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../models/stock_area.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Returns management page matching React's Returns page
class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  bool _isLoading = true;
  List<Return> _returns = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReturns();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReturns() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';

    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ApiClient.getReturns(projectId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() {
        _returns = data.map((e) => Return.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Return> get _filteredReturns {
    List<Return> result = _returns;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((r) {
        return r.material.toLowerCase().contains(query) ||
            r.reason.toLowerCase().contains(query);
      }).toList();
    }

    if (_statusFilter != null) {
      result = result.where((r) => r.status == _statusFilter).toList();
    }

    return result;
  }

  List<Return> get _paginatedReturns {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredReturns;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredReturns.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'Returns',
      route: '/returns',
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
                      'Returns',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage material returns and refunds',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'New Return',
                  icon: LucideIcons.packageX,
                  onPressed: () => _showReturnDialog(),
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
                    title: 'Total Returns',
                    value: _returns.length.toString(),
                    icon: LucideIcons.packageX,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Pending',
                    value: _returns.where((r) => r.status == 'Pending').length.toString(),
                    icon: LucideIcons.clock,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Processed',
                    value: _returns.where((r) => r.status == 'Processed').length.toString(),
                    icon: LucideIcons.circleCheck,
                    iconColor: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Rejected',
                    value: _returns.where((r) => r.status == 'Rejected').length.toString(),
                    icon: LucideIcons.circleX,
                    iconColor: AppTheme.lightDestructive,
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
                  hintText: 'Search returns...',
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
                    MadSelectOption(value: 'Processed', label: 'Processed'),
                    MadSelectOption(value: 'Rejected', label: 'Rejected'),
                  ],
                  onChanged: (value) => setState(() {
                    _statusFilter = value;
                    _currentPage = 1;
                  }),
                ),
              ),
              if (isMobile)
                MadButton(
                  icon: LucideIcons.packageX,
                  text: 'Return',
                  onPressed: () => _showReturnDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReturns.isEmpty
                    ? _buildEmptyState(isDark)
                    : MadCard(
                        child: Column(
                          children: [
                            // Table header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.3),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: Row(
                                children: [
                                  _buildHeaderCell('Date', flex: 1, isDark: isDark),
                                  _buildHeaderCell('Material', flex: 2, isDark: isDark),
                                  if (!isMobile) ...[
                                    _buildHeaderCell('Quantity', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Reason', flex: 2, isDark: isDark),
                                  ],
                                  _buildHeaderCell('Status', flex: 1, isDark: isDark),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            // Table rows
                            Expanded(
                              child: ListView.separated(
                                itemCount: _paginatedReturns.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                ),
                                itemBuilder: (context, index) {
                                  return _buildTableRow(_paginatedReturns[index], isDark, isMobile);
                                },
                              ),
                            ),
                            // Pagination
                            if (_totalPages > 1)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredReturns.length ? _filteredReturns.length : _currentPage * _itemsPerPage} of ${_filteredReturns.length}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                                      ),
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
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text('$_currentPage of $_totalPages'),
                                        ),
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
                              ),
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
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
        ),
      ),
    );
  }

  Widget _buildTableRow(Return returnItem, bool isDark, bool isMobile) {
    BadgeVariant statusVariant;
    switch (returnItem.status) {
      case 'Processed':
        statusVariant = BadgeVariant.default_;
        break;
      case 'Pending':
        statusVariant = BadgeVariant.secondary;
        break;
      case 'Rejected':
        statusVariant = BadgeVariant.destructive;
        break;
      default:
        statusVariant = BadgeVariant.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              returnItem.date ?? '-',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(returnItem.material, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (isMobile)
                  Text(
                    '${returnItem.quantity.toStringAsFixed(0)} - ${returnItem.reason}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Expanded(
              flex: 1,
              child: Text(
                returnItem.quantity.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                returnItem.reason,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          Expanded(
            flex: 1,
            child: MadBadge(text: returnItem.status, variant: statusVariant),
          ),
          MadDropdownMenuButton(
            items: [
              MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
              if (returnItem.status == 'Pending') ...[
                MadMenuItem(label: 'Approve', icon: LucideIcons.circleCheck, onTap: () {}),
                MadMenuItem(label: 'Reject', icon: LucideIcons.circleX, destructive: true, onTap: () {}),
              ],
              MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
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
              LucideIcons.packageX,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No returns yet' : 'No returns found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Create a return request for damaged or excess materials'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'New Return',
                icon: LucideIcons.packageX,
                onPressed: () => _showReturnDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReturnDialog() {
    MadFormDialog.show(
      context: context,
      title: 'New Return Request',
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadSelect<String>(
            labelText: 'Material',
            placeholder: 'Select material',
            searchable: true,
            options: const [
              MadSelectOption(value: 'cement', label: 'Cement OPC 53'),
              MadSelectOption(value: 'pvc', label: 'PVC Pipe 4"'),
              MadSelectOption(value: 'sand', label: 'River Sand'),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          MadInput(
            labelText: 'Quantity',
            hintText: 'Enter quantity to return',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          MadSelect<String>(
            labelText: 'Reason',
            placeholder: 'Select reason',
            options: const [
              MadSelectOption(value: 'damaged', label: 'Damaged'),
              MadSelectOption(value: 'defective', label: 'Defective'),
              MadSelectOption(value: 'excess', label: 'Excess Quantity'),
              MadSelectOption(value: 'wrong', label: 'Wrong Material'),
              MadSelectOption(value: 'other', label: 'Other'),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          MadTextarea(
            labelText: 'Additional Details',
            hintText: 'Provide more details about the return...',
            minLines: 3,
          ),
        ],
      ),
      actions: [
        MadButton(
          text: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        MadButton(
          text: 'Submit Return',
          onPressed: () {
            Navigator.pop(context);
            _loadReturns();
          },
        ),
      ],
    );
  }
}
