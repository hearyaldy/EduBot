import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_user.dart';
import '../services/admin_service.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../core/theme/app_colors.dart';
import '../widgets/gradient_header.dart';

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
    if (!appProvider.isSuperadmin) {
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
      backgroundColor: AppColors.gray50,
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
                  Expanded(child: _buildStatsCard('Total Users', _stats['total_users']?.toString() ?? '0')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatsCard('Premium', _stats['premium_users']?.toString() ?? '0')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatsCard('New (30d)', _stats['new_users_30_days']?.toString() ?? '0')),
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
                      value: _selectedAccountFilter,
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
                      value: _selectedStatusFilter,
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
                      itemBuilder: (context, index) => _buildUserCard(_users[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(AdminUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getAccountTypeColor(user.accountType),
                  child: Text(
                    user.name?.substring(0, 1).toUpperCase() ?? 
                    user.email.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? 'No name',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAccountTypeBadge(user.accountType),
              ],
            ),
            const SizedBox(height: 12),
            
            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Questions', '${user.dailyQuestions}/${user.dailyQuestionLimit == -1 ? '∞' : user.dailyQuestionLimit}'),
                ),
                Expanded(
                  child: _buildDetailItem('Total', '${user.totalQuestions}'),
                ),
                Expanded(
                  child: _buildDetailItem('Status', user.statusDisplay),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Joined', _formatDate(user.createdAt)),
                ),
                Expanded(
                  child: _buildDetailItem('Last Active', user.lastSignIn != null ? _formatDate(user.lastSignIn!) : 'Never'),
                ),
                if (user.accountType == AccountType.premium)
                  Expanded(
                    child: _buildDetailItem('Premium', user.premiumStatus),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                if (user.accountType != AccountType.premium && user.accountType != AccountType.superadmin)
                  ElevatedButton.icon(
                    onPressed: () => _upgradeToPremium(user),
                    icon: const Icon(Icons.upgrade, size: 16),
                    label: const Text('Upgrade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (user.accountType == AccountType.premium)
                  ElevatedButton.icon(
                    onPressed: () => _downgradeFromPremium(user),
                    icon: const Icon(Icons.trending_down, size: 16),
                    label: const Text('Downgrade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                if (user.status == UserStatus.active)
                  TextButton.icon(
                    onPressed: () => _suspendUser(user),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Suspend'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                if (user.status == UserStatus.suspended)
                  TextButton.icon(
                    onPressed: () => _unsuspendUser(user),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Unsuspend'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showUserDetailsDialog(user),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.guest:
        return AppTheme.textSecondary;
      case AccountType.registered:
        return AppColors.info;
      case AccountType.premium:
        return AppColors.warning;
      case AccountType.superadmin:
        return AppColors.error;
    }
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

  Widget _buildAnalyticsItem(String title, String value, Color color, IconData icon) {
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
                    leading: const Icon(Icons.download, color: AppColors.success),
                    title: const Text('Export Users'),
                    subtitle: const Text('Download user data as CSV'),
                    onTap: _exportUsers,
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.notification_important, color: AppColors.warning),
                    title: const Text('Send Notification'),
                    subtitle: const Text('Send notification to all users'),
                    onTap: _sendNotification,
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

  Future<void> _upgradeToPremium(AdminUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: Text('Upgrade ${user.email} to Premium account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final success = await _adminService.upgradeToPremium(
          user.id,
          isLifetime: true,
        );
        
        if (success) {
          _showSnackBar('User upgraded to Premium successfully');
          _loadInitialData();
        } else {
          _showSnackBar('Failed to upgrade user');
        }
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _downgradeFromPremium(AdminUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Downgrade from Premium'),
        content: Text('Downgrade ${user.email} from Premium account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Downgrade'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final success = await _adminService.downgradeFromPremium(user.id);
        
        if (success) {
          _showSnackBar('User downgraded from Premium successfully');
          _loadInitialData();
        } else {
          _showSnackBar('Failed to downgrade user');
        }
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _suspendUser(AdminUser user) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Suspend ${user.email}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final success = await _adminService.suspendUser(
          user.id,
          reasonController.text.trim().isEmpty ? 'No reason provided' : reasonController.text.trim(),
        );
        
        if (success) {
          _showSnackBar('User suspended successfully');
          _loadInitialData();
        } else {
          _showSnackBar('Failed to suspend user');
        }
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _unsuspendUser(AdminUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsuspend User'),
        content: Text('Unsuspend ${user.email} and restore their access?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unsuspend'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final success = await _adminService.unsuspendUser(user.id);
        
        if (success) {
          _showSnackBar('User unsuspended successfully');
          _loadInitialData();
        } else {
          _showSnackBar('Failed to unsuspend user');
        }
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}');
      }
    }
  }

  void _showUserDetailsDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details - ${user.name ?? 'No name'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogDetailItem('ID', user.id),
              _buildDialogDetailItem('Email', user.email),
              _buildDialogDetailItem('Name', user.name ?? 'Not provided'),
              _buildDialogDetailItem('Account Type', user.accountTypeDisplay),
              _buildDialogDetailItem('Status', user.statusDisplay),
              _buildDialogDetailItem('Email Verified', user.isEmailVerified ? 'Yes' : 'No'),
              _buildDialogDetailItem('Created', _formatDate(user.createdAt)),
              _buildDialogDetailItem('Last Sign In', user.lastSignIn != null ? _formatDate(user.lastSignIn!) : 'Never'),
              _buildDialogDetailItem('Total Questions', user.totalQuestions.toString()),
              _buildDialogDetailItem('Daily Questions', user.dailyQuestions.toString()),
              if (user.lastQuestionAt != null)
                _buildDialogDetailItem('Last Question', _formatDate(user.lastQuestionAt!)),
              if (user.accountType == AccountType.premium)
                _buildDialogDetailItem('Premium Status', user.premiumStatus),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
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