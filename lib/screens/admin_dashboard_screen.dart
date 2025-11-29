import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_user.dart';
import '../services/admin_service.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../core/theme/app_colors.dart';
import '../widgets/gradient_header.dart';
import 'ai_lesson_generator_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _adminService = AdminService.instance;
  final _searchController = TextEditingController();

  List<AdminUser> _users = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  AccountType? _selectedAccountFilter;
  UserStatus? _selectedStatusFilter;
  final Set<String> _expandedUsers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _checkAdminAccess() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (!appProvider.isSuperadmin && !_adminService.isAdmin) {
      Navigator.of(context).pop();
      _showSnackBar('Admin access required');
      return;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers();
      final stats = await _adminService.getUserStats();

      if (mounted) {
        setState(() {
          _users = users;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading data: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          GradientHeader(
            title: 'Admin Dashboard',
            subtitle: 'User Management & Analytics',
            gradientColors: const [
              AppColors.analyticsStart,
              AppColors.analyticsMiddle,
              AppColors.analyticsEnd,
            ],
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                      child: _buildStatsCard('Total Users',
                          _stats['total_users']?.toString() ?? '0')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildStatsCard('Premium',
                          _stats['premium_users']?.toString() ?? '0')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildStatsCard('New (30d)',
                          _stats['new_users_30_days']?.toString() ?? '0')),
                ],
              ),
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryBlue,
              tabs: const [
                Tab(text: 'Users', icon: Icon(Icons.people)),
                Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
                Tab(text: 'Actions', icon: Icon(Icons.admin_panel_settings)),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildAnalyticsTab(),
                _buildActionsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.gray400,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            currentIndex:
                _tabController.index + 1, // Offset by 1 since Home is index 0
            onTap: (index) {
              if (index == 0) {
                // Navigate to Home (main app)
                Navigator.of(context).pop();
              } else {
                // Navigate to admin tabs
                setState(() {
                  _tabController.animateTo(index - 1);
                });
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outlined),
                activeIcon: Icon(Icons.people),
                label: 'Users',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_outlined),
                activeIcon: Icon(Icons.admin_panel_settings),
                label: 'Actions',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search and Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by email or name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterUsers();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                ),
                onChanged: (_) => _filterUsers(),
              ),
              const SizedBox(height: 12),

              // Filters
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AccountType?>(
                      initialValue: _selectedAccountFilter,
                      decoration: InputDecoration(
                        labelText: 'Account Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceVariant,
                      ),
                      items: [
                        const DropdownMenuItem<AccountType?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...AccountType.values.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name.toUpperCase()),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedAccountFilter = value);
                        _filterUsers();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<UserStatus?>(
                      initialValue: _selectedStatusFilter,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceVariant,
                      ),
                      items: [
                        const DropdownMenuItem<UserStatus?>(
                          value: null,
                          child: Text('All Status'),
                        ),
                        ...UserStatus.values.map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.name.toUpperCase()),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatusFilter = value);
                        _filterUsers();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // User List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) =>
                          _buildExpandableUserItem(_users[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildExpandableUserItem(AdminUser user) {
    final isExpanded = _expandedUsers.contains(user.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Main user info - always visible
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(user.status),
              child: Text(
                user.name?.substring(0, 1).toUpperCase() ??
                    user.email.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user.name ?? 'No Name',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildAccountTypeBadge(user.accountType),
                    _buildStatusBadge(user.status),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User actions dropdown
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) => _handleUserAction(user, action),
                  itemBuilder: (context) => [
                    // Account Type Actions
                    if (user.accountType != AccountType.premium)
                      const PopupMenuItem(
                        value: 'upgrade_premium',
                        child: Row(
                          children: [
                            Icon(
                              Icons.diamond,
                              color: Colors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('Upgrade to Premium'),
                          ],
                        ),
                      ),
                    if (user.accountType == AccountType.premium)
                      const PopupMenuItem(
                        value: 'downgrade_premium',
                        child: Row(
                          children: [
                            Icon(
                              Icons.diamond_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('Remove Premium'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'divider',
                      enabled: false,
                      child: Divider(),
                    ),
                    // Status Actions
                    if (user.status != UserStatus.active)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('Activate'),
                          ],
                        ),
                      ),
                    if (user.status != UserStatus.suspended)
                      const PopupMenuItem(
                        value: 'suspend',
                        child: Row(
                          children: [
                            Icon(
                              Icons.pause_circle,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('Suspend'),
                          ],
                        ),
                      ),
                  ],
                ),
                // Expand/collapse button
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedUsers.remove(user.id);
                      } else {
                        _expandedUsers.add(user.id);
                      }
                    });
                  },
                ),
              ],
            ),
            isThreeLine: true,
          ),

          // Expanded details - only visible when expanded
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('User ID', user.id),
                  _buildDetailRow(
                      'Email Verified', user.isEmailVerified ? 'Yes' : 'No'),
                  _buildDetailRow('Created', _formatDate(user.createdAt)),
                  if (user.lastSignIn != null)
                    _buildDetailRow(
                        'Last Updated', _formatDate(user.lastSignIn!)),
                  _buildDetailRow(
                      'Total Questions', user.totalQuestions.toString()),
                  _buildDetailRow(
                      'Daily Questions', user.dailyQuestions.toString()),
                  if (user.lastQuestionAt != null)
                    _buildDetailRow(
                        'Last Question', _formatDate(user.lastQuestionAt!)),
                  if (user.accountType == AccountType.premium &&
                      user.premiumExpiresAt != null)
                    _buildDetailRow(
                        'Premium Expires', _formatDate(user.premiumExpiresAt!)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.suspended:
        return Colors.orange;
      case UserStatus.deleted:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Icons.check_circle;
      case UserStatus.suspended:
        return Icons.pause_circle;
      case UserStatus.deleted:
        return Icons.cancel;
    }
  }

  Future<void> _handleUserAction(AdminUser user, String action) async {
    if (action == 'divider') return; // Ignore divider clicks

    try {
      bool success = false;
      String message = '';

      switch (action) {
        case 'upgrade_premium':
          success = await _adminService.upgradeToPremium(
            user.id,
            expiresAt: DateTime.now().add(const Duration(days: 365)), // 1 year
          );
          message = success
              ? 'User upgraded to Premium successfully'
              : 'Failed to upgrade user to Premium';
          break;

        case 'downgrade_premium':
          success = await _adminService.downgradeFromPremium(user.id);
          message = success
              ? 'User downgraded from Premium successfully'
              : 'Failed to downgrade user from Premium';
          break;

        case 'activate':
          if (user.status == UserStatus.suspended) {
            success = await _adminService.unsuspendUser(user.id);
            message = success
                ? 'User activated successfully'
                : 'Failed to activate user';
          }
          break;

        case 'suspend':
          if (user.status == UserStatus.active) {
            success =
                await _adminService.suspendUser(user.id, 'Suspended by admin');
            message = success
                ? 'User suspended successfully'
                : 'Failed to suspend user';
          }
          break;

        default:
          _showSnackBar('Unknown action: $action');
          return;
      }

      _showSnackBar(message);
      if (success) {
        _loadInitialData(); // Refresh the user list
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Widget _buildAccountTypeBadge(AccountType type) {
    Color color;
    IconData icon;

    switch (type) {
      case AccountType.guest:
        color = AppTheme.textSecondary;
        icon = Icons.person_outline;
        break;
      case AccountType.registered:
        color = AppColors.info;
        icon = Icons.person;
        break;
      case AccountType.premium:
        color = AppColors.warning;
        icon = Icons.diamond;
        break;
      case AccountType.superadmin:
        color = AppColors.error;
        icon = Icons.admin_panel_settings;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            type.name.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status),
              size: 14, color: _getStatusColor(status)),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsItem(
                    'Guest Users',
                    _stats['guest_users']?.toString() ?? '0',
                    AppTheme.textSecondary,
                    Icons.person_outline,
                  ),
                  _buildAnalyticsItem(
                    'Registered Users',
                    _stats['registered_users']?.toString() ?? '0',
                    AppColors.info,
                    Icons.person,
                  ),
                  _buildAnalyticsItem(
                    'Premium Users',
                    _stats['premium_users']?.toString() ?? '0',
                    AppColors.warning,
                    Icons.diamond,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Growth Metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Growth Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsItem(
                    'New Users (30 days)',
                    _stats['new_users_30_days']?.toString() ?? '0',
                    AppColors.success,
                    Icons.trending_up,
                  ),
                  _buildAnalyticsItem(
                    'Total Users',
                    _stats['total_users']?.toString() ?? '0',
                    AppTheme.primaryBlue,
                    Icons.people,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(
      String title, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
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
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.refresh, color: AppColors.info),
                    title: const Text('Refresh Data'),
                    subtitle: const Text('Reload user data and statistics'),
                    onTap: _loadInitialData,
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.download, color: AppColors.success),
                    title: const Text('Export Users'),
                    subtitle: const Text('Download user data as CSV'),
                    onTap: _exportUsers,
                  ),
                  ListTile(
                    leading: const Icon(Icons.notification_important,
                        color: AppColors.warning),
                    title: const Text('Send Notification'),
                    subtitle: const Text('Send notification to all users'),
                    onTap: _sendNotification,
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.auto_awesome, color: Colors.purple),
                    title: const Text('AI Lesson Generator'),
                    subtitle: const Text('Create lessons using AI'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AILessonGeneratorScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _filterUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers(
        searchQuery: _searchController.text,
        accountTypeFilter: _selectedAccountFilter,
        statusFilter: _selectedStatusFilter,
      );

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error filtering users: ${e.toString()}');
      }
    }
  }

  void _exportUsers() {
    _showSnackBar('Export functionality would be implemented here');
  }

  void _sendNotification() {
    _showSnackBar('Notification functionality would be implemented here');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
