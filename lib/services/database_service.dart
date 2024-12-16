import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:mid_app/models/chat.dart';
import 'package:mid_app/models/user_profile.dart';
import 'package:mid_app/services/auth_service.dart';
import 'package:mid_app/utils.dart';

import '../models/message.dart';

class DatabaseService {
  final GetIt _getIt = GetIt.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  late AuthService _authService;

  CollectionReference? _usersCollection;
  CollectionReference? _chatsCollection;

  DatabaseService() {
    _authService = _getIt.get<AuthService>();
    _setupCollectionReferences();
  }

  void _setupCollectionReferences() {
    _usersCollection =
        _firebaseFirestore.collection('users').withConverter<UserProfile>(
          fromFirestore: (snapshots, _) => UserProfile.fromJson(
            snapshots.data()!,
          ),
          toFirestore: (userProfile, _) => userProfile.toJson(),
        );
    _chatsCollection = _firebaseFirestore
        .collection('chats')
        .withConverter<Chat>(
      fromFirestore: (snapshots, _) => Chat.fromJson(snapshots.data()!),
      toFirestore: (chat, _) => chat.toJson(),
    );
  }

  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection?.doc(userId).get();
      if (doc != null && doc.exists) {
        return doc.data() as UserProfile;
      } else {
        throw Exception("User profile not found");
      }
    } catch (e) {
      throw Exception("Error fetching user profile: $e");
    }
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async {
    await _usersCollection?.doc(userProfile.uid).set(userProfile);
  }

  Stream<QuerySnapshot<UserProfile>> getUserProfiles() {
    return _usersCollection
        ?.where("uid", isNotEqualTo: _authService.user!.uid)
        .snapshots() as Stream<QuerySnapshot<UserProfile>>;
  }

  Future<bool> checkChatExists(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final result = await _chatsCollection?.doc(chatID).get();
    if (result != null) {
      return result.exists;
    }
    return false;
  }

  Future<void> createNewChat(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatsCollection!.doc(chatID);
    final chat = Chat(
      id: chatID,
      participants: [uid1, uid2],
      messages: [],
    );
    await docRef.set(chat);
  }

  Future<void> sendChatMessage(String uid1, String uid2, Message message) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatsCollection!.doc(chatID);
    await docRef.update(
      {
        "messages": FieldValue.arrayUnion(
          [
            message.toJson(),
          ],
        ),
      },
    );
  }

  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      await _usersCollection?.doc(uid).update(updatedData);
    } catch (e) {
      throw Exception("Failed to update user profile: $e");
    }
  }

  Stream<DocumentSnapshot<Chat>> getChatData(String uid1, String uid2) {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    return _chatsCollection?.doc(chatID).snapshots()
    as Stream<DocumentSnapshot<Chat>>;
  }
}
