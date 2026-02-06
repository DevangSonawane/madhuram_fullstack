import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Material Abstract Statement model
class MASItem {
  final String id;
  final String itemCode;
  final String description;
  final String category;
  final String unit;
  final double boqQty;
  final double orderedQty;
  final double receivedQty;
  final double consumedQty;
  final double balanceQty;

  const MASItem({required this.id, required this.itemCode, required this.description, required this.category, required this.unit, required this.boqQty, required this.orderedQty, required this.receivedQty, required this.consumedQty, required this.balanceQty});

  double get percentage => boqQty > 0 ? (consumedQty / boqQty * 100) : 0;
}

/// Material Abstract Statement page
class MASPageFull extends StatefulWidget {
  const MASPageFull({super.key});
  @override
  State<MASPageFull> createState() => _MASPageFullState();
}

class _MASPageFullState extends State<MASPageFull> {
  bool _isLoading = false;
  List<MASItem> _items = [];
  String _searchQuery = '';
  String? _categoryFilter;
  final _searchController = TextEditingController();

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _items = [
        MASItem(id: '1', itemCode: 'C-101', description: 'Cement OPC 53', category: 'Civil', unit: 'Bags', boqQty: 1000, orderedQty: 800, receivedQty: 750, consumedQty: 600, balanceQty: 150),
        MASItem(id: '2', itemCode: 'P-201', description: 'PVC Pipe 4"', category: 'Plumbing', unit: 'Meters', boqQty: 500, orderedQty: 400, receivedQty: 380, consumedQty: 350, balanceQty: 30),
        MASItem(id: '3', itemCode: 'S-301', description: 'Steel Rods 12mm', category: 'Civil', unit: 'KG', boqQty: 5000, orderedQty: 4500, receivedQty: 4500, consumedQty: 4200, balanceQty: 300),
      ];
      _isLoading = false;
    });
  }

  List<MASItem> get _filteredItems {
    List<MASItem> result = _items;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((i) => i.itemCode.toLowerCase().contains(query) || i.description.toLowerCase().contains(query)).toList();
    }
    if (_categoryFilter != null) result = result.where((i) => i.category == _categoryFilter).toList();
    return result;
  }

  List<String> get _categories => _items.map((i) => i.category).toSet().toList();

  double get _totalBOQValue => _items.fold(0, (sum, i) => sum + i.boqQty);
  double get _totalConsumed => _items.fold(0, (sum, i) => sum + i.consumedQty);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return ProtectedRoute(
      title: 'Material Abstract Statement',
      route: '/mas',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Material Abstract Statement', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
            const SizedBox(height: 4),
            Text('Summary of material quantities and consumption', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
          ])),
          if (!isMobile) Row(children: [
            MadButton(text: 'Export Excel', icon: LucideIcons.fileSpreadsheet, variant: ButtonVariant.outline, onPressed: () {}),
            const SizedBox(width: 12),
            MadButton(text: 'Export PDF', icon: LucideIcons.download, onPressed: () {}),
          ]),
        ]),
        const SizedBox(height: 24),
        if (!isMobile) Row(children: [
          Expanded(child: StatCard(title: 'Total Items', value: _items.length.toString(), icon: LucideIcons.package, iconColor: AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'BOQ Quantity', value: _totalBOQValue.toStringAsFixed(0), icon: LucideIcons.clipboardList, iconColor: const Color(0xFF8B5CF6))),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Consumed', value: _totalConsumed.toStringAsFixed(0), icon: LucideIcons.trendingDown, iconColor: const Color(0xFFF59E0B))),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Progress', value: _totalBOQValue > 0 ? '${(_totalConsumed / _totalBOQValue * 100).toStringAsFixed(1)}%' : '0%', icon: LucideIcons.chartPie, iconColor: const Color(0xFF22C55E))),
        ]),
        if (!isMobile) const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: isMobile ? double.infinity : 320, child: MadSearchInput(controller: _searchController, hintText: 'Search items...', onChanged: (v) => setState(() => _searchQuery = v), onClear: () => setState(() => _searchQuery = ''))),
          if (_categories.isNotEmpty) SizedBox(width: 150, child: MadSelect<String>(value: _categoryFilter, placeholder: 'All Categories', clearable: true, options: _categories.map((c) => MadSelectOption(value: c, label: c)).toList(), onChanged: (v) => setState(() => _categoryFilter = v))),
        ]),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : _filteredItems.isEmpty ? _buildEmptyState(isDark) : MadCard(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.3), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                child: Row(children: [
                  _buildHeaderCell('Code', flex: 1, isDark: isDark),
                  _buildHeaderCell('Description', flex: 2, isDark: isDark),
                  if (!isMobile) ...[_buildHeaderCell('BOQ', flex: 1, isDark: isDark), _buildHeaderCell('Ordered', flex: 1, isDark: isDark), _buildHeaderCell('Received', flex: 1, isDark: isDark), _buildHeaderCell('Consumed', flex: 1, isDark: isDark), _buildHeaderCell('Balance', flex: 1, isDark: isDark)],
                  _buildHeaderCell('Progress', flex: 1, isDark: isDark),
                ]),
              ),
              Expanded(child: ListView.separated(
                itemCount: _filteredItems.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5)),
                itemBuilder: (context, index) => _buildTableRow(_filteredItems[index], isDark, isMobile),
              )),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, required bool isDark}) => Expanded(flex: flex, child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)));

  Widget _buildTableRow(MASItem item, bool isDark, bool isMobile) {
    final progressColor = item.percentage > 80 ? const Color(0xFF22C55E) : item.percentage > 50 ? const Color(0xFFF59E0B) : AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(flex: 1, child: Text(item.itemCode, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12))),
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text('${item.unit} | ${item.category}', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
        ])),
        if (!isMobile) ...[
          Expanded(flex: 1, child: Text(item.boqQty.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
          Expanded(flex: 1, child: Text(item.orderedQty.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
          Expanded(flex: 1, child: Text(item.receivedQty.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
          Expanded(flex: 1, child: Text(item.consumedQty.toStringAsFixed(0), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(flex: 1, child: Text(item.balanceQty.toStringAsFixed(0), style: TextStyle(fontSize: 13, color: item.balanceQty < 0 ? AppTheme.lightDestructive : null))),
        ],
        Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${item.percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: progressColor)),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: item.percentage / 100, backgroundColor: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5), valueColor: AlwaysStoppedAnimation<Color>(progressColor), minHeight: 4)),
        ])),
      ]),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(LucideIcons.chartBar, size: 64, color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3)),
      const SizedBox(height: 24),
      Text('No data available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
      const SizedBox(height: 8),
      Text('Add BOQ items to see the material abstract statement', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
    ])));
  }
}
