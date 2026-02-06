import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../models/stock_area.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Stock Transfers page matching React's StockTransfers page
class StockTransfersPage extends StatefulWidget {
  const StockTransfersPage({super.key});

  @override
  State<StockTransfersPage> createState() => _StockTransfersPageState();
}

class _StockTransfersPageState extends State<StockTransfersPage> {
  bool _isLoading = true;
  List<StockTransfer> _transfers = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransfers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransfers() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';

    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ApiClient.getStockTransfers(projectId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() {
        _transfers = data.map((e) => StockTransfer.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<StockTransfer> get _filteredTransfers {
    List<StockTransfer> result = _transfers;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) {
        return t.fromArea.toLowerCase().contains(query) ||
            t.toArea.toLowerCase().contains(query) ||
            t.material.toLowerCase().contains(query);
      }).toList();
    }

    if (_statusFilter != null) {
      result = result.where((t) => t.status == _statusFilter).toList();
    }

    return result;
  }

  List<StockTransfer> get _paginatedTransfers {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredTransfers;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredTransfers.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'Stock Transfers',
      route: '/stock-transfers',
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
                      'Stock Transfers',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transfer materials between stock areas',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'New Transfer',
                  icon: LucideIcons.arrowLeftRight,
                  onPressed: () => _showTransferDialog(),
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
                    title: 'Total Transfers',
                    value: _transfers.length.toString(),
                    icon: LucideIcons.arrowLeftRight,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Pending',
                    value: _transfers.where((t) => t.status == 'Pending').length.toString(),
                    icon: LucideIcons.clock,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Completed',
                    value: _transfers.where((t) => t.status == 'Completed').length.toString(),
                    icon: LucideIcons.circleCheck,
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
                  hintText: 'Search transfers...',
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
                    MadSelectOption(value: 'Completed', label: 'Completed'),
                  ],
                  onChanged: (value) => setState(() {
                    _statusFilter = value;
                    _currentPage = 1;
                  }),
                ),
              ),
              if (isMobile)
                MadButton(
                  icon: LucideIcons.arrowLeftRight,
                  text: 'Transfer',
                  onPressed: () => _showTransferDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransfers.isEmpty
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
                                    _buildHeaderCell('From', flex: 1, isDark: isDark),
                                    _buildHeaderCell('To', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Quantity', flex: 1, isDark: isDark),
                                  ],
                                  _buildHeaderCell('Status', flex: 1, isDark: isDark),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            // Table rows
                            Expanded(
                              child: ListView.separated(
                                itemCount: _paginatedTransfers.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                ),
                                itemBuilder: (context, index) {
                                  return _buildTableRow(_paginatedTransfers[index], isDark, isMobile);
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
                                      'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredTransfers.length ? _filteredTransfers.length : _currentPage * _itemsPerPage} of ${_filteredTransfers.length}',
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

  Widget _buildTableRow(StockTransfer transfer, bool isDark, bool isMobile) {
    BadgeVariant statusVariant;
    switch (transfer.status) {
      case 'Completed':
        statusVariant = BadgeVariant.default_;
        break;
      case 'Pending':
        statusVariant = BadgeVariant.secondary;
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
              transfer.date ?? '-',
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
                Text(transfer.material, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (isMobile)
                  Text(
                    '${transfer.fromArea} → ${transfer.toArea}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(LucideIcons.arrowUp, size: 14, color: AppTheme.lightDestructive),
                  const SizedBox(width: 4),
                  Flexible(child: Text(transfer.fromArea, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(LucideIcons.arrowDown, size: 14, color: const Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                  Flexible(child: Text(transfer.toArea, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                transfer.quantity.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
          Expanded(
            flex: 1,
            child: MadBadge(text: transfer.status, variant: statusVariant),
          ),
          MadDropdownMenuButton(
            items: [
              MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
              if (transfer.status == 'Pending')
                MadMenuItem(label: 'Complete', icon: LucideIcons.circleCheck, onTap: () {}),
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
              LucideIcons.arrowLeftRight,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No transfers yet' : 'No transfers found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Create a transfer to move materials between areas'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'New Transfer',
                icon: LucideIcons.arrowLeftRight,
                onPressed: () => _showTransferDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTransferDialog() {
    MadFormDialog.show(
      context: context,
      title: 'New Stock Transfer',
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadSelect<String>(
            labelText: 'Material',
            placeholder: 'Select material',
            options: const [
              MadSelectOption(value: 'cement', label: 'Cement OPC 53'),
              MadSelectOption(value: 'pvc', label: 'PVC Pipe 4"'),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MadSelect<String>(
                  labelText: 'From Area',
                  placeholder: 'Select source',
                  options: const [
                    MadSelectOption(value: 'main', label: 'Main Warehouse'),
                    MadSelectOption(value: 'secondary', label: 'Secondary Store'),
                  ],
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MadSelect<String>(
                  labelText: 'To Area',
                  placeholder: 'Select destination',
                  options: const [
                    MadSelectOption(value: 'main', label: 'Main Warehouse'),
                    MadSelectOption(value: 'secondary', label: 'Secondary Store'),
                  ],
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MadInput(
            labelText: 'Quantity',
            hintText: 'Enter quantity to transfer',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          MadTextarea(
            labelText: 'Notes',
            hintText: 'Optional notes...',
            minLines: 2,
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
          text: 'Create Transfer',
          onPressed: () {
            Navigator.pop(context);
            _loadTransfers();
          },
        ),
      ],
    );
  }
}
