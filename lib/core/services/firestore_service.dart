import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/skill_model.dart';
import '../models/skill_request.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;
  User? get _authUser => FirebaseAuth.instance.currentUser;

  // --- Profile Methods ---

  DocumentReference get _userDoc =>
      _firestore.collection('users').doc(_authUser?.uid);

  Future<void> saveUserProfile(UserProfile profile) async {
    print('DEBUG: Saving user profile for UID: ${profile.uid}, Name: ${profile.name}');
    // 1. Save user profile
    await _userDoc.set(profile.toMap(), SetOptions(merge: true));

    // 2. Sync name across all skills posted by this user
    final batch = _firestore.batch();

    // Update offered skills
    final offeredSnapshot = await _offeredSkillsRef
        .where('userId', isEqualTo: profile.uid)
        .get();
    print('DEBUG: Found ${offeredSnapshot.docs.length} offered skills to sync');
    for (var doc in offeredSnapshot.docs) {
      batch.update(doc.reference, {'userName': profile.name});
    }

    // Update wanted skills
    final wantedSnapshot = await _wantedSkillsRef
        .where('userId', isEqualTo: profile.uid)
        .get();
    print('DEBUG: Found ${wantedSnapshot.docs.length} wanted skills to sync');
    for (var doc in wantedSnapshot.docs) {
      batch.update(doc.reference, {'userName': profile.name});
    }

    await batch.commit();
    print('DEBUG: Profile sync committed');
  }

  Future<UserProfile?> getUserProfile() async {
    if (_authUser == null) return null;
    final doc = await _userDoc.get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // --- Skills Methods ---

  CollectionReference get _offeredSkillsRef =>
      _firestore.collection('offeredSkills');

  CollectionReference get _wantedSkillsRef =>
      _firestore.collection('wantedSkills');

  Future<void> addOfferedSkill(OfferedSkill skill) async {
    await _offeredSkillsRef.add(skill.toMap());
  }

  Future<void> addWantedSkill(WantedSkill skill) async {
    await _wantedSkillsRef.add(skill.toMap());
  }

  Stream<List<OfferedSkill>> getMyOfferedSkills() {
    return _offeredSkillsRef
        .where('userId', isEqualTo: _authUser?.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                OfferedSkill.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<WantedSkill>> getMyWantedSkills() {
    return _wantedSkillsRef
        .where('userId', isEqualTo: _authUser?.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                WantedSkill.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<OfferedSkill>> getAllOfferedSkills() {
    return _offeredSkillsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            OfferedSkill.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<void> deleteOfferedSkill(String skillId) async {
    await _offeredSkillsRef.doc(skillId).delete();
  }

  Future<void> deleteWantedSkill(String skillId) async {
    await _wantedSkillsRef.doc(skillId).delete();
  }

  // --- Skill Request Methods ---

  CollectionReference get _requestsRef =>
      _firestore.collection('skillRequests');

  Future<void> sendSkillRequest(SkillRequest request) async {
    await _requestsRef.add(request.toMap());
  }

  Stream<List<SkillRequest>> getReceivedRequests() {
    if (_authUser == null) return Stream.value([]);
    return _requestsRef
        .where('toUserId', isEqualTo: _authUser?.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SkillRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<SkillRequest>> getSentRequests() {
    if (_authUser == null) return Stream.value([]);
    return _requestsRef
        .where('fromUserId', isEqualTo: _authUser?.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SkillRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<SkillRequest?> getRequestForSkill(String skillId) {
    if (_authUser == null) return Stream.value(null);
    return _requestsRef
        .where('fromUserId', isEqualTo: _authUser?.uid)
        .where('requestedSkillId', isEqualTo: skillId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          // Priority to 'accepted' or 'pending' if multiple exist (unlikely but safe)
          final docs = snapshot.docs.map((doc) => 
            SkillRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
          
          final accepted = docs.where((r) => r.status == 'accepted').firstOrNull;
          if (accepted != null) return accepted;
          
          final pending = docs.where((r) => r.status == 'pending').firstOrNull;
          if (pending != null) return pending;
          
          return docs.first;
        });
  }

  Future<void> respondToRequest(String requestId, String status, {String? selectedSkillName}) async {
    final data = {
      'status': status,
    };
    if (selectedSkillName != null) {
      data['selectedSkillName'] = selectedSkillName;
    }
    await _requestsRef.doc(requestId).update(data);
  }

  // --- Legacy Task Methods (Retained for compatibility if needed) ---
  CollectionReference get _taskRef =>
      _userDoc.collection('tasks');

  Future<void> addTask(String title, String description) async {
    await _taskRef.add({
      'title': title,
      'description': description,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getTasks() {
    return _taskRef.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateStatus(String docId, String status) async {
    await _taskRef.doc(docId).update({'status': status});
  }

  Future<void> deleteTask(String docId) async {
    await _taskRef.doc(docId).delete();
  }
}
