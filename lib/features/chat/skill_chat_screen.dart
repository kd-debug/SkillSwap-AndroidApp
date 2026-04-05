import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/chat_message.dart';
import '../../core/models/skill_request.dart';
import '../../core/services/firestore_service.dart';

class SkillChatScreen extends StatefulWidget {
  final SkillRequest request;

  const SkillChatScreen({super.key, required this.request});

  @override
  State<SkillChatScreen> createState() => _SkillChatScreenState();
}

class _SkillChatScreenState extends State<SkillChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _firestoreService.ensureChatRoom(widget.request);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _chatId => _firestoreService.chatIdForRequest(widget.request.id);

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _currentUserName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'You';

  String get _otherUserName {
    final currentUserId = _currentUserId;
    if (currentUserId == widget.request.fromUserId) {
      return widget.request.toUserName;
    }
    return widget.request.fromUserName;
  }

  String get _otherUserId {
    final currentUserId = _currentUserId;
    if (currentUserId == widget.request.fromUserId) {
      return widget.request.toUserId;
    }
    return widget.request.fromUserId;
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _firestoreService.sendChatMessage(
        chatId: _chatId,
        requestId: widget.request.id,
        senderId: _currentUserId,
        senderName: _currentUserName,
        recipientId: _otherUserId,
        text: text,
      );
      _messageController.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.request.requestedSkillName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Chat with $_otherUserName',
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              gradient: const LinearGradient(
                colors: [Color(0xFF005B5B), Color(0xFF149D9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.requestedSkillName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accepted swap with $_otherUserName',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _firestoreService.getChatMessages(_chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Start the conversation about ${widget.request.requestedSkillName}.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == _currentUserId;
                    return _MessageBubble(message: message, isMine: isMine);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Write a message...'
                            ,
                        filled: true,
                        fillColor: const Color(0xFFF3F7F7),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? Colors.teal : Colors.white;
    final textColor = isMine ? Colors.white : Colors.black87;
    final borderColor = isMine ? Colors.teal : Colors.teal.shade100;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.senderName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMine ? Colors.white70 : Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
