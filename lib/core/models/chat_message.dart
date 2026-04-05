import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String requestId;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'requestId': requestId,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      chatId: map['chatId'] ?? '',
      requestId: map['requestId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      recipientId: map['recipientId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
