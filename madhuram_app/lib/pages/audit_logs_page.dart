import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Audit log entry model
class AuditLog {
  final String id;
  final String user;
  final String action;
  final String time;
  final String status;
  final String? initials;
  final String? details;
  final String? ipAddress;

  const AuditLog({required this.id, required this.user, required this.action, required this.time, required this.status, this.initials, this.details, this.ipAddress});

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: (json['log_id'] ?? json['id'] ?? '').toString(),
      user: json['user'] ?? '',
      action: json['action'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'info',
      initials: json['initials'],
      details: json['details'],
      ipAddress: json['ip_address'],
    );
  }

  Color get statusColor {
    switch (status) {
      case 'success': return const Color(0xFF22C55E);
      case 'warning': return const Color(0xFFF59E0B);
      case 'error': return const Color(0xFFEF4444);
      default: return AppTheme.primaryColor;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'success': return LucideIcons.circleCheck;
      case 'warning': return LucideIcons.triangleAlert;
      case 'error': return LucideIcons.circleX;
      default: return LucideIcons.info;
    }
  }
}

/// Audit Logs page
class AuditLogsPageFull extends StatefulWidget {
  const AuditLogsPageFull({super.key});
  @override
  State<AuditLogsPageFull> createState() => _AuditLogsPageFullState();
}

class _AuditLogsPageFullState extends State<AuditLogsPageFull> {
  bool _isLoading = true;
  List<AuditLog> _logs = [];
  String _searchQuery = '';
  String? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';
    
    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    
    final result = await ApiClient.getAuditLogs(projectId);
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() { _logs = data.map((e) => AuditLog.fromJson(e)).toList(); _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<AuditLog> get _filteredLogs {
    List<AuditLog> result = _logs;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((l) => l.user.toLowerCase().contains(query) || l.action.toLowerCase().contains(query)).toList();
    }
    if (_statusFilter != null) result = result.where((l) => l.status == _statusFilter).toList();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return ProtectedRoute(
      title: 'Audit Logs',
      route: '/audit-logs',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Audit Logs', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
            const SizedBox(height: 4),
            Text('Track all system activities and changes', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
          ])),
          if (!isMobile) MadButton(text: 'Export Logs', icon: LucideIcons.download, variant: ButtonVariant.outline, onPressed: () {}),
        ]),
        const SizedBox(height: 24),
        if (!isMobile) Row(children: [
          Expanded(child: StatCard(title: 'Total Activities', value: _logs.length.toString(), icon: LucideIcons.activity, iconColor: AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Success', value: _logs.where((l) => l.status == 'success').length.toString(), icon: LucideIcons.circleCheck, iconColor: const Color(0xFF22C55E))),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Warnings', value: _logs.where((l) => l.status == 'warning').length.toString(), icon: LucideIcons.triangleAlert, iconColor: const Color(0xFFF59E0B))),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Errors', value: _logs.where((l) => l.status == 'error').length.toString(), icon: LucideIcons.circleX, iconColor: const Color(0xFFEF4444))),
        ]),
        if (!isMobile) const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: isMobile ? double.infinity : 320, child: MadSearchInput(controller: _searchController, hintText: 'Search activities...', onChanged: (v) => setState(() => _searchQuery = v), onClear: () => setState(() => _searchQuery = ''))),
          SizedBox(width: 150, child: MadSelect<String>(value: _statusFilter, placeholder: 'All Status', clearable: true, options: const [MadSelectOption(value: 'success', label: 'Success'), MadSelectOption(value: 'warning', label: 'Warning'), MadSelectOption(value: 'error', label: 'Error'), MadSelectOption(value: 'info', label: 'Info')], onChanged: (v) => setState(() => _statusFilter = v))),
        ]),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : _filteredLogs.isEmpty ? _buildEmptyState(isDark) : MadCard(
            child: ListView.separated(
              itemCount: _filteredLogs.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5)),
              itemBuilder: (context, index) => _buildLogItem(_filteredLogs[index], isDark, isMobile),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildLogItem(AuditLog log, bool isDark, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: log.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Center(child: log.initials != null 
              ? Text(log.initials!, style: TextStyle(fontWeight: FontWeight.w600, color: log.statusColor, fontSize: 14))
              : Icon(log.statusIcon, color: log.statusColor, size: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(log.user, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: log.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(log.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: log.statusColor)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(log.action, style: TextStyle(color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
          const SizedBox(height: 4),
          Text(log.time, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
        ])),
        if (!isMobile) MadDropdownMenuButton(items: [
          MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
          MadMenuItem(label: 'Copy', icon: LucideIcons.copy, onTap: () {}),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(LucideIcons.scrollText, size: 64, color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3)),
      const SizedBox(height: 24),
      Text('No activities found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
      const SizedBox(height: 8),
      Text(_searchQuery.isEmpty ? 'Activity logs will appear here' : 'Try a different search term', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
    ])));
  }
}
