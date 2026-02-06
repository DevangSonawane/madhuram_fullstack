import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../models/stock_area.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Consumption tracking page matching React's Consumption page
class ConsumptionPage extends StatefulWidget {
  const ConsumptionPage({super.key});

  @override
  State<ConsumptionPage> createState() => _ConsumptionPageState();
}

class _ConsumptionPageState extends State<ConsumptionPage> {
  bool _isLoading = true;
  List<Consumption> _consumptions = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _floorFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConsumptions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConsumptions() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';

    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ApiClient.getConsumption(projectId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() {
        _consumptions = data.map((e) => Consumption.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Consumption> get _filteredConsumptions {
    List<Consumption> result = _consumptions;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((c) {
        return c.material.toLowerCase().contains(query);
      }).toList();
    }

    if (_floorFilter != null) {
      result = result.where((c) => c.floor == _floorFilter).toList();
    }

    return result;
  }

  List<Consumption> get _paginatedConsumptions {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredConsumptions;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredConsumptions.length / _itemsPerPage).ceil();

  double get _totalQuantity => _consumptions.fold(0, (sum, c) => sum + c.quantity);

  List<String> get _floors {
    return _consumptions
        .where((c) => c.floor != null)
        .map((c) => c.floor!)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'Consumption',
      route: '/consumption',
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
                      'Consumption',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track material consumption across floors',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'Record Consumption',
                  icon: LucideIcons.plus,
                  onPressed: () => _showConsumptionDialog(),
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
                    title: 'Total Records',
                    value: _consumptions.length.toString(),
                    icon: LucideIcons.clipboardList,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Total Consumed',
                    value: _totalQuantity.toStringAsFixed(0),
                    icon: LucideIcons.packageMinus,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Floors',
                    value: _floors.length.toString(),
                    icon: LucideIcons.building2,
                    iconColor: const Color(0xFF8B5CF6),
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
                  hintText: 'Search consumption records...',
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
              if (_floors.isNotEmpty)
                SizedBox(
                  width: 150,
                  child: MadSelect<String>(
                    value: _floorFilter,
                    placeholder: 'All Floors',
                    clearable: true,
                    options: _floors.map((f) => MadSelectOption(value: f, label: f)).toList(),
                    onChanged: (value) => setState(() {
                      _floorFilter = value;
                      _currentPage = 1;
                    }),
                  ),
                ),
              if (isMobile)
                MadButton(
                  icon: LucideIcons.plus,
                  text: 'Record',
                  onPressed: () => _showConsumptionDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConsumptions.isEmpty
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
                                    _buildHeaderCell('Unit', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Floor', flex: 1, isDark: isDark),
                                  ],
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            // Table rows
                            Expanded(
                              child: ListView.separated(
                                itemCount: _paginatedConsumptions.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                ),
                                itemBuilder: (context, index) {
                                  return _buildTableRow(_paginatedConsumptions[index], isDark, isMobile);
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
                                      'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredConsumptions.length ? _filteredConsumptions.length : _currentPage * _itemsPerPage} of ${_filteredConsumptions.length}',
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

  Widget _buildTableRow(Consumption consumption, bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              consumption.date ?? '-',
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
                Text(consumption.material, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (isMobile && consumption.floor != null)
                  Text(
                    '${consumption.quantity} ${consumption.unit} - ${consumption.floor}',
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
              child: Text(
                consumption.quantity.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(flex: 1, child: Text(consumption.unit)),
            Expanded(
              flex: 1,
              child: consumption.floor != null
                  ? MadBadge(text: consumption.floor!, variant: BadgeVariant.secondary)
                  : const Text('-'),
            ),
          ],
          MadDropdownMenuButton(
            items: [
              MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
              MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () {}),
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
              LucideIcons.packageMinus,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No consumption records yet' : 'No records found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Record material consumption to track usage'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'Record Consumption',
                icon: LucideIcons.plus,
                onPressed: () => _showConsumptionDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showConsumptionDialog() {
    MadFormDialog.show(
      context: context,
      title: 'Record Consumption',
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
          Row(
            children: [
              Expanded(
                child: MadInput(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MadSelect<String>(
                  labelText: 'Unit',
                  placeholder: 'Select',
                  options: const [
                    MadSelectOption(value: 'bags', label: 'Bags'),
                    MadSelectOption(value: 'meters', label: 'Meters'),
                    MadSelectOption(value: 'kg', label: 'KG'),
                    MadSelectOption(value: 'liters', label: 'Liters'),
                  ],
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MadSelect<String>(
            labelText: 'Floor',
            placeholder: 'Select floor',
            options: const [
              MadSelectOption(value: 'ground', label: 'Ground Floor'),
              MadSelectOption(value: '1st', label: '1st Floor'),
              MadSelectOption(value: '2nd', label: '2nd Floor'),
              MadSelectOption(value: '3rd', label: '3rd Floor'),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          MadTextarea(
            labelText: 'Remarks',
            hintText: 'Optional remarks...',
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
          text: 'Record',
          onPressed: () {
            Navigator.pop(context);
            _loadConsumptions();
          },
        ),
      ],
    );
  }
}
