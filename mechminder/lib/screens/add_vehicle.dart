import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../service/api_service.dart';
import 'package:provider/provider.dart';
import '../service/settings_provider.dart';
import '../widgets/full_screen_photo_viewer.dart';
import '../service/notification_service.dart';
import '../service/vehicle_provider.dart';
import '../core/api_constants.dart';


class AddVehicleScreen extends StatefulWidget {
  final int? vehicleId;
  const AddVehicleScreen({super.key, this.vehicleId});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLERS ---
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _variantController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();

  String? _selectedFuelType;

  // --- PHOTO STATE ---
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _existingPhotos = []; // Photos already saved in DB
  final List<XFile> _newImageFiles = []; // Photos picked in this session
  // --- END PHOTO STATE ---

  bool _isEditMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.vehicleId != null;
    _purchaseDateController.text = DateTime.now().toIso8601String().split(
      'T',
    )[0];
    if (_isEditMode) {
      _loadVehicleData();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _purchaseDateController.dispose();
    _colorController.dispose();
    _regNoController.dispose();
    _ownerNameController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleData() async {
    try {
      final vehicle = await ApiService.getVehicleById(widget.vehicleId!);

      if (vehicle != null) {
        _makeController.text = vehicle['make'] ?? '';
        _modelController.text = vehicle['model'] ?? '';
        _variantController.text = vehicle['variant'] ?? '';
        _purchaseDateController.text = vehicle['purchase_date'] ?? '';
        _selectedFuelType = vehicle['fuel_type'];
        _colorController.text = vehicle['vehicle_color'] ?? '';
        _regNoController.text = vehicle['reg_no'] ?? '';
        _ownerNameController.text = vehicle['owner_name'] ?? '';
        _odometerController.text = (vehicle['current_odometer'] ?? '')
            .toString();

        // Handle Photos from the API
        if (vehicle['Photos'] != null) {
          _existingPhotos = List<Map<String, dynamic>>.from(vehicle['Photos']);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vehicle from API: $e')),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  // --- PHOTO PICKER FUNCTION ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Optimized: Reduces 12MP photos to ~1MP
        imageQuality: 70, // Optimized: Good quality, typically 10x smaller file
      );
      if (pickedFile == null) return;
      setState(() {
        _newImageFiles.add(pickedFile);
      });
    } catch (e) {
      // Quietly fail image picking
    }
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final Map<String, String> fields = {
          'make': _makeController.text,
          'model': _modelController.text,
          'variant': _variantController.text,
          'purchase_date': _purchaseDateController.text,
          'fuel_type': _selectedFuelType ?? '',
          'vehicle_color': _colorController.text,
          'reg_no': _regNoController.text,
          'owner_name': _ownerNameController.text,
          'initial_odometer': _odometerController.text,
          'current_odometer': _odometerController.text,
        };

        dynamic result;
        final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);

        if (_isEditMode) {
          final int vehicleId = widget.vehicleId!;
          String? firstPhotoName;
          List<int>? firstPhotoBytes;

          if (_newImageFiles.isNotEmpty) {
            final file = File(_newImageFiles.first.path);
            firstPhotoBytes = await file.readAsBytes();
            firstPhotoName = p.basename(_newImageFiles.first.path);
          }

          await ApiService.updateVehicle(
            vehicleId,
            fields,
            photoName: firstPhotoName,
            photoBytes: firstPhotoBytes,
          );
          result = {'id': vehicleId}; 
        } else {
          List<int>? photoBytes;
          String? photoName;
          if (_newImageFiles.isNotEmpty) {
            photoBytes = await _newImageFiles.first.readAsBytes();
            photoName = _newImageFiles.first.name;
          }

          result = await ApiService.registerVehicle(
            fields,
            photoBytes: photoBytes,
            photoName: photoName,
          );
        }

        if (result != null && mounted) {
          // Refresh global state
          await vehicleProvider.syncAllData();

          final int currentOdo = int.tryParse(_odometerController.text) ?? 0;
          final settings = Provider.of<SettingsProvider>(context, listen: false);

          // Trigger local notification based on new cloud state
          await NotificationService().checkAndShowOdometerReminders(
            reminders: vehicleProvider.reminders.where((r) => r['vehicle_id'] == result['id']).toList(),
            currentOdometer: currentOdo,
            unitType: settings.unitType,
          );

          Navigator.of(context).pop();
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving vehicle: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = settings.primaryColor;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // --- MODERN INPUT DECORATION HELPER ---
    InputDecoration modernInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        title: Text(
          _isEditMode ? 'Edit Vehicle' : 'Add New Vehicle',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Vehicle Details", isDark),
                    const SizedBox(height: 16),

                    // --- ROW 1: BRAND ---
                    TextFormField(
                      controller: _makeController,
                      decoration: modernInputDecoration(
                        "Company",
                        Icons.directions_car,
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- ROW 2: MODEL ---
                    TextFormField(
                      controller: _modelController,
                      decoration: modernInputDecoration(
                        "Model",
                        Icons.directions_car_filled,
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- ROW 3: VARIANT & DATE ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _variantController,
                            decoration: modernInputDecoration(
                              "Variant (Opt)",
                              Icons.merge_type,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.tryParse(
                                      _purchaseDateController.text,
                                    ) ??
                                    DateTime.now(),
                                firstDate: DateTime(1950),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                _purchaseDateController.text = pickedDate
                                    .toIso8601String()
                                    .split('T')[0];
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _purchaseDateController,
                                decoration: modernInputDecoration(
                                  "Purchase Date",
                                  Icons.calendar_today,
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- ROW 4: COLOR & FUEL TYPE ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _colorController,
                            decoration: modernInputDecoration(
                              "Color",
                              Icons.palette,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedFuelType,
                            decoration: modernInputDecoration(
                              "Fuel Type",
                              Icons.local_gas_station,
                            ),
                            items:
                                [
                                      'Petrol',
                                      'Diesel',
                                      'Electric',
                                      'Hybrid',
                                      'CNG',
                                    ]
                                    .map(
                                      (label) => DropdownMenuItem(
                                        value: label,
                                        child: Text(label),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedFuelType = val),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Registration & Owner", isDark),
                    const SizedBox(height: 16),

                    // --- REG NO ---
                    TextFormField(
                      controller: _regNoController,
                      decoration: modernInputDecoration(
                        "Registration No.",
                        Icons.featured_video,
                      ),
                      textCapitalization:
                          TextCapitalization.characters, // Auto-caps
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- OWNER NAME ---
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: modernInputDecoration(
                        "Owner Name",
                        Icons.person,
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- ODOMETER ---
                    TextFormField(
                      controller: _odometerController,
                      decoration: modernInputDecoration(
                        _isEditMode ? 'Current Odometer' : 'Initial Odometer',
                        Icons.speed,
                      ).copyWith(suffixText: settings.unitType),
                      enabled: !_isEditMode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Gallery", isDark),
                    const SizedBox(height: 16),

                    // --- MODERN PHOTO PICKER ---
                    _buildPhotoPicker(isDark, primaryColor),
                  ],
                ),
              ),
            ),
          ),

          // --- STICKY BOTTOM BUTTON ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _saveVehicle,
                  child: Text(
                    _isEditMode ? 'UPDATE VEHICLE' : 'SAVE VEHICLE',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WRAPPERS ---
  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPicker(bool isDark, Color primaryColor) {
    return Column(
      children: [
        if (_existingPhotos.isEmpty && _newImageFiles.isEmpty)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade400,
                  style: BorderStyle.solid,
                ), // Dashed look simulated with grey
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap to add photos",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Add Button
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Center(
                      child: Icon(Icons.add, size: 40, color: primaryColor),
                    ),
                  ),
                ),
                // Existing Photos
                ..._existingPhotos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final photo = entry.value;
                  final String photoPath = photo['uri'] ?? '';
                  final String fullUrl = photoPath.startsWith('http')
                      ? photoPath
                      : '${ApiConstants.serverUrl}$photoPath';

                  return _buildPhotoItem(
                    Image.network(fullUrl, fit: BoxFit.cover),
                    () {
                      final paths = _existingPhotos
                          .map((p) {
                            final uri = p['uri'] ?? '';
                            return uri.startsWith('http')
                                ? uri
                                : '${ApiConstants.serverUrl}$uri';
                          })
                          .toList()
                          .cast<String>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenPhotoViewer(
                            photoPaths: paths,
                            initialIndex: index,
                            isNetwork: true,
                          ),
                        ),
                      );
                    },
                    () async {
                      final photoId = photo['id'];

                      if (photoId != null) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Photo'),
                            content: const Text(
                              'Are you sure you want to delete this photo from the server?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            await ApiService.deletePhoto(photoId);
                            setState(() {
                              _existingPhotos.removeAt(index);
                            });
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete photo: $e'),
                                ),
                              );
                            }
                          }
                        }
                      } else {
                        // This case should ideally not be hit for 'existingPhotos'
                        // as they are expected to have an ID from the backend.
                        // However, as a fallback, remove from UI if no ID.
                        setState(() {
                          _existingPhotos.removeAt(index);
                        });
                      }
                    },
                  );
                }),
                // New Photos
                ..._newImageFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return _buildPhotoItem(
                    Image.file(File(file.path), fit: BoxFit.cover),
                    null, // No full screen for unsaved yet, or could add
                    () {
                      setState(() {
                        _newImageFiles.removeAt(index);
                      });
                    },
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoItem(
    Widget imageWidget,
    VoidCallback? onTap,
    VoidCallback onDelete,
  ) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: imageWidget,
          ),
        ),
        Positioned(
          top: 4,
          right: 16, // Adjust for margin
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
