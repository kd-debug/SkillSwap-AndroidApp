import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser!;

  CollectionReference get _taskRef =>
      _firestore.collection('users').doc(_user.uid).collection('tasks');

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
