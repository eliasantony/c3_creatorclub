import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Full-screen, swipeable image gallery for room photos.
class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.title,
  });

  final List<String> photos;
  final int initialIndex;
  final String? title;

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late final PageController _controller;
  late int _index;
  late TransformationController _transformController;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.photos.isEmpty ? 0 : widget.photos.length - 1;
    _index = widget.initialIndex.clamp(0, maxIndex);
    _controller = PageController(initialPage: _index);
    _transformController = TransformationController();
  }

  @override
  void dispose() {
    _transformController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            if (widget.title != null)
              Expanded(
                child: Text(
                  widget.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (widget.title != null) const SizedBox(width: 8),
            Text(
              total > 0 ? '${(_index + 1).clamp(1, total)} / $total' : '',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          // Allow quick swipe-down to dismiss
          if ((details.primaryVelocity ?? 0) > 500) {
            Navigator.of(context).maybePop();
          }
        },
        child: PageView.builder(
          controller: _controller,
          itemCount: total,
          physics: _isZoomed
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          onPageChanged: (i) {
            setState(() {
              _index = i;
              _isZoomed = false;
              _transformController.value = Matrix4.identity();
            });
          },
          itemBuilder: (context, i) {
            final url = widget.photos[i];
            return Center(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 4.0,
                clipBehavior: Clip.none,
                onInteractionUpdate: (details) {
                  final m = _transformController.value;
                  // Approximate scale from matrix
                  final currentScale = m.getMaxScaleOnAxis();
                  final zoomed = currentScale > 1.01; // tolerate tiny deltas
                  if (zoomed != _isZoomed) {
                    setState(() => _isZoomed = zoomed);
                  }
                },
                onInteractionEnd: (details) {
                  final currentScale = _transformController.value
                      .getMaxScaleOnAxis();
                  if (currentScale <= 1.01 && _isZoomed) {
                    setState(() => _isZoomed = false);
                  }
                },
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 150),
                  placeholder: (c, _) => const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                  errorWidget: (c, _, __) => const Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 48,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
