import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../widgets/settings_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final WebViewController _localController;
  late final WebViewController _publicController;
  
  String _localUrl = AppConstants.defaultLocalUrl;
  String _publicUrl = AppConstants.defaultPublicUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
  }

  void _initializeControllers() {
    // Force Desktop User Agent to ensure login forms appear (avoids mobile site redirect issues)
    const String userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

    // Controller for Local Remote
    _localController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white) // Ensure white bg for login forms
      ..setUserAgent(userAgent) 
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
             debugPrint("Local Remote Error: ${error.description}");
          },
          // Handle HTTP Basic Auth (Pop-up Login)
          onHttpAuthRequest: (HttpAuthRequest request) {
            _showAuthDialog(request);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    // Controller for Public Remote
    _publicController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(userAgent)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
             debugPrint("Public Remote Error: ${error.description}");
          },
          // Handle HTTP Basic Auth (Pop-up Login)
          onHttpAuthRequest: (HttpAuthRequest request) {
            _showAuthDialog(request);
          },
          onNavigationRequest: (NavigationRequest request) {
             return NavigationDecision.navigate;
          },
        ),
      );
  }

  // Helper to show login dialog for Basic Auth
  Future<void> _showAuthDialog(HttpAuthRequest request) async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Login Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              request.onCancel();
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              request.onProceed(
                WebViewCredential(
                  user: usernameController.text,
                  password: passwordController.text,
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localUrl = prefs.getString(AppConstants.keyLocalUrl) ?? AppConstants.defaultLocalUrl;
      _publicUrl = prefs.getString(AppConstants.keyPublicUrl) ?? AppConstants.defaultPublicUrl;
      _isLoading = false;
    });
    
    // Clear cache to prevent stale session issues (ERR_CACHE_MISS often related)
    await _localController.clearCache();
    await _publicController.clearCache();

    // Initial Load
    try {
        _localController.loadRequest(Uri.parse(_localUrl));
    } catch (e) {
        debugPrint("Error loading local URL: $e");
    }
    
    try {
        _publicController.loadRequest(Uri.parse(_publicUrl));
    } catch (e) {
        debugPrint("Error loading public URL: $e");
    }
  }

  void _onSettingsSaved(String newLocal, String newPublic) {
    setState(() {
      _localUrl = newLocal;
      _publicUrl = newPublic;
    });
    
    // Reload URL if it changed
    _localController.loadRequest(Uri.parse(newLocal));
    _publicController.loadRequest(Uri.parse(newPublic));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: false, // Set to true if you want transparent app bar effect
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? "Remote Local Monitor" : "Remote Public Monitor",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reload Page",
            onPressed: () {
               if (_currentIndex == 0) {
                 _localController.reload();
               } else {
                 _publicController.reload();
               }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: SettingsDrawer(onSaveCompleted: _onSettingsSaved),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : IndexedStack(
            index: _currentIndex,
            children: [
              // Local Remote View
              WebViewWidget(controller: _localController),
              // Public Remote View
              WebViewWidget(controller: _publicController),
            ],
          ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lan_outlined),
            selectedIcon: Icon(Icons.lan, color: Colors.white),
            label: 'Local Remote',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public, color: Colors.white),
            label: 'Public Remote',
          ),
        ],
        elevation: 3.0,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary,
      ),
    );
  }
}
