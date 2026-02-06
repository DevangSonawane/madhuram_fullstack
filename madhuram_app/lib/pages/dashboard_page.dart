import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../components/ui/mad_card.dart';
import '../components/ui/mad_button.dart';
import '../components/ui/stat_card.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';

/// Dashboard page matching React's Dashboard.jsx - Responsive version
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  
  // Dashboard data from API
  List<Map<String, dynamic>> _consumptionData = [];
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';
    
    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ApiClient.getDashboardStats(projectId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _stats = {
          'total_value': data['total_value'] ?? '₹0',
          'total_value_change': (data['total_value_change'] as num?)?.toDouble() ?? 0.0,
          'active_orders': data['active_orders']?.toString() ?? '0',
          'active_orders_change': (data['active_orders_change'] as num?)?.toDouble() ?? 0.0,
          'low_stock_items': data['low_stock_items']?.toString() ?? '0',
          'total_materials': data['total_materials']?.toString() ?? '0',
          'warehouses': data['warehouses'] ?? 0,
        };
        
        final chartData = data['consumption_chart'] as List<dynamic>? ?? [];
        _consumptionData = chartData.map((e) => <String, dynamic>{
          'name': e['name'] ?? '',
          'total': (e['total'] as num?)?.toInt() ?? 0,
        }).toList();
        
        final activityData = data['recent_activity'] as List<dynamic>? ?? [];
        _recentActivity = activityData.map((e) => <String, dynamic>{
          'user': e['user'] ?? 'Unknown',
          'action': e['action'] ?? '',
          'time': e['time'] ?? '',
          'status': e['status'] ?? 'info',
          'initials': e['initials'] ?? 'U',
        }).toList();
        
        _isLoading = false;
      });
    } else {
      setState(() {
        _stats = {
          'total_value': '₹0',
          'total_value_change': 0.0,
          'active_orders': '0',
          'active_orders_change': 0.0,
          'low_stock_items': '0',
          'total_materials': '0',
          'warehouses': 0,
        };
        _consumptionData = [];
        _recentActivity = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _DashboardViewModel>(
      converter: (store) => _DashboardViewModel(
        isAuthenticated: store.state.auth.isAuthenticated,
        selectedProject: store.state.project.selectedProject,
      ),
      builder: (context, vm) {
        if (!vm.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.selectedProject == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/projects');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildDashboard(context, vm);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, _DashboardViewModel vm) {
    final List<Map<String, dynamic>> consumptionData = _consumptionData.isNotEmpty ? _consumptionData : <Map<String, dynamic>>[
      {'name': 'Jan', 'total': 0},
      {'name': 'Feb', 'total': 0},
      {'name': 'Mar', 'total': 0},
    ];
    
    final List<Map<String, dynamic>> recentActivity = _recentActivity.isNotEmpty ? _recentActivity : <Map<String, dynamic>>[];
    
    final stats = _stats.isNotEmpty ? _stats : {
      'total_value': '₹0',
      'total_value_change': 0.0,
      'active_orders': '0',
      'active_orders_change': 0.0,
      'low_stock_items': '0',
      'total_materials': '0',
      'warehouses': 0,
    };
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return ProtectedRoute(
      title: 'Dashboard',
      route: '/dashboard',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, vm, isDark, responsive),
            SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),

            // Stats cards - Responsive grid
            _buildStatsGrid(stats, responsive),
            SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),

            // Chart and Activity - Stack on mobile, side by side on desktop
            if (responsive.isMobile)
              Column(
                children: [
                  _buildConsumptionChart(isDark, consumptionData, responsive),
                  SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
                  _buildRecentActivity(isDark, recentActivity, responsive),
                ],
              )
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: responsive.isTablet ? 1 : 3,
                      child: _buildConsumptionChart(isDark, consumptionData, responsive),
                    ),
                    SizedBox(width: responsive.spacing),
                    Expanded(
                      flex: responsive.isTablet ? 1 : 2,
                      child: _buildRecentActivity(isDark, recentActivity, responsive),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _DashboardViewModel vm, bool isDark, Responsive responsive) {
    return Column(
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
                    'Dashboard',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overview of ${vm.projectName}',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 13, tablet: 14, desktop: 14),
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (responsive.isDesktop)
              Row(
                children: [
                  MadButton(
                    text: 'Export',
                    icon: LucideIcons.download,
                    variant: ButtonVariant.outline,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export started...')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  MadButton(
                    text: 'New Request',
                    icon: LucideIcons.plus,
                    onPressed: () => Navigator.pushNamed(context, '/purchase-requests'),
                  ),
                ],
              ),
          ],
        ),
        // Mobile action buttons
        if (responsive.isMobile) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MadButton(
                  text: 'Export',
                  icon: LucideIcons.download,
                  variant: ButtonVariant.outline,
                  size: ButtonSize.sm,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export started...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MadButton(
                  text: 'New Request',
                  icon: LucideIcons.plus,
                  size: ButtonSize.sm,
                  onPressed: () => Navigator.pushNamed(context, '/purchase-requests'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, Responsive responsive) {
    final statCards = [
      StatCard(
        title: 'Total Value',
        value: stats['total_value']?.toString() ?? '₹0',
        icon: LucideIcons.indianRupee,
        iconColor: AppTheme.primaryColor,
        change: (stats['total_value_change'] as num?)?.toDouble(),
        subtitle: 'from last month',
      ),
      StatCard(
        title: 'Active Orders',
        value: stats['active_orders']?.toString() ?? '0',
        icon: LucideIcons.shoppingCart,
        iconColor: Colors.blue,
        iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
        change: (stats['active_orders_change'] as num?)?.toDouble(),
        subtitle: 'from last month',
      ),
      StatCard(
        title: 'Low Stock',
        value: stats['low_stock_items']?.toString() ?? '0',
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        iconBackgroundColor: Colors.orange.withValues(alpha: 0.1),
        subtitle: 'Requires attention',
      ),
      StatCard(
        title: 'Total Materials',
        value: stats['total_materials']?.toString() ?? '0',
        icon: LucideIcons.package,
        iconColor: Colors.green,
        iconBackgroundColor: Colors.green.withValues(alpha: 0.1),
        subtitle: 'Across ${stats['warehouses'] ?? 0} warehouses',
      ),
    ];

    // Use 1 column for very narrow screens (< 360px), 2 for mobile, etc.
    final isVeryNarrow = responsive.screenWidth < 360;
    final crossAxisCount = isVeryNarrow ? 1 : responsive.value(mobile: 2, tablet: 2, desktop: 4);
    // Lower aspect ratio = taller cards (more height relative to width)
    final aspectRatio = isVeryNarrow ? 2.2 : responsive.value(mobile: 1.0, tablet: 1.2, desktop: 1.4);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: responsive.value(mobile: 8, tablet: 12, desktop: 16),
      mainAxisSpacing: responsive.value(mobile: 8, tablet: 12, desktop: 16),
      childAspectRatio: aspectRatio,
      children: statCards,
    );
  }

  Widget _buildConsumptionChart(bool isDark, List<Map<String, dynamic>> chartData, Responsive responsive) {
    double maxY = 100;
    if (chartData.isNotEmpty) {
      final values = chartData.map((e) => (e['total'] as num?)?.toDouble() ?? 0.0).toList();
      maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;
      if (maxY <= 0) maxY = 100;
    }
    
    final chartHeight = responsive.value(mobile: 220.0, tablet: 260.0, desktop: 300.0);
    final barWidth = responsive.value(mobile: 20.0, tablet: 26.0, desktop: 32.0);
    
    return MadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MadCardHeader(
            title: const MadCardTitle('Overview'),
            subtitle: const MadCardDescription('Monthly consumption trends.'),
          ),
          MadCardContent(
            child: chartData.isEmpty 
              ? SizedBox(
                  height: chartHeight,
                  child: const Center(child: Text('No consumption data available')),
                )
              : SizedBox(
                  height: chartHeight,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex < chartData.length) {
                              return BarTooltipItem(
                                '${chartData[groupIndex]['name']}\n₹${rod.toY.toInt()}',
                                const TextStyle(color: Colors.white, fontSize: 12),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < chartData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    chartData[value.toInt()]['name']?.toString() ?? '',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                                      fontSize: responsive.value(mobile: 10, tablet: 11, desktop: 12),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: chartData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: (entry.value['total'] as num?)?.toDouble() ?? 0.0,
                              color: AppTheme.primaryColor,
                              width: barWidth,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark, List<Map<String, dynamic>> activityData, Responsive responsive) {
    return MadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MadCardHeader(
            title: const MadCardTitle('Recent Activity'),
            subtitle: const MadCardDescription('Latest actions across the system.'),
          ),
          MadCardContent(
            child: activityData.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: activityData.take(responsive.isMobile ? 3 : 5).map((activity) {
                    return _buildActivityItem(activity, isDark, responsive);
                  }).toList(),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, bool isDark, Responsive responsive) {
    final status = activity['status'] as String? ?? 'info';
    Color statusColor;
    switch (status) {
      case 'success':
        statusColor = Colors.green;
        break;
      case 'warning':
        statusColor = Colors.orange;
        break;
      case 'error':
        statusColor = Colors.red;
        break;
      default:
        statusColor = AppTheme.primaryColor;
    }

    final avatarSize = responsive.value(mobile: 32.0, tablet: 36.0, desktop: 40.0);

    return Padding(
      padding: EdgeInsets.only(bottom: responsive.value(mobile: 12, tablet: 14, desktop: 16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(avatarSize / 2),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                activity['initials'] ?? 'U',
                style: TextStyle(
                  fontSize: responsive.value(mobile: 10, tablet: 11, desktop: 12),
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                ),
              ),
            ),
          ),
          SizedBox(width: responsive.value(mobile: 8, tablet: 10, desktop: 12)),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(responsive.value(mobile: 10, tablet: 11, desktop: 12)),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity['user'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: responsive.value(mobile: 13, tablet: 13, desktop: 14),
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        activity['time'] ?? '',
                        style: TextStyle(
                          fontSize: responsive.value(mobile: 10, tablet: 11, desktop: 12),
                          fontFamily: 'monospace',
                          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['action'] ?? '',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 12, tablet: 12, desktop: 13),
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardViewModel {
  final bool isAuthenticated;
  final Map<String, dynamic>? selectedProject;

  _DashboardViewModel({
    required this.isAuthenticated,
    required this.selectedProject,
  });

  String get projectName => selectedProject?['name']?.toString() ?? 'your inventory';
}
