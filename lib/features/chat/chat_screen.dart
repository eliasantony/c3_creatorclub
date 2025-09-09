import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/group.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.groupId, this.group});
  final String groupId;
  final Group? group;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  /// Multiple pending attachments (images and files)
  final List<_PendingAttachment> _pending = <_PendingAttachment>[];
  bool _isSendingAttachment = false;
  final Map<String, Map<String, String?>> _userHints = {};

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));
    final authUser = ref.watch(authStateChangesProvider).value;
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(widget.group?.name ?? 'Chat')),
      body: messagesAsync.when(
        data: (msgs) {
          // Build user hints from latest messages (senderName/senderPhotoUrl fields in Firestore)
          _userHints.clear();
          final controller = ref.watch(chatControllerProvider(widget.groupId));
          final currentUserId = authUser?.uid ?? 'anon';
          // Extract metadata hints for avatars/names
          for (final m in msgs) {
            final md = m.metadata;
            if (md != null) {
              final uid = m.authorId;
              final name = md['senderName'] as String?;
              final photo = md['senderPhotoUrl'] as String?;
              if (name != null || photo != null) {
                _userHints[uid] = {
                  'name': name ?? _userHints[uid]?['name'],
                  'photoUrl': photo ?? _userHints[uid]?['photoUrl'],
                };
              }
            }
          }

          return Stack(
            children: [
              // Chat list area; keep bottom padding so content isn't hidden by composer
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 92),
                  child: Chat(
                    chatController: controller,
                    currentUserId: currentUserId,
                    onAttachmentTap: () => _handleAttachmentTap(ref),
                    builders: Builders(
                      // HIDE library composer (we render our own at the bottom)
                      composerBuilder: (_) => const SizedBox.shrink(),

                      // WhatsApp-like text bubbles (right: outgoing, left: incoming) with in-bubble timestamp
                      textMessageBuilder:
                          (
                            context,
                            m,
                            index, {
                            required bool isSentByMe,
                            groupStatus,
                          }) {
                            final scheme = Theme.of(context).colorScheme;
                            final bg = isSentByMe
                                ? scheme.primary
                                : scheme.surfaceContainerHighest;
                            final fg = isSentByMe
                                ? scheme.onPrimary
                                : scheme.onSurface;
                            final t = m.resolvedTime?.toLocal();
                            final label = t != null
                                ? TimeOfDay.fromDateTime(t).format(context)
                                : '';

                            BorderRadius bubbleRadius() => BorderRadius.only(
                              topLeft: Radius.circular(isSentByMe ? 16 : 6),
                              topRight: Radius.circular(isSentByMe ? 6 : 16),
                              bottomLeft: const Radius.circular(16),
                              bottomRight: const Radius.circular(16),
                            );

                            // Let wrapper position the bubble and size to its content
                            return UnconstrainedBox(
                              alignment: isSentByMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 100, // room for timestamp
                                  maxWidth: 320,
                                ),
                                child: IntrinsicWidth(
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          10,
                                          50,
                                          18,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius: bubbleRadius(),
                                        ),
                                        // Make sure the text itself is always left-aligned inside the bubble
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            m.text,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(color: fg),
                                          ),
                                        ),
                                      ),
                                      if (label.isNotEmpty)
                                        Positioned(
                                          right: 10,
                                          bottom: 6,
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSentByMe
                                                  ? scheme.onPrimary.withValues(
                                                      alpha: 0.9,
                                                    )
                                                  : scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },

                      // Custom wrapper (no ChatMessage) so the library can't add its own outer time
                      chatMessageBuilder:
                          (
                            context,
                            message,
                            index,
                            animation,
                            child, {
                            isRemoved,
                            required bool isSentByMe,
                            groupStatus,
                          }) {
                            final meta = message.metadata ?? const {};
                            final showAvatar =
                                !isSentByMe &&
                                (groupStatus == null || groupStatus.isFirst);
                            final showName =
                                !isSentByMe &&
                                (groupStatus == null || groupStatus.isFirst) &&
                                (meta['senderName'] != null);

                            final ctrl = context.read<ChatController>();
                            final messages = ctrl.messages;
                            DateTime? previousTime;
                            if (index > 0) {
                              previousTime = messages[index - 1].resolvedTime;
                            }
                            final needDateHeader = _needsDateHeader(
                              previousTime,
                              message.resolvedTime,
                            );

                            final bubbleRow = Row(
                              mainAxisAlignment: isSentByMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isSentByMe)
                                  _AvatarSlot(
                                    show: showAvatar,
                                    userId: message.authorId,
                                  ),
                                if (!isSentByMe) const SizedBox(width: 4),
                                // Do not wrap with Flexible so bubble sizes to content
                                child,
                                // No extra right padding for outgoing messages
                              ],
                            );

                            return SizeTransition(
                              sizeFactor: animation,
                              child: Padding(
                                // Make grouped messages appear closer together
                                padding: EdgeInsets.only(
                                  top:
                                      (groupStatus != null &&
                                          (groupStatus.isMiddle ||
                                              groupStatus.isLast))
                                      ? 2
                                      : 4,
                                  bottom:
                                      (groupStatus != null &&
                                          (groupStatus.isMiddle ||
                                              groupStatus.isLast))
                                      ? 2
                                      : 4,
                                  left: 8,
                                  // Remove right padding for outgoing messages
                                  right: isSentByMe ? 0 : 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (needDateHeader)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: _DateHeader(
                                          date: message.resolvedTime,
                                        ),
                                      ),
                                    if (showName)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 44,
                                            bottom: 2,
                                          ),
                                          child: _AuthorName(
                                            userId: message.authorId,
                                            overrideName:
                                                meta['senderName'] as String? ??
                                                _userHints[message
                                                    .authorId]?['name'],
                                          ),
                                        ),
                                      ),
                                    bubbleRow,
                                  ],
                                ),
                              ),
                            );
                          },

                      imageMessageBuilder:
                          (
                            context,
                            m,
                            index, {
                            required bool isSentByMe,
                            groupStatus,
                          }) {
                            return GestureDetector(
                              onTap: () => _openImageViewer(context, m.source),
                              child: _MediaBubble(
                                isSentByMe: isSentByMe,
                                time: m.resolvedTime,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _NetworkImageWithLoader(
                                    url: m.source,
                                    width: 220,
                                    height: 220,
                                  ),
                                ),
                              ),
                            );
                          },

                      fileMessageBuilder:
                          (
                            context,
                            m,
                            index, {
                            required bool isSentByMe,
                            groupStatus,
                          }) {
                            final scheme = Theme.of(context).colorScheme;
                            final isPdf =
                                (m.mimeType ?? '').contains('pdf') ||
                                m.name.toLowerCase().endsWith('.pdf');
                            return _MediaBubble(
                              isSentByMe: isSentByMe,
                              time: m.resolvedTime,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 100,
                                  maxWidth: 300,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    22,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSentByMe
                                        ? scheme.primary
                                        : scheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isPdf
                                            ? Icons.picture_as_pdf
                                            : Icons.insert_drive_file,
                                        color: isSentByMe
                                            ? scheme.onPrimary
                                            : scheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              m.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: isSentByMe
                                                    ? scheme.onPrimary
                                                    : scheme.onSurface,
                                              ),
                                            ),
                                            if (m.mimeType != null)
                                              Text(
                                                m.mimeType!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isSentByMe
                                                      ? scheme.onPrimary
                                                            .withValues(
                                                              alpha: 0.8,
                                                            )
                                                      : scheme.onSurfaceVariant,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _handleFileOpen(
                                          context,
                                          m.source,
                                          m.mimeType,
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isSentByMe
                                              ? scheme.onPrimary
                                              : scheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: Icon(
                                          Icons.open_in_new,
                                          size: 18,
                                          color: scheme.onPrimary,
                                        ),
                                        label: Text(
                                          'Open',
                                          style: TextStyle(
                                            color: scheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                    ),
                    resolveUser: (UserID id) async {
                      if (profile != null && profile.uid == id) {
                        return User(
                          id: id,
                          name: profile.name,
                          imageSource: profile.photoUrl,
                        );
                      }
                      try {
                        final fs = ref.read(firestoreProvider);
                        final snap = await fs.collection('users').doc(id).get();
                        if (snap.exists) {
                          final data = snap.data() as Map<String, dynamic>;
                          return User(
                            id: id,
                            name: data['name'] as String?,
                            imageSource: data['photoUrl'] as String?,
                          );
                        }
                      } catch (_) {}
                      final hint = _userHints[id];
                      return User(
                        id: id,
                        name: hint?['name'],
                        imageSource: hint?['photoUrl'],
                      );
                    },
                    theme: ChatTheme.fromThemeData(Theme.of(context)),
                  ),
                ),
              ),

              // Bottom-anchored composer; expands with keyboard
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: _Composer(
                    onSend: (text) async {
                      final txt = text.trim();
                      if (txt.isEmpty || authUser == null) return false;
                      await ref
                          .read(chatRepositoryProvider)
                          .sendText(
                            groupId: widget.groupId,
                            uid: authUser.uid,
                            text: txt,
                            senderName: profile?.name,
                            senderPhotoUrl: profile?.photoUrl,
                          );
                      return true;
                    },
                    onAttachment: () => _handleAttachmentTap(ref),
                    pending: _pending,
                    isSendingAttachment: _isSendingAttachment,
                    onRemoveAttachment: () {
                      setState(() => _pending.clear());
                    },
                    onSendAttachment: () async {
                      if (_pending.isEmpty || authUser == null) return;
                      setState(() => _isSendingAttachment = true);
                      try {
                        final repo = ref.read(chatRepositoryProvider);
                        for (final att in List<_PendingAttachment>.from(
                          _pending,
                        )) {
                          final isImage =
                              att.mime?.startsWith('image/') ?? false;
                          if (isImage) {
                            await repo.sendImage(
                              groupId: widget.groupId,
                              uid: authUser.uid,
                              file: att.file,
                              senderName: profile?.name,
                              senderPhotoUrl: profile?.photoUrl,
                            );
                          } else {
                            await repo.sendFile(
                              groupId: widget.groupId,
                              uid: authUser.uid,
                              file: att.file,
                              mimeType: att.mime,
                              senderName: profile?.name,
                              senderPhotoUrl: profile?.photoUrl,
                            );
                          }
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSendingAttachment = false;
                            _pending.clear();
                          });
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
        error: (e, st) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _handleAttachmentTap(WidgetRef ref) async {
    // Bottom sheet to pick type
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photos from library (multi-select)'),
              onTap: () => Navigator.of(ctx).pop('images'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF document'),
              onTap: () => Navigator.of(ctx).pop('pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == 'images') {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(maxWidth: 2000);
      if (picked.isEmpty) return;
      setState(() {
        _pending
          ..clear()
          ..addAll(
            picked.map((x) {
              final f = File(x.path);
              final isPng = x.path.toLowerCase().endsWith('.png');
              return _PendingAttachment(
                file: f,
                mime: 'image/${isPng ? 'png' : 'jpeg'}',
                name: x.name,
                preview: FileImage(f),
              );
            }),
          );
      });
    } else if (choice == 'camera') {
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
      );
      if (shot == null) return;
      // Instant send like WhatsApp
      final authUser = ref.read(authStateChangesProvider).value;
      final profile = ref.read(userProfileProvider).value;
      if (authUser == null) return;
      await ref
          .read(chatRepositoryProvider)
          .sendImage(
            groupId: widget.groupId,
            uid: authUser.uid,
            file: File(shot.path),
            senderName: profile?.name,
            senderPhotoUrl: profile?.photoUrl,
          );
    } else if (choice == 'pdf') {
      // iOS requires UTI for PDF picking
      final typeGroup = const XTypeGroup(
        label: 'PDF',
        extensions: ['pdf'],
        uniformTypeIdentifiers: ['com.adobe.pdf'],
      );
      final xfile = await openFile(acceptedTypeGroups: [typeGroup]);
      if (xfile == null) return;
      if (!xfile.path.toLowerCase().endsWith('.pdf')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a PDF file')),
          );
        }
        return;
      }
      setState(() {
        _pending
          ..clear()
          ..add(
            _PendingAttachment(
              file: File(xfile.path),
              mime: 'application/pdf',
              name: xfile.name,
            ),
          );
      });
    }
  }

  bool _needsDateHeader(DateTime? previous, DateTime? current) {
    if (current == null) return false;
    if (previous == null) return true;
    return previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day;
  }
}

class _AvatarSlot extends ConsumerWidget {
  const _AvatarSlot({required this.show, required this.userId});
  final bool show;
  final String userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 40,
      child: show ? _Avatar(userId: userId) : const SizedBox.shrink(),
    );
  }
}

class _Avatar extends ConsumerWidget {
  const _Avatar({required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolve = context.read<ResolveUserCallback>();
    final futureUser = resolve(
      userId,
    ).then((u) => u ?? const User(id: 'unknown'));
    return FutureBuilder<User>(
      future: futureUser,
      builder: (ctx, snap) {
        final u = snap.data;
        final metaHints = context
            .findAncestorStateOfType<_ChatScreenState>()
            ?._userHints[userId];
        final img = (metaHints?['photoUrl']?.isNotEmpty == true)
            ? metaHints!['photoUrl']
            : u?.imageSource;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            radius: 16,
            backgroundImage: (img != null && img.isNotEmpty)
                ? NetworkImage(img)
                : null,
            child: (img == null || img.isEmpty)
                ? Text(
                    ((metaHints?['name']?.isNotEmpty == true)
                        ? metaHints!['name']!.substring(0, 1)
                        : (u?.name?.isNotEmpty == true
                              ? u!.name!.substring(0, 1)
                              : '?')),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _AuthorName extends ConsumerWidget {
  const _AuthorName({required this.userId, this.overrideName});
  final String userId;
  final String? overrideName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolve = context.read<ResolveUserCallback>();
    return FutureBuilder<User>(
      future: resolve(userId).then((u) => u ?? const User(id: 'unknown')),
      builder: (ctx, snap) {
        final name = overrideName ?? snap.data?.name ?? '';
        if (name.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}

void _openImageViewer(BuildContext context, String url) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Hero(
                tag: url,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _launchExternal(url);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _handleFileOpen(
  BuildContext context,
  String url,
  String? mime,
) async {
  // Always prefer the device's native viewer for robustness (esp. PDFs)
  await _launchExternal(url);
}

Future<void> _launchExternal(String url) async {
  try {
    final uri = Uri.parse(url);
    // Try external app first
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    }
    // Fallback to in-app browser view (CustomTabs/SafariVC)
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    // swallow
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.onSend,
    required this.onAttachment,
    required this.pending,
    required this.isSendingAttachment,
    required this.onRemoveAttachment,
    required this.onSendAttachment,
  });
  final Future<bool> Function(String text) onSend; // return true to clear
  final VoidCallback onAttachment;
  final List<_PendingAttachment> pending;
  final bool isSendingAttachment;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSendAttachment;
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();
  bool _sending = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.pending.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < widget.pending.length; i++)
                          _PendingThumb(
                            att: widget.pending[i],
                            onRemove: widget.isSendingAttachment
                                ? null
                                : () {
                                    setState(() => widget.pending.removeAt(i));
                                  },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: widget.isSendingAttachment
                              ? null
                              : widget.onRemoveAttachment,
                          child: Text(
                            'Clear',
                            style: TextStyle(color: scheme.onPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: widget.isSendingAttachment
                              ? null
                              : widget.onSendAttachment,
                          child: widget.isSendingAttachment
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : Text('Send ${widget.pending.length}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onAttachment,
                    icon: const Icon(Icons.attach_file),
                  ),
                  IconButton(
                    onPressed: _sending
                        ? null
                        : () async {
                            final text = _controller.text;
                            setState(() => _sending = true);
                            try {
                              final clear = await widget.onSend(text);
                              if (clear) _controller.clear();
                            } finally {
                              if (mounted) setState(() => _sending = false);
                            }
                          },
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaBubble extends StatelessWidget {
  const _MediaBubble({
    required this.child,
    required this.time,
    required this.isSentByMe,
  });
  final Widget child;
  final DateTime? time;
  final bool isSentByMe;
  @override
  Widget build(BuildContext context) {
    final t = time?.toLocal();
    final label = t != null ? TimeOfDay.fromDateTime(t).format(context) : '';
    return Stack(
      children: [
        // Ensure space for bottom-right timestamp overlay for media
        Padding(
          padding: EdgeInsets.only(bottom: label.isNotEmpty ? 22 : 0),
          child: child,
        ),
        if (label.isNotEmpty)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});
  final DateTime? date;
  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date!.year, date!.month, date!.day);
    final yesterday = today.subtract(const Duration(days: 1));
    String label;
    if (d == today) {
      label = 'Today';
    } else if (d == yesterday) {
      label = 'Yesterday';
    } else {
      label = '${date!.day}.${date!.month}.${date!.year}';
    }
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Internal model for attachments queued in the composer.
class _PendingAttachment {
  _PendingAttachment({required this.file, this.mime, this.name, this.preview});
  final File file;
  final String? mime;
  final String? name;
  final ImageProvider? preview;
}

/// Small thumbnail tile used in the composer for pending attachments.
class _PendingThumb extends StatelessWidget {
  const _PendingThumb({required this.att, this.onRemove});
  final _PendingAttachment att;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isImage = (att.mime ?? '').startsWith('image/');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: scheme.surfaceContainerHighest,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: isImage && att.preview != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(image: att.preview!, fit: BoxFit.cover),
                )
              : Icon(
                  (att.mime ?? '').contains('pdf')
                      ? Icons.picture_as_pdf
                      : Icons.insert_drive_file,
                ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.onError),
                ),
                child: Icon(Icons.close, size: 14, color: scheme.onError),
              ),
            ),
          ),
      ],
    );
  }
}

class _PdfPreview extends StatefulWidget {
  const _PdfPreview({required this.url, required this.onOpenExternal});
  final String url;
  final VoidCallback onOpenExternal;
  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _NetworkImageWithLoader extends StatelessWidget {
  const _NetworkImageWithLoader({required this.url, this.width, this.height});
  final String url;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final pct = progress.expectedTotalBytes != null
            ? (progress.cumulativeBytesLoaded / progress.expectedTotalBytes!)
            : null;
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(0),
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: pct),
                if (pct != null)
                  Text(
                    '${(pct * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11),
                  ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Icon(Icons.broken_image, size: 40),
      ),
    );
  }
}

class _PdfPreviewState extends State<_PdfPreview> {
  PdfControllerPinch? _controller;
  bool _error = false;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      debugPrint('Loading PDF from ${widget.url}');
      final resp = await http.get(Uri.parse(widget.url));
      if (resp.statusCode == 200) {
        final doc = await PdfDocument.openData(resp.bodyBytes);
        if (mounted) {
          setState(() {
            _controller = PdfControllerPinch(document: Future.value(doc));
            _loading = false;
          });
        }
      } else {
        if (mounted)
          setState(() {
            _error = true;
            _loading = false;
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _error = true;
          _loading = false;
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _error
                  ? const Center(
                      child: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                        size: 48,
                      ),
                    )
                  : (_loading || _controller == null)
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : PdfViewPinch(
                      controller: _controller!,
                      onDocumentError: (e) => setState(() => _error = true),
                    ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    onPressed: widget.onOpenExternal,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
