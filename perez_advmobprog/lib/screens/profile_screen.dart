import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    // get persisted user data from SharedPreferences via userservice
  
    _userFuture = _userService.getUser();
  }

  //logout function also removes persisted data via userservice
  void _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
  
    return FutureBuilder<User>(
      future: _userFuture,
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

        final user = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Text(
                      'Account Details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF8A94A6),
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    
                    _buildInfoCard(
                      icon: Icons.person_outline_rounded,
                      label: 'Username',
                      value: '@${user.username}',
                      isDark: isDark,
                    ),
                    SizedBox(height: 10.h),
                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                      isDark: isDark,
                    ),
                    SizedBox(height: 10.h),
                    _buildInfoCard(
                      icon: Icons.wc_rounded,
                      label: 'Gender',
                      value: user.gender.isNotEmpty
                          ? user.gender[0].toUpperCase() +
                              user.gender.substring(1)
                          : '—',
                      isDark: isDark,
                    ),
                    SizedBox(height: 10.h),
                    _buildInfoCard(
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      value: '#${user.id}',
                      isDark: isDark,
                    ),
                    SizedBox(height: 32.h),
                   
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


  Widget _buildHeader(User user) {
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
                  user.image.isNotEmpty ? NetworkImage(user.image) : null,
              child: user.image.isEmpty
                  ? Icon(Icons.person_rounded,
                      size: 50.sp, color: Colors.white70)
                  : null,
            ),
          ),
          SizedBox(height: 14.h),
         
          Text(
            user.fullName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
         
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withOpacity(0.22),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFF4A6CF7).withOpacity(0.50),
                width: 1,
              ),
            ),
            child: Text(
              '@${user.username}',
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


  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
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
                    color: isDark ? Colors.white : const Color(0xFF1B2A4A),
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
}
