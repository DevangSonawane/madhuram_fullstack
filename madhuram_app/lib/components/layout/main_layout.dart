import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import '../../theme/app_theme.dart';
import '../../store/app_state.dart';
import '../../utils/responsive.dart';
import 'sidebar.dart';
import 'app_header.dart';

/// Main layout matching React's MainLayout.jsx - Responsive version
class MainLayout extends StatefulWidget {
  final String title;
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.title,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  void _navigate(String route, String title) {
    // Close drawer on mobile
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final responsive = Responsive(context);

    return StoreConnector<AppState, _MainLayoutViewModel>(
      converter: (store) => _MainLayoutViewModel(
        isAuthenticated: store.state.auth.isAuthenticated,
        hasSelectedProject: store.state.project.selectedProject != null,
        projectName: store.state.project.selectedProjectName,
      ),
      builder: (context, vm) {
        // Auth check - redirect if not authenticated
        if (!vm.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Project check - redirect if no project selected
        if (!vm.hasSelectedProject) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/projects');
            }
          });
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          drawer: responsive.isMobile || responsive.isTablet
              ? Drawer(
                  width: responsive.isMobile ? responsive.screenWidth * 0.85 : 288,
                  child: AppSidebar(
                    isCollapsed: false,
                    currentRoute: widget.currentRoute,
                    onNavigate: _navigate,
                  ),
                )
              : null,
          body: Row(
            children: [
              // Desktop sidebar only
              if (responsive.isDesktop)
                Stack(
                  children: [
                    AppSidebar(
                      isCollapsed: _isSidebarCollapsed,
                      currentRoute: widget.currentRoute,
                      onNavigate: _navigate,
                    ),
                    SidebarToggleButton(
                      isCollapsed: _isSidebarCollapsed,
                      onToggle: _toggleSidebar,
                    ),
                  ],
                ),
              
              // Main content
              Expanded(
                child: Column(
                  children: [
                    AppHeader(
                      title: widget.title,
                      onMenuPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: responsive.padding,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MainLayoutViewModel {
  final bool isAuthenticated;
  final bool hasSelectedProject;
  final String? projectName;

  _MainLayoutViewModel({
    required this.isAuthenticated,
    required this.hasSelectedProject,
    this.projectName,
  });
}

/// Protected route wrapper - wraps pages with MainLayout
class ProtectedRoute extends StatelessWidget {
  final String title;
  final String route;
  final Widget child;

  const ProtectedRoute({
    super.key,
    required this.title,
    required this.route,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: title,
      currentRoute: route,
      child: child,
    );
  }
}
