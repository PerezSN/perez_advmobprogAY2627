import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isSending = false;

  //tracks local optimistic messages while firestore confirms them
  final List<_PendingMessage> _pendingMessages = [];

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    _messageCtrl.clear();
    setState(() => _isSending = true);

    //add optimistic pending message so user sees it instantly
    final pending = _PendingMessage(text: text);
    setState(() => _pendingMessages.add(pending));
    _scrollToBottom();

    try {
      await _chatService.sendMessage(widget.receiverId, text);
      //mark as delivered once firestore confirms
      setState(() {
        pending.state = _SendState.delivered;
        _pendingMessages.remove(pending);
      });
    } catch (_) {
      setState(() => pending.state = _SendState.failed);
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUid = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessage(currentUid, widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  //pending messages show at top (bottom visually, reversed list)
                  itemCount: docs.length + _pendingMessages.length,
                  itemBuilder: (context, index) {
                    if (index < _pendingMessages.length) {
                      final pending = _pendingMessages[
                          _pendingMessages.length - 1 - index];
                      return _buildPendingBubble(pending, isDark);
                    }
                    final doc =
                        docs[index - _pendingMessages.length];
                    final data = doc.data() as Map<String, dynamic>;
                    final msg = MessageModel.fromMap(data);
                    final isMe = msg.senderId == currentUid;
                    return _buildMessageBubble(msg, isMe, isDark);
                  },
                );
              },
            ),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final initials = widget.receiverName.isNotEmpty
        ? widget.receiverName[0].toUpperCase()
        : '?';

    return AppBar(
      elevation: 1,
      leadingWidth: 40.w,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xFF4A6CF7).withOpacity(0.15),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A6CF7),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              widget.receiverName,
              style:
                  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe, bool isDark) {
    return _AnimatedBubble(
      key: ValueKey(msg.timestamp),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            bottom: 8.h,
            left: isMe ? 50.w : 0,
            right: isMe ? 0 : 50.w,
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF4A6CF7)
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.15)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(isMe ? 18.r : 4.r),
              bottomRight: Radius.circular(isMe ? 4.r : 18.r),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                msg.message,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isMe ? Colors.white : null,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(msg.timestamp),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey,
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 4.w),
                    //double checkmark = delivered/seen
                    Icon(
                      Icons.done_all_rounded,
                      size: 13.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingBubble(_PendingMessage pending, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h, left: 50.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFF4A6CF7).withOpacity(0.6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(18.r),
            bottomRight: Radius.circular(4.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              pending.text,
              style: TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'sending...',
                  style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white.withOpacity(0.7)),
                ),
                SizedBox(width: 4.w),
                //single checkmark = sending state
                Icon(Icons.done_rounded,
                    size: 13.sp,
                    color: Colors.white.withOpacity(0.7)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h)
              .copyWith(bottom: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle:
                    TextStyle(fontSize: 14.sp, color: Colors.grey),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.grey.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                color: _isSending
                    ? Colors.grey
                    : const Color(0xFF4A6CF7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final dt = timestamp.toDate().toLocal();
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

//fade+slide animation wrapper for incoming messages
class _AnimatedBubble extends StatefulWidget {
  final Widget child;
  const _AnimatedBubble({super.key, required this.child});

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

//simple state tracker for optimistic pending messages
enum _SendState { sending, delivered, failed }

class _PendingMessage {
  final String text;
  _SendState state;
  _PendingMessage({required this.text, this.state = _SendState.sending});
}
