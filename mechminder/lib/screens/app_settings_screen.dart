import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../service/settings_provider.dart'; // Make sure this path is correct

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../screens/vehicle_list.dart';
import '../screens/todo_list_screen.dart';

import 'package:mechminder/service/subscription_provider.dart';





class AppSettingsScreen extends StatelessWidget {
  final GlobalKey<VehicleListScreenState> vehicleListKey;
  final GlobalKey<TodoListScreenState> allRemindersKey;
  final VoidCallback onShowTour; // NEW: Callback for tutorial

  const AppSettingsScreen({
    super.key,
    required this.vehicleListKey,
    required this.allRemindersKey,
    required this.onShowTour, // NEW: Required
  });






  // --- NEW: FUNCTION TO SHOW COLOR PICKER ---
  void _showColorPickerDialog(BuildContext context, SettingsProvider settings) {
    Color pickerColor = settings.primaryColor;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color; // Update the color in the dialog
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                settings.updatePrimaryColor(pickerColor); // Save to provider
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }



  // --- (Your Currency dialogs are unchanged) ---
  void _showUnitDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return SimpleDialog(
          title: const Text('Select Unit'),
          children: [
            RadioListTile<String>(
              title: const Text('Kilometers (km)'),
              value: 'km',
              groupValue: settings.unitType,
              onChanged: (String? value) {
                if (value != null) {
                  settings.updateUnit(value);
                }
                Navigator.of(ctx).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Miles (mi)'),
              value: 'mi',
              groupValue: settings.unitType,
              onChanged: (String? value) {
                if (value != null) {
                  settings.updateUnit(value);
                }
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyDialog(BuildContext context, SettingsProvider settings) {
    final Map<String, String> currencies = {
      '\$': 'Dollar (USD)',
      '₹': 'Rupee (INR)',
      '€': 'Euro (EUR)',
      '£': 'Pound (GBP)',
    };
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return SimpleDialog(
          title: const Text('Select Currency Symbol'),
          children: [
            for (var entry in currencies.entries)
              RadioListTile<String>(
                title: Text('${entry.value} (${entry.key})'),
                value: entry.key,
                groupValue: settings.currencySymbol,
                onChanged: (String? value) {
                  if (value != null) {
                    settings.updateCurrency(value);
                  }
                  Navigator.of(ctx).pop();
                },
              ),
            ListTile(
              title: const Text('Other...'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showCustomCurrencyDialog(context, settings);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCustomCurrencyDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final currencyController = TextEditingController(
      text: settings.currencySymbol,
    );
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Set Custom Symbol'),
          content: TextField(
            controller: currencyController,
            decoration: const InputDecoration(labelText: 'Symbol (e.g., ¥)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (currencyController.text.isNotEmpty) {
                  settings.updateCurrency(currencyController.text);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        scrollable:
            true, // IMPORTANT: Allows the whole dialog content to scroll
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '1. Introduction\n'
              'Welcome to MechMinder, a vehicle maintenance and management application developed by Krimal Techworks. We are committed to protecting your privacy. This Privacy Policy explains how MechMinder handles information.\n\n'
              'Crucially, MechMinder is a Cloud-Sync application. Your data is stored securely on our cloud servers and is linked to your device identifier to ensure seamless synchronization across your devices and reliable data restoration.\n\n'

              '2. Information We Collect\n'
              'Information you enter into MechMinder is stored securely on our cloud servers. This allows you to access your vehicle records from any device. The types of information stored include:\n\n'
              'Vehicle Information: Make, model, registration number, fuel type, and owner name.\n'
              'Maintenance Records: Service history, odometer readings, service costs, and notes.\n'
              'Financial Data: Fuel expenses and other vehicle-related costs.\n'
              'Reminders: Maintenance schedules and due dates.\n'
              'Documents & Photos: Images of your vehicle, service receipts, and vehicle papers (such as Insurance or PUC documents).\n'
              'Vendor Information: Names and contact details of your mechanics or service centers.\n\n'
              '3. How We Use Your Information\n'
              'Your data is used solely to provide the app\'s features to you, such as:\n\n'
              'Tracking your vehicle\'s service history and expenses.\n'
              'Calculating total spending on your vehicle.\n'
              'Sending you notifications for upcoming service reminders.\n'
              'Allowing you to export your data to Excel files.\n\n'
              '4. Permissions We Request\n'
              'To provide its full functionality, MechMinder may request the following permissions:\n\n'
              'Camera: To allow you to take photos of your vehicle, receipts, or documents.\n'
              'Storage/Media: To allow you to pick existing photos/documents from your gallery and to save exported Excel reports to your device.\n'
              'Notifications: To send you alerts for maintenance tasks and document expiry dates.\n'
              'Internet: Required for account authentication and synchronizing your records with the cloud.\n\n'
              '5. Data Security and Storage\n'
              'Your data is stored securely on our cloud servers. We use industry-standard security measures to protect your information.\n\n'

              'Data Retention: Data remains on our servers until you request deletion or delete your account context.\n'
              'User Control: You have full control over your data. You can add, edit, or delete any record at any time via the application.\n\n'

              '6. Third-Party Services\n'
              'MechMinder does not share your data with any third parties. If you use the "Share" feature within the app, you are manually choosing to send specific data to another application (like WhatsApp or Email) of your choice.\n\n'
              '7. Children’s Privacy\n'
              'MechMinder does not collect any personal information from anyone, including children under the age of 13.\n\n'
              '8. Changes to This Policy\n'
              'We may update our Privacy Policy from time to time. Any changes will be posted on this page with an updated "Last Updated" date.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --- UPDATED BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, SubscriptionProvider>(
      builder: (context, settings, subProvider, child) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [



            // --- PREFERENCES (UPDATED) ---
            const ListTile(
              title: Text(
                'Preferences',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            //Color Picker Tile
            ListTile(
              leading: Icon(Icons.color_lens, color: settings.primaryColor),
              title: const Text('App Color'),
              subtitle: const Text('Change the primary app color'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: settings.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              onTap: () {
                _showColorPickerDialog(context, settings);
              },
            ),

            // --- NEW: THEME BUTTON ---

            // --- END NEW ---
            ListTile(
              leading: Icon(Icons.straighten, color: settings.primaryColor),
              title: const Text('Units'),
              subtitle: Text(
                settings.unitType == 'km' ? 'Kilometers' : 'Miles',
              ),
              onTap: () {
                _showUnitDialog(context, settings);
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_money, color: settings.primaryColor),
              title: const Text('Currency'),
              subtitle: Text(settings.currencySymbol),
              onTap: () {
                _showCurrencyDialog(context, settings);
              },
            ),

            const Divider(),

            // --- HELP SECTION ---
            const ListTile(
              title: Text(
                'Help & Info',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: settings.primaryColor),
              title: const Text('App Tour'),
              subtitle: const Text('See what MechMinder can do'),
              onTap: () {
                // Trigger the home screen tutorial
                onShowTour();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.privacy_tip_outlined,
                color: settings.primaryColor,
              ),
              title: const Text('Privacy Policy'),
              subtitle: const Text('Data usage and protection'),
              onTap: () {
                _showPrivacyPolicyDialog(context);
              },
            ),
          ],
        );
      },
    );
  }
}
