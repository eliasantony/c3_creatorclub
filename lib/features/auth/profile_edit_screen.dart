import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/auth_repository.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _niche = TextEditingController();
  String? _profession;
  File? _avatar;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _niche.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) setState(() => _avatar = File(img.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final authUser = ref.read(authStateChangesProvider).asData?.value;
    final profile = ref.read(userProfileProvider).asData?.value;
    if (authUser == null || profile == null) return;
    setState(() => _loading = true);
    try {
      String? photoUrl = profile.photoUrl;
      if (_avatar != null) {
        photoUrl = await ref
            .read(authRepositoryProvider)
            .uploadAvatar(uid: authUser.uid, filePath: _avatar!.path);
      }
      final updated = profile.copyWith(
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        profession: _profession,
        niche: _niche.text.trim().isEmpty ? null : _niche.text.trim(),
        photoUrl: photoUrl,
      );
      await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(profile.uid)
          .set(updated.toJson());
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('No profile'));
          _name.text = _name.text.isEmpty ? profile.name : _name.text;
          _phone.text = _phone.text.isEmpty
              ? (profile.phone ?? '')
              : _phone.text;
          _niche.text = _niche.text.isEmpty
              ? (profile.niche ?? '')
              : _niche.text;
          _profession ??= profile.profession;
          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: InkWell(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundImage: _avatar != null
                            ? FileImage(_avatar!)
                            : (profile.photoUrl != null
                                      ? NetworkImage(profile.photoUrl!)
                                      : null)
                                  as ImageProvider?,
                        child: (profile.photoUrl == null && _avatar == null)
                            ? const Icon(Icons.camera_alt)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _profession,
                    decoration: const InputDecoration(labelText: 'Profession'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Photographer',
                        child: Text('Photographer'),
                      ),
                      DropdownMenuItem(
                        value: 'Videographer',
                        child: Text('Videographer'),
                      ),
                      DropdownMenuItem(
                        value: 'Content Creator',
                        child: Text('Content Creator'),
                      ),
                      DropdownMenuItem(
                        value: 'Web Designer',
                        child: Text('Web Designer'),
                      ),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _profession = v),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _niche,
                    decoration: const InputDecoration(
                      labelText: 'Niche (e.g., Portraits)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const CircularProgressIndicator.adaptive()
                        : const Text('Save changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
