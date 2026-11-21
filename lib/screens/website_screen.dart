import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

/// The gym's website inside the app, with a simple offline fallback.
class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  static const url = 'https://crossfit1000hills.com';

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _failed = false;

  bool get _webViewSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_webViewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.background)
        ..setNavigationDelegate(NavigationDelegate(
          onProgress: (p) => mounted ? setState(() => _progress = p) : null,
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) setState(() => _failed = true);
          },
        ))
        ..loadRequest(Uri.parse(WebsiteScreen.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CrossFit 1000 Hills'),
        actions: [
          if (_controller != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _failed = false);
                _controller!.reload();
              },
            ),
        ],
        bottom: _progress > 0 && _progress < 100
            ? PreferredSize(preferredSize: const Size.fromHeight(2), child: LinearProgressIndicator(value: _progress / 100, minHeight: 2))
            : null,
      ),
      body: _controller == null || _failed ? _about() : WebViewWidget(controller: _controller!),
    );
  }

  Widget _about() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('CrossFit 1000 Hills', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.lime)),
          const SizedBox(height: 12),
          const Text('The CrossFit box in Kigali. Push your limits with community, strength and endurance training.',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
          const SizedBox(height: 20),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.place, color: AppColors.lime), title: Text('Kigali, Rwanda')),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.mail, color: AppColors.lime), title: Text('info@crossfit1000hills.com')),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.public, color: AppColors.lime), title: Text(WebsiteScreen.url)),
          if (_failed) const Text('The website could not be loaded. Check your connection and tap refresh.', style: TextStyle(color: Colors.amber)),
        ],
      );
}
