import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Tab item definition
class MadTabItem {
  final String id;
  final String label;
  final IconData? icon;
  final Widget content;
  final bool disabled;

  const MadTabItem({
    required this.id,
    required this.label,
    this.icon,
    required this.content,
    this.disabled = false,
  });
}

/// Tabs component matching shadcn/ui Tabs
class MadTabs extends StatefulWidget {
  final List<MadTabItem> tabs;
  final String? defaultTab;
  final ValueChanged<String>? onTabChanged;
  final TabStyle style;

  const MadTabs({
    super.key,
    required this.tabs,
    this.defaultTab,
    this.onTabChanged,
    this.style = TabStyle.default_,
  });

  @override
  State<MadTabs> createState() => _MadTabsState();
}

enum TabStyle { default_, underline, pills }

class _MadTabsState extends State<MadTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.defaultTab ?? widget.tabs.first.id;
    final initialIndex = widget.tabs.indexWhere((t) => t.id == _selectedTab);
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedTab = widget.tabs[_tabController.index].id;
    });
    widget.onTabChanged?.call(_selectedTab);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar
        _buildTabBar(isDark),
        const SizedBox(height: 16),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.tabs.map((tab) => tab.content).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    switch (widget.style) {
      case TabStyle.underline:
        return _buildUnderlineTabs(isDark);
      case TabStyle.pills:
        return _buildPillTabs(isDark);
      case TabStyle.default_:
        return _buildDefaultTabs(isDark);
    }
  }

  Widget _buildDefaultTabs(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelColor: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
        unselectedLabelColor:
            isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: widget.tabs.map((tab) => _buildTab(tab)).toList(),
      ),
    );
  }

  Widget _buildUnderlineTabs(bool isDark) {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppTheme.primaryColor,
      indicatorWeight: 2,
      labelColor: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
      unselectedLabelColor:
          isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      dividerColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      tabs: widget.tabs.map((tab) => _buildTab(tab)).toList(),
    );
  }

  Widget _buildPillTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _tabController.index == index;

          return Padding(
            padding: EdgeInsets.only(right: index < widget.tabs.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: tab.disabled ? null : () => _tabController.animateTo(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tab.icon != null) ...[
                      Icon(
                        tab.icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTab(MadTabItem tab) {
    return Tab(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tab.icon != null) ...[
            Icon(tab.icon, size: 16),
            const SizedBox(width: 8),
          ],
          Text(tab.label),
        ],
      ),
    );
  }
}

/// Simple tabs list (just the tab buttons, no content)
class MadTabsList extends StatelessWidget {
  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final TabStyle style;

  const MadTabsList({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
    this.style = TabStyle.default_,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: style == TabStyle.default_
          ? BoxDecoration(
              color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      padding: style == TabStyle.default_ ? const EdgeInsets.all(4) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final isSelected = tab == selectedTab;
          return GestureDetector(
            onTap: () => onTabChanged(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected && style == TabStyle.default_
                    ? (isDark ? AppTheme.darkCard : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: style == TabStyle.underline && isSelected
                    ? Border(
                        bottom: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      )
                    : null,
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppTheme.darkForeground : AppTheme.lightForeground)
                      : (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
