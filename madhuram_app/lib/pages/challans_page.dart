import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/layout/main_layout.dart';
import '../components/ui/components.dart';
import '../models/challan.dart';
import '../services/api_client.dart';
import '../store/app_state.dart';
import '../theme/app_theme.dart';

class ChallansPageFull extends StatefulWidget {
  const ChallansPageFull({super.key});

  @override
  State<ChallansPageFull> createState() => _ChallansPageFullState();
}

class _ChallansPageFullState extends State<ChallansPageFull> {
  bool _isLoading = false;
  List<Challan> _challans = [];
  String _searchQuery = '';
  String _lastProjectId = '';
  String? _emptyReason;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      const candidateKeys = [
        'data',
        'items',
        'rows',
        'records',
        'challans',
        'result',
      ];
      for (final key in candidateKeys) {
        if (raw.containsKey(key)) {
          final extracted = _extractList(raw[key]);
          if (extracted.isNotEmpty) return extracted;
        }
      }
      for (final value in raw.values) {
        final extracted = _extractList(value);
        if (extracted.isNotEmpty) return extracted;
      }
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChallans());
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _challans = [];
        _emptyReason = 'No project selected';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiClient.getChallansByProject(projectId);
      if (!mounted) return;

      final raw = result['data'];
      final data = _extractList(raw);

      if (result['success'] == true && data.isNotEmpty) {
        final loaded = data
            .whereType<Map>()
            .map((e) => Challan.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _challans = loaded;
          _isLoading = false;
          _emptyReason = null;
        });
      } else {
        setState(() {
          _challans = [];
          _isLoading = false;
          _emptyReason = result['error']?.toString();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _challans = [];
        _isLoading = false;
        _emptyReason = 'Failed to load challans';
      });
    }
  }

  List<Challan> get _filteredChallans {
    final term = _searchQuery.trim().toLowerCase();
    if (term.isEmpty) return _challans;
    return _challans.where((x) {
      final challanNumber = x.challanNumber.toLowerCase();
      final poNumber = (x.poNumber ?? '').toLowerCase();
      return challanNumber.contains(term) || poNumber.contains(term);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final selectedProjectId =
        StoreProvider.of<AppState>(context).state.project.selectedProjectId ?? '';
    if (selectedProjectId != _lastProjectId) {
      _lastProjectId = selectedProjectId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadChallans());
    }

    final pendingCount = _challans.where((x) => x.status == 'incomplete').length;
    final verifiedCount = _challans.where((x) => x.status == 'completed').length;
    final totalCount = _challans.length;

    if (isMobile) {
      return ProtectedRoute(
        title: 'Delivery Challans',
        route: '/challans',
        child: SingleChildScrollView(
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
              const SizedBox(height: 8),
              Text(
                'Create and track delivery challans.',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkMutedForeground
                      : AppTheme.lightMutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: MadButton(
                  text: 'Record New Delivery',
                  icon: LucideIcons.truck,
                  onPressed: () => Navigator.pushNamed(context, '/challans/new')
                      .then((_) => _loadChallans()),
                ),
              ),
              const SizedBox(height: 24),
              _metricCard(
                title: 'Pending Verification',
                value: pendingCount.toString(),
                icon: LucideIcons.triangleAlert,
                iconColor: const Color(0xFFEAB308),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _metricCard(
                title: 'Verified Today',
                value: verifiedCount.toString(),
                icon: LucideIcons.circleCheck,
                iconColor: const Color(0xFF22C55E),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _metricCard(
                title: 'Total Deliveries',
                value: totalCount.toString(),
                icon: LucideIcons.truck,
                iconColor: isDark
                    ? AppTheme.darkMutedForeground
                    : AppTheme.lightMutedForeground,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              Text(
                'Challan History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: MadSearchInput(
                  controller: _searchController,
                  hintText: 'Search challan no, PO no...',
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                  }),
                  onClear: () => setState(() {
                    _searchQuery = '';
                  }),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredChallans.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      _emptyReason == null || _emptyReason!.isEmpty
                          ? 'No delivery challans found.'
                          : _emptyReason!,
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkMutedForeground
                            : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ),
                )
              else
                _buildMobileList(isDark, embeddedInPage: true),
            ],
          ),
        ),
      );
    }

    return ProtectedRoute(
      title: 'Delivery Challans',
      route: '/challans',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: isDark
                              ? AppTheme.darkForeground
                              : AppTheme.lightForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create and track delivery challans.',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkMutedForeground
                              : AppTheme.lightMutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                MadButton(
                  text: 'Record New Delivery',
                  icon: LucideIcons.truck,
                  onPressed: () => Navigator.pushNamed(context, '/challans/new')
                      .then((_) => _loadChallans()),
                ),
              ],
          ),
          const SizedBox(height: 24),

          Row(
              children: [
                Expanded(
                  child: _metricCard(
                    title: 'Pending Verification',
                    value: pendingCount.toString(),
                    icon: LucideIcons.triangleAlert,
                    iconColor: const Color(0xFFEAB308),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _metricCard(
                    title: 'Verified Today',
                    value: verifiedCount.toString(),
                    icon: LucideIcons.circleCheck,
                    iconColor: const Color(0xFF22C55E),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _metricCard(
                    title: 'Total Deliveries',
                    value: totalCount.toString(),
                    icon: LucideIcons.truck,
                    iconColor: isDark
                        ? AppTheme.darkMutedForeground
                        : AppTheme.lightMutedForeground,
                    isDark: isDark,
                  ),
                ),
              ],
          ),
          const SizedBox(height: 24),

          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Challan History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: MadSearchInput(
                    controller: _searchController,
                    hintText: 'Search challan no, PO no...',
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                    }),
                    onClear: () => setState(() {
                      _searchQuery = '';
                    }),
                  ),
                ),
              ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChallans.isEmpty
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          _emptyReason == null || _emptyReason!.isEmpty
                              ? 'No delivery challans found.'
                              : _emptyReason!,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkMutedForeground
                                : AppTheme.lightMutedForeground,
                          ),
                        ),
                      )
                    : _buildDesktopTable(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted)
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _header('Challan No', flex: 2, isDark: isDark),
              _header('Date', flex: 2, isDark: isDark),
              _header('PO No', flex: 2, isDark: isDark),
              _header('Items', flex: 3, isDark: isDark),
              _header('Counts', flex: 2, isDark: isDark, align: TextAlign.right),
              _header('Status', flex: 2, isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _filteredChallans.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                  .withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              final dc = _filteredChallans[index];
              final statusVariant = dc.status == 'completed'
                  ? BadgeVariant.default_
                  : BadgeVariant.secondary;
              final date = dc.challanDate ??
                  dc.orderDate ??
                  (dc.createdAt?.toIso8601String() ?? '');
              final items = dc.items
                  .map((it) => it.name)
                  .where((n) => n.isNotEmpty)
                  .join(', ');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        dc.challanNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(flex: 2, child: Text(date)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        dc.poNumber ?? dc.poId ?? '',
                        style:
                            const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(items, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${dc.totalPoItems ?? '—'} / ${dc.totalChallanItems ?? dc.items.length}',
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: MadBadge(text: dc.status, variant: statusVariant),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(bool isDark, {bool embeddedInPage = false}) {
    return ListView.separated(
      shrinkWrap: embeddedInPage,
      physics: embeddedInPage
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: _filteredChallans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final dc = _filteredChallans[index];
        final statusVariant =
            dc.status == 'completed' ? BadgeVariant.default_ : BadgeVariant.secondary;
        final date = dc.challanDate ??
            dc.orderDate ??
            (dc.createdAt?.toIso8601String() ?? '');
        final items = dc.items.map((it) => it.name).where((n) => n.isNotEmpty).join(', ');

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dc.challanNumber,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkMutedForeground
                                  : AppTheme.lightMutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MadBadge(text: dc.status, variant: statusVariant),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PO Ref',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.darkMutedForeground
                                  : AppTheme.lightMutedForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dc.poNumber ?? dc.poId ?? '',
                            style:
                                const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.darkMutedForeground
                                  : AppTheme.lightMutedForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(items, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(
    String text, {
    required int flex,
    required bool isDark,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return MadCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppTheme.darkMutedForeground
                          : AppTheme.lightMutedForeground,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: iconColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
