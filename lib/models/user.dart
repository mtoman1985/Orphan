import 'dart:convert';

class UserPermission {
  static const String viewOrphans = 'view_orphans';
  static const String editOrphans = 'edit_orphans';
  static const String deleteOrphans = 'delete_orphans';
  static const String printOrphans = 'print_orphans';
  static const String viewSponsors = 'view_sponsors';
  static const String editSponsors = 'edit_sponsors';
  static const String deleteSponsors = 'delete_sponsors';
  static const String viewPayments = 'view_payments';
  static const String addPayments = 'add_payments';
  static const String manageUsers = 'manage_users';
  static const String viewReports = 'view_reports';

  static List<String> getAll() => [
    viewOrphans,
    editOrphans,
    deleteOrphans,
    printOrphans,
    viewSponsors,
    editSponsors,
    deleteSponsors,
    viewPayments,
    addPayments,
    manageUsers,
    viewReports,
  ];

  static Map<String, String> getLabelsAr() => {
    viewOrphans: 'عرض الأيتام',
    editOrphans: 'تعديل الأيتام',
    deleteOrphans: 'حذف الأيتام',
    printOrphans: 'طباعة بيانات الأيتام',
    viewSponsors: 'عرض الكفلاء',
    editSponsors: 'تعديل الكفلاء',
    deleteSponsors: 'حذف الكفلاء',
    viewPayments: 'عرض المدفوعات',
    addPayments: 'إضافة مدفوعات',
    manageUsers: 'إدارة المستخدمين',
    viewReports: 'عرض التقارير',
  };
}

class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String password; // In a real app, this would be a hash
  final String role; // 'admin' or 'user'
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isSynced;
  final String? createdBy;
  final String? updatedBy;

  AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.password,
    this.role = 'user',
    this.permissions = const [],
    required this.createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    this.isSynced = false,
    this.createdBy,
    this.updatedBy,
  }) : updatedAt = updatedAt ?? createdAt;

  bool hasPermission(String permission) {
    if (role == 'admin') return true;
    return permissions.contains(permission);
  }

  bool get canEditOrphans => hasPermission(UserPermission.editOrphans);
  bool get canDeleteOrphans => hasPermission(UserPermission.deleteOrphans);
  bool get canPrintOrphans => hasPermission(UserPermission.printOrphans);
  bool get canEditSponsors => hasPermission(UserPermission.editSponsors);
  bool get canDeleteSponsors => hasPermission(UserPermission.deleteSponsors);
  bool get canAddPayments => hasPermission(UserPermission.addPayments);
  bool get canManageUsers => hasPermission(UserPermission.manageUsers);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'password': password,
      'role': role,
      'permissions': jsonEncode(permissions),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    List<String> perms = [];
    if (json['permissions'] != null) {
      try {
        if (json['permissions'] is String) {
          perms = List<String>.from(jsonDecode(json['permissions']));
        } else if (json['permissions'] is List) {
          perms = List<String>.from(json['permissions']);
        }
      } catch (e) {
        print('Error decoding permissions: $e');
      }
    }

    final createdAt =
        json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now();

    return AppUser(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'user',
      permissions: perms,
      createdAt: createdAt,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : (json['updatedAt'] != null
                  ? DateTime.parse(json['updatedAt'])
                  : createdAt),
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
      isSynced: (json['is_synced'] == 1 || json['is_synced'] == true),
      createdBy: json['created_by']?.toString(),
      updatedBy: json['updated_by']?.toString(),
    );
  }

  AppUser copyWith({
    String? username,
    String? fullName,
    String? password,
    String? role,
    List<String>? permissions,
    bool? isActive,
    bool? isSynced,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return AppUser(
      id: this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
