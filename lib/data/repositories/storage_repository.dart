import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart' as mime;

final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

class StorageRepository {
  StorageRepository(this._storage);
  final FirebaseStorage _storage;

  Future<String> uploadUserAvatar({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref().child('avatars').child('$uid.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadChatImage({
    required String groupId,
    required String uid,
    required File file,
  }) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$uid.jpg';
    final ref = _storage
        .ref()
        .child('chat')
        .child(groupId)
        .child('images')
        .child(filename);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadChatFile({
    required String groupId,
    required String uid,
    required File file,
  }) async {
    final namePart = file.path.split('/').last;
    final filename =
        '${DateTime.now().millisecondsSinceEpoch}_${uid}_$namePart';
    final contentType =
        mime.lookupMimeType(file.path) ?? 'application/octet-stream';
    final ref = _storage
        .ref()
        .child('chat')
        .child(groupId)
        .child('files')
        .child(filename);
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(ref.watch(firebaseStorageProvider));
});
