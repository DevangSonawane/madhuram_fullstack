import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';

/// Hierarchical models for Warehouse -> Zone -> Rack
class WarehouseModel {
  final String id;
  final String name;
  final String location;
  final String status;
  final double totalCapacity;
  final double currentStock;

  const WarehouseModel({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.totalCapacity,
    required this.currentStock,
  });

  double get utilizationPercent =>
      totalCapacity > 0 ? (currentStock / totalCapacity) * 100 : 0;
}

class ZoneModel {
  final String id;
  final String name;
  final String warehouseId;
  final List<String> rackIds;

  const ZoneModel({
    required this.id,
    required this.name,
    required this.warehouseId,
    required this.rackIds,
  });
}

class RackModel {
  final String id;
  final String name;
  final String zoneId;

  const RackModel({
    required this.id,
    required this.name,
    required this.zoneId,
  });
}

/// Stock Areas page matching React's hierarchical Warehouse -> Zone -> Rack
class StockAreasPage extends StatefulWidget {
  const StockAreasPage({super.key});

  @override
  State<StockAreasPage> createState() => _StockAreasPageState();
}

class _StockAreasPageState extends State<StockAreasPage> {
  bool _isLoading = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  late List<WarehouseModel> _warehouses;
  late List<ZoneModel> _zones;
  late List<RackModel> _racks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _warehouses = [
        const WarehouseModel(
          id: 'wh1',
          name: 'Main Warehouse',
          location: 'Site A',
          status: 'Active',
          totalCapacity: 10000,
          currentStock: 7200,
        ),
        const WarehouseModel(
          id: 'wh2',
          name: 'Secondary Store',
          location: 'Site B',
          status: 'Active',
          totalCapacity: 5000,
          currentStock: 2100,
        ),
        const WarehouseModel(
          id: 'wh3',
          name: 'Overflow Storage',
          location: 'Site A',
          status: 'Active',
          totalCapacity: 3000,
          currentStock: 450,
        ),
      ];
      _zones = [
        const ZoneModel(id: 'zA', name: 'Zone A', warehouseId: 'wh1', rackIds: ['A-1', 'A-2', 'A-3']),
        const ZoneModel(id: 'zB', name: 'Zone B', warehouseId: 'wh1', rackIds: ['B-1', 'B-2']),
        const ZoneModel(id: 'zC', name: 'Zone C', warehouseId: 'wh2', rackIds: ['C-1', 'C-2']),
        const ZoneModel(id: 'zD', name: 'Zone D', warehouseId: 'wh3', rackIds: ['D-1']),
      ];
      _racks = [
        const RackModel(id: 'A-1', name: 'A-1', zoneId: 'zA'),
        const RackModel(id: 'A-2', name: 'A-2', zoneId: 'zA'),
        const RackModel(id: 'A-3', name: 'A-3', zoneId: 'zA'),
        const RackModel(id: 'B-1', name: 'B-1', zoneId: 'zB'),
        const RackModel(id: 'B-2', name: 'B-2', zoneId: 'zB'),
        const RackModel(id: 'C-1', name: 'C-1', zoneId: 'zC'),
        const RackModel(id: 'C-2', name: 'C-2', zoneId: 'zC'),
        const RackModel(id: 'D-1', name: 'D-1', zoneId: 'zD'),
      ];
      _isLoading = false;
    });
  }

  List<WarehouseModel> get _filteredWarehouses {
    if (_searchQuery.isEmpty) return _warehouses;
    final q = _searchQuery.toLowerCase();
    return _warehouses.where((w) {
      if (w.name.toLowerCase().contains(q) || w.location.toLowerCase().contains(q)) return true;
      final zoneNames = _zones.where((z) => z.warehouseId == w.id).map((z) => z.name.toLowerCase());
      if (zoneNames.any((n) => n.contains(q))) return true;
      return false;
    }).toList();
  }

  List<ZoneModel> zonesForWarehouse(String warehouseId) =>
      _zones.where((z) => z.warehouseId == warehouseId).toList();

  List<RackModel> racksForZone(ZoneModel zone) =>
      _racks.where((r) => zone.rackIds.contains(r.id)).toList();

  double get _totalCapacity => _warehouses.fold(0, (s, w) => s + w.totalCapacity);
  double get _totalCurrentStock => _warehouses.fold(0, (s, w) => s + w.currentStock);
  double get _utilizationPercent =>
      _totalCapacity > 0 ? (_totalCurrentStock / _totalCapacity) * 100 : 0;

  void _addWarehouse(WarehouseModel w) {
    setState(() {
      _warehouses = [..._warehouses, w];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

    return ProtectedRoute(
      title: 'Stock Overview',
      route: '/stock-areas',
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
                      'Stock Overview',
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
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
                  text: 'Add Warehouse',
                  icon: LucideIcons.plus,
                  onPressed: () => _showAddWarehouseDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          if (!isMobile)
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Areas',
                    value: _warehouses.length.toString(),
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
                    value: '${_utilizationPercent.toStringAsFixed(1)}%',
                    icon: LucideIcons.chartPie,
                    iconColor: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          if (!isMobile) const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: MadSearchInput(
                  controller: _searchController,
                  hintText: 'Search warehouses...',
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onClear: () => setState(() => _searchQuery = ''),
                ),
              ),
              if (isMobile) ...[
                const SizedBox(width: 12),
                MadButton(
                  icon: LucideIcons.plus,
                  size: ButtonSize.icon,
                  onPressed: () => _showAddWarehouseDialog(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWarehouses.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        itemCount: _filteredWarehouses.length,
                        itemBuilder: (context, index) =>
                            _buildWarehouseExpansion(_filteredWarehouses[index], isDark),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseExpansion(WarehouseModel warehouse, bool isDark) {
    final util = warehouse.utilizationPercent;
    final utilColor = util > 90
        ? AppTheme.lightDestructive
        : util > 70
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);
    final zones = zonesForWarehouse(warehouse.id);

    return MadCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: _filteredWarehouses.length <= 3,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(LucideIcons.warehouse, color: AppTheme.primaryColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warehouse.location,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            MadBadge(
              text: warehouse.status,
              variant: warehouse.status == 'Active' ? BadgeVariant.default_ : BadgeVariant.secondary,
            ),
            const SizedBox(width: 16),
            Text(
              'Capacity: ${warehouse.currentStock.toStringAsFixed(0)} / ${warehouse.totalCapacity.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${util.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: utilColor),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Utilization',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                  Text(
                    '${util.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: utilColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: util / 100,
                  backgroundColor:
                      (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(utilColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        children: [
          ...zones.map((zone) {
            final racks = racksForZone(zone);
            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
              leading: Icon(
                LucideIcons.mapPin,
                size: 20,
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
              title: Text(
                zone.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                ),
              ),
              subtitle: Text(
                '${racks.length} rack(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                ),
              ),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: racks
                      .map(
                        (rack) => Chip(
                          avatar: Icon(LucideIcons.box, size: 16, color: AppTheme.primaryColor),
                          label: Text(rack.name, overflow: TextOverflow.ellipsis),
                          backgroundColor:
                              (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          }),
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
              LucideIcons.warehouse,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)
                  .withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No warehouses yet' : 'No warehouses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Add your first warehouse to organize inventory'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'Add Warehouse',
                icon: LucideIcons.plus,
                onPressed: () => _showAddWarehouseDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddWarehouseDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    String status = 'Active';

    MadFormDialog.show(
      context: context,
      title: 'Add Warehouse',
      maxWidth: 500,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MadInput(
                controller: nameController,
                labelText: 'Warehouse Name',
                hintText: 'e.g. Main Warehouse',
              ),
              const SizedBox(height: 16),
              MadInput(
                controller: locationController,
                labelText: 'Location',
                hintText: 'e.g. Site A',
              ),
              const SizedBox(height: 16),
              MadSelect<String>(
                labelText: 'Status',
                value: status,
                placeholder: 'Select status',
                options: const [
                  MadSelectOption(value: 'Active', label: 'Active'),
                  MadSelectOption(value: 'Inactive', label: 'Inactive'),
                  MadSelectOption(value: 'Maintenance', label: 'Maintenance'),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => status = value);
                },
              ),
            ],
          );
        },
      ),
      actions: [
        MadButton(
          text: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        MadButton(
          text: 'Add Warehouse',
          onPressed: () {
            final name = nameController.text.trim();
            final location = locationController.text.trim();
            if (name.isEmpty) return;
            final id = 'wh_${DateTime.now().millisecondsSinceEpoch}';
            _addWarehouse(WarehouseModel(
              id: id,
              name: name,
              location: location.isEmpty ? '—' : location,
              status: status,
              totalCapacity: 0,
              currentStock: 0,
            ));
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
