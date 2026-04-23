import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StitchViewer extends StatefulWidget {
  final String path;

  const StitchViewer({super.key, required this.path});

  @override
  State<StitchViewer> createState() => _StitchViewerState();
}

class _StitchViewerState extends State<StitchViewer> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFile(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: controller),
    );
  }
}