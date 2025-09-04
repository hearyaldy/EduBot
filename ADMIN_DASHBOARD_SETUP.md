# Admin Dashboard Setup Guide

This guide explains how to set up and use the EduBot Admin Dashboard for user management and premium upgrades.

## 🔧 Database Setup

### 1. Create Supabase Tables

Run the SQL script in `database_schema.sql` on your Supabase database:

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `database_schema.sql`
4. Execute the script

This will create:
- `profiles` table for user management
- Automatic triggers to sync with `auth.users`
- Row Level Security (RLS) policies
- Necessary indexes for performance

### 2. Configure Environment Variables

Update your `.env` file with your Supabase credentials:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

**Important Security Notes:**
- **SUPABASE_ANON_KEY**: Public key for client-side operations (safe to expose)
- **SUPABASE_SERVICE_ROLE_KEY**: Secret key with full database access (NEVER expose publicly)
- The service role key is used for admin operations like user management and premium upgrades
- Keep the service role key secure and never commit it to version control

**Where to Find These Keys:**
1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **API**
3. **Project URL**: Copy the "Project URL"
4. **anon public**: Copy the "anon" key (this is your SUPABASE_ANON_KEY)
5. **service_role secret**: Copy the "service_role" key (this is your SUPABASE_SERVICE_ROLE_KEY)

⚠️ **Warning**: Never share or expose the service_role key publicly as it bypasses all RLS policies!

## 👤 Admin Access Setup

### 1. Create Superadmin User

1. Register a user through the app's normal registration flow
2. In your Supabase Auth dashboard, find the user
3. Edit the user's metadata to include:
   ```json
   {
     "is_superadmin": true
   }
   ```
4. The user will now have admin access

### 2. Alternative: Enable Superadmin in Settings

1. Open the app
2. Go to **Settings**
3. Enable **Superadmin Mode**
4. Enter the superadmin password (configured in `.env`)

## 📱 Using the Admin Dashboard

### Access the Dashboard

1. Login as a superadmin user
2. Navigate to **Settings**
3. Tap **Admin Dashboard** (only visible to superadmins)

### Dashboard Features

#### **Users Tab**
- **Search**: Find users by email or name
- **Filter**: Filter by account type (Guest/Registered/Premium) or status
- **User Cards**: View detailed user information
- **Actions**: Upgrade to premium, suspend/unsuspend users

#### **Analytics Tab**
- **User Distribution**: See breakdown by account type
- **Growth Metrics**: Track new user registrations
- **Statistics**: Total users, premium users, etc.

#### **Actions Tab**
- **Refresh Data**: Reload all user data
- **Export Users**: Download user data (placeholder)
- **Send Notification**: Broadcast to all users (placeholder)

## ⭐ Premium Management

### Upgrade User to Premium

1. In the **Users** tab, find the target user
2. Click **Upgrade** button on their user card
3. Confirm the upgrade
4. User immediately gains premium benefits:
   - Unlimited daily questions
   - Premium badge in their account
   - Enhanced features access

### Downgrade from Premium

1. Find premium users (they have a diamond badge)
2. Click **Downgrade** button
3. Confirm the action
4. User returns to registered status (60 questions/day)

### Bulk Operations

Currently implemented per-user operations. For bulk operations, you would need to:
1. Select multiple users
2. Apply actions to the selection
3. Confirm batch operation

## 🛡️ Security Features

### Permission System
- Only superadmin users can access the dashboard
- Row Level Security (RLS) enforced at database level
- All admin actions are logged

### Data Protection
- User passwords are never displayed
- Sensitive data is protected by Supabase security
- Admin actions require confirmation dialogs

## 🔄 User Status Management

### User Statuses
- **Active**: Normal user, can use the app
- **Suspended**: Cannot access app features
- **Deleted**: Soft delete, data preserved

### Suspension Process
1. Click **Suspend** on active user
2. Enter suspension reason (optional)
3. User loses access immediately
4. Can be unsuspended at any time

## 📊 User Types & Limits

| Account Type | Daily Questions | Features |
|-------------|----------------|----------|
| Guest | 30 | Basic features |
| Registered | 60 | Account sync, history |
| Premium | Unlimited | All features, priority support |
| Superadmin | Unlimited | Admin dashboard access |

## 🚀 Production Deployment

### 1. Database Security
- Ensure RLS policies are properly configured
- Test admin access in staging environment
- Verify user data privacy

### 2. Performance Optimization
- Monitor query performance with large user bases
- Consider adding database indexes if needed
- Implement pagination for large datasets

### 3. Monitoring
- Track admin actions
- Monitor user upgrade/downgrade patterns
- Set up alerts for suspicious activity

## 🐛 Troubleshooting

### Common Issues

**Admin Dashboard Not Visible**
- Verify user has `is_superadmin: true` in metadata
- Check if superadmin mode is enabled in settings
- Ensure database connection is working

**Cannot Upgrade Users**
- Check Supabase permissions
- Verify profiles table exists
- Review database logs for errors

**Search Not Working**
- Ensure profiles table has proper indexes
- Check search query syntax
- Verify user data exists in profiles table

### Debug Mode
Enable debug mode in environment config to see detailed logs:
```env
DEBUG_MODE=true
```

## 🔮 Future Enhancements

Planned features for the admin dashboard:

1. **Advanced Analytics**
   - User engagement metrics
   - Revenue tracking
   - Usage patterns

2. **Bulk Operations**
   - Mass user management
   - Batch premium upgrades
   - Group notifications

3. **Advanced Filters**
   - Date range filtering
   - Usage-based filtering
   - Geographic filtering

4. **Export Features**
   - CSV export
   - PDF reports
   - Data visualization

5. **Notification System**
   - Push notifications
   - Email campaigns
   - In-app announcements

## 🎯 Best Practices

1. **Regular Monitoring**: Check admin dashboard daily for user issues
2. **Premium Management**: Monitor premium subscriptions and renewals
3. **User Support**: Use suspension feature responsibly
4. **Data Backup**: Regularly backup user data
5. **Security Audits**: Review admin access logs regularly

## 📞 Support

For technical support with the admin dashboard:
1. Check the troubleshooting section above
2. Review Supabase dashboard for errors
3. Check application logs for detailed error messages
4. Ensure all environment variables are properly configured

---

**Note**: This admin dashboard is designed for internal use by authorized administrators only. Never share admin credentials or access with unauthorized users.