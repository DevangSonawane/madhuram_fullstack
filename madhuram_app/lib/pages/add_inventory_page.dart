import 'package:flutter/material.dart' hide Material;
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../models/inventory.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';
import '../utils/formatters.dart';
import '../store/project_actions.dart';

class AddInventoryPage extends StatefulWidget {
  const AddInventoryPage({super.key});

  @override
  State<AddInventoryPage> createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  final _brandController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  String? _activeProjectId;
  bool _stockIn = true;
  bool _loading = false;
  bool _saving = false;
  String _stockFilter = 'all';
  String _searchTerm = '';
  List<InventoryItem> _items = [];
  bool _didInitLoad = false;

  @override
  void dispose() {
    _brandController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    if (_activeProjectId == null || _activeProjectId!.isEmpty) {
      setState(() => _items = []);
      return;
    }

    setState(() => _loading = true);
    final result = await ApiClient.getInventoriesByProject(_activeProjectId!);
    if (!mounted) return;

    if (result['success'] == true && result['data'] is List) {
      final data = (result['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _items = data.map(InventoryItem.fromJson).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _createInventory() async {
    if (_activeProjectId == null || _activeProjectId!.isEmpty) {
      showToast(context, 'Select a project first');
      return;
    }
    if (_brandController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
      showToast(context, 'Brand and item name are required');
      return;
    }

    setState(() => _saving = true);
    final payload = {
      'project_id': _activeProjectId,
      'brand': _brandController.text.trim(),
      'name': _nameController.text.trim(),
      'quantity': double.tryParse(_quantityController.text.trim()) ?? 0,
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'stockin': _stockIn,
    };

    final result = await ApiClient.createInventory(payload);
    if (!mounted) return;

    setState(() => _saving = false);
    if (result['success'] == true) {
      _brandController.clear();
      _nameController.clear();
      _quantityController.clear();
      _priceController.clear();
      setState(() => _stockIn = true);
      await _loadItems();
      if (!mounted) return;
      showToast(context, 'Inventory item created');
    } else {
      showToast(context, (result['error'] ?? 'Failed to create inventory').toString());
    }
  }

  List<InventoryItem> get _filteredItems {
    final query = _searchTerm.trim().toLowerCase();
    return _items.where((item) {
      final matchesSearch = query.isEmpty ||
          item.brand.toLowerCase().contains(query) ||
          item.name.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query);
      final matchesStock = _stockFilter == 'all' ||
          (_stockFilter == 'in' && item.stockIn) ||
          (_stockFilter == 'out' && !item.stockIn);
      return matchesSearch && matchesStock;
    }).toList();
  }

  double get _totalQuantity => _filteredItems.fold(0, (sum, i) => sum + i.quantity);
  double get _totalValue => _filteredItems.fold(0, (sum, i) => sum + i.value);

  String _valueText(double value, {bool decimals = false}) {
    return decimals ? Formatters.indianNumber(value) : Formatters.integer(value);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StoreConnector<AppState, _InventoryViewModel>(
      converter: (store) => _InventoryViewModel(
        projects: store.state.project.projects,
        selectedProjectId: store.state.project.selectedProjectId,
      ),
      builder: (context, vm) {
        _activeProjectId ??= vm.selectedProjectId;
        if (!_didInitLoad) {
          _didInitLoad = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
        }

        final projectOptions = vm.projects.map((p) {
          final id = p['id']?.toString() ?? p['project_id']?.toString() ?? '';
          final name = p['name']?.toString() ?? p['project_name']?.toString() ?? 'Project $id';
          return MadSelectOption<String>(value: id, label: name);
        }).toList();

        return ProtectedRoute(
          title: 'Add Inventory',
          route: '/inventory/add',
          headerLeadingIcon: LucideIcons.arrowLeft,
          onHeaderLeadingPressed: () => Navigator.pushReplacementNamed(context, '/projects'),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStats(responsive, isDark),
                      SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
                      if (responsive.isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 380,
                              child: _buildForm(projectOptions),
                            ),
                            SizedBox(width: responsive.spacing),
                            Expanded(child: _buildTable(isDark, responsive)),
                          ],
                        )
                      else ...[
                        _buildForm(projectOptions),
                        SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
                        _buildTable(isDark, responsive),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStats(Responsive responsive, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: responsive.value(mobile: 2, tablet: 2, desktop: 4),
      crossAxisSpacing: responsive.value(mobile: 8, tablet: 12, desktop: 16),
      mainAxisSpacing: responsive.value(mobile: 8, tablet: 12, desktop: 16),
      childAspectRatio: responsive.value(mobile: 1.55, tablet: 1.85, desktop: 2.15),
      children: [
        _statTile(
          title: 'Total Items',
          value: _filteredItems.length.toString(),
          subtitle: 'Matching current filters',
          isDark: isDark,
        ),
        _statTile(
          title: 'Total Quantity',
          value: _valueText(_totalQuantity),
          subtitle: 'Units across visible rows',
          isDark: isDark,
        ),
        _statTile(
          title: 'Inventory Value',
          value: Formatters.currency(_totalValue),
          subtitle: 'Quantity x price',
          isDark: isDark,
        ),
        _statTile(
          title: 'In Stock',
          value: _filteredItems.where((it) => it.stockIn).length.toString(),
          subtitle: 'Items currently available',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _statTile({
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
  }) {
    return MadCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(List<MadSelectOption<String>> projectOptions) {
    return MadCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.packagePlus, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('New Item', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Mapped fields: project_id, brand, quantity, name, price, stockin.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkMutedForeground
                    : AppTheme.lightMutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            MadSelect<String>(
              labelText: 'Project',
              placeholder: 'Select project',
              value: _activeProjectId,
              options: projectOptions,
              onChanged: (value) {
                setState(() => _activeProjectId = value);
                final store = StoreProvider.of<AppState>(context);
                final match = store.state.project.projects.firstWhere(
                  (p) => (p['id']?.toString() ?? p['project_id']?.toString()) == value,
                  orElse: () => const {},
                );
                if (match.isNotEmpty) {
                  store.dispatch(SelectProject(match));
                }
                _loadItems();
              },
            ),
            const SizedBox(height: 12),
            MadInput(controller: _brandController, labelText: 'Brand', hintText: 'e.g. ACC'),
            const SizedBox(height: 12),
            MadInput(controller: _nameController, labelText: 'Item Name', hintText: 'e.g. Cement Bag'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MadInput(
                    controller: _quantityController,
                    labelText: 'Quantity',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MadInput(
                    controller: _priceController,
                    labelText: 'Price',
                    hintText: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MadSelect<String>(
              labelText: 'Stock Status',
              value: _stockIn ? 'in' : 'out',
              options: const [
                MadSelectOption(value: 'in', label: 'In Stock'),
                MadSelectOption(value: 'out', label: 'Out of Stock'),
              ],
              onChanged: (value) => setState(() => _stockIn = value == 'in'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: MadButton(
                text: _saving ? 'Saving...' : '+ Add inventory',
                disabled: _saving || _activeProjectId == null || _activeProjectId!.isEmpty,
                onPressed: _saving ? null : _createInventory,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(bool isDark, Responsive responsive) {
    final isMobile = responsive.isMobile;

    return MadCard(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 2 : 6, 4, isMobile ? 2 : 6, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.boxes, size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Project Inventory',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current items for the selected project.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isMobile) ...[
                    SizedBox(
                      width: double.infinity,
                      child: MadInput(
                        hintText: 'Search...',
                        prefix: Icon(
                          LucideIcons.search,
                          size: 16,
                          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                        ),
                        onChanged: (value) => setState(() => _searchTerm = value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: MadSelect<String>(
                            value: _stockFilter,
                            options: const [
                              MadSelectOption(value: 'all', label: 'All'),
                              MadSelectOption(value: 'in', label: 'In Stock'),
                              MadSelectOption(value: 'out', label: 'Out Stock'),
                            ],
                            onChanged: (value) => setState(() => _stockFilter = value ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MadButton(
                          icon: LucideIcons.refreshCw,
                          variant: ButtonVariant.outline,
                          size: ButtonSize.icon,
                          loading: _loading,
                          disabled: _activeProjectId == null || _activeProjectId!.isEmpty,
                          onPressed: _loading ? null : _loadItems,
                        ),
                      ],
                    ),
                  ] else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          child: MadInput(
                            hintText: 'Search...',
                            prefix: Icon(
                              LucideIcons.search,
                              size: 16,
                              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                            ),
                            onChanged: (value) => setState(() => _searchTerm = value),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: MadSelect<String>(
                            value: _stockFilter,
                            options: const [
                              MadSelectOption(value: 'all', label: 'All'),
                              MadSelectOption(value: 'in', label: 'In Stock'),
                              MadSelectOption(value: 'out', label: 'Out Stock'),
                            ],
                            onChanged: (value) => setState(() => _stockFilter = value ?? 'all'),
                          ),
                        ),
                        MadButton(
                          icon: LucideIcons.refreshCw,
                          variant: ButtonVariant.outline,
                          size: ButtonSize.icon,
                          loading: _loading,
                          disabled: _activeProjectId == null || _activeProjectId!.isEmpty,
                          onPressed: _loading ? null : _loadItems,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final tableHeight = (responsive.value(
                  mobile: 420.0,
                  tablet: 460.0,
                  desktop: 520.0,
                ) as num)
                    .toDouble();
                final tableWidth = constraints.maxWidth < 820 ? 820.0 : constraints.maxWidth;

                return Container(
                  height: tableHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 24.0,
                          headingRowHeight: 44,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 56,
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Brand')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Quantity'), numeric: true),
                            DataColumn(label: Text('Price'), numeric: true),
                            DataColumn(label: Text('Value'), numeric: true),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: _loading
                              ? [
                                  const DataRow(
                                    cells: [
                                      DataCell(Text('Loading...')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                    ],
                                  ),
                                ]
                              : _filteredItems.isEmpty
                                  ? [
                                      const DataRow(
                                        cells: [
                                          DataCell(Text('No inventory items found.')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                        ],
                                      ),
                                    ]
                                  : _filteredItems.map((item) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              item.id,
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          DataCell(Text(item.brand)),
                                          DataCell(Text(item.name)),
                                          DataCell(Text(_valueText(item.quantity))),
                                          DataCell(Text(Formatters.currency(item.price))),
                                          DataCell(Text(Formatters.currency(item.value))),
                                          DataCell(
                                            MadBadge(
                                              text: item.stockIn ? 'In Stock' : 'Out of Stock',
                                              variant: item.stockIn
                                                  ? BadgeVariant.default_
                                                  : BadgeVariant.secondary,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryViewModel {
  final List<Map<String, dynamic>> projects;
  final String? selectedProjectId;

  _InventoryViewModel({
    required this.projects,
    required this.selectedProjectId,
  });
}
