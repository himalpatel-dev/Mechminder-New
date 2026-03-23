import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/api_service.dart';
import '../service/settings_provider.dart';
import 'add_service_screen.dart';
import '../widgets/full_screen_photo_viewer.dart';
import '../core/api_constants.dart';

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;
  final int vehicleId;
  final int currentOdometer;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    required this.vehicleId,
    required this.currentOdometer,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  Map<String, dynamic>? _service;
  List<dynamic> _serviceItems = [];
  List<dynamic> _servicePhotos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final serviceData = await ApiService.getServiceById(widget.serviceId);
      if (serviceData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to load service details. Check your connection or server.',
              ),
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _service = serviceData;
        _serviceItems = serviceData['ServiceItems'] ?? [];
        _servicePhotos = serviceData['Photos'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading service details: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Service?'),
          content: const Text(
            'Are you sure you want to permanently delete this service record? All its parts and photos will be lost.',
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
              ),
              onPressed: () async {
                await ApiService.deleteService(widget.serviceId);
                // Also need to handle photos/reminders cleanup on backend (ideally).
                // Or manual calls if not.
                if (mounted) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = settings.primaryColor;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Service not found.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _service!['service_name'] ?? 'Service Detail',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: primaryColor),
            tooltip: 'Edit Service',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddServiceScreen(
                    vehicleId: widget.vehicleId,
                    currentOdometer: widget.currentOdometer,
                    serviceId: widget.serviceId,
                  ),
                ),
              ).then((_) {
                _loadServiceDetails();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Delete Service',
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(settings, isDark, primaryColor),
            const SizedBox(height: 20),
            if (_serviceItems.isNotEmpty) ...[
              Text(
                "PARTS & ITEMS",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              _buildPartsList(settings, isDark),
              const SizedBox(height: 24),
            ],
            if (_servicePhotos.isNotEmpty) ...[
              Text(
                "PHOTOS",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              _buildPhotosList(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    SettingsProvider settings,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(
                "Date",
                _service!['service_date'] ?? 'N/A',
                Icons.calendar_today,
                isDark,
                primaryColor,
              ),
              _buildInfoColumn(
                "Odometer",
                '${_service!['odometer'] ?? 'N/A'} ${settings.unitType}',
                Icons.speed,
                isDark,
                primaryColor,
                crossAlign: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade100),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.store, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Workshop",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      _service!['Vendor']?['name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_service!['notes'] != null &&
              _service!['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notes,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Notes",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        _service!['notes'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Cost",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${settings.currencySymbol}${_service!['total_cost'] ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    IconData icon,
    bool isDark,
    Color primaryColor, {
    CrossAxisAlignment crossAlign = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (crossAlign == CrossAxisAlignment.start) ...[
              Icon(
                icon,
                size: 14,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            if (crossAlign == CrossAxisAlignment.end) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 14,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildPartsList(SettingsProvider settings, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _serviceItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == _serviceItems.length - 1;
          final name = item['name'] ?? 'Part';
          final qty = (item['qty'] ?? 1).toDouble();
          final cost = (item['unit_cost'] ?? 0).toDouble();
          final total = qty * cost;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$qty x ${settings.currencySymbol}$cost',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${settings.currencySymbol}${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotosList(bool isDark) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _servicePhotos.length,
        itemBuilder: (context, index) {
          final photo = _servicePhotos[index];
          final photoUri = photo['uri'] ?? '';
          final String fullUrl = photoUri.startsWith('http')
              ? photoUri
              : '${ApiConstants.serverUrl}$photoUri';

          return GestureDetector(
            onTap: () {
              final paths = _servicePhotos.map((p) {
                final uri = p['uri'] as String;
                return uri.startsWith('http')
                    ? uri
                    : '${ApiConstants.serverUrl}$uri';
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
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(fullUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
