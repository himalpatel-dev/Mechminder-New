import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/api_service.dart';
import '../service/settings_provider.dart';
import '../core/api_constants.dart';
import 'vehicle_detail.dart'; // Add this back
import '../widgets/mini_spending_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => VehicleListScreenState();
}

class VehicleListScreenState extends State<VehicleListScreen> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshVehicleList();
  }

  void refreshVehicleList() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final allVehicles = await ApiService.getVehicles();
      setState(() {
        _vehicles = allVehicles;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Loading dashboard..."),
              ],
            ),
          )
        : _vehicles.isEmpty
        ? const Center(
            // (Empty list text is unchanged)
            child: Text(
              'No vehicles found. \nTap the "+" button to add one!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
        : AnimationLimiter(
            child: ListView.builder(
              // (Your animated list is unchanged)
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 140.0),
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];

                // (All your data logic is unchanged)
                String nextReminderText = "No upcoming reminders";
                final String? nextTemplate = vehicle['template_name'];
                final String? nextDate = vehicle['due_date'];
                final int? nextOdo = vehicle['due_odometer'];
                if (nextTemplate != null) {
                  if (nextDate != null) {
                    nextReminderText = 'Next: $nextTemplate (by $nextDate)';
                  } else if (nextOdo != null) {
                    nextReminderText =
                        'Next: $nextTemplate (by $nextOdo ${settings.unitType})';
                  }
                }
                final double serviceTotal = (vehicle['service_total'] ?? 0)
                    .toDouble();
                final double expenseTotal = (vehicle['expense_total'] ?? 0)
                    .toDouble();
                final double totalSpending = serviceTotal + expenseTotal;

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Card(
                        // (Your beautiful card UI is unchanged)
                        clipBehavior: Clip.antiAlias,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            final int vehicleId = vehicle['id'];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VehicleDetailScreen(vehicleId: vehicleId),
                              ),
                            ).then((_) {
                              refreshVehicleList();
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: _buildVehicleImage(
                                      vehicle['photo_uri'],
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    right: 12,
                                    child: Text(
                                      '${vehicle['make']} ${vehicle['model']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${vehicle['purchase_date'] ?? 'N/A'} | ${vehicle['reg_no'] ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'NEXT REMINDER',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            nextReminderText,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (totalSpending == 0)
                                            Column(
                                              children: [
                                                Icon(
                                                  Icons.pie_chart_outline,
                                                  size: 40,
                                                  color: Colors.grey[300],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${settings.currencySymbol}0 total',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Column(
                                              children: [
                                                SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child: MiniSpendingChart(
                                                    serviceSpending:
                                                        serviceTotal,
                                                    expenseSpending:
                                                        expenseTotal,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${settings.currencySymbol}${totalSpending.toStringAsFixed(0)} total',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }

  // (Unified helper function for network/file images)
  Widget _buildVehicleImage(String? photoPath) {
    if (photoPath != null && photoPath.isNotEmpty) {
      final isNetwork =
          photoPath.startsWith('http') || photoPath.startsWith('/uploads');
      final fullUrl = isNetwork && !photoPath.startsWith('http')
          ? '${ApiConstants.serverUrl}$photoPath'
          : photoPath;

      return isNetwork
          ? Image.network(
              fullUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                );
              },
            )
          : Image.file(
              File(photoPath),
              fit: BoxFit.cover,
              cacheWidth: 800, // Optimize memory for list items

              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                );
              },
            );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.directions_car, color: Colors.grey[400], size: 60),
      );
    }
  }
}
