import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _page = PageController();
  int _index = 0;

  // Details form
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _niche = TextEditingController();
  String? _profession;
  File? _avatar;
  bool _saving = false;

  @override
  void dispose() {
    _page.dispose();
    _phone.dispose();
    _niche.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) setState(() => _avatar = File(img.path));
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final user = ref.read(firebaseAuthProvider).currentUser!;
      String? photoUrl;
      if (_avatar != null) {
        photoUrl = await auth.uploadAvatar(
          uid: user.uid,
          filePath: _avatar!.path,
        );
      }
      await ref.read(firestoreProvider).collection('users').doc(user.uid).set({
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'niche': _niche.text.trim().isEmpty ? null : _niche.text.trim(),
        'profession': _profession,
        if (photoUrl != null) 'photoUrl': photoUrl,
      }, SetOptions(merge: true));
      if (!mounted) return;
      context.go('/rooms');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    setState(() => _index += 1);
    _page.animateToPage(
      _index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _IntroPage(
                    title: 'Welcome to C3',
                    message:
                        'Find rooms, connect with other creators, and grow your craft.',
                    icon: SvgPicture.asset(
                      'assets/logo.svg',
                      width: 120,
                      height: 120,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    onNext: _next,
                  ),
                  _IntroPage(
                    title: 'Community & Collaboration',
                    message:
                        'Join chats, book spaces, and access premium features with membership.',
                    icon: const Icon(
                      Icons.groups_2_rounded,
                      size: 120,
                      color: AppColors.primary,
                    ),
                    onNext: _next,
                  ),
                  _DetailsPage(
                    formKey: _formKey,
                    phone: _phone,
                    niche: _niche,
                    profession: _profession,
                    onProfessionChanged: (v) => setState(() => _profession = v),
                    avatar: _avatar,
                    onPickAvatar: _pickAvatar,
                    onComplete: _complete,
                    saving: _saving,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: active ? 20 : 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : scheme.onSurface.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.title,
    required this.message,
    required this.icon,
    required this.onNext,
  });
  final String title;
  final String message;
  final Widget icon;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onNext, child: const Text('Next')),
          ),
        ],
      ),
    );
  }
}

class _DetailsPage extends StatelessWidget {
  const _DetailsPage({
    required this.formKey,
    required this.phone,
    required this.niche,
    required this.profession,
    required this.onProfessionChanged,
    required this.avatar,
    required this.onPickAvatar,
    required this.onComplete,
    required this.saving,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phone;
  final TextEditingController niche;
  final String? profession;
  final ValueChanged<String?> onProfessionChanged;
  final File? avatar;
  final VoidCallback onPickAvatar;
  final VoidCallback onComplete;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Form(
          key: formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: InkWell(
                    onTap: onPickAvatar,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: avatar != null
                          ? FileImage(avatar!)
                          : null,
                      child: avatar == null
                          ? const Icon(Icons.camera_alt)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: phone,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: niche,
                  decoration: const InputDecoration(
                    labelText: 'Niche (e.g., Comedy)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: profession,
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
                      value: 'Sound Engineer',
                      child: Text('Sound Engineer'),
                    ),
                    DropdownMenuItem(
                      value: 'Content Creator',
                      child: Text('Content Creator'),
                    ),
                    DropdownMenuItem(
                      value: 'Designer',
                      child: Text('Designer'),
                    ),
                    DropdownMenuItem(
                      value: 'Web Designer',
                      child: Text('Web Designer'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: onProfessionChanged,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : onComplete,
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Finish up!'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
