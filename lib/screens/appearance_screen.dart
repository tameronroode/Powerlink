import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  // This holds the theme choice before the user confirms it.
  late ThemeMode _selectedThemeMode;

  @override
  void initState() {
    super.initState();
    // Initialize the selection with the app's current theme.
    _selectedThemeMode = context.read<ThemeService>().themeMode;
  }

  void _applyTheme() {
    // Get the ThemeService without listening to changes.
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    // Apply the chosen theme.
    themeService.setTheme(_selectedThemeMode);
    
    // Go back to the previous screen (Settings).
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8.0),
              children: [
                _buildThemeOption(
                  context,
                  title: 'Light Mode',
                  value: ThemeMode.light,
                ),
                _buildThemeOption(
                  context,
                  title: 'Dark Mode',
                  value: ThemeMode.dark,
                ),
                _buildThemeOption(
                  context,
                  title: 'System Default',
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
          // Add the Apply button at the bottom
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyTheme,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Apply Change'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    {
    required String title,
    required ThemeMode value,
  }) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      value: value,
      groupValue: _selectedThemeMode, // The group value is now the temporary state
      onChanged: (newValue) {
        // When a radio button is tapped, only update the temporary state.
        setState(() {
          _selectedThemeMode = newValue!;
        });
      },
      activeColor: Theme.of(context).primaryColor,
    );
  }
}
