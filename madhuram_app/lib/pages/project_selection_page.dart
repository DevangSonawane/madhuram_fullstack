import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../store/project_actions.dart';
import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../components/ui/mad_card.dart';
import '../components/ui/mad_button.dart';
import '../components/ui/mad_badge.dart';
import '../components/ui/mad_input.dart';
import '../utils/responsive.dart';
import '../models/project.dart';

/// Project Selection page - Responsive version
class ProjectSelectionPage extends StatefulWidget {
  const ProjectSelectionPage({super.key});

  @override
  State<ProjectSelectionPage> createState() => _ProjectSelectionPageState();
}

class _ProjectSelectionPageState extends State<ProjectSelectionPage> {
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  List<Project> _projects = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoadProjects() async {
    if (!mounted) return;
    
    final store = StoreProvider.of<AppState>(context);
    
    // Check if authenticated
    if (!store.state.auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    
    await _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final store = StoreProvider.of<AppState>(context);
    store.dispatch(FetchProjectsStart());

    try {
      final result = await ApiClient.getProjects();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        // Handle both List and other response formats
        final List<dynamic> projectList = data is List ? data : [];
        final projectMaps = projectList
            .map((e) => e as Map<String, dynamic>)
            .toList();
        final projects = projectMaps
            .map((e) => Project.fromJson(e))
            .toList();
        
        store.dispatch(FetchProjectsSuccess(projectMaps));
        setState(() {
          _projects = projects;
          _isLoading = false;
          _error = null;
        });
      } else {
        final errorMsg = result['error']?.toString() ?? 'Failed to load projects';
        store.dispatch(FetchProjectsFailure(errorMsg));
        setState(() {
          _isLoading = false;
          _error = errorMsg;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = 'Error loading projects: $e';
      store.dispatch(FetchProjectsFailure(errorMsg));
      setState(() {
        _isLoading = false;
        _error = errorMsg;
      });
    }
  }

  void _selectProject(Project project) {
    if (project.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project ID is missing. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final store = StoreProvider.of<AppState>(context);
    // Convert Project to Map for Redux state storage
    store.dispatch(SelectProject(project.toMap()));
    
    // Save selected project ID to storage for persistence (like React app)
    AuthStorage.setSelectedProjectId(project.id);
    
    // Navigate to dashboard
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  List<Project> get _filteredProjects {
    if (_searchQuery.isEmpty) return _projects;
    final query = _searchQuery.toLowerCase();
    return _projects.where((p) {
      return p.name.toLowerCase().contains(query) ||
          (p.client?.toLowerCase().contains(query) ?? false) ||
          (p.location?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ProjectSelectionViewModel>(
      converter: (store) => _ProjectSelectionViewModel(
        isAuthenticated: store.state.auth.isAuthenticated,
        userName: store.state.auth.userName ?? 'User',
        isAdmin: store.state.auth.isAdmin,
      ),
      builder: (context, vm) {
        // Check auth
        if (!vm.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildPage(context, vm);
      },
    );
  }

  Widget _buildPage(BuildContext context, _ProjectSelectionViewModel vm) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(responsive.value(mobile: 16, tablet: 20, desktop: 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: responsive.value(mobile: 36, tablet: 38, desktop: 40),
                        height: responsive.value(mobile: 36, tablet: 38, desktop: 40),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.package2,
                          color: Colors.white,
                          size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Madhuram',
                        style: TextStyle(
                          fontSize: responsive.value(mobile: 20, tablet: 22, desktop: 24),
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                        ),
                      ),
                      const Spacer(),
                      if (vm.isAdmin)
                        MadButton(
                          icon: LucideIcons.plus,
                          text: responsive.isMobile ? null : 'New Project',
                          onPressed: () => _showCreateProjectDialog(),
                          size: responsive.isMobile ? ButtonSize.icon : ButtonSize.md,
                        ),
                    ],
                  ),
                  SizedBox(height: responsive.value(mobile: 24, tablet: 28, desktop: 32)),
                  Text(
                    'Welcome, ${vm.userName}',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 24, tablet: 28, desktop: 32),
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a project to continue to the dashboard.',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 14, tablet: 15, desktop: 16),
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                  SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
                  // Search
                  MadSearchInput(
                    controller: _searchController,
                    hintText: 'Search projects...',
                    width: double.infinity,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onClear: () => setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    }),
                  ),
                ],
              ),
            ),

            // Projects grid or loading/error state
            Expanded(
              child: _buildContent(isDark, responsive),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Responsive responsive) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading projects...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: responsive.value(mobile: 48, tablet: 56, desktop: 64),
                color: Colors.red.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load projects',
                style: TextStyle(
                  fontSize: responsive.value(mobile: 16, tablet: 17, desktop: 18),
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: responsive.value(mobile: 13, tablet: 13, desktop: 14),
                  color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              MadButton(
                icon: LucideIcons.refreshCw,
                text: 'Retry',
                onPressed: _loadProjects,
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredProjects.isEmpty) {
      return _buildEmptyState(isDark, responsive);
    }

    final crossAxisCount = responsive.value(mobile: 1, tablet: 2, desktop: responsive.screenWidth > 1200 ? 3 : 2);
    final spacing = responsive.value(mobile: 16.0, tablet: 20.0, desktop: 24.0);
    final aspectRatio = responsive.value(mobile: 1.6, tablet: 1.4, desktop: 1.3);

    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: GridView.builder(
        padding: EdgeInsets.all(responsive.value(mobile: 16, tablet: 20, desktop: 24)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: _filteredProjects.length,
        itemBuilder: (context, index) {
          return _buildProjectCard(_filteredProjects[index], isDark, responsive);
        },
      ),
    );
  }

  Widget _buildProjectCard(Project project, bool isDark, Responsive responsive) {
    return MadCard(
      hoverable: true,
      onTap: () => _selectProject(project),
      child: Padding(
        padding: EdgeInsets.all(responsive.value(mobile: 16, tablet: 20, desktop: 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 16, tablet: 18, desktop: 20),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: project.status ?? 'Planning'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              project.client ?? '',
              style: TextStyle(
                fontSize: responsive.value(mobile: 12, tablet: 13, desktop: 14),
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Project info
            _buildInfoRow(
              icon: LucideIcons.mapPin,
              value: project.location ?? 'No location specified',
              isDark: isDark,
              responsive: responsive,
            ),
            SizedBox(height: responsive.value(mobile: 6, tablet: 7, desktop: 8)),
            _buildInfoRow(
              icon: LucideIcons.calendar,
              value: 'Started: ${project.startDate ?? 'N/A'}',
              isDark: isDark,
              responsive: responsive,
            ),
            if (project.estimateValue != null) ...[
              SizedBox(height: responsive.value(mobile: 8, tablet: 10, desktop: 12)),
              Text(
                project.estimateValue!,
                style: TextStyle(
                  fontSize: responsive.value(mobile: 15, tablet: 16, desktop: 18),
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                ),
              ),
            ],
            const Spacer(),
            // Action button
            SizedBox(
              width: double.infinity,
              child: MadButton(
                text: 'Select Project',
                size: responsive.isMobile ? ButtonSize.sm : ButtonSize.md,
                onPressed: () => _selectProject(project),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String value,
    required bool isDark,
    required Responsive responsive,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: responsive.value(mobile: 14, tablet: 15, desktop: 16),
          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
        ),
        SizedBox(width: responsive.value(mobile: 6, tablet: 7, desktop: 8)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.value(mobile: 12, tablet: 13, desktop: 14),
              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, Responsive responsive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.folderOpen,
              size: responsive.value(mobile: 48, tablet: 56, desktop: 64),
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
            Text(
              _searchQuery.isEmpty ? 'No projects yet' : 'No projects found',
              style: TextStyle(
                fontSize: responsive.value(mobile: 16, tablet: 17, desktop: 18),
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Create your first project to get started'
                  : 'Try a different search term',
              style: TextStyle(
                fontSize: responsive.value(mobile: 13, tablet: 13, desktop: 14),
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
              MadButton(
                icon: LucideIcons.plus,
                text: 'New Project',
                onPressed: () => _showCreateProjectDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final clientController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MadInput(
                controller: nameController,
                labelText: 'Project Name',
                hintText: 'Enter project name',
              ),
              const SizedBox(height: 16),
              MadInput(
                controller: clientController,
                labelText: 'Client Name',
                hintText: 'Enter client name',
              ),
              const SizedBox(height: 16),
              MadInput(
                controller: locationController,
                labelText: 'Location',
                hintText: 'Enter location',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Refresh projects after creation
              _loadProjects();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _ProjectSelectionViewModel {
  final bool isAuthenticated;
  final String userName;
  final bool isAdmin;

  _ProjectSelectionViewModel({
    required this.isAuthenticated,
    required this.userName,
    required this.isAdmin,
  });
}
