import '../models/tree_model.dart';
import 'auth_service.dart';

enum Permission {
  // Tree permissions
  createTree,
  editOwnTree,
  editAnyTree,
  deleteOwnTree,
  deleteAnyTree,
  viewTree,
  
  // Update permissions
  createUpdate,
  editOwnUpdate,
  editAnyUpdate,
  deleteOwnUpdate,
  deleteAnyUpdate,
  
  // Data permissions
  exportData,
  viewReports,
  viewAnalytics,
  
  // User management
  manageUsers,
  viewUsers,
  assignTrees,
  
  // System permissions
  manageSettings,
  viewLogs,
  sendNotifications,
}

class PermissionsService {
  // Role-based permissions matrix
  static final Map<String, Set<Permission>> _rolePermissions = {
    'admin': {
      // Admins can do everything
      ...Permission.values,
    },
    'manager': {
      // Managers can manage trees and users but not system settings
      Permission.createTree,
      Permission.editAnyTree,
      Permission.deleteAnyTree,
      Permission.viewTree,
      Permission.createUpdate,
      Permission.editAnyUpdate,
      Permission.deleteAnyUpdate,
      Permission.exportData,
      Permission.viewReports,
      Permission.viewAnalytics,
      Permission.viewUsers,
      Permission.assignTrees,
      Permission.sendNotifications,
    },
    'worker': {
      // Workers can only manage their own trees
      Permission.createTree,
      Permission.editOwnTree,
      Permission.deleteOwnTree,
      Permission.viewTree,
      Permission.createUpdate,
      Permission.editOwnUpdate,
      Permission.deleteOwnUpdate,
      Permission.viewReports,
      Permission.viewAnalytics,
    },
    'viewer': {
      // Viewers can only view
      Permission.viewTree,
      Permission.viewReports,
      Permission.viewAnalytics,
    },
  };

  // Check if current user has a specific permission
  static Future<bool> hasPermission(Permission permission) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;
    
    final rolePermissions = _rolePermissions[user.role] ?? {};
    return rolePermissions.contains(permission);
  }

  // Check if user can edit a specific tree
  static Future<bool> canEditTree(TreeRecord tree) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;
    
    // Admins and managers can edit any tree
    if (await hasPermission(Permission.editAnyTree)) return true;
    
    // Workers can only edit their own trees
    if (await hasPermission(Permission.editOwnTree)) {
      return tree.userId == user.id;
    }
    
    return false;
  }

  // Check if user can delete a specific tree
  static Future<bool> canDeleteTree(TreeRecord tree) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;
    
    // Admins and managers can delete any tree
    if (await hasPermission(Permission.deleteAnyTree)) return true;
    
    // Workers can only delete their own trees
    if (await hasPermission(Permission.deleteOwnTree)) {
      return tree.userId == user.id;
    }
    
    return false;
  }

  // Check if user can edit a specific update
  static Future<bool> canEditUpdate(TreeUpdate update) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;
    
    // Admins and managers can edit any update
    if (await hasPermission(Permission.editAnyUpdate)) return true;
    
    // Workers can only edit their own updates
    if (await hasPermission(Permission.editOwnUpdate)) {
      return update.userId == user.id;
    }
    
    return false;
  }

  // Get user's role display name
  static String getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'manager':
        return 'Manager';
      case 'worker':
        return 'Field Worker';
      case 'viewer':
        return 'Viewer';
      default:
        return role;
    }
  }

  // Get role color
  static String getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return '#F87171'; // Red
      case 'manager':
        return '#FBBF24'; // Yellow
      case 'worker':
        return '#34D399'; // Green
      case 'viewer':
        return '#60A5FA'; // Blue
      default:
        return '#9CA3AF'; // Gray
    }
  }

  // Check if user has any of the given permissions
  static Future<bool> hasAnyPermission(List<Permission> permissions) async {
    for (var permission in permissions) {
      if (await hasPermission(permission)) return true;
    }
    return false;
  }

  // Check if user has all of the given permissions
  static Future<bool> hasAllPermissions(List<Permission> permissions) async {
    for (var permission in permissions) {
      if (!await hasPermission(permission)) return false;
    }
    return true;
  }

  // Get all permissions for current user's role
  static Future<Set<Permission>> getUserPermissions() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return {};
    
    return _rolePermissions[user.role] ?? {};
  }
}
