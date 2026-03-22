import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../service/settings_provider.dart';
import '../service/vendor_provider.dart';
import '../models/reminder_vendor.dart';
import '../widgets/common_popup.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to refresh after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VendorProvider>(context, listen: false).refreshVendors();
    });
  }

  // --- DIALOG LOGIC ---
  void _showAddEditVendorDialog({Vendor? vendor}) {
    bool isEditing = vendor != null;

    if (isEditing) {
      _nameController.text = vendor.name;
      _phoneController.text = vendor.phone ?? '';
      _addressController.text = vendor.address ?? '';
    } else {
      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        final primaryColor = Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).primaryColor;
        return CommonPopup(
          title: isEditing ? 'Edit Workshop' : 'Add New Workshop',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                _nameController,
                "Workshop Name",
                Icons.store,
                primaryColor,
                true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _phoneController,
                "Phone",
                Icons.phone,
                primaryColor,
                false,
                TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _addressController,
                "Address",
                Icons.location_on,
                primaryColor,
                false,
              ),
            ],
          ),
          actions: [
            if (isEditing) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(
                    vendor.id!,
                    primaryColor,
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Delete'),
              ),
              const Spacer(),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                _saveVendor(vendor);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    Color color,
    bool autofocus, [
    TextInputType? type,
  ]) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  void _saveVendor(Vendor? vendor) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final Map<String, dynamic> row = {
      'name': name,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);

    if (vendor != null) {
      row['id'] = vendor.id;
      await vendorProvider.updateVendor(row);
    } else {
      await vendorProvider.createVendor(row);
    }
  }

  void _showDeleteConfirmation(int id, Color primaryColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Workshop?'),
        content: const Text(
          'Are you sure you want to permanently delete this Workshop?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await Provider.of<VendorProvider>(context, listen: false).deleteVendor(id);
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final vendorProvider = Provider.of<VendorProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = settings.primaryColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        title: Text(
          'Manage Workshops',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.grey.shade900,
        ),
      ),
      body: vendorProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : vendorProvider.vendors.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
              onRefresh: () => vendorProvider.refreshVendors(),
              color: primaryColor,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vendorProvider.vendors.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final vendor = vendorProvider.vendors[index];
                  return _buildVendorCard(vendor, isDark, primaryColor);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditVendorDialog(vendor: null),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Workshop",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Workshops Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your trusted mechanics and service centers.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(
    Vendor vendor,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAddEditVendorDialog(vendor: vendor),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.store, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      if ((vendor.phone?.isNotEmpty ?? false) || (vendor.address?.isNotEmpty ?? false))
                        const SizedBox(height: 6),
                      if (vendor.phone?.isNotEmpty ?? false)
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vendor.phone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      if ((vendor.phone?.isNotEmpty ?? false) && (vendor.address?.isNotEmpty ?? false))
                        const SizedBox(height: 4),
                      if (vendor.address?.isNotEmpty ?? false)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vendor.address!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Action Icon
                Icon(
                  Icons.edit_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
