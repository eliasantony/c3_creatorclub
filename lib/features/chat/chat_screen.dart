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
  File? _pendingFile;
  String? _pendingMime;
  String? _pendingName;
  ImageProvider? _pendingImageProvider;
  bool _isSendingAttachment = false;
  final Map<String, Map<String, String?>> _userHints =
      {}; // {uid: {name, photoUrl}}

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));
    final authUser = ref.watch(authStateChangesProvider).value;
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(widget.group?.name ?? 'Chat')),
      body: messagesAsync.when(
        data: (msgs) {
          // Build user hints from latest messages (senderName/senderPhotoUrl fields in Firestore)
          _userHints.clear();
          for (final m in msgs.reversed) {
            if (m is TextMessage || m is ImageMessage || m is FileMessage) {
              // Can't access metadata since not set; we will add extraction later if we include it
              // For now hints come from Firestore snapshot via resolve below (fallback no-op)
            }
          }
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
          return Chat(
            chatController: controller,
            currentUserId: currentUserId,
            onMessageSend: (text) async {
              final txt = text.trim();
              if (txt.isEmpty || authUser == null) return;
              await ref
                  .read(chatRepositoryProvider)
                  .sendText(
                    groupId: widget.groupId,
                    uid: authUser.uid,
                    text: txt,
                    senderName: profile?.name,
                    senderPhotoUrl: profile?.photoUrl,
                  );
            },
            onAttachmentTap: () => _handleAttachmentTap(ref),
            builders: Builders(
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
                    final controller = context.read<ChatController>();
                    final messages = controller.messages;
                    DateTime? previousTime;
                    if (index > 0)
                      previousTime = messages[index - 1].resolvedTime;
                    final needDateHeader = _needsDateHeader(
                      previousTime,
                      message.resolvedTime,
                    );
                    return ChatMessage(
                      message: message,
                      index: index,
                      animation: animation,
                      isRemoved: isRemoved,
                      groupStatus: groupStatus,
                      headerWidget: needDateHeader
                          ? _DateHeader(date: message.resolvedTime)
                          : null,
                      leadingWidget: !isSentByMe
                          ? _AvatarSlot(
                              show: showAvatar,
                              userId: message.authorId,
                            )
                          : null,
                      topWidget: showName
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 2,
                                ),
                                child: _AuthorName(
                                  userId: message.authorId,
                                  overrideName:
                                      meta['senderName'] as String? ??
                                      _userHints[message.authorId]?['name'],
                                ),
                              ),
                            )
                          : null,
                      child: child,
                    );
                  },
              imageMessageBuilder:
                  (context, m, index, {required bool isSentByMe, groupStatus}) {
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
                  (context, m, index, {required bool isSentByMe, groupStatus}) {
                    final scheme = Theme.of(context).colorScheme;
                    return GestureDetector(
                      onTap: () =>
                          _handleFileOpen(context, m.source, m.mimeType),
                      child: _MediaBubble(
                        isSentByMe: isSentByMe,
                        time: m.resolvedTime,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 260),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSentByMe
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                color: isSentByMe
                                    ? scheme.onPrimary
                                    : scheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      m.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSentByMe
                                            ? scheme.onPrimary
                                            : scheme.onSurface,
                                      ),
                                    ),
                                    if (m.mimeType != null)
                                      Text(
                                        m.mimeType!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSentByMe
                                              ? scheme.onPrimary.withValues(
                                                  alpha: 0.8,
                                                )
                                              : scheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.download,
                                size: 18,
                                color: isSentByMe
                                    ? scheme.onPrimary
                                    : scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
              composerBuilder: (context) => _Composer(
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
                pendingFile: _pendingFile,
                pendingName: _pendingName,
                pendingMime: _pendingMime,
                pendingImageProvider: _pendingImageProvider,
                isSendingAttachment: _isSendingAttachment,
                onRemoveAttachment: () {
                  setState(() {
                    _pendingFile = null;
                    _pendingMime = null;
                    _pendingName = null;
                    _pendingImageProvider = null;
                  });
                },
                onSendAttachment: () async {
                  if (_pendingFile == null || authUser == null) return;
                  setState(() => _isSendingAttachment = true);
                  try {
                    final repo = ref.read(chatRepositoryProvider);
                    final isImage =
                        (_pendingMime?.startsWith('image/') ?? false);
                    if (isImage) {
                      await repo.sendImage(
                        groupId: widget.groupId,
                        uid: authUser.uid,
                        file: _pendingFile!,
                        senderName: profile?.name,
                        senderPhotoUrl: profile?.photoUrl,
                      );
                    } else {
                      await repo.sendFile(
                        groupId: widget.groupId,
                        uid: authUser.uid,
                        file: _pendingFile!,
                        mimeType: _pendingMime,
                        senderName: profile?.name,
                        senderPhotoUrl: profile?.photoUrl,
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSendingAttachment = false;
                        _pendingFile = null;
                        _pendingMime = null;
                        _pendingName = null;
                        _pendingImageProvider = null;
                      });
                    }
                  }
                },
              ),
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
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo from library'),
              onTap: () => Navigator.of(ctx).pop('image'),
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

    if (choice == 'image') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
      );
      if (picked == null) return;
      final file = File(picked.path);
      setState(() {
        _pendingFile = file;
        _pendingMime =
            'image/${picked.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'}';
        _pendingName = picked.name;
        _pendingImageProvider = FileImage(file);
      });
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
        _pendingFile = File(xfile.path);
        _pendingMime = 'application/pdf';
        _pendingName = xfile.name;
        _pendingImageProvider = null;
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
  if (mime != null && mime.contains('pdf')) {
    // In-app PDF preview
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) =>
          _PdfPreview(url: url, onOpenExternal: () => _launchExternal(url)),
    );
    return;
  }
  await _launchExternal(url);
}

Future<void> _launchExternal(String url) async {
  try {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // swallow
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.onSend,
    required this.onAttachment,
    required this.pendingFile,
    required this.pendingName,
    required this.pendingMime,
    required this.pendingImageProvider,
    required this.isSendingAttachment,
    required this.onRemoveAttachment,
    required this.onSendAttachment,
  });
  final Future<bool> Function(String text) onSend; // return true to clear
  final VoidCallback onAttachment;
  final File? pendingFile;
  final String? pendingName;
  final String? pendingMime;
  final ImageProvider? pendingImageProvider;
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
            if (widget.pendingFile != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          (widget.pendingMime?.startsWith('image/') ?? false) &&
                              widget.pendingImageProvider != null
                          ? Image(
                              image: widget.pendingImageProvider!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              color: scheme.primaryContainer,
                              child: Icon(
                                widget.pendingMime == 'application/pdf'
                                    ? Icons.picture_as_pdf
                                    : Icons.insert_drive_file,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.pendingName ??
                                widget.pendingFile!.path.split('/').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.pendingMime ?? 'attachment',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.isSendingAttachment
                          ? null
                          : widget.onRemoveAttachment,
                      icon: const Icon(Icons.close),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: widget.isSendingAttachment
                          ? null
                          : widget.onSendAttachment,
                      child: widget.isSendingAttachment
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send'),
                    ),
                  ],
                ),
              ),
            Row(
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
        child,
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
  PdfController? _controller;
  bool _error = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await http.get(Uri.parse(widget.url));
      if (resp.statusCode == 200) {
        final doc = await PdfDocument.openData(resp.bodyBytes);
        if (mounted) {
          setState(() {
            _controller = PdfController(document: Future.value(doc));
          });
        }
      } else {
        if (mounted) setState(() => _error = true);
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
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
              child: _error || _controller == null
                  ? const Center(
                      child: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                        size: 48,
                      ),
                    )
                  : PdfView(
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
