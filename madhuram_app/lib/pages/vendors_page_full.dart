import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';
import '../models/vendor.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';
import '../demo_data/vendors_demo.dart';

/// Vendors page with full implementation
class VendorsPageFull extends StatefulWidget {
  const VendorsPageFull({super.key});

  @override
  State<VendorsPageFull> createState() => _VendorsPageFullState();
}

class _VendorsPageFullState extends State<VendorsPageFull> {
  // START WITH DEMO DATA – never show blank
  bool _isLoading = false;
  List<Vendor> _vendors = VendorsDemo.vendors
      .map((e) => Vendor.fromJson(e))
      .toList();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    // Try real API in background; demo data already visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVendors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Seed with demo data when API is unavailable
  void _seedDemoData() {
    debugPrint('[Vendors] API unavailable – falling back to demo data');
    setState(() {
      _vendors = VendorsDemo.vendors.map((e) => Vendor.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadVendors() async {
    try {
      final result = await ApiClient.getVendors();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as List;
        final loaded = data.map((e) => Vendor.fromJson(e)).toList();
        if (loaded.isEmpty) {
          debugPrint('[Vendors] API returned empty list – falling back to demo data');
          _seedDemoData();
        } else {
          setState(() {
            _vendors = loaded;
            _isLoading = false;
          });
        }
      } else {
        _seedDemoData();
      }
    } catch (e) {
      debugPrint('[Vendors] API error: $e – falling back to demo data');
      if (!mounted) return;
      _seedDemoData();
    }
  }

  List<Vendor> get _filteredVendors {
    List<Vendor> result = _vendors;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((v) {
        return v.name.toLowerCase().contains(query) ||
            (v.contactPerson?.toLowerCase().contains(query) ?? false) ||
            (v.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_statusFilter != null) {
      result = result.where((v) => v.status == _statusFilter).toList();
    }

    return result;
  }

  List<Vendor> get _paginatedVendors {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredVendors;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredVendors.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

    return ProtectedRoute(
      title: 'Vendors',
      route: '/vendors',
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
                      'Vendors',
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage vendor relationships and contacts',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'Add Vendor',
                  icon: LucideIcons.userPlus,
                  onPressed: () => _showAddVendorDialog(),
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
                    title: 'Total Vendors',
                    value: _vendors.length.toString(),
                    icon: LucideIcons.users,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Active',
                    value: _vendors.where((v) => v.status == 'Active').length.toString(),
                    icon: LucideIcons.userCheck,
                    iconColor: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Avg Rating',
                    value: _vendors.isNotEmpty
                        ? (_vendors.where((v) => v.rating != null).map((v) => v.rating!).fold(0.0, (a, b) => a + b) /
                                _vendors.where((v) => v.rating != null).length)
                            .toStringAsFixed(1)
                        : '-',
                    icon: LucideIcons.star,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          if (!isMobile) const SizedBox(height: 24),

          // Search and filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 320,
                child: MadSearchInput(
                  controller: _searchController,
                  hintText: 'Search vendors...',
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                    _currentPage = 1;
                  }),
                  onClear: () => setState(() {
                    _searchQuery = '';
                    _currentPage = 1;
                  }),
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 150,
                child: MadSelect<String>(
                  value: _statusFilter,
                  placeholder: 'All Status',
                  clearable: true,
                  options: const [
                    MadSelectOption(value: 'Active', label: 'Active'),
                    MadSelectOption(value: 'Inactive', label: 'Inactive'),
                  ],
                  onChanged: (value) => setState(() {
                    _statusFilter = value;
                    _currentPage = 1;
                  }),
                ),
              ),
              if (isMobile)
                MadButton(
                  icon: LucideIcons.userPlus,
                  text: 'Add',
                  onPressed: () => _showAddVendorDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Vendor cards/list
          Expanded(
            child: _isLoading
                ? MadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: MadListSkeleton(itemCount: 6, showAvatar: true, showAction: true),
                    ),
                  )
                : _filteredVendors.isEmpty
                    ? _buildEmptyState(isDark)
                    : isMobile
                        ? _buildMobileList(isDark)
                        : _buildDesktopGrid(isDark),
          ),

          // Pagination
          if (_totalPages > 1 && !_isLoading) _buildPagination(isDark),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(bool isDark) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: _paginatedVendors.length,
      itemBuilder: (context, index) => _buildVendorCard(_paginatedVendors[index], isDark),
    );
  }

  Widget _buildMobileList(bool isDark) {
    return ListView.separated(
      itemCount: _paginatedVendors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildVendorCard(_paginatedVendors[index], isDark),
    );
  }

  Widget _buildVendorCard(Vendor vendor, bool isDark) {
    return MadCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (vendor.contactPerson != null)
                        Text(
                          vendor.contactPerson!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                MadDropdownMenuButton(
                  items: [
                    MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () => _showVendorDetails(vendor)),
                    MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () => _showEditVendorDialog(vendor)),
                    MadMenuItem(label: 'Create PO', icon: LucideIcons.shoppingCart, onTap: () {}),
                    MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () => _showDeleteConfirm(vendor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (vendor.rating != null) ...[
                  Icon(LucideIcons.star, size: 16, color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    vendor.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                ],
                MadBadge(
                  text: vendor.status,
                  variant: vendor.status == 'Active' ? BadgeVariant.default_ : BadgeVariant.secondary,
                ),
                if (vendor.type != null && vendor.type!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  MadBadge(
                    text: vendor.type!,
                    variant: BadgeVariant.secondary,
                  ),
                ],
              ],
            ),
            const Spacer(),
            Divider(color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (vendor.phone != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.phone,
                          size: 14,
                          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            vendor.phone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (vendor.email != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.mail,
                          size: 14,
                          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            vendor.email!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredVendors.length ? _filteredVendors.length : _currentPage * _itemsPerPage} of ${_filteredVendors.length}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
            ),
          ),
          Row(
            children: [
              MadButton(
                icon: LucideIcons.chevronLeft,
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                disabled: _currentPage == 1,
                onPressed: () => setState(() => _currentPage--),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_currentPage of $_totalPages'),
              ),
              MadButton(
                icon: LucideIcons.chevronRight,
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                disabled: _currentPage >= _totalPages,
                onPressed: () => setState(() => _currentPage++),
              ),
            ],
          ),
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
              LucideIcons.users,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No vendors yet' : 'No vendors found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Add your first vendor to get started'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'Add Vendor',
                icon: LucideIcons.userPlus,
                onPressed: () => _showAddVendorDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVendorDetails(Vendor vendor) {
    MadDialog.show(
      context: context,
      title: vendor.name,
      maxWidth: 500,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vendor.contactPerson != null)
            _buildDetailRow('Contact Person', vendor.contactPerson!),
          if (vendor.phone != null)
            _buildDetailRow('Phone', vendor.phone!),
          if (vendor.email != null)
            _buildDetailRow('Email', vendor.email!),
          if (vendor.address != null)
            _buildDetailRow('Address', vendor.address!),
          if (vendor.gstNo != null)
            _buildDetailRow('GST Number', vendor.gstNo!),
          if (vendor.panNo != null)
            _buildDetailRow('PAN Number', vendor.panNo!),
          if (vendor.rating != null)
            _buildDetailRow('Rating', '${vendor.rating!.toStringAsFixed(1)} / 5.0'),
          if (vendor.type != null && vendor.type!.isNotEmpty)
            _buildDetailRow('Type', vendor.type!),
          _buildDetailRow('Status', vendor.status),
        ],
      ),
      actions: [
        MadButton(
          text: 'Edit',
          variant: ButtonVariant.outline,
          onPressed: () {
            Navigator.pop(context);
            _showEditVendorDialog(vendor);
          },
        ),
        MadButton(
          text: 'Create PO',
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/purchase-orders');
          },
        ),
      ],
    );
  }

  void _showEditVendorDialog(Vendor vendor) {
    final nameController = TextEditingController(text: vendor.name);
    final contactController = TextEditingController(text: vendor.contactPerson ?? '');
    final phoneController = TextEditingController(text: vendor.phone ?? '');
    final emailController = TextEditingController(text: vendor.email ?? '');
    final addressController = TextEditingController(text: vendor.address ?? '');
    final gstController = TextEditingController(text: vendor.gstNo ?? '');
    final panController = TextEditingController(text: vendor.panNo ?? '');
    String? selectedStatus = vendor.status;
    String? selectedType = vendor.type;

    MadFormDialog.show(
      context: context,
      title: 'Edit Vendor',
      maxWidth: 500,
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MadInput(
                  controller: nameController,
                  labelText: 'Company Name',
                  hintText: 'Enter vendor company name',
                ),
                const SizedBox(height: 16),
                MadSelect<String>(
                  labelText: 'Type',
                  value: selectedType,
                  placeholder: 'Select type',
                  options: const [
                    MadSelectOption(value: 'Vendor', label: 'Vendor'),
                    MadSelectOption(value: 'Customer', label: 'Customer'),
                    MadSelectOption(value: 'Service Provider', label: 'Service Provider'),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MadInput(
                        controller: contactController,
                        labelText: 'Contact Person',
                        hintText: 'Primary contact name',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MadInput(
                        controller: phoneController,
                        labelText: 'Phone',
                        hintText: 'Contact number',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MadInput(
                  controller: emailController,
                  labelText: 'Email',
                  hintText: 'vendor@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                MadTextarea(
                  controller: addressController,
                  labelText: 'Address',
                  hintText: 'Full business address',
                  minLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MadInput(
                        controller: gstController,
                        labelText: 'GST Number',
                        hintText: 'GSTIN (optional)',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MadInput(
                        controller: panController,
                        labelText: 'PAN Number',
                        hintText: 'PAN (optional)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MadSelect<String>(
                  labelText: 'Status',
                  value: selectedStatus,
                  placeholder: 'Select status',
                  options: const [
                    MadSelectOption(value: 'Active', label: 'Active'),
                    MadSelectOption(value: 'Inactive', label: 'Inactive'),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        MadButton(
          text: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        MadButton(
          text: 'Save',
          onPressed: () async {
            final data = <String, dynamic>{
              'name': nameController.text.trim(),
              'contact_person': contactController.text.trim().isEmpty ? null : contactController.text.trim(),
              'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
              'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
              'address': addressController.text.trim().isEmpty ? null : addressController.text.trim(),
              'gst_no': gstController.text.trim().isEmpty ? null : gstController.text.trim(),
              'pan_no': panController.text.trim().isEmpty ? null : panController.text.trim(),
              'status': selectedStatus ?? 'Active',
              'type': selectedType,
            };
            Navigator.pop(context);
            final result = await ApiClient.updateVendor(vendor.id, data);
            if (!mounted) return;
            if (result['success'] == true) {
              _loadVendors();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vendor updated successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message']?.toString() ?? 'Failed to update vendor')),
              );
            }
          },
        ),
      ],
    );
  }

  void _showDeleteConfirm(Vendor vendor) {
    MadDialog.confirm(
      context: context,
      title: 'Delete Vendor',
      description: 'Are you sure you want to delete "${vendor.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      final result = await ApiClient.deleteVendor(vendor.id);
      if (!mounted) return;
      if (result['success'] == true) {
        _loadVendors();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Failed to delete vendor')),
        );
      }
    });
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVendorDialog() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final gstController = TextEditingController();
    final panController = TextEditingController();
    String? selectedStatus = 'Active';
    String? selectedType = 'Vendor';

    MadFormDialog.show(
      context: context,
      title: 'Add Vendor',
      maxWidth: 500,
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MadInput(
                  controller: nameController,
                  labelText: 'Company Name',
                  hintText: 'Enter vendor company name',
                ),
                const SizedBox(height: 16),
                MadSelect<String>(
                  labelText: 'Type',
                  value: selectedType,
                  placeholder: 'Select type',
                  options: const [
                    MadSelectOption(value: 'Vendor', label: 'Vendor'),
                    MadSelectOption(value: 'Customer', label: 'Customer'),
                    MadSelectOption(value: 'Service Provider', label: 'Service Provider'),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MadInput(
                        controller: contactController,
                        labelText: 'Contact Person',
                        hintText: 'Primary contact name',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MadInput(
                        controller: phoneController,
                        labelText: 'Phone',
                        hintText: 'Contact number',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MadInput(
                  controller: emailController,
                  labelText: 'Email',
                  hintText: 'vendor@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                MadTextarea(
                  controller: addressController,
                  labelText: 'Address',
                  hintText: 'Full business address',
                  minLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MadInput(
                        controller: gstController,
                        labelText: 'GST Number',
                        hintText: 'GSTIN (optional)',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MadInput(
                        controller: panController,
                        labelText: 'PAN Number',
                        hintText: 'PAN (optional)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MadSelect<String>(
                  labelText: 'Status',
                  value: selectedStatus,
                  placeholder: 'Select status',
                  options: const [
                    MadSelectOption(value: 'Active', label: 'Active'),
                    MadSelectOption(value: 'Inactive', label: 'Inactive'),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        MadButton(
          text: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        MadButton(
          text: 'Add Vendor',
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Company name is required')),
              );
              return;
            }
            final data = <String, dynamic>{
              'name': name,
              'contact_person': contactController.text.trim().isEmpty ? null : contactController.text.trim(),
              'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
              'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
              'address': addressController.text.trim().isEmpty ? null : addressController.text.trim(),
              'gst_no': gstController.text.trim().isEmpty ? null : gstController.text.trim(),
              'pan_no': panController.text.trim().isEmpty ? null : panController.text.trim(),
              'status': selectedStatus ?? 'Active',
              'type': selectedType,
            };
            Navigator.pop(context);
            final result = await ApiClient.createVendor(data);
            if (!mounted) return;
            if (result['success'] == true) {
              _loadVendors();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vendor added successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message']?.toString() ?? 'Failed to add vendor')),
              );
            }
          },
        ),
      ],
    );
  }
}
