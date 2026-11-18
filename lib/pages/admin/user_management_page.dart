import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/sqlite_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:uuid/uuid.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<AppUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await SqliteService().listUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _showAddEditUserDialog([AppUser? user]) {
    final isEditing = user != null;
    final fullNameCtl = TextEditingController(text: user?.fullName);
    final usernameCtl = TextEditingController(text: user?.username);
    final passwordCtl = TextEditingController(text: user?.password);
    String selectedRole = user?.role ?? 'user';
    List<String> userPermissions = List.from(user?.permissions ?? []);

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      width: 500,
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isEditing ? 'تعديل مستخدم' : 'إضافة مستخدم جديد',
                              style: GoogleFonts.cairo(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // User Info Section
                            _buildSectionTitle('المعلومات الأساسية'),
                            const SizedBox(height: 16),
                            _buildStyledTextField(
                              controller: fullNameCtl,
                              label: 'الاسم الكامل',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),
                            _buildUsernameField(usernameCtl, isEditing),
                            const SizedBox(height: 20),

                            _buildStyledTextField(
                              controller: passwordCtl,
                              label: 'كلمة المرور',
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            const SizedBox(height: 24),

                            // Roles Section
                            _buildSectionTitle('الدور والصلاحيات'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedRole,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'admin',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.admin_panel_settings_outlined,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('مدير نظام'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'user',
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_outline, size: 20),
                                          SizedBox(width: 8),
                                          Text('مستخدم عادي'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null)
                                      setDialogState(() => selectedRole = val);
                                  },
                                ),
                              ),
                            ),

                            if (selectedRole == 'user') ...[
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  children:
                                      UserPermission.getAll().map((perm) {
                                        final label =
                                            UserPermission.getLabelsAr()[perm] ??
                                            perm;
                                        final isSelected = userPermissions
                                            .contains(perm);
                                        return CheckboxListTile(
                                          title: Text(
                                            label,
                                            style: GoogleFonts.cairo(
                                              fontSize: 14,
                                            ),
                                          ),
                                          value: isSelected,
                                          activeColor: Colors.blue.shade700,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          onChanged: (val) {
                                            setDialogState(() {
                                              if (val == true) {
                                                userPermissions.add(perm);
                                              } else {
                                                userPermissions.remove(perm);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],

                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey.shade600,
                                  ),
                                  child: Text(
                                    'إلغاء',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (usernameCtl.text.isEmpty ||
                                        passwordCtl.text.isEmpty)
                                      return;

                                    if (!isEditing) {
                                      final existing = await SqliteService()
                                          .getUserByUsername(
                                            usernameCtl.text.trim(),
                                          );
                                      if (existing != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'اسم المستخدم موجود بالفعل، يرجى اختيار اسم آخر',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    final currentUser =
                                        Provider.of<AuthService>(
                                          context,
                                          listen: false,
                                        ).currentUser;
                                    final executorName =
                                        currentUser?.fullName ??
                                        currentUser?.username ??
                                        'System';

                                    final newUser = AppUser(
                                      id: user?.id ?? const Uuid().v4(),
                                      username: usernameCtl.text.trim(),
                                      fullName: fullNameCtl.text.trim(),
                                      password: passwordCtl.text.trim(),
                                      role: selectedRole,
                                      permissions:
                                          selectedRole == 'admin'
                                              ? []
                                              : userPermissions,
                                      createdAt:
                                          user?.createdAt ?? DateTime.now(),
                                      isActive: user?.isActive ?? true,
                                      createdBy:
                                          !isEditing
                                              ? executorName
                                              : user?.createdBy,
                                      updatedBy: executorName,
                                    );

                                    if (isEditing) {
                                      // Keep existing isActive status if editing, unless changed (will implement toggle in list usually)
                                      // But let's allow updating it here if we want to add a checkbox later.
                                      // For now, we use the user's existing isActive or true.

                                      // Re-create user with updated fields but keep ID and CreatedAt
                                      // Note: We are creating a new instance
                                      final updatedUser = user.copyWith(
                                        username: usernameCtl.text.trim(),
                                        fullName: fullNameCtl.text.trim(),
                                        password: passwordCtl.text.trim(),
                                        role: selectedRole,
                                        permissions:
                                            selectedRole == 'admin'
                                                ? []
                                                : userPermissions,
                                        updatedBy: executorName,
                                      );
                                      await SqliteService().updateUser(
                                        updatedUser,
                                      );
                                    } else {
                                      await SqliteService().insertUser(newUser);
                                    }

                                    _loadUsers();
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade900,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'حفظ',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildUsernameField(
    TextEditingController controller,
    bool isReadOnly,
  ) {
    return _buildStyledTextField(
      controller: controller,
      label: 'اسم المستخدم',
      icon: Icons.alternate_email,
      enabled: !isReadOnly,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 24, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText:
          isPassword, // Note: Password toggle logic is not fully implemented in this quick refactor for simplicity, could be added
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    if (user.id == 'admin_1') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف المستخدم ${user.fullName}؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await SqliteService().deleteUser(user.id);
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المستخدمين والصلاحيات', style: GoogleFonts.cairo()),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditUserDialog(),
        label: const Text('إضافة مستخدم'),
        icon: const Icon(Icons.person_add),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
              ? const Center(child: Text('لا يوجد مستخدمين بعد'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final currentUser =
                        Provider.of<AuthService>(
                          context,
                          listen: false,
                        ).currentUser;
                    final isMe = currentUser?.id == user.id;

                    return FadeInUp(
                      delay: Duration(milliseconds: index * 100),
                      child: Card(
                        elevation: isMe ? 4 : 2,
                        color: isMe ? Colors.blue.shade50 : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side:
                              isMe
                                  ? BorderSide(
                                    color: Colors.blue.shade300,
                                    width: 2,
                                  )
                                  : BorderSide.none,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () => _showAddEditUserDialog(user),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    user.role == 'admin'
                                        ? Colors.blue.shade900
                                        : Colors.blue.shade100,
                                child: Icon(
                                  user.role == 'admin'
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                  color:
                                      user.role == 'admin'
                                          ? Colors.white
                                          : Colors.blue.shade900,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color:
                                        user.isActive
                                            ? Colors.green
                                            : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'أنت',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@${user.username} - ${user.role == 'admin' ? 'مدير نظام' : 'مستخدم'}',
                              ),
                              // Show "داخل البرنامج" only for the currently logged-in user
                              if (isMe)
                                Text(
                                  'داخل البرنامج (متصل الآن)',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                Text(
                                  user.isActive ? 'حساب فعال' : 'حساب معطل',
                                  style: TextStyle(
                                    color:
                                        user.isActive
                                            ? Colors.blue.shade600
                                            : Colors.red.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (currentUser?.role == 'admin') ...[
                                const SizedBox(height: 4),
                                if (user.createdBy != null)
                                  Text(
                                    'أضيف بواسطة: ${user.createdBy}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                if (user.updatedBy != null)
                                  Text(
                                    'عُدل بواسطة: ${user.updatedBy}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Active/Inactive Toggle
                              if (user.id != 'admin_1' && !isMe)
                                Switch(
                                  value: user.isActive,
                                  activeColor: Colors.green,
                                  onChanged: (val) async {
                                    final updated = user.copyWith(
                                      isActive: val,
                                    );
                                    await SqliteService().updateUser(updated);
                                    _loadUsers();
                                  },
                                ),

                              const SizedBox(width: 8),

                              if (user.id != 'admin_1')
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showAddEditUserDialog(user),
                                  tooltip: 'تعديل',
                                ),
                              const SizedBox(width: 16),

                              if (user.id != 'admin_1' && !isMe)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteUser(user),
                                  tooltip: 'حذف',
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
