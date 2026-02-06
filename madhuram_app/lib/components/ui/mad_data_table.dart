import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'mad_button.dart';
import 'mad_input.dart';
import 'mad_card.dart';

/// Column definition for MadDataTable
class MadTableColumn<T> {
  final String id;
  final String header;
  final Widget Function(T item) cellBuilder;
  final double? width;
  final double? minWidth;
  final double? maxWidth;
  final bool sortable;
  final int Function(T a, T b)? comparator;
  final TextAlign align;
  /// Whether to show this column on mobile in card view
  final bool showInMobileCard;
  /// Priority for mobile card display (lower = more important)
  final int mobilePriority;

  const MadTableColumn({
    required this.id,
    required this.header,
    required this.cellBuilder,
    this.width,
    this.minWidth,
    this.maxWidth,
    this.sortable = false,
    this.comparator,
    this.align = TextAlign.left,
    this.showInMobileCard = true,
    this.mobilePriority = 10,
  });
}

/// Sort direction enum
enum SortDirection { ascending, descending }

/// Data table component matching shadcn/ui DataTable - Responsive version
class MadDataTable<T> extends StatefulWidget {
  final List<T> data;
  final List<MadTableColumn<T>> columns;
  final bool showSearch;
  final String? searchHint;
  final bool Function(T item, String query)? searchFilter;
  final bool showPagination;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final bool selectable;
  final Set<T>? selectedItems;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final VoidCallback? onSelectAll;
  final Widget Function(T item)? rowActions;
  final bool loading;
  final String? emptyMessage;
  final Widget? emptyWidget;
  final Widget? headerActions;
  final double? height;
  /// Title column ID for mobile card view (shown as card header)
  final String? mobileCardTitleColumn;
  /// Subtitle column ID for mobile card view
  final String? mobileCardSubtitleColumn;
  /// Custom mobile card builder
  final Widget Function(T item, List<MadTableColumn<T>> columns)? mobileCardBuilder;
  /// Callback when row/card is tapped
  final void Function(T item)? onRowTap;

  const MadDataTable({
    super.key,
    required this.data,
    required this.columns,
    this.showSearch = true,
    this.searchHint,
    this.searchFilter,
    this.showPagination = true,
    this.rowsPerPage = 10,
    this.rowsPerPageOptions = const [10, 25, 50, 100],
    this.selectable = false,
    this.selectedItems,
    this.onSelectionChanged,
    this.onSelectAll,
    this.rowActions,
    this.loading = false,
    this.emptyMessage,
    this.emptyWidget,
    this.headerActions,
    this.height,
    this.mobileCardTitleColumn,
    this.mobileCardSubtitleColumn,
    this.mobileCardBuilder,
    this.onRowTap,
  });

  @override
  State<MadDataTable<T>> createState() => _MadDataTableState<T>();
}

class _MadDataTableState<T> extends State<MadDataTable<T>> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  int _currentPage = 0;
  late int _rowsPerPage;
  String? _sortColumn;
  SortDirection _sortDirection = SortDirection.ascending;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _rowsPerPage = widget.rowsPerPage;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredData {
    List<T> result = widget.data;

    // Apply search filter
    if (_searchQuery.isNotEmpty && widget.searchFilter != null) {
      result = result.where((item) => widget.searchFilter!(item, _searchQuery)).toList();
    }

    // Apply sorting
    if (_sortColumn != null) {
      final column = widget.columns.firstWhere((c) => c.id == _sortColumn);
      if (column.comparator != null) {
        result = List.from(result)
          ..sort((a, b) {
            final comparison = column.comparator!(a, b);
            return _sortDirection == SortDirection.ascending ? comparison : -comparison;
          });
      }
    }

    return result;
  }

  List<T> get _paginatedData {
    if (!widget.showPagination) return _filteredData;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filteredData.length);
    if (start >= _filteredData.length) return [];
    return _filteredData.sublist(start, end);
  }

  int get _totalPages => (_filteredData.length / _rowsPerPage).ceil();

  void _handleSort(MadTableColumn<T> column) {
    if (!column.sortable) return;
    setState(() {
      if (_sortColumn == column.id) {
        _sortDirection = _sortDirection == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending;
      } else {
        _sortColumn = column.id;
        _sortDirection = SortDirection.ascending;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    
    if (responsive.isMobile) {
      return _buildMobileView(context, responsive);
    }
    
    return _buildDesktopView(context, responsive);
  }

  Widget _buildMobileView(BuildContext context, Responsive responsive) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with search and actions
        if (widget.showSearch || widget.headerActions != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                if (widget.showSearch)
                  MadSearchInput(
                    controller: _searchController,
                    hintText: widget.searchHint ?? 'Search...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 0;
                      });
                    },
                    onClear: () {
                      setState(() {
                        _searchQuery = '';
                        _currentPage = 0;
                      });
                    },
                  ),
                if (widget.headerActions != null) ...[
                  const SizedBox(height: 12),
                  widget.headerActions!,
                ],
              ],
            ),
          ),

        // Cards list
        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator())
              : _paginatedData.isEmpty
                  ? Center(
                      child: widget.emptyWidget ??
                          Text(
                            widget.emptyMessage ?? 'No data found',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkMutedForeground
                                  : AppTheme.lightMutedForeground,
                            ),
                          ),
                    )
                  : ListView.separated(
                      itemCount: _paginatedData.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _paginatedData[index];
                        return _buildMobileCard(item, isDark, responsive);
                      },
                    ),
        ),

        // Pagination
        if (widget.showPagination && _filteredData.isNotEmpty)
          _buildMobilePagination(isDark, responsive),
      ],
    );
  }

  Widget _buildMobileCard(T item, bool isDark, Responsive responsive) {
    // Custom builder
    if (widget.mobileCardBuilder != null) {
      return widget.mobileCardBuilder!(item, widget.columns);
    }

    final isSelected = widget.selectedItems?.contains(item) ?? false;
    
    // Sort columns by priority for mobile display
    final mobileColumns = widget.columns
        .where((c) => c.showInMobileCard)
        .toList()
      ..sort((a, b) => a.mobilePriority.compareTo(b.mobilePriority));

    // Find title and subtitle columns
    final titleColumn = widget.mobileCardTitleColumn != null
        ? widget.columns.firstWhere(
            (c) => c.id == widget.mobileCardTitleColumn,
            orElse: () => mobileColumns.first,
          )
        : mobileColumns.first;
    
    MadTableColumn<T>? subtitleColumn;
    if (widget.mobileCardSubtitleColumn != null) {
      subtitleColumn = widget.columns.firstWhere(
        (c) => c.id == widget.mobileCardSubtitleColumn,
        orElse: () => mobileColumns.length > 1 ? mobileColumns[1] : mobileColumns.first,
      );
    }

    // Get remaining columns (excluding title and subtitle)
    final detailColumns = mobileColumns
        .where((c) => c.id != titleColumn.id && c.id != subtitleColumn?.id)
        .take(4)
        .toList();

    return MadCard(
      hoverable: true,
      onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title, subtitle, and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.selectable)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (checked) {
                        final newSelection = Set<T>.from(widget.selectedItems ?? {});
                        if (checked == true) {
                          newSelection.add(item);
                        } else {
                          newSelection.remove(item);
                        }
                        widget.onSelectionChanged?.call(newSelection);
                      },
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                        ),
                        child: titleColumn.cellBuilder(item),
                      ),
                      // Subtitle
                      if (subtitleColumn != null) ...[
                        const SizedBox(height: 4),
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                          ),
                          child: subtitleColumn.cellBuilder(item),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.rowActions != null)
                  widget.rowActions!(item),
              ],
            ),
            // Detail rows
            if (detailColumns.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: detailColumns.map((column) {
                  return SizedBox(
                    width: (responsive.screenWidth - 80) / 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          column.header,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                          ),
                          child: column.cellBuilder(item),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePagination(bool isDark, Responsive responsive) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Text(
            'Showing ${_currentPage * _rowsPerPage + 1}-${((_currentPage + 1) * _rowsPerPage).clamp(0, _filteredData.length)} of ${_filteredData.length}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MadButton(
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                icon: Icons.chevron_left,
                disabled: _currentPage == 0,
                onPressed: () => setState(() => _currentPage--),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              MadButton(
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                icon: Icons.chevron_right,
                disabled: _currentPage >= _totalPages - 1,
                onPressed: () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopView(BuildContext context, Responsive responsive) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with search and actions
        if (widget.showSearch || widget.headerActions != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                if (widget.showSearch)
                  Expanded(
                    child: MadSearchInput(
                      controller: _searchController,
                      hintText: widget.searchHint ?? 'Search...',
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _currentPage = 0;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _searchQuery = '';
                          _currentPage = 0;
                        });
                      },
                    ),
                  ),
                if (widget.headerActions != null) ...[
                  const SizedBox(width: 16),
                  widget.headerActions!,
                ],
              ],
            ),
          ),

        // Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  child: Row(
                    children: [
                      if (widget.selectable)
                        SizedBox(
                          width: 48,
                          child: Checkbox(
                            value: widget.selectedItems?.length == widget.data.length &&
                                widget.data.isNotEmpty,
                            tristate: true,
                            onChanged: (_) => widget.onSelectAll?.call(),
                          ),
                        ),
                      ...widget.columns.map((column) => _buildHeaderCell(column, isDark)),
                      if (widget.rowActions != null)
                        const SizedBox(
                          width: 80,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Table body
                Expanded(
                  child: widget.loading
                      ? const Center(child: CircularProgressIndicator())
                      : _paginatedData.isEmpty
                          ? Center(
                              child: widget.emptyWidget ??
                                  Text(
                                    widget.emptyMessage ?? 'No data found',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkMutedForeground
                                          : AppTheme.lightMutedForeground,
                                    ),
                                  ),
                            )
                          : ListView.separated(
                              itemCount: _paginatedData.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                              itemBuilder: (context, index) {
                                final item = _paginatedData[index];
                                final isSelected = widget.selectedItems?.contains(item) ?? false;
                                return _buildRow(item, isSelected, isDark);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),

        // Pagination
        if (widget.showPagination && _filteredData.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: responsive.isTablet
                ? _buildTabletPagination(isDark)
                : _buildDesktopPagination(isDark),
          ),
      ],
    );
  }

  Widget _buildTabletPagination(bool isDark) {
    return Column(
      children: [
        Text(
          'Showing ${_currentPage * _rowsPerPage + 1} to ${((_currentPage + 1) * _rowsPerPage).clamp(0, _filteredData.length)} of ${_filteredData.length} entries',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MadButton(
              variant: ButtonVariant.outline,
              size: ButtonSize.sm,
              icon: Icons.chevron_left,
              disabled: _currentPage == 0,
              onPressed: () => setState(() => _currentPage--),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            MadButton(
              variant: ButtonVariant.outline,
              size: ButtonSize.sm,
              icon: Icons.chevron_right,
              disabled: _currentPage >= _totalPages - 1,
              onPressed: () => setState(() => _currentPage++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopPagination(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${_currentPage * _rowsPerPage + 1} to ${((_currentPage + 1) * _rowsPerPage).clamp(0, _filteredData.length)} of ${_filteredData.length} entries',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
          ),
        ),
        Row(
          children: [
            // Rows per page selector
            Row(
              children: [
                Text(
                  'Rows per page: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                  ),
                ),
                DropdownButton<int>(
                  value: _rowsPerPage,
                  underline: const SizedBox(),
                  items: widget.rowsPerPageOptions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _rowsPerPage = value;
                        _currentPage = 0;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Page navigation
            MadButton(
              variant: ButtonVariant.outline,
              size: ButtonSize.sm,
              icon: Icons.chevron_left,
              disabled: _currentPage == 0,
              onPressed: () => setState(() => _currentPage--),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            MadButton(
              variant: ButtonVariant.outline,
              size: ButtonSize.sm,
              icon: Icons.chevron_right,
              disabled: _currentPage >= _totalPages - 1,
              onPressed: () => setState(() => _currentPage++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCell(MadTableColumn<T> column, bool isDark) {
    final isSorted = _sortColumn == column.id;

    return Expanded(
      child: InkWell(
        onTap: column.sortable ? () => _handleSort(column) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: column.align == TextAlign.right
                ? MainAxisAlignment.end
                : column.align == TextAlign.center
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  column.header,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (column.sortable) ...[
                const SizedBox(width: 4),
                Icon(
                  isSorted
                      ? (_sortDirection == SortDirection.ascending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 16,
                  color: isSorted
                      ? AppTheme.primaryColor
                      : (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(T item, bool isSelected, bool isDark) {
    return InkWell(
      onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
      child: Container(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        child: Row(
          children: [
            if (widget.selectable)
              SizedBox(
                width: 48,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (checked) {
                    final newSelection = Set<T>.from(widget.selectedItems ?? {});
                    if (checked == true) {
                      newSelection.add(item);
                    } else {
                      newSelection.remove(item);
                    }
                    widget.onSelectionChanged?.call(newSelection);
                  },
                ),
              ),
            ...widget.columns.map((column) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Align(
                      alignment: column.align == TextAlign.right
                          ? Alignment.centerRight
                          : column.align == TextAlign.center
                              ? Alignment.center
                              : Alignment.centerLeft,
                      child: column.cellBuilder(item),
                    ),
                  ),
                )),
            if (widget.rowActions != null)
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: widget.rowActions!(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
