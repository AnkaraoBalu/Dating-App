import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatImageViewer extends StatelessWidget {
  const ChatImageViewer({
    super.key,
    required this.image,
    this.localFile = false,
  });
  final String image;
  final bool localFile;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text('Shared photo'),
    ),
    body: Center(
      child: InteractiveViewer(
        child: localFile
            ? Image.file(File(image), fit: BoxFit.contain)
            : image.startsWith('http')
            ? Image.network(image, fit: BoxFit.contain)
            : Image.asset(image, fit: BoxFit.contain),
      ),
    ),
  );
}
