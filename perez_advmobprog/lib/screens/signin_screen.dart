import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); //username OR email
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  LoginType _selectedType = LoginType.dummyJson;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeIn));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    UserService userService = UserService();
    setState(() => _isLoading = true);

    try {
      if (_selectedType == LoginType.dummyJson) {
        final response = await userService.loginUser(
          _identifierController.text.trim(),
          _passwordController.text,
        );
        await userService.saveUserData(response);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home', arguments: response);
      } else {
        //Firebase: email is the identifier
        await userService.signIn(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFirebase = _selectedType == LoginType.firebase;
    final String identifierLabel = isFirebase ? 'Email Address' : 'Username';
    final String identifierHint =
        isFirebase ? 'Enter your email' : 'Enter your username';
    final IconData identifierIcon =
        isFirebase ? Icons.email_outlined : Icons.person_outline;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B2A4A),
              Color(0xFF2D3561),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 260.w,
                height: 260.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4A6CF7).withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -90,
              child: Container(
                width: 300.w,
                height: 300.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C63FF).withOpacity(0.07),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 56.h),

                    // App logo
                    Container(
                      width: 88.w,
                      height: 88.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.all(14.w),
                      child: Image.asset(
                        'assets/images/nubdexchange_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 22.h),

                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Sign in to continue shopping',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.50),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildBackendToggle(),
                    ),

                    SizedBox(height: 24.h),

                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: EdgeInsets.all(28.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.14),
                                  width: 1,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Username OR Email (changes with toggle)
                                    _buildLabel(identifierLabel),
                                    SizedBox(height: 8.h),
                                    _buildTextField(
                                      controller: _identifierController,
                                      hint: identifierHint,
                                      prefixIcon: identifierIcon,
                                      keyboardType: isFirebase
                                          ? TextInputType.emailAddress
                                          : TextInputType.text,
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? '$identifierLabel is required'
                                              : null,
                                    ),
                                    SizedBox(height: 20.h),

                                    _buildLabel('Password'),
                                    SizedBox(height: 8.h),
                                    _buildTextField(
                                      controller: _passwordController,
                                      hint: 'Enter your password',
                                      prefixIcon: Icons.lock_outline,
                                      obscure: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.white54,
                                          size: 20.sp,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Password is required'
                                              : null,
                                    ),
                                    SizedBox(height: 32.h),

                                    // Sign In button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52.h,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF4A6CF7),
                                              Color(0xFF6C63FF),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF4A6CF7)
                                                  .withOpacity(0.40),
                                              blurRadius: 18,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed:
                                              _isLoading ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      14.r),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 16.sp,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 28.h),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.sp,
                              color: Colors.white.withOpacity(0.50),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, '/signup'),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9AB0FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendToggle() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          _buildToggleOption(
            label: 'DummyJSON',
            icon: Icons.cloud_outlined,
            selected: _selectedType == LoginType.dummyJson,
            onTap: () => setState(() {
              _selectedType = LoginType.dummyJson;
              _identifierController.clear();
            }),
          ),
          _buildToggleOption(
            label: 'Firebase',
            icon: Icons.local_fire_department_outlined,
            selected: _selectedType == LoginType.firebase,
            onTap: () => setState(() {
              _selectedType = LoginType.firebase;
              _identifierController.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF4A6CF7), Color(0xFF6C63FF)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4A6CF7).withOpacity(0.35),
                      blurRadius: 10,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16.sp,
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.45)),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.sp,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.75),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontSize: 14.sp,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white38,
          fontSize: 13.sp,
          fontFamily: 'Poppins',
        ),
        prefixIcon: Icon(prefixIcon, color: Colors.white54, size: 20.sp),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding:
            EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              const BorderSide(color: Color(0xFF4A6CF7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.sp,
          color: Colors.redAccent,
        ),
      ),
    );
  }
}