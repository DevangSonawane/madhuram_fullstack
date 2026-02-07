import 'package:flutter/material.dart' hide Material;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';
import '../models/material.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';
import '../demo_data/materials_demo.dart';

/// Materials (Product Master) page matching React's Materials page
class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  // START WITH DEMO DATA – never show blank
  bool _isLoading = false;
  List<Material> _materials = MaterialsDemo.materials
      .map((e) => Material.fromJson(e))
      .toList();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _categoryFilter;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Try to load real data in background; demo data already visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMaterials();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Seed with demo data when API is unavailable
  void _seedDemoData() {
    debugPrint('[Materials] API unavailable – falling back to demo data');
    setState(() {
      _materials = MaterialsDemo.materials.map((e) => Material.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadMaterials() async {
    try {
      final result = await ApiClient.getMaterials();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as List;
        final loaded = data.map((e) => Material.fromJson(e)).toList();
        if (loaded.isEmpty) {
          debugPrint('[Materials] API returned empty list – falling back to demo data');
          _seedDemoData();
        } else {
          setState(() {
            _materials = loaded;
            _isLoading = false;
          });
        }
      } else {
        _seedDemoData();
      }
    } catch (e) {
      debugPrint('[Materials] API error: $e – falling back to demo data');
      if (!mounted) return;
      _seedDemoData();
    }
  }

  List<Material> get _filteredMaterials {
    List<Material> result = _materials;
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.code.toLowerCase().contains(query) ||
            (item.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    if (_categoryFilter != null) {
      result = result.where((item) => item.category == _categoryFilter).toList();
    }
    
    return result;
  }

  List<Material> get _paginatedMaterials {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredMaterials;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredMaterials.length / _itemsPerPage).ceil();
  
  List<String> get _categories {
    return _materials
        .where((m) => m.category != null)
        .map((m) => m.category!)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

    return ProtectedRoute(
      title: 'Product Master',
      route: '/materials',
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
                      'Product Master',
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage materials and products inventory',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'Add Material',
                  icon: LucideIcons.plus,
                  onPressed: () => _showAddMaterialDialog(),
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
                    title: 'Total Materials',
                    value: _materials.length.toString(),
                    icon: LucideIcons.package,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Low Stock Items',
                    value: _materials.where((m) => m.isLowStock).length.toString(),
                    icon: LucideIcons.triangleAlert,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Categories',
                    value: _categories.length.toString(),
                    icon: LucideIcons.layoutGrid,
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
                  hintText: 'Search materials...',
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
              if (_categories.isNotEmpty)
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: MadSelect<String>(
                    value: _categoryFilter,
                    placeholder: 'All Categories',
                    clearable: true,
                    options: _categories.map((c) => MadSelectOption(value: c, label: c)).toList(),
                    onChanged: (value) => setState(() {
                      _categoryFilter = value;
                      _currentPage = 1;
                    }),
                  ),
                ),
              if (isMobile)
                MadButton(
                  icon: LucideIcons.plus,
                  text: 'Add',
                  onPressed: () => _showAddMaterialDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Data table or mobile cards
          Expanded(
            child: _isLoading
                ? MadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: MadTableSkeleton(rows: 8, columns: 6),
                    ),
                  )
                : _filteredMaterials.isEmpty
                    ? _buildEmptyState(isDark)
                    : isMobile
                        ? _buildMobileCardView(isDark)
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
                                      SizedBox(
                                        width: 40,
                                        child: MadCheckbox(
                                          value: _selectedIds.length == _paginatedMaterials.length && _paginatedMaterials.isNotEmpty,
                                          onChanged: (v) {
                                            setState(() {
                                              if (v) {
                                                _selectedIds.addAll(_paginatedMaterials.map((m) => m.id));
                                              } else {
                                                _selectedIds.removeAll(_paginatedMaterials.map((m) => m.id));
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildHeaderCell('Code', flex: 1, isDark: isDark),
                                      _buildHeaderCell('Name', flex: 2, isDark: isDark),
                                      _buildHeaderCell('Category', flex: 1, isDark: isDark),
                                      _buildHeaderCell('Unit', flex: 1, isDark: isDark),
                                      _buildHeaderCell('Stock', flex: 1, isDark: isDark),
                                      _buildHeaderCell('Unit Price', flex: 1, isDark: isDark),
                                      _buildHeaderCell('Status', flex: 1, isDark: isDark),
                                      const SizedBox(width: 48),
                                    ],
                                  ),
                                ),
                                // Table rows
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: _paginatedMaterials.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                    ),
                                    itemBuilder: (context, index) {
                                      return _buildTableRow(_paginatedMaterials[index], isDark, false);
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
                                      'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredMaterials.length ? _filteredMaterials.length : _currentPage * _itemsPerPage} of ${_filteredMaterials.length}',
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

  Widget _buildTableRow(Material item, bool isDark, bool isMobile) {
    final isSelected = _selectedIds.contains(item.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: MadCheckbox(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v) {
                    _selectedIds.add(item.id);
                  } else {
                    _selectedIds.remove(item.id);
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              item.code,
              style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                if (isMobile && item.category != null)
                  Text(
                    item.category!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: item.category != null
                ? MadBadge(text: item.category!, variant: BadgeVariant.secondary)
                : const Text('-'),
          ),
          Expanded(flex: 1, child: Text(item.unit, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 1,
            child: Text(
              item.stock?.toStringAsFixed(0) ?? '-',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: item.isLowStock ? AppTheme.lightDestructive : null,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item.unitPrice != null ? '₹${item.unitPrice!.toStringAsFixed(2)}' : '-',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: MadBadge(
              text: item.isLowStock ? 'Low Stock' : 'In Stock',
              variant: item.isLowStock ? BadgeVariant.destructive : BadgeVariant.default_,
            ),
          ),
          MadDropdownMenuButton(
            items: [
              MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
              MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () => _showEditMaterialDialog(item)),
              MadMenuItem(label: 'Adjust Stock', icon: LucideIcons.package, onTap: () => _showAdjustStockDialog(item)),
              MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () => _showDeleteConfirm(item)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCardView(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _paginatedMaterials.length + (_totalPages > 1 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _paginatedMaterials.length) {
          return _totalPages > 1
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page $_currentPage of $_totalPages',
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
                )
              : const SizedBox.shrink();
        }
        final item = _paginatedMaterials[index];
        final isSelected = _selectedIds.contains(item.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MadCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MadCheckbox(
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v) {
                              _selectedIds.add(item.id);
                            } else {
                              _selectedIds.remove(item.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.code,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                              ),
                            ),
                            if (item.category != null) ...[
                              const SizedBox(height: 8),
                              MadBadge(text: item.category!, variant: BadgeVariant.secondary),
                            ],
                          ],
                        ),
                      ),
                      MadDropdownMenuButton(
                        items: [
                          MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () => _showEditMaterialDialog(item)),
                          MadMenuItem(label: 'Adjust Stock', icon: LucideIcons.package, onTap: () => _showAdjustStockDialog(item)),
                          MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () => _showDeleteConfirm(item)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _mobileCardLabel(isDark, 'Unit', item.unit),
                      _mobileCardLabel(isDark, 'Stock', item.stock?.toStringAsFixed(0) ?? '-'),
                      _mobileCardLabel(isDark, 'Unit Price', item.unitPrice != null ? '₹${item.unitPrice!.toStringAsFixed(2)}' : '-'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MadBadge(
                    text: item.isLowStock ? 'Low Stock' : 'In Stock',
                    variant: item.isLowStock ? BadgeVariant.destructive : BadgeVariant.default_,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mobileCardLabel(bool isDark, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
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
              LucideIcons.package,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No materials yet' : 'No materials found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Add your first material to get started'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'Add Material',
                icon: LucideIcons.plus,
                onPressed: () => _showAddMaterialDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddMaterialDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final unitController = TextEditingController();
    final stockController = TextEditingController();
    final minStockController = TextEditingController();
    final unitPriceController = TextEditingController();

    MadFormDialog.show(
      context: context,
      title: 'Add Material',
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: MadInput(controller: codeController, labelText: 'Material Code', hintText: 'MAT-001')),
              const SizedBox(width: 16),
              Expanded(child: MadInput(controller: unitController, labelText: 'Unit', hintText: 'e.g. KG, Meters')),
            ],
          ),
          const SizedBox(height: 16),
          MadInput(controller: nameController, labelText: 'Material Name', hintText: 'Enter material name'),
          const SizedBox(height: 16),
          MadInput(controller: categoryController, labelText: 'Category', hintText: 'e.g. Civil, Plumbing'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: MadInput(controller: stockController, labelText: 'Initial Stock', hintText: '0', keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: MadInput(controller: minStockController, labelText: 'Min Stock Level', hintText: '0', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          MadInput(controller: unitPriceController, labelText: 'Unit Price', hintText: '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        ],
      ),
      actions: [
        MadButton(
          text: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        MadButton(
          text: 'Add Material',
          onPressed: () {
            Navigator.pop(context);
            _loadMaterials();
          },
        ),
      ],
    );
  }

  void _showEditMaterialDialog(Material item) {
    final codeController = TextEditingController(text: item.code);
    final nameController = TextEditingController(text: item.name);
    final categoryController = TextEditingController(text: item.category ?? '');
    final unitController = TextEditingController(text: item.unit);
    final stockController = TextEditingController(text: item.stock?.toString() ?? '');
    final minStockController = TextEditingController(text: item.minStock?.toString() ?? '');
    final unitPriceController = TextEditingController(text: item.unitPrice?.toString() ?? '');

    MadFormDialog.show(
      context: context,
      title: 'Edit Material',
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: MadInput(controller: codeController, labelText: 'Material Code', hintText: 'MAT-001')),
              const SizedBox(width: 16),
              Expanded(child: MadInput(controller: unitController, labelText: 'Unit', hintText: 'e.g. KG, Meters')),
            ],
          ),
          const SizedBox(height: 16),
          MadInput(controller: nameController, labelText: 'Material Name', hintText: 'Enter material name'),
          const SizedBox(height: 16),
          MadInput(controller: categoryController, labelText: 'Category', hintText: 'e.g. Civil, Plumbing'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: MadInput(controller: stockController, labelText: 'Stock', hintText: '0', keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: MadInput(controller: minStockController, labelText: 'Min Stock Level', hintText: '0', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          MadInput(controller: unitPriceController, labelText: 'Unit Price', hintText: '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        ],
      ),
      actions: [
        MadButton(
          text: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        MadButton(
          text: 'Save',
          onPressed: () {
            Navigator.pop(context);
            final stock = double.tryParse(stockController.text.trim());
            final minStock = double.tryParse(minStockController.text.trim());
            final unitPrice = double.tryParse(unitPriceController.text.trim());
            setState(() {
              final idx = _materials.indexWhere((m) => m.id == item.id);
              if (idx >= 0) {
                _materials[idx] = item.copyWith(
                  code: codeController.text.trim().isEmpty ? item.code : codeController.text.trim(),
                  name: nameController.text.trim().isEmpty ? item.name : nameController.text.trim(),
                  category: categoryController.text.trim().isEmpty ? item.category : categoryController.text.trim(),
                  unit: unitController.text.trim().isEmpty ? item.unit : unitController.text.trim(),
                  stock: stock ?? item.stock,
                  minStock: minStock ?? item.minStock,
                  unitPrice: unitPrice,
                );
              }
            });
            showToast(context, 'Update saved locally');
          },
        ),
      ],
    );
  }

  void _showDeleteConfirm(Material item) {
    MadDialog.confirm(
      context: context,
      title: 'Delete Material',
      description: 'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      setState(() {
        _materials.removeWhere((m) => m.id == item.id);
        _selectedIds.remove(item.id);
      });
      showToast(context, 'Material deleted');
    });
  }

  void _showAdjustStockDialog(Material item) {
    final qtyController = TextEditingController(text: item.stock?.toString() ?? '0');

    MadFormDialog.show(
      context: context,
      title: 'Adjust Stock',
      maxWidth: 400,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '${item.code} · Current: ${item.stock?.toStringAsFixed(0) ?? '0'} ${item.unit}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          MadInput(
            controller: qtyController,
            labelText: 'New quantity',
            hintText: '0',
            keyboardType: TextInputType.number,
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
          text: 'Update',
          onPressed: () {
            Navigator.pop(context);
            final newStock = double.tryParse(qtyController.text.trim());
            if (newStock != null) {
              setState(() {
                final idx = _materials.indexWhere((m) => m.id == item.id);
                if (idx >= 0) {
                  _materials[idx] = item.copyWith(stock: newStock);
                }
              });
              showToast(context, 'Stock updated');
            }
          },
        ),
      ],
    );
  }
}
