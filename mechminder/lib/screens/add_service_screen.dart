import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../service/api_service.dart';
import '../service/notification_service.dart';
import '../core/api_constants.dart';
import '../widgets/full_screen_photo_viewer.dart';
import 'package:provider/provider.dart';
import '../service/settings_provider.dart'; 
import '../service/vehicle_provider.dart';


// --- (UPDATED HELPER CLASS) ---
class ServiceItem {
  String name;
  double qty;
  double cost;
  int? templateId;
  int? intervalDays;
  int? intervalKm;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController costController = TextEditingController();

  ServiceItem({
    this.name = '',
    this.qty = 1.0,
    this.cost = 0.0,
    this.templateId,
    this.intervalDays,
    this.intervalKm,
  }) {
    nameController.text = name;
    // --- FIX 1: Show "1" instead of "1.0" ---
    qtyController.text = qty.toStringAsFixed(0);
    // --- FIX 2: Show "0" instead of "0.0" ---
    costController.text = cost.toStringAsFixed(0);
  }

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    costController.dispose();
  }
}
// --- End of helper class ---

class AddServiceScreen extends StatefulWidget {
  final int vehicleId;
  final int currentOdometer;
  final int? serviceId;
  const AddServiceScreen({
    super.key,
    required this.vehicleId,
    required this.currentOdometer,
    this.serviceId,
  });
  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // (Controllers)
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // (State for Dropdowns and Lists)
  List<Map<String, dynamic>> _allVendors = [];
  int? _selectedVendorId;
  List<Map<String, dynamic>> _allTemplates = [];
  final List<ServiceItem> _serviceItems = [ServiceItem()];
  int? _selectedTemplateId;

  // (State for Photos)
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _newImageFiles = [];
  List<Map<String, dynamic>> _existingPhotos = [];

  // (State for Loading/Editing)
  bool _isEditMode = false;
  bool _isLoading = true;
  bool _isLoadingVendors = true;
  bool _isLoadingTemplates = true;

  @override
  void initState() {
    super.initState();
    if (widget.serviceId != null) {
      _isEditMode = true;
      _loadServiceData();
    } else {
      _dateController.text = DateTime.now().toIso8601String().split('T')[0];
      _odometerController.text = widget.currentOdometer.toString();
      _loadDropdownData();
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- DATA LOADING FUNCTIONS ---
  Future<void> _loadDropdownData() async {
    final vendors = await ApiService.getVendors();
    final templates = await ApiService.getTemplates();
    setState(() {
      _allVendors = vendors.map((v) => Map<String, dynamic>.from(v)).toList();
      _allTemplates = templates
          .map((t) => Map<String, dynamic>.from(t))
          .toList();
      _isLoadingVendors = false;
      _isLoadingTemplates = false;
    });
  }

  Future<void> _loadServiceData() async {
    await _loadDropdownData();
    final service = await ApiService.getServiceById(widget.serviceId!);
    if (service == null) {
      /* (Error handling) */
      return;
    }
    _existingPhotos = List.from(service['Photos'] ?? []);
    final items = service['ServiceItems'] as List<dynamic>? ?? [];

    _serviceNameController.text = service['service_name'] ?? '';
    _dateController.text = service['service_date'] ?? '';
    _odometerController.text = (service['odometer'] ?? '').toString();
    _totalCostController.text = (service['total_cost'] ?? '').toString();
    _notesController.text = service['notes'] ?? '';
    _selectedVendorId = service['vendor_id'];

    _serviceItems.clear();
    if (items.isEmpty) {
      _serviceItems.add(ServiceItem());
    } else {
      for (var item in items) {
        _serviceItems.add(
          ServiceItem(
            name: item['name'],
            qty: (item['qty'] as num).toDouble(),
            cost: (item['unit_cost'] as num).toDouble(),
            templateId: item['template_id'],
          ),
        );
      }
    }
    setState(() {
      _isLoading = false;
      _updateTotalCost();
    });
  }

  // --- UI HELPER FUNCTIONS ---
  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = pickedDate.toIso8601String().split('T')[0];
      });
    }
  }

  void _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Optimized: Reduces 12MP photos to ~1MP
        imageQuality: 70, // Optimized: Good quality, typically 10x smaller file
      );
      if (pickedFile != null) {
        setState(() {
          _newImageFiles.add(pickedFile);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void _addPartFromTemplate() {
    // (This function is unchanged)
    if (_selectedTemplateId == null) {
      return;
    }
    final templateToAdd = _allTemplates.firstWhere(
      (t) => t['id'] == _selectedTemplateId,
    );
    _selectedTemplateId = null;
    setState(() {
      if (_serviceItems.length == 1 &&
          _serviceItems[0].nameController.text.isEmpty) {
        _serviceItems[0].nameController.text = templateToAdd['name'];
        _serviceItems[0].qtyController.text = '1'; // Use "1"
        _serviceItems[0].costController.text = '0'; // Use "0"
        _serviceItems[0].templateId = templateToAdd['id'];
        _serviceItems[0].intervalDays = templateToAdd['interval_days'];
        _serviceItems[0].intervalKm = templateToAdd['interval_km'];
      } else {
        _serviceItems.add(
          ServiceItem(
            name: templateToAdd['name'],
            qty: 1.0,
            cost: 0.0,
            templateId: templateToAdd['id'],
            intervalDays: templateToAdd['interval_days'],
            intervalKm: templateToAdd['interval_km'],
          ),
        );
      }
    });
    _updateTotalCost();
  }

  void _updateTotalCost() {
    // (This function is unchanged)
    double total = 0.0;
    for (var item in _serviceItems) {
      final qty = double.tryParse(item.qtyController.text) ?? 0.0;
      final cost = double.tryParse(item.costController.text) ?? 0.0;
      total += qty * cost;
    }
    setState(() {
      _totalCostController.text = total.toStringAsFixed(2);
    });
  }

  // --- SAVE FUNCTION (unchanged) ---



  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      _updateTotalCost();

      final List<Map<String, dynamic>> itemsList = [];
      for (var item in _serviceItems) {
        String name = item.nameController.text;
        if (name.isNotEmpty) {
          itemsList.add({
            'name': name,
            'qty': double.tryParse(item.qtyController.text) ?? 1.0,
            'unit_cost': double.tryParse(item.costController.text) ?? 0.0,
            'total_cost':
                (double.tryParse(item.qtyController.text) ?? 1.0) *
                (double.tryParse(item.costController.text) ?? 0.0),
            'template_id': item.templateId,
          });
        }
      }

      Map<String, dynamic> serviceRow = {
        'vehicle_id': widget.vehicleId,
        'service_name': _serviceNameController.text,
        'service_date': _dateController.text,
        'odometer': int.tryParse(_odometerController.text),
        'total_cost': double.tryParse(_totalCostController.text),
        'vendor_id': _selectedVendorId,
        'notes': _notesController.text,
        'ServiceItems': itemsList, // Send nested items
      };

      int? serviceId;
      if (_isEditMode) {
        await ApiService.updateService(widget.serviceId!, serviceRow);
        serviceId = widget.serviceId!;
      } else {
        final newService = await ApiService.createService(serviceRow);
        serviceId = newService?['id'];
      }

      // Odometer update sync
      int newOdometer = int.tryParse(_odometerController.text) ?? 0;
      if (newOdometer > widget.currentOdometer) {
        await ApiService.updateOdometer(widget.vehicleId, newOdometer);
      }

      // Save new photos
      if (serviceId != null) {
        for (var imageFile in _newImageFiles) {
          await ApiService.uploadPhoto(
            parentId: serviceId,
            parentType: 'service',
            imageFile: imageFile,
          );
        }

        // --- NEW: Reminder Management ---
        for (var item in _serviceItems) {
          if (item.templateId != null) {
            // 1. Complete existing reminders for this template
            await ApiService.completeRemindersByTemplate(
              vehicleId: widget.vehicleId,
              templateId: item.templateId!,
              serviceId: serviceId,
            );

            // 2. Create new reminder if interval is set
            if (item.intervalDays != null || item.intervalKm != null) {
              String? nextDate;
              int? nextOdo;
              if (item.intervalDays != null) {
                nextDate = DateTime.now()
                    .add(Duration(days: item.intervalDays!))
                    .toIso8601String()
                    .split('T')[0];
              }
              if (item.intervalKm != null) {
                nextOdo = newOdometer + item.intervalKm!;
              }

              await ApiService.createReminder({
                'vehicle_id': widget.vehicleId,
                'template_id': item.templateId,
                'service_id': serviceId,
                'due_date': nextDate,
                'due_odometer': nextOdo,
                'status': 'pending',
              });
            }
          }
        }
      }

      if (mounted) {
        final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
        await vehicleProvider.syncAllData(); // Refresh global cloud state
        
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        await NotificationService().checkAndShowOdometerReminders(
          reminders: vehicleProvider.reminders.where((r) => r['vehicle_id'] == widget.vehicleId).toList(),
          currentOdometer: newOdometer,
          unitType: settings.unitType,
        );
        Navigator.of(context).pop();
      }
    }
  }


  // --- MAIN BUILD METHOD (unchanged) ---
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = settings.primaryColor;

    final usedTemplateIds = _serviceItems
        .where((item) => item.templateId != null)
        .map((item) => item.templateId)
        .toSet();
    final availableTemplates = _allTemplates
        .where((template) => !usedTemplateIds.contains(template['id']))
        .toList();

    // --- MODERN INPUT DECORATION HELPER ---
    InputDecoration modernInputDecoration(
      String label,
      IconData icon, {
      String? suffixText,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        suffixText: suffixText,
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        title: Text(
          _isEditMode ? 'Edit Service' : 'Add Service Record',
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
                    _buildSectionHeader("Service Details", isDark),
                    const SizedBox(height: 16),

                    // --- SERVICE NAME ---
                    TextFormField(
                      controller: _serviceNameController,
                      decoration: modernInputDecoration(
                        "Service Name",
                        Icons.build,
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- DATE & ODOMETER ---
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateController,
                                decoration: modernInputDecoration(
                                  "Date",
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _odometerController,
                            decoration: modernInputDecoration(
                              "Odometer",
                              Icons.speed,
                              suffixText: settings.unitType,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Parts & Cost", isDark),
                    const SizedBox(height: 16),

                    // --- PARTS SELECTION ---
                    _isLoadingTemplates
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _selectedTemplateId,
                                  decoration: modernInputDecoration(
                                    "Add from Auto Parts",
                                    Icons.build_circle,
                                  ),
                                  items: availableTemplates.map((template) {
                                    return DropdownMenuItem<int>(
                                      value: template['id'],
                                      child: Text(template['name']),
                                    );
                                  }).toList(),
                                  onChanged: (int? newId) {
                                    setState(() {
                                      _selectedTemplateId = newId;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.add, color: primaryColor),
                                  onPressed: _addPartFromTemplate,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),

                    // --- SERVICE ITEMS LIST ---
                    ..._serviceItems.asMap().entries.map((entry) {
                      return _buildServiceItemRow(
                        entry.value,
                        entry.key,
                        isDark,
                        primaryColor,
                        settings.currencySymbol,
                      );
                    }),

                    const SizedBox(height: 16),
                    // Add Manual Item Button
                    Center(
                      child: TextButton.icon(
                        icon: Icon(Icons.add, color: primaryColor),
                        label: Text(
                          'Add Manual Item',
                          style: TextStyle(
                            fontSize: 16,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _serviceItems.add(ServiceItem());
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    // --- TOTAL COST ---
                    TextFormField(
                      controller: _totalCostController,
                      decoration:
                          modernInputDecoration(
                            "Total Cost",
                            Icons.attach_money, // Or generic money icon
                          ).copyWith(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                settings.currencySymbol,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                      readOnly: true,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Workshop & Notes", isDark),
                    const SizedBox(height: 16),

                    // --- VENDOR ---
                    _isLoadingVendors
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _selectedVendorId,
                            decoration: modernInputDecoration(
                              "Workshop / Garage",
                              Icons.store,
                            ),
                            items: _allVendors.map((vendor) {
                              return DropdownMenuItem<int>(
                                value: vendor['id'],
                                child: Text(vendor['name']),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() => _selectedVendorId = newValue);
                            },
                          ),
                    const SizedBox(height: 16),

                    // --- NOTES ---
                    TextFormField(
                      controller: _notesController,
                      decoration: modernInputDecoration(
                        "Notes (Optional)",
                        Icons.notes,
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Upload Bill", isDark),
                    const SizedBox(height: 16),
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
                  onPressed: _saveService,
                  child: Text(
                    _isEditMode ? 'UPDATE SERVICE' : 'SAVE SERVICE',
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

  Widget _buildServiceItemRow(
    ServiceItem item,
    int index,
    bool isDark,
    Color primaryColor,
    String currencySymbol,
  ) {
    // Mini-decoration helper for these smaller fields
    InputDecoration itemDecoration(String label) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: item.nameController,
              decoration: itemDecoration("Part/Service"),
              validator: (val) => val == null || val.isEmpty ? 'Req' : null,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: item.qtyController,
              decoration: itemDecoration(""),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _updateTotalCost(),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 2, // Gave it a bit more space
            child: TextFormField(
              controller: item.costController,
              decoration: itemDecoration(
                "Cost",
              ), // Removed prefix to save space, or could add partial
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onTap: () {
                if (item.costController.text == '0') {
                  item.costController.clear();
                }
              },
              onChanged: (_) => _updateTotalCost(),
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () {
              setState(() {
                if (_serviceItems.length > 1) {
                  item.dispose();
                  _serviceItems.removeAt(index);
                } else {
                  // Clear the first item if it's the only one
                  _serviceItems[index].nameController.clear();
                  _serviceItems[index].qtyController.text = '1';
                  _serviceItems[index].costController.text = '0';
                  _serviceItems[index].templateId = null;
                }
                _updateTotalCost();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker(bool isDark, Color primaryColor) {
    List<dynamic> photos = _isEditMode
        ? [..._existingPhotos, ..._newImageFiles]
        : _newImageFiles;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + 1,
        itemBuilder: (context, index) {
          if (index == photos.length) {
            return _buildAddPhotoButton(isDark, primaryColor);
          }
          final photo = photos[index];
          final String? uri = (photo is Map)
              ? photo['file_path']
              : (photo as XFile).path;

          return _buildPhotoThumbnail(
            uri,
            index,
            isDark,
            primaryColor,
            isExisting: photo is Map,
            onDelete: () async {
              if (photo is Map) {
                await ApiService.deletePhoto(photo['id']);
                setState(() => _existingPhotos.remove(photo));
              } else {
                setState(() => _newImageFiles.remove(photo));
              }
            },
            onTap: () {
              final paths = photos.map((p) {
                if (p is Map) {
                  final u = p['file_path'] as String;
                  return u.startsWith('http')
                      ? u
                      : '${ApiConstants.serverUrl}/$u';
                }
                return (p as XFile).path;
              }).toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenPhotoViewer(
                    photoPaths: paths,
                    initialIndex: index,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAddPhotoButton(bool isDark, Color primaryColor) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              "Add Photo",
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(
    String? uri,
    int index,
    bool isDark,
    Color primaryColor, {
    required bool isExisting,
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    if (uri == null) return const SizedBox();

    ImageProvider imageProvider;
    if (isExisting) {
      final String fullUrl = uri.startsWith('http')
          ? uri
          : '${ApiConstants.serverUrl}/$uri';
      imageProvider = NetworkImage(fullUrl);
    } else {
      imageProvider = FileImage(File(uri));
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 17,
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

  @override
  void dispose() {
    _serviceNameController.dispose();
    _dateController.dispose();
    _odometerController.dispose();
    _totalCostController.dispose();
    _notesController.dispose();
    for (var item in _serviceItems) {
      item.dispose();
    }
    super.dispose();
  }
}
