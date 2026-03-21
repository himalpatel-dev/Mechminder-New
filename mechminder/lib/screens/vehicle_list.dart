import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import 'vehicle_detail.dart';
import 'package:provider/provider.dart';
import '../service/settings_provider.dart';
import '../service/vehicle_provider.dart';
import 'dart:io';
import '../widgets/mini_spending_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => VehicleListScreenState();
}

class VehicleListScreenState extends State<VehicleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshVehicleList();
    });
  }

  void refreshVehicleList() {
    Provider.of<VehicleProvider>(context, listen: false).refreshVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        if (vehicleProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Loading dashboard..."),
              ],
            ),
          );
        }

        final vehicles = vehicleProvider.vehicles;

        if (vehicles.isEmpty) {
          return const Center(
            child: Text(
              'No vehicles found. \nTap the "+" button to add one!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 140.0),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];

              String nextReminderText = "No upcoming reminders";
              if (vehicle.templateName != null) {
                if (vehicle.nextReminderDate != null) {
                  nextReminderText =
                      'Next: ${vehicle.templateName} (by ${vehicle.nextReminderDate})';
                } else if (vehicle.nextReminderOdometer != null) {
                  nextReminderText =
                      'Next: ${vehicle.templateName} (by ${vehicle.nextReminderOdometer} ${settings.unitType})';
                }
              }

              final double totalSpending =
                  vehicle.serviceTotal + vehicle.expenseTotal;

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (vehicle.id != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VehicleDetailScreen(vehicleId: vehicle.id!),
                              ),
                            ).then((_) {
                              refreshVehicleList();
                            });
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: _buildVehicleImage(vehicle.photoUri),
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
                                    '${vehicle.make} ${vehicle.model}',
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
                                          '${vehicle.purchaseDate ?? 'N/A'} | ${vehicle.regNo ?? 'N/A'}',
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
                                                      vehicle.serviceTotal,
                                                  expenseSpending:
                                                      vehicle.expenseTotal,
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
      },
    );
  }

  Widget _buildVehicleImage(String? photoPath) {
    if (photoPath != null && photoPath.isNotEmpty) {
      if (photoPath.startsWith('http')) {
        return Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 40,
              ),
            );
          },
        );
      }
      return Image.file(
        File(photoPath),
        fit: BoxFit.cover,
        cacheWidth: 800, // Optimize memory for list items

        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
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
