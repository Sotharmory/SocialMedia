import 'dart:typed_data';

import 'package:flutter/material.dart';
class AvatarView extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const AvatarView({Key? key, this.imageUrl, this.imageBytes}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem Ảnh'),
      ),
      body: Center(
        child: imageUrl != null
            ? Image.network(
          imageUrl!,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Failed to load image');
          },
        )
            : imageBytes != null
            ? Image.memory(imageBytes!)
            : const Text('No image to display.'),
      ),
    );
  }
}