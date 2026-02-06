import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Vendor quote for comparison
class VendorQuote {
  final String vendorId;
  final String vendorName;
  final String material;
  final double rate;
  final double quantity;
  final String? delivery;
  final String? paymentTerms;
  final double? rating;

  const VendorQuote({
    required this.vendorId,
    required this.vendorName,
    required this.material,
    required this.rate,
    required this.quantity,
    this.delivery,
    this.paymentTerms,
    this.rating,
  });

  double get totalAmount => rate * quantity;
}

/// Vendor Comparison page matching React's VendorComparison page
class VendorComparisonPageFull extends StatefulWidget {
  const VendorComparisonPageFull({super.key});

  @override
  State<VendorComparisonPageFull> createState() => _VendorComparisonPageFullState();
}

class _VendorComparisonPageFullState extends State<VendorComparisonPageFull> {
  bool _isLoading = false;
  String? _selectedMaterial;
  List<VendorQuote> _quotes = [];

  final List<String> _materials = [
    'Cement OPC 53',
    'PVC Pipe 4"',
    'Steel Rods 12mm',
    'River Sand',
    'Aggregate 20mm',
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadQuotes(String material) async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _quotes = [
        VendorQuote(vendorId: '1', vendorName: 'ABC Suppliers', material: material, rate: 350, quantity: 500, delivery: '3 days', paymentTerms: '30 days', rating: 4.5),
        VendorQuote(vendorId: '2', vendorName: 'XYZ Traders', material: material, rate: 340, quantity: 500, delivery: '5 days', paymentTerms: '15 days', rating: 4.2),
        VendorQuote(vendorId: '3', vendorName: 'PQR Industries', material: material, rate: 360, quantity: 500, delivery: '2 days', paymentTerms: '45 days', rating: 4.8),
      ];
      _isLoading = false;
    });
  }

  VendorQuote? get _lowestQuote {
    if (_quotes.isEmpty) return null;
    return _quotes.reduce((a, b) => a.rate < b.rate ? a : b);
  }

  VendorQuote? get _fastestDelivery {
    if (_quotes.isEmpty) return null;
    return _quotes.reduce((a, b) {
      final aDelivery = int.tryParse(a.delivery?.split(' ').first ?? '999') ?? 999;
      final bDelivery = int.tryParse(b.delivery?.split(' ').first ?? '999') ?? 999;
      return aDelivery < bDelivery ? a : b;
    });
  }

  VendorQuote? get _highestRated {
    if (_quotes.isEmpty) return null;
    return _quotes.reduce((a, b) => (a.rating ?? 0) > (b.rating ?? 0) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'Vendor Comparison',
      route: '/vendor-comparison',
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
                      'Vendor Comparison',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Compare vendor quotations side by side',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'Add Quotation',
                  icon: LucideIcons.plus,
                  onPressed: () => _showAddQuoteDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Material selector
          Row(
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 300,
                child: MadSelect<String>(
                  value: _selectedMaterial,
                  labelText: 'Select Material',
                  placeholder: 'Choose a material to compare',
                  options: _materials.map((m) => MadSelectOption(value: m, label: m)).toList(),
                  onChanged: (value) {
                    setState(() => _selectedMaterial = value);
                    if (value != null) _loadQuotes(value);
                  },
                ),
              ),
              if (isMobile) ...[
                const SizedBox(width: 12),
                MadButton(
                  icon: LucideIcons.plus,
                  size: ButtonSize.icon,
                  onPressed: () => _showAddQuoteDialog(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: _selectedMaterial == null
                ? _buildSelectMaterialState(isDark)
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _quotes.isEmpty
                        ? _buildEmptyState(isDark)
                        : _buildComparisonView(isDark, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectMaterialState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.scale,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a Material',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a material to compare vendor quotations',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
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
              LucideIcons.fileSearch,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No quotations found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add vendor quotations to compare',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            MadButton(
              text: 'Add Quotation',
              icon: LucideIcons.plus,
              onPressed: () => _showAddQuoteDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView(bool isDark, bool isMobile) {
    return Column(
      children: [
        // Summary cards
        if (!isMobile)
          Row(
            children: [
              Expanded(
                child: _buildRecommendationCard(
                  'Lowest Price',
                  _lowestQuote?.vendorName ?? '-',
                  '₹${_lowestQuote?.rate.toStringAsFixed(2) ?? '0'}',
                  LucideIcons.indianRupee,
                  const Color(0xFF22C55E),
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRecommendationCard(
                  'Fastest Delivery',
                  _fastestDelivery?.vendorName ?? '-',
                  _fastestDelivery?.delivery ?? '-',
                  LucideIcons.truck,
                  AppTheme.primaryColor,
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRecommendationCard(
                  'Highest Rated',
                  _highestRated?.vendorName ?? '-',
                  '${_highestRated?.rating ?? 0} ★',
                  LucideIcons.star,
                  const Color(0xFFF59E0B),
                  isDark,
                ),
              ),
            ],
          ),
        if (!isMobile) const SizedBox(height: 24),

        // Comparison table
        Expanded(
          child: MadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Quotation Comparison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                ),
                Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 40,
                      columns: const [
                        DataColumn(label: Text('Vendor')),
                        DataColumn(label: Text('Rate/Unit'), numeric: true),
                        DataColumn(label: Text('Quantity'), numeric: true),
                        DataColumn(label: Text('Total'), numeric: true),
                        DataColumn(label: Text('Delivery')),
                        DataColumn(label: Text('Payment')),
                        DataColumn(label: Text('Rating'), numeric: true),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _quotes.map((quote) {
                        final isLowest = quote.vendorId == _lowestQuote?.vendorId;
                        return DataRow(
                          color: isLowest ? WidgetStateProperty.all(
                            const Color(0xFF22C55E).withOpacity(0.1),
                          ) : null,
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  Text(
                                    quote.vendorName,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  if (isLowest) ...[
                                    const SizedBox(width: 8),
                                    MadBadge(text: 'Best Price', variant: BadgeVariant.default_),
                                  ],
                                ],
                              ),
                            ),
                            DataCell(Text('₹${quote.rate.toStringAsFixed(2)}')),
                            DataCell(Text(quote.quantity.toStringAsFixed(0))),
                            DataCell(Text(
                              '₹${quote.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            )),
                            DataCell(Text(quote.delivery ?? '-')),
                            DataCell(Text(quote.paymentTerms ?? '-')),
                            DataCell(Row(
                              children: [
                                const Icon(LucideIcons.star, size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(quote.rating?.toStringAsFixed(1) ?? '-'),
                              ],
                            )),
                            DataCell(
                              MadButton(
                                text: 'Select',
                                variant: ButtonVariant.outline,
                                size: ButtonSize.sm,
                                onPressed: () => _selectVendor(quote),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(String title, String vendor, String value, IconData icon, Color color, bool isDark) {
    return MadCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                  Text(
                    vendor,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectVendor(VendorQuote quote) {
    MadDialog.confirm(
      context: context,
      title: 'Create Purchase Order?',
      description: 'Do you want to create a purchase order with ${quote.vendorName} for ${quote.material}?',
      confirmText: 'Create PO',
    ).then((confirmed) {
      if (confirmed) {
        Navigator.pushNamed(context, '/purchase-orders');
      }
    });
  }

  void _showAddQuoteDialog() {
    MadFormDialog.show(
      context: context,
      title: 'Add Vendor Quotation',
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadSelect<String>(
            labelText: 'Vendor',
            placeholder: 'Select vendor',
            searchable: true,
            options: const [
              MadSelectOption(value: 'abc', label: 'ABC Suppliers'),
              MadSelectOption(value: 'xyz', label: 'XYZ Traders'),
              MadSelectOption(value: 'pqr', label: 'PQR Industries'),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          MadSelect<String>(
            labelText: 'Material',
            placeholder: 'Select material',
            options: _materials.map((m) => MadSelectOption(value: m, label: m)).toList(),
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MadInput(
                  labelText: 'Rate per Unit',
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MadInput(
                  labelText: 'Quantity',
                  hintText: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MadInput(
                  labelText: 'Delivery Time',
                  hintText: 'e.g. 3 days',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MadInput(
                  labelText: 'Payment Terms',
                  hintText: 'e.g. 30 days',
                ),
              ),
            ],
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
          text: 'Add Quotation',
          onPressed: () {
            Navigator.pop(context);
            if (_selectedMaterial != null) {
              _loadQuotes(_selectedMaterial!);
            }
          },
        ),
      ],
    );
  }
}
