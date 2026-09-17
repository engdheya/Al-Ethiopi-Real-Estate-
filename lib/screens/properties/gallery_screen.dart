import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../core/utils/formatters.dart';
import '../../models/property.dart';

/// Full-screen gallery with pinch-to-zoom and swipe navigation.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  final List<PropertyImage> images;
  final int initialIndex;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ImageProvider _provider(String url) {
    if (url.startsWith('http')) {
      return CachedNetworkImageProvider(url);
    }
    if (url.startsWith('assets/')) {
      return AssetImage(url);
    }
    return FileImage(File(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${Formatters.toArabicDigits((_index + 1).toString())} / ${Formatters.toArabicDigits(widget.images.length.toString())}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: widget.images.isEmpty
          ? const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white54,
                size: 64,
              ),
            )
          : PhotoViewGallery.builder(
              pageController: _controller,
              itemCount: widget.images.length,
              onPageChanged: (int i) =>
                  setState(() => _index = i),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              builder: (BuildContext context, int i) {
                return PhotoViewGalleryPageOptions(
                  imageProvider:
                      _provider(widget.images[i].url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: 'property-image-$i',
                  ),
                );
              },
              loadingBuilder: (BuildContext context, ImageChunkEvent? e) =>
                  Center(
                child: CircularProgressIndicator(
                  value: e == null || e.expectedTotalBytes == null
                      ? null
                      : e.cumulativeBytesLoaded /
                          e.expectedTotalBytes!,
                ),
              ),
            ),
    );
  }
}
