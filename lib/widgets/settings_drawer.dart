import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class SettingsDrawer extends StatefulWidget {
  final Function(String, String) onSaveCompleted;

  const SettingsDrawer({Key? key, required this.onSaveCompleted}) : super(key: key);

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  final TextEditingController _localController = TextEditingController();
  final TextEditingController _publicController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localController.text = prefs.getString(AppConstants.keyLocalUrl) ?? AppConstants.defaultLocalUrl;
      _publicController.text = prefs.getString(AppConstants.keyPublicUrl) ?? AppConstants.defaultPublicUrl;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String local = _localController.text.trim();
    String public = _publicController.text.trim();
    
    // Ensure protocol is present
    if (local.isNotEmpty && !local.startsWith('http')) {
      local = 'http://$local'; // Default to http for local
    }
    if (public.isNotEmpty && !public.startsWith('http')) {
      public = 'https://$public'; // Default to https for public
    }

    _localController.text = local;
    _publicController.text = public;

    await prefs.setString(AppConstants.keyLocalUrl, local);
    await prefs.setString(AppConstants.keyPublicUrl, public);
    
    widget.onSaveCompleted(local, public);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully! Reloading...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Close drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: const Text(
                  "Remote Config", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                ),
                accountEmail: const Text("Manage Web Connections"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.settings_remote, size: 40, color: theme.colorScheme.primary),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Local Connection", 
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _localController,
                      decoration: InputDecoration(
                        labelText: "Local URL",
                        hintText: "http://192.168.1.1",
                        helperText: "For internal network access",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lan),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Public Connection", 
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _publicController,
                      decoration: InputDecoration(
                        labelText: "Public URL",
                        hintText: "https://example.com",
                        helperText: "For external internet access",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.public),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text("Save & Apply Settings"),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
