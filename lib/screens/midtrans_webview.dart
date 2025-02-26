import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MidtransWebView extends StatefulWidget {
  final String snapUrl;

  const MidtransWebView({Key? key, required this.snapUrl}) : super(key: key);

  @override
  _MidtransWebViewState createState() => _MidtransWebViewState();
}

class _MidtransWebViewState extends State<MidtransWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Deteksi URL callback dari Midtrans
            if (request.url.contains("https://your-callback-url.com/success")) {
              Navigator.pop(context, true); // Pembayaran berhasil
            } else if (request.url.contains("https://your-callback-url.com/failure")) {
              Navigator.pop(context, false); // Pembayaran gagal
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran Midtrans"),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
