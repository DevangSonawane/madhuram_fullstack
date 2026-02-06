import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Document model
class Document {
  final String id;
  final String name;
  final String type;
  final String? size;
  final String? uploadedBy;
  final String? uploadedAt;
  final String? folder;

  const Document({required this.id, required this.name, required this.type, this.size, this.uploadedBy, this.uploadedAt, this.folder});

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'pdf': return LucideIcons.fileText;
      case 'xlsx': case 'xls': return LucideIcons.fileSpreadsheet;
      case 'docx': case 'doc': return LucideIcons.fileText;
      case 'jpg': case 'jpeg': case 'png': return LucideIcons.image;
      default: return LucideIcons.file;
    }
  }

  Color get iconColor {
    switch (type.toLowerCase()) {
      case 'pdf': return const Color(0xFFEF4444);
      case 'xlsx': case 'xls': return const Color(0xFF22C55E);
      case 'docx': case 'doc': return const Color(0xFF3B82F6);
      case 'jpg': case 'jpeg': case 'png': return const Color(0xFF8B5CF6);
      default: return AppTheme.primaryColor;
    }
  }
}

/// Documents page
class DocumentsPageFull extends StatefulWidget {
  const DocumentsPageFull({super.key});
  @override
  State<DocumentsPageFull> createState() => _DocumentsPageFullState();
}

class _DocumentsPageFullState extends State<DocumentsPageFull> {
  bool _isLoading = false;
  List<Document> _documents = [];
  String _searchQuery = '';
  String? _folderFilter;
  final _searchController = TextEditingController();

  final List<String> _folders = ['BOQ', 'Purchase Orders', 'Challans', 'MIR', 'ITR', 'Invoices'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _documents = [
        Document(id: '1', name: 'BOQ_Project_A.xlsx', type: 'xlsx', size: '2.4 MB', uploadedBy: 'John Doe', uploadedAt: '2024-01-20', folder: 'BOQ'),
        Document(id: '2', name: 'PO-001.pdf', type: 'pdf', size: '1.2 MB', uploadedBy: 'Jane Smith', uploadedAt: '2024-01-22', folder: 'Purchase Orders'),
        Document(id: '3', name: 'MIR-001_Report.pdf', type: 'pdf', size: '856 KB', uploadedBy: 'Mike Johnson', uploadedAt: '2024-01-23', folder: 'MIR'),
        Document(id: '4', name: 'Site_Photo_01.jpg', type: 'jpg', size: '3.1 MB', uploadedBy: 'John Doe', uploadedAt: '2024-01-24', folder: null),
      ];
      _isLoading = false;
    });
  }

  List<Document> get _filteredDocuments {
    List<Document> result = _documents;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((d) => d.name.toLowerCase().contains(query)).toList();
    }
    if (_folderFilter != null) result = result.where((d) => d.folder == _folderFilter).toList();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final screenWidth = MediaQuery.of(context).size.width;

    return ProtectedRoute(
      title: 'Documents',
      route: '/documents',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Documents', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
            const SizedBox(height: 4),
            Text('Manage project documents and files', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
          ])),
          if (!isMobile) MadButton(text: 'Upload File', icon: LucideIcons.upload, onPressed: () => _showUploadDialog()),
        ]),
        const SizedBox(height: 24),
        if (!isMobile) Row(children: [
          Expanded(child: StatCard(title: 'Total Files', value: _documents.length.toString(), icon: LucideIcons.files, iconColor: AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'PDFs', value: _documents.where((d) => d.type == 'pdf').length.toString(), icon: LucideIcons.fileText, iconColor: const Color(0xFFEF4444))),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Spreadsheets', value: _documents.where((d) => d.type == 'xlsx' || d.type == 'xls').length.toString(), icon: LucideIcons.fileSpreadsheet, iconColor: const Color(0xFF22C55E))),
          const SizedBox(width: 16),
          Expanded(child: StatCard(title: 'Images', value: _documents.where((d) => ['jpg', 'jpeg', 'png'].contains(d.type)).length.toString(), icon: LucideIcons.image, iconColor: const Color(0xFF8B5CF6))),
        ]),
        if (!isMobile) const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: isMobile ? double.infinity : 320, child: MadSearchInput(controller: _searchController, hintText: 'Search documents...', onChanged: (v) => setState(() => _searchQuery = v), onClear: () => setState(() => _searchQuery = ''))),
          SizedBox(width: 180, child: MadSelect<String>(value: _folderFilter, placeholder: 'All Folders', clearable: true, options: _folders.map((f) => MadSelectOption(value: f, label: f)).toList(), onChanged: (v) => setState(() => _folderFilter = v))),
          if (isMobile) MadButton(icon: LucideIcons.upload, text: 'Upload', onPressed: () => _showUploadDialog()),
        ]),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : _filteredDocuments.isEmpty ? _buildEmptyState(isDark) : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isMobile ? 1 : (screenWidth > 1200 ? 4 : 3), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: isMobile ? 3 : 1.5),
            itemCount: _filteredDocuments.length,
            itemBuilder: (context, index) => _buildDocumentCard(_filteredDocuments[index], isDark),
          ),
        ),
      ]),
    );
  }

  Widget _buildDocumentCard(Document doc, bool isDark) {
    return MadCard(
      onTap: () {},
      hoverable: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: doc.iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(doc.icon, color: doc.iconColor, size: 20),
            ),
            const Spacer(),
            MadDropdownMenuButton(items: [
              MadMenuItem(label: 'Download', icon: LucideIcons.download, onTap: () {}),
              MadMenuItem(label: 'Preview', icon: LucideIcons.eye, onTap: () {}),
              MadMenuItem(label: 'Share', icon: LucideIcons.share2, onTap: () {}),
              MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
            ]),
          ]),
          const SizedBox(height: 12),
          Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(children: [
            Text(doc.size ?? '', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
            const SizedBox(width: 8),
            Text('•', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
            const SizedBox(width: 8),
            Expanded(child: Text(doc.uploadedAt ?? '', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground), overflow: TextOverflow.ellipsis)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(LucideIcons.folderOpen, size: 64, color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3)),
      const SizedBox(height: 24),
      Text('No documents yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
      const SizedBox(height: 8),
      Text('Upload your first document to get started', style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
      const SizedBox(height: 24),
      MadButton(text: 'Upload File', icon: LucideIcons.upload, onPressed: () => _showUploadDialog()),
    ])));
  }

  void _showUploadDialog() {
    MadFormDialog.show(
      context: context,
      title: 'Upload Document',
      maxWidth: 500,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 150,
          decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), style: BorderStyle.solid), borderRadius: BorderRadius.circular(12), color: AppTheme.primaryColor.withOpacity(0.05)),
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.cloudUpload, size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            Text('Click to browse or drag and drop', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
          ])),
        ),
        const SizedBox(height: 16),
        MadSelect<String>(labelText: 'Folder', placeholder: 'Select folder (optional)', options: _folders.map((f) => MadSelectOption(value: f, label: f)).toList(), onChanged: (v) {}),
      ]),
      actions: [
        MadButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
        MadButton(text: 'Upload', onPressed: () { Navigator.pop(context); _loadDocuments(); }),
      ],
    );
  }
}
