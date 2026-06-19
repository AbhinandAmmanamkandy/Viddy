import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viddy Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BrowserScreen(),
    );
  }
}

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  double _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              if (!_focusNode.hasFocus) {
                _urlController.text = url;
              }
            });
          },
          onPageFinished: (String url) async {
            final canBack = await _controller.canGoBack();
            final canForward = await _controller.canGoForward();
            setState(() {
              _isLoading = false;
              if (!_focusNode.hasFocus) {
                _urlController.text = url;
              }
              _canGoBack = canBack;
              _canGoForward = canForward;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.google.com'));

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _urlController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _urlController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadUrl() {
    String url = _urlController.text.trim();
    if (url.isNotEmpty) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        if (!url.contains('.')) {
          url = 'https://www.google.com/search?q=$url';
        } else {
          url = 'https://$url';
        }
      }
      _controller.loadRequest(Uri.parse(url));
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading && _progress < 1.0)
              LinearProgressIndicator(
                value: _progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        height: 64,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: _canGoBack ? () => _controller.goBack() : null,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward, size: 20),
              onPressed: _canGoForward ? () => _controller.goForward() : null,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _controller.reload(),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(Icons.home, size: 20),
              onPressed: () => _controller.loadRequest(Uri.parse('https://www.google.com')),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _urlController,
                  focusNode: _focusNode,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search or type URL',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onSubmitted: (value) => _loadUrl(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, size: 20),
              onPressed: _loadUrl,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ),
    );
  }
}
