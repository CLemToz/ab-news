import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wp_post.dart';

class SaveManager {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static User? get _user => _auth.currentUser;

  static CollectionReference<Map<String, dynamic>>? get _collection {
    if (_user == null) return null;
    return _firestore.collection('users').doc(_user!.uid).collection('saved_articles');
  }

  /// ✅ Get all saved posts
  static Future<List<WPPost>> getAll() async {
    if (_collection == null) return [];
    final snapshot = await _collection!.get();
    return snapshot.docs.map((doc) => WPPost.fromJson(doc.data())).toList();
  }

  /// ✅ Save a post
  static Future<void> save(WPPost post) async {
    if (_collection == null) return;
    await _collection!.doc(post.id.toString()).set(post.toJson());
  }

  /// ✅ Remove a saved post
  static Future<void> remove(WPPost post) async {
    if (_collection == null) return;
    await _collection!.doc(post.id.toString()).delete();
  }

  /// ✅ Check if a post is saved
  static Future<bool> isSaved(int id) async {
    if (_collection == null) return false;
    final doc = await _collection!.doc(id.toString()).get();
    return doc.exists;
  }
}
