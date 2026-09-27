import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
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
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //handles DummyJSON or Firebase registration based on selected type
  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedType == LoginType.dummyJson) {
        await _userService.createAccount(
          firstName: _fNameController.text.trim(),
          lastName: _lNameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()) ?? 0,
          phone: _phoneController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        await _userService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName:
              '${_fNameController.text.trim()} ${_lNameController.text.trim()}'
                  .trim(),
          age: int.tryParse(_ageController.text.trim()) ?? 0,
          phone: _phoneController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please sign in.'),
            backgroundColor: Color(0xFF4A6CF7),
          ),
        );
        Navigator.pushReplacementNamed(context, '/signin');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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
                    SizedBox(height: 40.h),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Fill in your details to get started',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.sp,
                              color: Colors.white.withOpacity(0.50),
                            ),
                          ),
                        ],
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
                              padding: EdgeInsets.all(24.w),
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildLabel('First Name'),
                                              SizedBox(height: 8.h),
                                              _buildTextField(
                                                controller: _fNameController,
                                                hint: 'First name',
                                                prefixIcon:
                                                    Icons.person_outline,
                                                validator: (v) =>
                                                    (v == null ||
                                                            v.trim().isEmpty)
                                                        ? 'Required'
                                                        : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildLabel('Last Name'),
                                              SizedBox(height: 8.h),
                                              _buildTextField(
                                                controller: _lNameController,
                                                hint: 'Last name',
                                                prefixIcon:
                                                    Icons.person_outline,
                                                validator: (v) =>
                                                    (v == null ||
                                                            v.trim().isEmpty)
                                                        ? 'Required'
                                                        : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildLabel('Age'),
                                              SizedBox(height: 8.h),
                                              _buildTextField(
                                                controller: _ageController,
                                                hint: 'Age',
                                                prefixIcon:
                                                    Icons.cake_outlined,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly
                                                ],
                                                validator: (v) {
                                                  if (v == null ||
                                                      v.trim().isEmpty) {
                                                    return 'Required';
                                                  }
                                                  final age =
                                                      int.tryParse(v);
                                                  if (age == null ||
                                                      age < 1 ||
                                                      age > 120) {
                                                    return 'Invalid age';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildLabel('Contact No.'),
                                              SizedBox(height: 8.h),
                                              _buildTextField(
                                                controller: _phoneController,
                                                hint: 'Phone number',
                                                prefixIcon:
                                                    Icons.phone_outlined,
                                                keyboardType:
                                                    TextInputType.phone,
                                                validator: (v) =>
                                                    (v == null ||
                                                            v.trim().isEmpty)
                                                        ? 'Required'
                                                        : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    _buildLabel('Username'),
                                    SizedBox(height: 8.h),
                                    _buildTextField(
                                      controller: _usernameController,
                                      hint: 'Choose a username',
                                      prefixIcon:
                                          Icons.alternate_email_rounded,
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Username is required'
                                              : null,
                                    ),
                                    SizedBox(height: 16.h),

                                    _buildLabel('Email Address'),
                                    SizedBox(height: 8.h),
                                    _buildTextField(
                                      controller: _emailController,
                                      hint: 'Enter your email',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(v.trim())) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16.h),

                                    // Password (with validation)
                                    _buildLabel('Password'),
                                    SizedBox(height: 8.h),
                                    _buildTextField(
                                      controller: _passwordController,
                                      hint: 'Min 8 chars, letter & number',
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
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Password is required';
                                        }
                                        if (v.length < 8) {
                                          return 'At least 8 characters';
                                        }
                                        if (!RegExp(r'[a-zA-Z]')
                                            .hasMatch(v)) {
                                          return 'Must contain a letter';
                                        }
                                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                                          return 'Must contain a number';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 28.h),

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
                                          onPressed: _isLoading
                                              ? null
                                              : _register,
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
                                                  'Create Account',
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

                    SizedBox(height: 24.h),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.sp,
                              color: Colors.white.withOpacity(0.50),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, '/signin'),
                            child: Text(
                              'Sign In',
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
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //toggle between DummyJSON and Firebase backend
  Widget _buildBackendToggle() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          _buildToggleOption(
            label: 'DummyJSON',
            icon: Icons.cloud_outlined,
            selected: _selectedType == LoginType.dummyJson,
            onTap: () => setState(() => _selectedType = LoginType.dummyJson),
          ),
          _buildToggleOption(
            label: 'Firebase',
            icon: Icons.local_fire_department_outlined,
            selected: _selectedType == LoginType.firebase,
            onTap: () => setState(() => _selectedType = LoginType.firebase),
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
              Icon(
                icon,
                size: 16.sp,
                color: selected
                    ? Colors.white
                    : Colors.white.withOpacity(0.45),
              ),
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
        fontSize: 12.sp,
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontSize: 13.sp,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white38,
          fontSize: 12.sp,
          fontFamily: 'Poppins',
        ),
        prefixIcon: Icon(prefixIcon, color: Colors.white54, size: 18.sp),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding:
            EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.15)),
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
          fontSize: 10.sp,
          color: Colors.redAccent,
        ),
      ),
    );
  }
}
