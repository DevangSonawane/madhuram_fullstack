import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Menu item model matching React's menuItems.js exactly
class MenuItem {
  final String title;
  final String route;
  final String category;
  final IconData icon;
  
  const MenuItem({
    required this.title,
    required this.route,
    required this.category,
    required this.icon,
  });
}

/// Menu category model
class MenuCategory {
  final String name;
  final List<MenuItem> items;
  
  const MenuCategory({required this.name, required this.items});
}

// Category constants matching React
const _main = 'Main';
const _projectManagement = 'Project Management';
const _procurement = 'Procurement';
const _deliveryInspection = 'Delivery & Inspection';
const _billing = 'Billing';
const _inventory = 'Inventory';
const _documents = 'Documents';
const _analytics = 'Analytics';

/// Menu items matching React's menuItems.js exactly with same icons
const menuItems = <MenuItem>[
  // Main
  MenuItem(
    title: 'Dashboard',
    route: '/dashboard',
    category: _main,
    icon: LucideIcons.layoutDashboard,
  ),
  
  // Project Management
  MenuItem(
    title: 'Projects',
    route: '/projects',
    category: _projectManagement,
    icon: LucideIcons.briefcase,
  ),
  MenuItem(
    title: 'BOQ Management',
    route: '/boq',
    category: _projectManagement,
    icon: LucideIcons.clipboardList,
  ),
  MenuItem(
    title: 'MAS',
    route: '/mas',
    category: _projectManagement,
    icon: Icons.check_box_outlined,
  ),
  
  // Procurement
  MenuItem(
    title: 'Sample Management',
    route: '/samples',
    category: _procurement,
    icon: LucideIcons.layers,
  ),
  MenuItem(
    title: 'Purchase Requests',
    route: '/purchase-requests',
    category: _procurement,
    icon: LucideIcons.shoppingCart,
  ),
  MenuItem(
    title: 'Vendor Comparison',
    route: '/vendor-comparison',
    category: _procurement,
    icon: LucideIcons.arrowRightLeft,
  ),
  MenuItem(
    title: 'Purchase Orders',
    route: '/purchase-orders',
    category: _procurement,
    icon: LucideIcons.fileText,
  ),
  MenuItem(
    title: 'Vendors',
    route: '/vendors',
    category: _procurement,
    icon: LucideIcons.users,
  ),
  
  // Delivery & Inspection
  MenuItem(
    title: 'Delivery Challans',
    route: '/challans',
    category: _deliveryInspection,
    icon: LucideIcons.truck,
  ),
  MenuItem(
    title: 'MER',
    route: '/mer',
    category: _deliveryInspection,
    icon: LucideIcons.fileCheck,
  ),
  MenuItem(
    title: 'MIR',
    route: '/mir',
    category: _deliveryInspection,
    icon: LucideIcons.eye,
  ),
  MenuItem(
    title: 'ITR',
    route: '/itr',
    category: _deliveryInspection,
    icon: LucideIcons.hammer,
  ),
  
  // Billing
  MenuItem(
    title: 'Billing & Invoices',
    route: '/billing',
    category: _billing,
    icon: LucideIcons.receipt,
  ),
  
  // Inventory
  MenuItem(
    title: 'Stock Overview',
    route: '/stock-areas',
    category: _inventory,
    icon: LucideIcons.warehouse,
  ),
  MenuItem(
    title: 'Product Master',
    route: '/materials',
    category: _inventory,
    icon: LucideIcons.package,
  ),
  MenuItem(
    title: 'Stock Transfers',
    route: '/stock-transfers',
    category: _inventory,
    icon: LucideIcons.arrowRightLeft,
  ),
  MenuItem(
    title: 'Consumption',
    route: '/consumption',
    category: _inventory,
    icon: LucideIcons.trendingDown,
  ),
  MenuItem(
    title: 'Returns',
    route: '/returns',
    category: _inventory,
    icon: LucideIcons.undo2,
  ),
  
  // Documents
  MenuItem(
    title: 'Repository',
    route: '/documents',
    category: _documents,
    icon: LucideIcons.folderOpen,
  ),
  
  // Analytics
  MenuItem(
    title: 'Reports',
    route: '/reports',
    category: _analytics,
    icon: Icons.bar_chart,
  ),
  MenuItem(
    title: 'Audit Logs',
    route: '/audit-logs',
    category: _analytics,
    icon: LucideIcons.history,
  ),
];

/// Get menu items grouped by category
List<MenuCategory> getMenuCategories() {
  final categories = <String, List<MenuItem>>{};
  for (final item in menuItems) {
    categories.putIfAbsent(item.category, () => []).add(item);
  }
  return categories.entries
      .map((e) => MenuCategory(name: e.key, items: e.value))
      .toList();
}
