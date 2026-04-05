import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/skill_model.dart';
import '../models/skill_request.dart';
import '../models/chat_message.dart';
import 'unsplash_service.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;
  User? get _authUser => FirebaseAuth.instance.currentUser;

  // --- Profile Methods ---

  DocumentReference get _userDoc =>
      _firestore.collection('users').doc(_authUser?.uid);

  Future<void> saveUserProfile(UserProfile profile) async {
    print(
        'DEBUG: Saving user profile for UID: ${profile.uid}, Name: ${profile.name}');
    // 1. Save user profile
    await _userDoc.set(profile.toMap(), SetOptions(merge: true));

    // 2. Sync name across all skills posted by this user
    final batch = _firestore.batch();

    // Update offered skills
    final offeredSnapshot =
        await _offeredSkillsRef.where('userId', isEqualTo: profile.uid).get();
    print('DEBUG: Found ${offeredSnapshot.docs.length} offered skills to sync');
    for (var doc in offeredSnapshot.docs) {
      batch.update(doc.reference, {'userName': profile.name});
    }

    // Update wanted skills
    final wantedSnapshot =
        await _wantedSkillsRef.where('userId', isEqualTo: profile.uid).get();
    print('DEBUG: Found ${wantedSnapshot.docs.length} wanted skills to sync');
    for (var doc in wantedSnapshot.docs) {
      batch.update(doc.reference, {'userName': profile.name});
    }

    await batch.commit();
    print('DEBUG: Profile sync committed');
  }

  Future<void> updateUserLocation(double lat, double lng) async {
    if (_authUser == null) return;

    final batch = _firestore.batch();

    // 1. Update user profile location
    batch.update(_userDoc, {
      'latitude': lat,
      'longitude': lng,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    // 2. Update all offered skills by this user to match their current location
    final offeredSnapshot = await _offeredSkillsRef
        .where('userId', isEqualTo: _authUser!.uid)
        .get();

    for (var doc in offeredSnapshot.docs) {
      batch.update(doc.reference, {
        'latitude': lat,
        'longitude': lng,
      });
    }

    await batch.commit();
    print(
        'DEBUG: User location and ${offeredSnapshot.docs.length} skills synced to Firestore');
  }

  Future<UserProfile?> getUserProfile() async {
    if (_authUser == null) return null;
    final doc = await _userDoc.get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<UserProfile?> getUserProfileStream() {
    if (_authUser == null) return Stream.value(null);
    return _userDoc.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Future<void> updateProfileImageUrl(String imageUrl) async {
    if (_authUser == null) return;
    await _userDoc.set({'profileImageUrl': imageUrl}, SetOptions(merge: true));
  }

  Future<void> updateProfileImagePath(String imagePath) async {
    if (_authUser == null) return;
    await _userDoc.set({
      'profileImagePath': imagePath,
      'profileImageUrl': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  // --- Skills Methods ---

  CollectionReference get _offeredSkillsRef =>
      _firestore.collection('offeredSkills');

  CollectionReference get _wantedSkillsRef =>
      _firestore.collection('wantedSkills');

  Future<void> addOfferedSkill(OfferedSkill skill) async {
    // Enrich with user's current location if available
    final userProfile = await getUserProfile();
    final enrichedSkill = {
      ...skill.toMap(),
      if (userProfile?.latitude != null) 'latitude': userProfile!.latitude,
      if (userProfile?.longitude != null) 'longitude': userProfile!.longitude,
    };
    await _offeredSkillsRef.add(enrichedSkill);
  }

  Future<void> addWantedSkill(WantedSkill skill) async {
    await _wantedSkillsRef.add(skill.toMap());
  }

  Future<void> updateOfferedSkill(OfferedSkill skill) async {
    await _offeredSkillsRef.doc(skill.id).update(skill.toMap());
  }

  Future<void> updateWantedSkill(WantedSkill skill) async {
    await _wantedSkillsRef.doc(skill.id).update(skill.toMap());
  }

  Stream<List<OfferedSkill>> getMyOfferedSkills() {
    return _offeredSkillsRef
        .where('userId', isEqualTo: _authUser?.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OfferedSkill.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
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

  Future<void> hydrateWantedSkillImages(List<WantedSkill> skills) async {
    if (_authUser == null) return;
    final unsplash = UnsplashService();

    for (final skill in skills) {
      if (skill.userId != _authUser!.uid) continue;
      if (skill.imageUrl != null && skill.imageUrl!.isNotEmpty) continue;

      final imageUrl = await unsplash.getSkillImage(
        skill.name,
        skill.category.isNotEmpty
            ? skill.category
            : (skill.remarks.isNotEmpty ? skill.remarks : skill.level),
      );

      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _wantedSkillsRef.doc(skill.id).update({'imageUrl': imageUrl});
      }
    }
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
            .map((doc) => SkillRequest.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<SkillRequest>> getSentRequests() {
    if (_authUser == null) return Stream.value([]);
    return _requestsRef
        .where('fromUserId', isEqualTo: _authUser?.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SkillRequest.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
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
      final docs = snapshot.docs
          .map((doc) =>
              SkillRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      final accepted = docs.where((r) => r.status == 'accepted').firstOrNull;
      if (accepted != null) return accepted;

      final pending = docs.where((r) => r.status == 'pending').firstOrNull;
      if (pending != null) return pending;

      return docs.first;
    });
  }

  Future<void> respondToRequest(String requestId, String status,
      {String? selectedSkillName}) async {
    final Map<String, dynamic> data = {
      'status': status,
    };
    if (selectedSkillName != null) {
      data['selectedSkillName'] = selectedSkillName;
    }
    await _requestsRef.doc(requestId).update(data);
  }

  // --- Chat Methods ---

  CollectionReference get _chatsRef => _firestore.collection('skillChats');

  String chatIdForRequest(String requestId) => requestId;

  Future<void> ensureChatRoom(SkillRequest request) async {
    await _chatsRef.doc(chatIdForRequest(request.id)).set({
      'requestId': request.id,
      'fromUserId': request.fromUserId,
      'fromUserName': request.fromUserName,
      'toUserId': request.toUserId,
      'toUserName': request.toUserName,
      'requestedSkillId': request.requestedSkillId,
      'requestedSkillName': request.requestedSkillName,
      'status': request.status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ChatMessage.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> sendChatMessage({
    required String chatId,
    required String requestId,
    required String senderId,
    required String senderName,
    required String recipientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatDoc = _chatsRef.doc(chatId);
    await chatDoc.set({
      'requestId': requestId,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': trimmed,
      'lastMessageBy': senderId,
    }, SetOptions(merge: true));

    await chatDoc.collection('messages').add({
      'chatId': chatId,
      'requestId': requestId,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Legacy Task Methods (Retained for compatibility if needed) ---
  CollectionReference get _taskRef => _userDoc.collection('tasks');

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

  // --- Matchmaking ---

  Future<Map<String, List<OfferedSkill>>> getMatchesForUser() async {
    if (_authUser == null) return {'direct': [], 'indirect': []};

    final myOfferedSnap = await _offeredSkillsRef
        .where('userId', isEqualTo: _authUser!.uid)
        .get();
    final myWantedSnap =
        await _wantedSkillsRef.where('userId', isEqualTo: _authUser!.uid).get();

    final myOffered = myOfferedSnap.docs
        .map(
            (d) => OfferedSkill.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
    final myWantedNames = myWantedSnap.docs
        .expand((d) {
          final data = d.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          final category = data['category']?.toString().toLowerCase() ?? '';
          return [name, category];
        })
        .where((v) => v.isNotEmpty)
        .toSet();
    final myOfferedCategories =
        myOffered.map((s) => s.category.toLowerCase()).toSet();

    final allSnap = await _offeredSkillsRef.get();
    final allSkills = allSnap.docs
        .map(
            (d) => OfferedSkill.fromMap(d.data() as Map<String, dynamic>, d.id))
        .where((s) => s.userId != _authUser!.uid)
        .toList();

    final direct = allSkills
        .where((s) =>
            myWantedNames.contains(s.name.toLowerCase()) ||
            myWantedNames.contains(s.category.toLowerCase()))
        .toList();

    final indirect = allSkills
        .where((s) =>
            !direct.contains(s) &&
            myOfferedCategories.contains(s.category.toLowerCase()))
        .toList();

    return {'direct': direct, 'indirect': indirect};
  }
}
