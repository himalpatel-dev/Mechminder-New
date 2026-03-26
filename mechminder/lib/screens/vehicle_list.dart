import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/vehicle_provider.dart';
import '../screens/vehicle_detail.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => VehicleListScreenState();
}

class VehicleListScreenState extends State<VehicleListScreen> {
  
  @override
  void initState() {
    super.initState();
    // Data is synced via Splash Screen, but UI will rebuild on changes
  }

  Future<void> refreshVehicleList() async {
    await Provider.of<VehicleProvider>(context, listen: false).syncAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        if (vehicleProvider.isLoading && vehicleProvider.vehicles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vehicleProvider.vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No vehicles added yet.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text('Your data is now safely synced in the cloud!'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: refreshVehicleList,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vehicleProvider.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicleProvider.vehicles[index];
              return _buildVehicleCard(vehicle);
            },
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final String make = vehicle['make'] ?? 'Unknown';
    final String model = vehicle['model'] ?? '';
    final String variant = vehicle['variant'] ?? '';
    final String regNo = vehicle['reg_no'] ?? '';
    final int currentOdo = vehicle['current_odometer'] ?? 0;
    
    // Construct photo URL if it exists
    final String? photoUrl = vehicle['photo_url'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailScreen(vehicleId: vehicle['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Vehicle Photo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.directions_car, size: 40),
                        ),
                      )
                    : const Icon(Icons.directions_car, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              // Vehicle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$make $model',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (variant.isNotEmpty)
                      Text(variant, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(
                      'Reg: $regNo',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Odometer: ${currentOdo.toString()} km',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
