import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../store/theme_actions.dart';
import '../services/api_client.dart';
import '../models/user.dart';
import '../components/ui/mad_card.dart';
import '../components/ui/mad_button.dart';
import '../components/ui/mad_badge.dart';
import '../components/ui/mad_input.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';

/// Profile page - Responsive version
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _users = [];
  bool _loadingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    final result = await ApiClient.getUsers();
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() {
        _users = data.map((e) => User.fromJson(e)).toList();
        _loadingUsers = false;
      });
    } else {
      setState(() => _loadingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return ProtectedRoute(
      title: 'Profile',
      route: '/profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Profile & Settings',
            style: TextStyle(
              fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your account settings and preferences',
            style: TextStyle(
              fontSize: responsive.value(mobile: 13, tablet: 14, desktop: 14),
              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
            ),
          ),
          SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: responsive.isMobile,
              indicator: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              unselectedLabelColor: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(fontSize: responsive.value(mobile: 13, tablet: 14, desktop: 14)),
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Appearance'),
                Tab(text: 'Users'),
              ],
            ),
          ),
          SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(isDark, responsive),
                _buildAppearanceTab(isDark, responsive),
                _buildUsersTab(isDark, responsive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(bool isDark, Responsive responsive) {
    return StoreConnector<AppState, AuthState>(
      converter: (store) => store.state.auth,
      builder: (context, auth) {
        return SingleChildScrollView(
          child: MadCard(
            child: Padding(
              padding: EdgeInsets.all(responsive.value(mobile: 16, tablet: 20, desktop: 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header - stack on mobile
                  if (responsive.isMobile)
                    Column(
                      children: [
                        _buildAvatar(auth, responsive),
                        const SizedBox(height: 16),
                        _buildProfileInfo(auth, isDark, responsive, centered: true),
                      ],
                    )
                  else
                    Row(
                      children: [
                        _buildAvatar(auth, responsive),
                        SizedBox(width: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
                        Expanded(child: _buildProfileInfo(auth, isDark, responsive)),
                      ],
                    ),
                  SizedBox(height: responsive.value(mobile: 24, tablet: 28, desktop: 32)),
                  const Divider(),
                  SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 16, tablet: 17, desktop: 18),
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Name', auth.userName ?? '-', isDark, responsive),
                  _buildInfoRow('Email', auth.userEmail ?? '-', isDark, responsive),
                  _buildInfoRow('Phone', auth.userPhone ?? '-', isDark, responsive),
                  _buildInfoRow('Role', _getRoleName(auth.userRole ?? ''), isDark, responsive),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(AuthState auth, Responsive responsive) {
    final size = responsive.value(mobile: 64.0, tablet: 72.0, desktop: 80.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          auth.userName?.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase() ?? 'U',
          style: TextStyle(
            fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(AuthState auth, bool isDark, Responsive responsive, {bool centered = false}) {
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          auth.userName ?? 'User',
          style: TextStyle(
            fontSize: responsive.value(mobile: 20, tablet: 22, desktop: 24),
            fontWeight: FontWeight.bold,
          ),
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 4),
        Text(
          auth.userEmail ?? '',
          style: TextStyle(
            fontSize: responsive.value(mobile: 13, tablet: 14, desktop: 14),
            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
          ),
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 8),
        MadBadge(
          text: _getRoleName(auth.userRole ?? ''),
          variant: BadgeVariant.secondary,
        ),
      ],
    );
  }

  Widget _buildAppearanceTab(bool isDark, Responsive responsive) {
    return StoreConnector<AppState, ThemeState>(
      converter: (store) => store.state.theme,
      builder: (context, themeState) {
        return SingleChildScrollView(
          child: MadCard(
            child: Padding(
              padding: EdgeInsets.all(responsive.value(mobile: 16, tablet: 20, desktop: 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 16, tablet: 17, desktop: 18),
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your preferred theme',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 13, tablet: 14, desktop: 14),
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                  SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),
                  // Theme options - stack on mobile
                  if (responsive.isMobile)
                    Column(
                      children: [
                        _buildThemeOption(
                          icon: LucideIcons.sun,
                          label: 'Light',
                          isSelected: themeState.mode == AppThemeMode.light,
                          onTap: () => _setTheme(AppThemeMode.light),
                          isDark: isDark,
                          responsive: responsive,
                        ),
                        const SizedBox(height: 12),
                        _buildThemeOption(
                          icon: LucideIcons.moon,
                          label: 'Dark',
                          isSelected: themeState.mode == AppThemeMode.dark,
                          onTap: () => _setTheme(AppThemeMode.dark),
                          isDark: isDark,
                          responsive: responsive,
                        ),
                        const SizedBox(height: 12),
                        _buildThemeOption(
                          icon: LucideIcons.laptop,
                          label: 'System',
                          isSelected: themeState.mode == AppThemeMode.system,
                          onTap: () => _setTheme(AppThemeMode.system),
                          isDark: isDark,
                          responsive: responsive,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildThemeOption(
                            icon: LucideIcons.sun,
                            label: 'Light',
                            isSelected: themeState.mode == AppThemeMode.light,
                            onTap: () => _setTheme(AppThemeMode.light),
                            isDark: isDark,
                            responsive: responsive,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildThemeOption(
                            icon: LucideIcons.moon,
                            label: 'Dark',
                            isSelected: themeState.mode == AppThemeMode.dark,
                            onTap: () => _setTheme(AppThemeMode.dark),
                            isDark: isDark,
                            responsive: responsive,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildThemeOption(
                            icon: LucideIcons.laptop,
                            label: 'System',
                            isSelected: themeState.mode == AppThemeMode.system,
                            onTap: () => _setTheme(AppThemeMode.system),
                            isDark: isDark,
                            responsive: responsive,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(bool isDark, Responsive responsive) {
    return StoreConnector<AppState, bool>(
      converter: (store) => store.state.auth.isAdmin,
      builder: (context, isAdmin) {
        if (!isAdmin) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: responsive.value(mobile: 48, tablet: 56, desktop: 64),
                    color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Admin access required',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 16, tablet: 17, desktop: 18),
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need admin privileges to manage users',
                    style: TextStyle(
                      fontSize: responsive.value(mobile: 13, tablet: 14, desktop: 14),
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (_loadingUsers) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Management',
                  style: TextStyle(
                    fontSize: responsive.value(mobile: 16, tablet: 17, desktop: 18),
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                  ),
                ),
                MadButton(
                  text: responsive.isMobile ? null : 'Add User',
                  icon: LucideIcons.plus,
                  size: ButtonSize.sm,
                  onPressed: () => _showAddUserDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MadCard(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _buildUserListTile(user, isDark, responsive);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserListTile(User user, bool isDark, Responsive responsive) {
    if (responsive.isMobile) {
      // Card-style on mobile
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                user.initials,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Text(
          user.initials,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(user.name),
      subtitle: Text(user.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadBadge(
            text: _getRoleName(user.role),
            variant: BadgeVariant.secondary,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, Responsive responsive) {
    if (responsive.isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
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

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Responsive responsive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(responsive.value(mobile: 12, tablet: 14, desktop: 16)),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: responsive.isMobile
            ? Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                ],
              )
            : Column(
                children: [
                  Icon(
                    icon,
                    size: responsive.value(mobile: 24, tablet: 28, desktop: 32),
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _setTheme(AppThemeMode mode) {
    final store = StoreProvider.of<AppState>(context);
    store.dispatch(SetTheme(mode));
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'project_manager':
        return 'Project Manager';
      case 'po_officer':
        return 'PO Officer';
      case 'labour':
        return 'Labour';
      default:
        return role;
    }
  }

  void _showAddUserDialog() {
    final responsive = Responsive(context);
    
    if (responsive.isMobile) {
      // Use bottom sheet on mobile
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add New User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  MadInput(labelText: 'Name', hintText: 'Enter full name'),
                  const SizedBox(height: 16),
                  MadInput(labelText: 'Email', hintText: 'Enter email'),
                  const SizedBox(height: 16),
                  MadInput(labelText: 'Phone', hintText: 'Enter phone number'),
                  const SizedBox(height: 16),
                  MadInput(labelText: 'Password', hintText: 'Enter password', obscureText: true),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: MadButton(
                          text: 'Cancel',
                          variant: ButtonVariant.outline,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MadButton(
                          text: 'Add User',
                          onPressed: () {
                            Navigator.pop(context);
                            _loadUsers();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MadInput(labelText: 'Name', hintText: 'Enter full name'),
                const SizedBox(height: 16),
                MadInput(labelText: 'Email', hintText: 'Enter email'),
                const SizedBox(height: 16),
                MadInput(labelText: 'Phone', hintText: 'Enter phone number'),
                const SizedBox(height: 16),
                MadInput(labelText: 'Password', hintText: 'Enter password', obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadUsers();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }
  }
}
