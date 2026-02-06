import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Sample model
class Sample {
  final String id;
  final String sampleNo;
  final String material;
  final String vendor;
  final String? submittedDate;
  final String status;
  final String? result;
  final String? remarks;

  const Sample({
    required this.id,
    required this.sampleNo,
    required this.material,
    required this.vendor,
    this.submittedDate,
    this.status = 'Pending',
    this.result,
    this.remarks,
  });
}

/// Samples page matching React's Samples page
class SamplesPageFull extends StatefulWidget {
  const SamplesPageFull({super.key});

  @override
  State<SamplesPageFull> createState() => _SamplesPageFullState();
}

class _SamplesPageFullState extends State<SamplesPageFull> {
  bool _isLoading = false;
  List<Sample> _samples = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSamples();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSamples() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _samples = [
        Sample(id: '1', sampleNo: 'SMP-001', material: 'Cement OPC 53', vendor: 'ABC Suppliers', submittedDate: '2024-01-20', status: 'Approved', result: 'Passed'),
        Sample(id: '2', sampleNo: 'SMP-002', material: 'PVC Pipe 4"', vendor: 'XYZ Traders', submittedDate: '2024-01-22', status: 'Under Testing', result: null),
        Sample(id: '3', sampleNo: 'SMP-003', material: 'Steel Rods 12mm', vendor: 'PQR Industries', submittedDate: '2024-01-23', status: 'Rejected', result: 'Failed', remarks: 'Does not meet specifications'),
      ];
      _isLoading = false;
    });
  }

  List<Sample> get _filteredSamples {
    List<Sample> result = _samples;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((s) {
        return s.sampleNo.toLowerCase().contains(query) ||
            s.material.toLowerCase().contains(query) ||
            s.vendor.toLowerCase().contains(query);
      }).toList();
    }

    if (_statusFilter != null) {
      result = result.where((s) => s.status == _statusFilter).toList();
    }

    return result;
  }

  List<Sample> get _paginatedSamples {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredSamples;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredSamples.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'Sample Management',
      route: '/samples',
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
                      'Sample Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track material samples and approval status',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'Submit Sample',
                  icon: LucideIcons.plus,
                  onPressed: () => _showSubmitSampleDialog(),
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
                    title: 'Total Samples',
                    value: _samples.length.toString(),
                    icon: LucideIcons.testTube,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Under Testing',
                    value: _samples.where((s) => s.status == 'Under Testing').length.toString(),
                    icon: LucideIcons.clock,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Approved',
                    value: _samples.where((s) => s.status == 'Approved').length.toString(),
                    icon: LucideIcons.circleCheck,
                    iconColor: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Rejected',
                    value: _samples.where((s) => s.status == 'Rejected').length.toString(),
                    icon: LucideIcons.circleX,
                    iconColor: AppTheme.lightDestructive,
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
                  hintText: 'Search samples...',
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
                width: 150,
                child: MadSelect<String>(
                  value: _statusFilter,
                  placeholder: 'All Status',
                  clearable: true,
                  options: const [
                    MadSelectOption(value: 'Pending', label: 'Pending'),
                    MadSelectOption(value: 'Under Testing', label: 'Under Testing'),
                    MadSelectOption(value: 'Approved', label: 'Approved'),
                    MadSelectOption(value: 'Rejected', label: 'Rejected'),
                  ],
                  onChanged: (value) => setState(() {
                    _statusFilter = value;
                    _currentPage = 1;
                  }),
                ),
              ),
              if (isMobile)
                MadButton(
                  icon: LucideIcons.plus,
                  text: 'Submit',
                  onPressed: () => _showSubmitSampleDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSamples.isEmpty
                    ? _buildEmptyState(isDark)
                    : MadCard(
                        child: Column(
                          children: [
                            // Table header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.3),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: Row(
                                children: [
                                  _buildHeaderCell('Sample #', flex: 1, isDark: isDark),
                                  _buildHeaderCell('Material', flex: 2, isDark: isDark),
                                  if (!isMobile) ...[
                                    _buildHeaderCell('Vendor', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Date', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Result', flex: 1, isDark: isDark),
                                  ],
                                  _buildHeaderCell('Status', flex: 1, isDark: isDark),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            // Table rows
                            Expanded(
                              child: ListView.separated(
                                itemCount: _paginatedSamples.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                ),
                                itemBuilder: (context, index) {
                                  return _buildTableRow(_paginatedSamples[index], isDark, isMobile);
                                },
                              ),
                            ),
                            // Pagination
                            if (_totalPages > 1) _buildPagination(isDark),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, required bool isDark}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
        ),
      ),
    );
  }

  Widget _buildTableRow(Sample sample, bool isDark, bool isMobile) {
    BadgeVariant statusVariant;
    switch (sample.status) {
      case 'Approved':
        statusVariant = BadgeVariant.default_;
        break;
      case 'Under Testing':
        statusVariant = BadgeVariant.secondary;
        break;
      case 'Rejected':
        statusVariant = BadgeVariant.destructive;
        break;
      default:
        statusVariant = BadgeVariant.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              sample.sampleNo,
              style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sample.material, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (isMobile)
                  Text(
                    sample.vendor,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Expanded(flex: 1, child: Text(sample.vendor)),
            Expanded(
              flex: 1,
              child: Text(
                sample.submittedDate ?? '-',
                style: TextStyle(
                  color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: sample.result != null
                  ? MadBadge(
                      text: sample.result!,
                      variant: sample.result == 'Passed' ? BadgeVariant.default_ : BadgeVariant.destructive,
                    )
                  : Text(
                      '-',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
            ),
          ],
          Expanded(
            flex: 1,
            child: MadBadge(text: sample.status, variant: statusVariant),
          ),
          MadDropdownMenuButton(
            items: [
              MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
              MadMenuItem(label: 'Update Status', icon: LucideIcons.refreshCw, onTap: () {}),
              MadMenuItem(label: 'Add Test Result', icon: LucideIcons.clipboardCheck, onTap: () {}),
              MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredSamples.length ? _filteredSamples.length : _currentPage * _itemsPerPage} of ${_filteredSamples.length}',
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
              LucideIcons.testTube,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No samples yet' : 'No samples found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Submit a sample for testing to get started'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'Submit Sample',
                icon: LucideIcons.plus,
                onPressed: () => _showSubmitSampleDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSubmitSampleDialog() {
    MadFormDialog.show(
      context: context,
      title: 'Submit Sample for Testing',
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadSelect<String>(
            labelText: 'Material',
            placeholder: 'Select material',
            searchable: true,
            options: const [
              MadSelectOption(value: 'cement', label: 'Cement OPC 53'),
              MadSelectOption(value: 'pvc', label: 'PVC Pipe 4"'),
              MadSelectOption(value: 'steel', label: 'Steel Rods 12mm'),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
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
          MadInput(
            labelText: 'Batch/Lot Number',
            hintText: 'Enter batch or lot number',
          ),
          const SizedBox(height: 16),
          MadTextarea(
            labelText: 'Remarks',
            hintText: 'Any additional notes...',
            minLines: 2,
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
          text: 'Submit Sample',
          onPressed: () {
            Navigator.pop(context);
            _loadSamples();
          },
        ),
      ],
    );
  }
}
