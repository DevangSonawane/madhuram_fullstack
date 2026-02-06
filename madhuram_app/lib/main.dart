import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'dart:io';

// Store
import 'store/app_state.dart';
import 'store/auth_reducer.dart';
import 'store/auth_actions.dart';
import 'store/project_actions.dart';

// Models
import 'models/project.dart';

// Services
import 'services/auth_storage.dart';
import 'services/http_overrides.dart';
import 'services/api_client.dart';

// Theme
import 'theme/app_theme.dart';

// Pages
import 'pages/login_page.dart';
import 'pages/project_selection_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/boq_page.dart';
import 'pages/profile_page.dart';
// Inventory Module
import 'pages/materials_page.dart';
import 'pages/stock_areas_page.dart';
import 'pages/stock_transfers_page.dart';
import 'pages/consumption_page.dart';
import 'pages/returns_page.dart';

// Procurement Module
import 'pages/purchase_requests_page.dart';
import 'pages/vendor_comparison_page.dart';
import 'pages/purchase_orders_page_full.dart';
import 'pages/vendors_page_full.dart';
import 'pages/samples_page.dart';

// Delivery & Inspection Module
import 'pages/challans_page.dart';
import 'pages/mer_page.dart';
import 'pages/mir_page_full.dart';
import 'pages/itr_page_full.dart';

// Project Management Module
import 'pages/mas_page.dart';
import 'pages/billing_page.dart';

// Reporting & Admin Module
import 'pages/documents_page.dart';
import 'pages/reports_page.dart';
import 'pages/audit_logs_page.dart';

// Create store globally
late Store<AppState> store;

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Allow self-signed certs in dev mode
  assert(() {
    HttpOverrides.global = DevHttpOverrides();
    return true;
  }());
  
  // Create the Redux store ONCE at app startup
  store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
  );
  
  // Restore auth state from storage before running app
  await _restoreAuthState();
  
  runApp(MyApp(store: store));
}

/// Restore authentication state from storage
Future<void> _restoreAuthState() async {
  try {
    final hasUser = await AuthStorage.hasUser();
    if (hasUser) {
      final user = await AuthStorage.getUser();
      if (user != null) {
        store.dispatch(LoginSuccess(user));
        
        // Also try to restore selected project
        final savedProjectId = await AuthStorage.getSelectedProjectId();
        if (savedProjectId != null) {
          // Fetch projects and restore selection
          final result = await ApiClient.getProjects();
          if (result['success'] == true) {
            final data = result['data'];
            final List<dynamic> projectList = data is List ? data : [];
            final projectMaps = projectList
                .map((e) => e as Map<String, dynamic>)
                .toList();
            store.dispatch(FetchProjectsSuccess(projectMaps));
            
            // Find and select the saved project using Project model for comparison
            final projects = projectMaps.map((m) => Project.fromJson(m)).toList();
            final savedProject = projects.firstWhere(
              (p) => p.id == savedProjectId,
              orElse: () => Project(id: '', name: ''),
            );
            if (savedProject.id.isNotEmpty) {
              store.dispatch(SelectProject(savedProject.toMap()));
            }
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Error restoring auth state: $e');
  }
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;
  
  const MyApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: store,
      child: StoreConnector<AppState, ThemeState>(
        converter: (store) => store.state.theme,
        builder: (context, themeState) {
          // Determine actual theme mode
          final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
          final effectiveTheme = themeState.mode == AppThemeMode.system
              ? (platformBrightness == Brightness.dark ? AppThemeMode.dark : AppThemeMode.light)
              : themeState.mode;
          
          return MaterialApp(
            title: 'Madhuram',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: effectiveTheme == AppThemeMode.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const AppRouter(),
            routes: {
              // Auth
              '/login': (context) => const LoginPage(),
              '/projects': (context) => const ProjectSelectionPage(),
              
              // Main
              '/dashboard': (context) => const DashboardPage(),
              
              // Project Management
              '/boq': (context) => const BOQPage(),
              '/mas': (context) => const MASPageFull(),
              
              // Procurement
              '/samples': (context) => const SamplesPageFull(),
              '/purchase-requests': (context) => const PurchaseRequestsPageFull(),
              '/vendor-comparison': (context) => const VendorComparisonPageFull(),
              '/purchase-orders': (context) => const PurchaseOrdersPageFull(),
              '/vendors': (context) => const VendorsPageFull(),
              
              // Delivery & Inspection
              '/challans': (context) => const ChallansPageFull(),
              '/mer': (context) => const MERPageFull(),
              '/mir': (context) => const MIRPageFull(),
              '/itr': (context) => const ITRPageFull(),
              
              // Billing
              '/billing': (context) => const BillingPageFull(),
              
              // Inventory
              '/stock-areas': (context) => const StockAreasPage(),
              '/materials': (context) => const MaterialsPage(),
              '/stock-transfers': (context) => const StockTransfersPage(),
              '/consumption': (context) => const ConsumptionPage(),
              '/returns': (context) => const ReturnsPage(),
              
              // Documents & Analytics
              '/documents': (context) => const DocumentsPageFull(),
              '/reports': (context) => const ReportsPageFull(),
              '/audit-logs': (context) => const AuditLogsPageFull(),
              
              // Profile
              '/profile': (context) => const ProfilePage(),
            },
          );
        },
      ),
    );
  }
}

/// App Router - handles initial routing based on auth state
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _AppRouterViewModel>(
      converter: (store) => _AppRouterViewModel(
        isAuthenticated: store.state.auth.isAuthenticated,
        hasSelectedProject: store.state.project.selectedProject != null,
      ),
      builder: (context, vm) {
        if (!vm.isAuthenticated) {
          return const LoginPage();
        }
        
        if (!vm.hasSelectedProject) {
          return const ProjectSelectionPage();
        }
        
        return const DashboardPage();
      },
    );
  }
}

class _AppRouterViewModel {
  final bool isAuthenticated;
  final bool hasSelectedProject;
  
  _AppRouterViewModel({
    required this.isAuthenticated,
    required this.hasSelectedProject,
  });
}
