import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({Key? key}) : super(key: key);

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0C1611))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://crossfit1000hills.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14221A),
        title: const Text('CrossFit 1000 Hills Web',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF84CC16)),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF84CC16),
              ),
            ),
        ],
      ),
    );
  }
}
