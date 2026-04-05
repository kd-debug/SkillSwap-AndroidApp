import 'package:cloud_firestore/cloud_firestore.dart';

class SkillRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String requestedSkillId;
  final String requestedSkillName;
  final List<String> offeredSkillNames;
  final String status;
  final String? selectedSkillName;
  final DateTime timestamp;

  SkillRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.requestedSkillId,
    required this.requestedSkillName,
    required this.offeredSkillNames,
    this.status = 'pending',
    this.selectedSkillName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'requestedSkillId': requestedSkillId,
      'requestedSkillName': requestedSkillName,
      'offeredSkillNames': offeredSkillNames,
      'status': status,
      'selectedSkillName': selectedSkillName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory SkillRequest.fromMap(Map<String, dynamic> map, String id) {
    return SkillRequest(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      toUserId: map['toUserId'] ?? '',
      toUserName: map['toUserName'] ?? '',
      requestedSkillId: map['requestedSkillId'] ?? '',
      requestedSkillName: map['requestedSkillName'] ?? '',
      offeredSkillNames: List<String>.from(map['offeredSkillNames'] ?? []),
      status: map['status'] ?? 'pending',
      selectedSkillName: map['selectedSkillName'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
