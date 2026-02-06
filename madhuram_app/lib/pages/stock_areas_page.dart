import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';
import '../models/stock_area.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Stock Areas page matching React's StockAreas page
class StockAreasPage extends StatefulWidget {
  const StockAreasPage({super.key});

  @override
  State<StockAreasPage> createState() => _StockAreasPageState();
}

class _StockAreasPageState extends State<StockAreasPage> {
  bool _isLoading = true;
  List<StockArea> _stockAreas = [];
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStockAreas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStockAreas() async {
    final result = await ApiClient.getStockAreas();

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() {
        _stockAreas = data.map((e) => StockArea.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<StockArea> get _filteredAreas {
    if (_searchQuery.isEmpty) return _stockAreas;
    final query = _searchQuery.toLowerCase();
    return _stockAreas.where((area) {
      return area.name.toLowerCase().contains(query) ||
          (area.location?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  double get _totalCapacity => _stockAreas.fold(0, (sum, a) => sum + (a.capacity ?? 0));
  double get _totalCurrentStock => _stockAreas.fold(0, (sum, a) => sum + (a.currentStock ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'Stock Overview',
      route: '/stock-areas',
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
                      'Stock Overview',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage warehouses and stock areas',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'Add Stock Area',
                  icon: LucideIcons.plus,
                  onPressed: () => _showAddAreaDialog(),
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
                    title: 'Total Areas',
                    value: _stockAreas.length.toString(),
                    icon: LucideIcons.warehouse,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Total Capacity',
                    value: _totalCapacity.toStringAsFixed(0),
                    icon: LucideIcons.box,
                    iconColor: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Current Stock',
                    value: _totalCurrentStock.toStringAsFixed(0),
                    icon: LucideIcons.package,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Utilization',
                    value: _totalCapacity > 0 
                        ? '${((_totalCurrentStock / _totalCapacity) * 100).toStringAsFixed(1)}%'
                        : '0%',
                    icon: LucideIcons.chartPie,
                    iconColor: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          if (!isMobile) const SizedBox(height: 24),

          // Search
          Row(
            children: [
              Expanded(
                child: MadSearchInput(
                  controller: _searchController,
                  hintText: 'Search stock areas...',
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onClear: () => setState(() => _searchQuery = ''),
                ),
              ),
              if (isMobile) ...[
                const SizedBox(width: 12),
                MadButton(
                  icon: LucideIcons.plus,
                  size: ButtonSize.icon,
                  onPressed: () => _showAddAreaDialog(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Stock areas grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAreas.isEmpty
                    ? _buildEmptyState(isDark)
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : (screenWidth > 1200 ? 3 : 2),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 2.5 : 1.8,
                        ),
                        itemCount: _filteredAreas.length,
                        itemBuilder: (context, index) => _buildAreaCard(_filteredAreas[index], isDark),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard(StockArea area, bool isDark) {
    final utilizationPercent = area.utilizationPercent;
    final utilizationColor = utilizationPercent > 90
        ? AppTheme.lightDestructive
        : utilizationPercent > 70
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);

    return MadCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        area.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (area.location != null)
                        Text(
                          area.location!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.warehouse,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Utilization bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Utilization',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                    Text(
                      '${utilizationPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: utilizationColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: utilizationPercent / 100,
                    backgroundColor: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(utilizationColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Stock',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                        ),
                      ),
                      Text(
                        area.currentStock?.toStringAsFixed(0) ?? '0',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capacity',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                        ),
                      ),
                      Text(
                        area.capacity?.toStringAsFixed(0) ?? '0',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Actions
            Row(
              children: [
                Expanded(
                  child: MadButton(
                    text: 'View Details',
                    variant: ButtonVariant.outline,
                    size: ButtonSize.sm,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                MadDropdownMenuButton(
                  items: [
                    MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () {}),
                    MadMenuItem(label: 'Transfer Stock', icon: LucideIcons.arrowLeftRight, onTap: () {}),
                    MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
                  ],
                ),
              ],
            ),
          ],
        ),
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
              LucideIcons.warehouse,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No stock areas yet' : 'No areas found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Add your first stock area to organize inventory'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'Add Stock Area',
                icon: LucideIcons.plus,
                onPressed: () => _showAddAreaDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddAreaDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final capacityController = TextEditingController();
    final descriptionController = TextEditingController();

    MadFormDialog.show(
      context: context,
      title: 'Add Stock Area',
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadInput(controller: nameController, labelText: 'Area Name', hintText: 'e.g. Main Warehouse'),
          const SizedBox(height: 16),
          MadInput(controller: locationController, labelText: 'Location', hintText: 'e.g. Site A, Building 1'),
          const SizedBox(height: 16),
          MadInput(
            controller: capacityController,
            labelText: 'Capacity',
            hintText: 'Maximum storage capacity',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          MadTextarea(
            controller: descriptionController,
            labelText: 'Description',
            hintText: 'Optional description...',
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
          text: 'Add Area',
          onPressed: () {
            Navigator.pop(context);
            _loadStockAreas();
          },
        ),
      ],
    );
  }
}
