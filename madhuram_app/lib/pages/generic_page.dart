import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../components/ui/mad_card.dart';
import '../components/ui/mad_button.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';

/// Generic page template for all other pages - Responsive version
class GenericPage extends StatelessWidget {
  final String title;
  final String route;
  final IconData icon;
  final String description;

  const GenericPage({
    super.key,
    required this.title,
    required this.route,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return ProtectedRoute(
      title: title,
      route: route,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, isDark, responsive),
          SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),

          // Placeholder content
          Expanded(
            child: MadCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(responsive.value(mobile: 24, tablet: 32, desktop: 48)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: responsive.value(mobile: 60, tablet: 70, desktop: 80),
                        height: responsive.value(mobile: 60, tablet: 70, desktop: 80),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(responsive.value(mobile: 30, tablet: 35, desktop: 40)),
                        ),
                        child: Icon(
                          icon,
                          size: responsive.value(mobile: 30, tablet: 35, desktop: 40),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: responsive.value(mobile: 20, tablet: 22, desktop: 24),
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This page is under development',
                        style: TextStyle(
                          fontSize: responsive.value(mobile: 14, tablet: 15, desktop: 16),
                          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: responsive.value(mobile: 24, tablet: 28, desktop: 32)),
                      MadButton(
                        text: 'Coming Soon',
                        variant: ButtonVariant.outline,
                        size: responsive.isMobile ? ButtonSize.sm : ButtonSize.md,
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Responsive responsive) {
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
                    title,
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 13, tablet: 14, desktop: 14),
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (responsive.isDesktop)
              MadButton(
                text: 'Add New',
                icon: LucideIcons.plus,
                onPressed: () {},
              ),
          ],
        ),
        // Mobile action button
        if (responsive.isMobile) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: MadButton(
              text: 'Add New',
              icon: LucideIcons.plus,
              size: ButtonSize.sm,
              onPressed: () {},
            ),
          ),
        ],
      ],
    );
  }
}

// Convenience pages using GenericPage

class PurchaseRequestsPage extends StatelessWidget {
  const PurchaseRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Purchase Requests',
      route: '/purchase-requests',
      icon: LucideIcons.shoppingCart,
      description: 'Manage purchase requests and approvals',
    );
  }
}

class VendorComparisonPage extends StatelessWidget {
  const VendorComparisonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Vendor Comparison',
      route: '/vendor-comparison',
      icon: LucideIcons.arrowRightLeft,
      description: 'Compare vendor quotes and pricing',
    );
  }
}

class PurchaseOrdersPage extends StatelessWidget {
  const PurchaseOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Purchase Orders',
      route: '/purchase-orders',
      icon: LucideIcons.fileText,
      description: 'Create and manage purchase orders',
    );
  }
}

class VendorsPage extends StatelessWidget {
  const VendorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Vendors',
      route: '/vendors',
      icon: LucideIcons.users,
      description: 'Manage your vendor contacts',
    );
  }
}

class ChallansPage extends StatelessWidget {
  const ChallansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Delivery Challans',
      route: '/challans',
      icon: LucideIcons.truck,
      description: 'Track delivery challans and receipts',
    );
  }
}

class MERPage extends StatelessWidget {
  const MERPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'MER',
      route: '/mer',
      icon: LucideIcons.fileCheck,
      description: 'Material Entry Reports',
    );
  }
}

class MIRPage extends StatelessWidget {
  const MIRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'MIR',
      route: '/mir',
      icon: LucideIcons.eye,
      description: 'Material Inspection Requests',
    );
  }
}

class ITRPage extends StatelessWidget {
  const ITRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'ITR',
      route: '/itr',
      icon: LucideIcons.hammer,
      description: 'Installation Test Reports',
    );
  }
}

class MASPage extends StatelessWidget {
  const MASPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'MAS',
      route: '/mas',
      icon: Icons.check_box_outlined,
      description: 'Material Approval Sheets',
    );
  }
}

class SamplesPage extends StatelessWidget {
  const SamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Sample Management',
      route: '/samples',
      icon: LucideIcons.layers,
      description: 'Manage material samples',
    );
  }
}

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Billing & Invoices',
      route: '/billing',
      icon: LucideIcons.receipt,
      description: 'Manage billing and invoices',
    );
  }
}

class StockAreasPage extends StatelessWidget {
  const StockAreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Stock Overview',
      route: '/stock-areas',
      icon: LucideIcons.warehouse,
      description: 'View stock areas and warehouses',
    );
  }
}

class MaterialsPage extends StatelessWidget {
  const MaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Product Master',
      route: '/materials',
      icon: LucideIcons.package,
      description: 'Manage material inventory',
    );
  }
}

class StockTransfersPage extends StatelessWidget {
  const StockTransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Stock Transfers',
      route: '/stock-transfers',
      icon: LucideIcons.arrowRightLeft,
      description: 'Transfer stock between locations',
    );
  }
}

class ConsumptionPage extends StatelessWidget {
  const ConsumptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Consumption',
      route: '/consumption',
      icon: LucideIcons.trendingDown,
      description: 'Track material consumption',
    );
  }
}

class ReturnsPage extends StatelessWidget {
  const ReturnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Returns',
      route: '/returns',
      icon: LucideIcons.undo2,
      description: 'Manage material returns',
    );
  }
}

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Repository',
      route: '/documents',
      icon: LucideIcons.folderOpen,
      description: 'Document repository and file management',
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Reports',
      route: '/reports',
      icon: Icons.bar_chart,
      description: 'Generate and view reports',
    );
  }
}

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericPage(
      title: 'Audit Logs',
      route: '/audit-logs',
      icon: LucideIcons.history,
      description: 'View system audit logs and activity',
    );
  }
}
