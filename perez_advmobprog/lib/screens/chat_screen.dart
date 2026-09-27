import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          //search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
                prefixIcon: Icon(Icons.search, size: 20.sp, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18.sp),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.grey.withOpacity(0.1),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          //user list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final currentUid = _auth.currentUser?.uid;
                final allUsers = snapshot.data ?? [];

                //exclude current user, then filter by search query
                final filtered = allUsers.where((user) {
                  if (user['uid'] == currentUid) return false;
                  if (_searchQuery.isEmpty) return true;
                  final name = (user['displayName'] ?? '').toLowerCase();
                  final email = (user['email'] ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60.sp, color: Colors.grey[300]),
                        SizedBox(height: 12.h),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No users found.'
                              : 'No results for "$_searchQuery"',
                          style: TextStyle(
                              fontSize: 14.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 4.h),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return _buildUserTile(user, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, bool isDark) {
    final displayName = user['displayName'] ?? user['email'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final uid = user['uid'] ?? '';
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      tileColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.withOpacity(0.06),
      leading: CircleAvatar(
        radius: 24.r,
        backgroundColor: const Color(0xFF4A6CF7).withOpacity(0.15),
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A6CF7),
          ),
        ),
      ),
      title: Text(
        displayName,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        email,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          size: 20.sp, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              receiverId: uid,
              receiverName: displayName,
            ),
          ),
        );
      },
    );
  }
}
