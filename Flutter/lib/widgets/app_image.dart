import 'dart:typed_data';

import 'package:beltei_app/data/firebase/media_store.dart';
import 'package:flutter/material.dart';

/// Displays network images and Firestore-backed `firestore-media://` URLs.
class AppImage extends StatefulWidget {
  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder;

  @override
  State<AppImage> createState() => _AppImageState();
}

class _AppImageState extends State<AppImage> {
  static final _mediaStore = MediaStore();
  Future<Uint8List?>? _mediaFuture;

  @override
  void initState() {
    super.initState();
    _loadMediaFuture();
  }

  @override
  void didUpdateWidget(covariant AppImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadMediaFuture();
    }
  }

  void _loadMediaFuture() {
    final mediaId = MediaStore.mediaIdFromUrl(widget.url);
    _mediaFuture = mediaId == null ? null : _mediaStore.readBytes(mediaId);
  }

  @override
  Widget build(BuildContext context) {
    final mediaId = MediaStore.mediaIdFromUrl(widget.url);
    if (mediaId != null) {
      return FutureBuilder<Uint8List?>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                width: widget.width,
                height: widget.height,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return _error(context, null, null);
          }
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: _error,
          );
        },
      );
    }

    return Image.network(
      widget.url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: _error,
    );
  }

  Widget _error(BuildContext context, Object? error, StackTrace? stackTrace) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, stackTrace);
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const ColoredBox(
        color: Colors.black12,
        child: Icon(Icons.broken_image, size: 32),
      ),
    );
  }
}
