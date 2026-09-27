import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  
  Future<Map<String, dynamic>> _loadProfile() async {
    final loginType = await _userService.getLoginType();

    if (loginType == LoginType.firebase) {
      //firebase: read from FirebaseAuth.currentUser + SharedPrefs for extra fields
      final fbUser = _userService.currentFirebaseUser;
      final prefs = await SharedPreferences.getInstance();
      return {
        'loginType': 'firebase',
        'firstName': fbUser?.displayName ?? fbUser?.email?.split('@').first ?? 'User',
        'lastName': '',
        'username': fbUser?.displayName ?? fbUser?.email?.split('@').first ?? '',
        'email': fbUser?.email ?? '',
        'image': fbUser?.photoURL ?? '',
        'gender': '',
        'id': 0,
        'phone': prefs.getString('phone') ?? '',
        'age': prefs.getInt('age') ?? 0,
      };
    } else {
      //dummyJSON: read from SharedPreferences
      final data = await _userService.getUserData();
      data['loginType'] = 'dummyJson';
      return data;
    }
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  //logout clears SharedPrefs AND signs out of Firebase.
  void _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/signin');
  }


  // Update Username dialog
  void _showUpdateUsernameDialog(String currentUsername, String loginType) {
    final controller = TextEditingController(text: currentUsername);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Update Username',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: 'New username',
            hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Poppins'),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF4A6CF7), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white54,
                    fontSize: 13.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6CF7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              try {
                if (loginType == 'firebase') {
                  await _userService.updateUsernameForFirebase(newName);
                } else {
                  await _userService.updateUsernameForDummyJson(newName);
                }
                _refreshProfile();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Username updated!'),
                    backgroundColor: Color(0xFF4A6CF7),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Save',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  //change password dialog
  void _showChangePasswordDialog(String email, String loginType) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Change Password',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loginType != 'firebase')
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  'Note: DummyJSON is a mock API — password changes are simulated only.',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.sp,
                      color: Colors.amber.withOpacity(0.8)),
                ),
              ),
            _dialogTextField(
              controller: currentPassCtrl,
              hint: 'Current password',
              obscure: true,
              onToggle: null,
            ),
            SizedBox(height: 12.h),
            _dialogTextField(
              controller: newPassCtrl,
              hint: 'New password (min 8 chars)',
              obscure: true,
              onToggle: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white54,
                    fontSize: 13.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6CF7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () async {
              final current = currentPassCtrl.text;
              final newPass = newPassCtrl.text;
              if (current.isEmpty || newPass.isEmpty) return;
              if (newPass.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('New password must be at least 8 characters.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await _userService.resetPasswordFromCurrentPassword(
                  email: email,
                  currentPassword: current,
                  newPassword: newPass,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Color(0xFF4A6CF7),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Update',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }


  void _showDeleteAccountDialog(String email, String loginType) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Delete Account',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.redAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This action cannot be undone. Enter your password to confirm.',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.sp,
                  color: Colors.white70),
            ),
            SizedBox(height: 16.h),
            _dialogTextField(
              controller: passCtrl,
              hint: 'Your password',
              obscure: true,
              onToggle: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white54,
                    fontSize: 13.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () async {
              final pass = passCtrl.text;
              if (pass.isEmpty) return;
              Navigator.pop(ctx);
              try {
                if (loginType == 'firebase') {
                  await _userService.deleteAccountForFirebase(
                      email: email, password: pass);
                } else {
                  await _userService.deleteAccountForDummyJson();
                }
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/signin');
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Delete',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading profile: ${snapshot.error}',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
            ),
          );
        }

        final profile = snapshot.data!;
        final loginType = profile['loginType'] as String;
        final isFirebase = loginType == 'firebase';

        final String fullName =
            '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
        final String username = profile['username'] ?? '';
        final String email = profile['email'] ?? '';
        final String image = profile['image'] ?? '';
        final String gender = profile['gender'] ?? '';
        final int id = profile['id'] ?? 0;
        final String phone = profile['phone'] ?? '';
        final int age = profile['age'] ?? 0;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(
                fullName: fullName.isNotEmpty ? fullName : username,
                username: username,
                imageUrl: image,
                isFirebase: isFirebase,
              ),
              SizedBox(height: 24.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Login Method'),
                    SizedBox(height: 10.h),
                    _buildInfoCard(
                      icon: isFirebase
                          ? Icons.local_fire_department_outlined
                          : Icons.cloud_outlined,
                      label: 'Backend',
                      value: isFirebase ? 'Firebase Auth' : 'DummyJSON',
                      isDark: isDark,
                      valueColor: isFirebase
                          ? const Color(0xFFFF6B35)
                          : const Color(0xFF4A6CF7),
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionLabel('Account Details'),
                    SizedBox(height: 10.h),
                    _buildInfoCard(
                      icon: Icons.person_outline_rounded,
                      label: 'Username',
                      value: '@$username',
                      isDark: isDark,
                    ),
                    SizedBox(height: 10.h),
                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email.isNotEmpty ? email : '—',
                      isDark: isDark,
                    ),

                    SizedBox(height: 10.h),
                    _buildInfoCard(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: age > 0 ? age.toString() : '—',
                      isDark: isDark,
                    ),
                    SizedBox(height: 10.h),
                    _buildInfoCard(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: phone.isNotEmpty ? phone : '—',
                      isDark: isDark,
                    ),
                    if (!isFirebase) SizedBox(height: 10.h),
                    if (!isFirebase) _buildInfoCard(
                      icon: Icons.wc_rounded,
                      label: 'Gender',
                      value: gender.isNotEmpty
                          ? gender[0].toUpperCase() + gender.substring(1)
                          : '—',
                      isDark: isDark,
                    ),
                    if (!isFirebase) SizedBox(height: 10.h),
                    if (!isFirebase) _buildInfoCard(
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      value: id > 0 ? '#$id' : '—',
                      isDark: isDark,
                    ),

                    SizedBox(height: 28.h),

                    _buildSectionLabel('Account Actions'),
                    SizedBox(height: 10.h),

                    // Update Username
                    _buildActionButton(
                      icon: Icons.drive_file_rename_outline_rounded,
                      label: 'Update Username',
                      color: const Color(0xFF4A6CF7),
                      onTap: () =>
                          _showUpdateUsernameDialog(username, loginType),
                    ),
                    SizedBox(height: 10.h),

                    // Change Password
                    _buildActionButton(
                      icon: Icons.lock_reset_rounded,
                      label: 'Change Password',
                      color: const Color(0xFF6C63FF),
                      onTap: () =>
                          _showChangePasswordDialog(email, loginType),
                    ),
                    SizedBox(height: 10.h),

                    // Delete Account
                    _buildActionButton(
                      icon: Icons.delete_forever_rounded,
                      label: 'Delete Account',
                      color: Colors.redAccent,
                      onTap: () =>
                          _showDeleteAccountDialog(email, loginType),
                    ),

                    SizedBox(height: 20.h),

                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: Icon(
                          Icons.logout_rounded,
                          size: 20.sp,
                          color: Colors.redAccent,
                        ),
                        label: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildHeader({
    required String fullName,
    required String username,
    required String imageUrl,
    required bool isFirebase,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 28.h, bottom: 28.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2A4A), Color(0xFF2D3561)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4A6CF7), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A6CF7).withOpacity(0.45),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50.r,
              backgroundColor: Colors.white12,
              backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? Icon(Icons.person_rounded,
                      size: 50.sp, color: Colors.white70)
                  : null,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            fullName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withOpacity(0.22),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFF4A6CF7).withOpacity(0.50),
                width: 1,
              ),
            ),
            child: Text(
              '@$username',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.sp,
                color: const Color(0xFF9AB0FF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF8A94A6),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.09)
              : Colors.grey.withOpacity(0.15),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: const Color(0xFF4A6CF7), size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.sp,
                    color: isDark ? Colors.white54 : const Color(0xFF8A94A6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: valueColor ??
                        (isDark ? Colors.white : const Color(0xFF1B2A4A)),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Poppins'),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        suffixIcon: onToggle != null
            ? IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white54,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF4A6CF7), width: 1.5),
        ),
      ),
    );
  }
}
