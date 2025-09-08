import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import '../models/group.dart';
import 'auth_repository.dart';
import 'storage_repository.dart';

final _groupsCol = 'groups';

class ChatRepository {
  ChatRepository(this._firestore, this._storageRepository);
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepository;

  // Groups stream (all for now; community/private segmentation later)
  Stream<List<Group>> watchGroups() {
    return _firestore
        .collection(_groupsCol)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Group.fromJson({'id': d.id, ...d.data()}))
              .toList(),
        );
  }

  // Messages stream for a group
  Stream<List<Message>> watchMessages(String groupId) {
    return _firestore
        .collection(_groupsCol)
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => _toMessage(d.id, d.data())).toList(),
        );
  }

  Message _toMessage(String id, Map<String, dynamic> data) {
    final createdAt = _toMillis(data['createdAt']);
    final authorId = (data['senderId'] as String?) ?? 'unknown';
    final senderName = data['senderName'] as String?;
    final senderPhotoUrl = data['senderPhotoUrl'] as String?;
    Map<String, dynamic>? metadata;
    if (senderName != null || senderPhotoUrl != null) {
      metadata = {
        if (senderName != null) 'senderName': senderName,
        if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
      };
    }
    if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty) {
      return ImageMessage(
        id: id,
        authorId: authorId,
        createdAt: createdAt != null
            ? DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true)
            : null,
        source: data['imageUrl'] as String,
        metadata: metadata,
      );
    }
    if (data['fileUrl'] != null && (data['fileUrl'] as String).isNotEmpty) {
      return FileMessage(
        id: id,
        authorId: authorId,
        createdAt: createdAt != null
            ? DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true)
            : null,
        source: data['fileUrl'] as String,
        mimeType: data['fileMimeType'] as String?,
        name: (data['fileName'] as String?) ?? 'file',
        metadata: metadata,
      );
    }
    return TextMessage(
      id: id,
      authorId: authorId,
      createdAt: createdAt != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true)
          : null,
      text: (data['text'] as String?) ?? '',
      metadata: metadata,
    );
  }

  int? _toMillis(dynamic ts) {
    if (ts == null) return null;
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    if (ts is DateTime) return ts.millisecondsSinceEpoch;
    if (ts is int) return ts;
    if (ts is Map && ts['seconds'] != null) {
      final seconds = (ts['seconds'] as num).toInt();
      final nanos = (ts['nanoseconds'] as num? ?? 0).toInt();
      return seconds * 1000 + nanos ~/ 1000000;
    }
    return null;
  }

  Future<void> sendText({
    required String groupId,
    required String uid,
    required String text,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    final doc = _firestore
        .collection(_groupsCol)
        .doc(groupId)
        .collection('messages')
        .doc();
    await doc.set({
      'senderId': uid,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendImage({
    required String groupId,
    required String uid,
    required File file,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    final url = await _storageRepository.uploadChatImage(
      groupId: groupId,
      uid: uid,
      file: file,
    );
    final doc = _firestore
        .collection(_groupsCol)
        .doc(groupId)
        .collection('messages')
        .doc();
    await doc.set({
      'senderId': uid,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'imageUrl': url,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendFile({
    required String groupId,
    required String uid,
    required File file,
    String? mimeType,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    final url = await _storageRepository.uploadChatFile(
      groupId: groupId,
      uid: uid,
      file: file,
    );
    final doc = _firestore
        .collection(_groupsCol)
        .doc(groupId)
        .collection('messages')
        .doc();
    await doc.set({
      'senderId': uid,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'fileUrl': url,
      'fileMimeType': mimeType,
      'fileName': file.path.split('/').last,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageRepositoryProvider),
  );
});

final groupsStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchGroups();
});

final groupMessagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, id) {
      final repo = ref.watch(chatRepositoryProvider);
      return repo.watchMessages(id);
    });

// Provide a simple in-memory controller bound to Firestore stream
final chatControllerProvider = Provider.autoDispose
    .family<InMemoryChatController, String>((ref, groupId) {
      final controller = InMemoryChatController();
      ref.listen(groupMessagesProvider(groupId), (prev, next) {
        next.whenData((msgs) {
          // Use raw message list; grouping & time display handled by UI builders.
          controller.setMessages(msgs);
        });
      }, fireImmediately: true);
      ref.onDispose(() {
        controller.dispose();
      });
      return controller;
    });

// (Legacy) Previous logic suppressed intermediate timestamps; retained here for reference.
