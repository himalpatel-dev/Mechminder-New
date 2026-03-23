import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../service/api_service.dart';
import '../widgets/stats_pie_chart.dart';
import '../service/settings_provider.dart';
import '../service/excel_service.dart';

class StatsTab extends StatefulWidget {
  final int vehicleId;
  const StatsTab({super.key, required this.vehicleId});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  double _totalSpending = 0.0;
  List<Map<String, dynamic>> _spendingByCategory = [];
  bool _isLoading = true;

  DateTime? _selectedMonth; // Null means "All Time"

  late ScrollController _scrollController;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _loadStats();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isFabVisible) {
          setState(() {
            _isFabVisible = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_isFabVisible) {
          setState(() {
            _isFabVisible = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        ApiService.getExpensesForVehicle(widget.vehicleId),
        ApiService.getServicesForVehicle(widget.vehicleId),
        ApiService.getPapersForVehicle(widget.vehicleId),
      ]);

      final List<dynamic> expenses = results[0];
      final List<dynamic> services = results[1];
      final List<dynamic> papers = results[2];

      double totalSpending = 0.0;
      Map<String, double> categoryTotals = {};

      DateTime? filterStart;
      DateTime? filterEnd;

      if (_selectedMonth != null) {
        filterStart = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
        filterEnd = DateTime(
          _selectedMonth!.year,
          _selectedMonth!.month + 1,
          0,
        );
      }

      // 1. Process Expenses
      for (var e in expenses) {
        final String? dateStr =
            e['service_date'] ?? e['expense_date'] ?? e['created_at'];
        if (dateStr == null) continue;
        final DateTime date = DateTime.parse(dateStr);

        if (_selectedMonth != null) {
          if (date.isBefore(filterStart!) || date.isAfter(filterEnd!)) continue;
        }

        final double cost = (e['total_cost'] ?? 0.0).toDouble();
        totalSpending += cost;

        final String category = e['category'] ?? 'General';
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + cost;
      }

      // 2. Process Services
      for (var s in services) {
        final String? dateStr = s['service_date'] ?? s['created_at'];
        if (dateStr == null) continue;
        final DateTime date = DateTime.parse(dateStr);

        if (_selectedMonth != null) {
          if (date.isBefore(filterStart!) || date.isAfter(filterEnd!)) continue;
        }

        final double cost = (s['total_cost'] ?? 0.0).toDouble();
        totalSpending += cost;

        // Categorize all services as "Maintenance" for stats purposes
        const String category = 'Maintenance';
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + cost;
      }

      // 3. Process Papers (Essential Costs)
      for (var p in papers) {
        final String? dateStr = p['created_at'];
        if (dateStr == null) continue;
        final DateTime date = DateTime.parse(dateStr);

        if (_selectedMonth != null) {
          if (date.isBefore(filterStart!) || date.isAfter(filterEnd!)) continue;
        }

        final double cost = (p['cost'] ?? 0.0).toDouble();
        totalSpending += cost;

        const String category = 'Essential Costs';
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + cost;
      }

      final byCategory = categoryTotals.entries.map((entry) {
        return {'category': entry.key, 'total': entry.value};
      }).toList();

      byCategory.sort(
        (a, b) => (b['total'] as num).compareTo(a['total'] as num),
      );

      if (mounted) {
        setState(() {
          _totalSpending = totalSpending;
          _spendingByCategory = byCategory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final initialDate = _selectedMonth ?? now;
    int selectedYear = initialDate.year;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedYear--;
                      });
                    },
                  ),
                  Text(
                    selectedYear.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedYear++;
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    final monthDate = DateTime(selectedYear, index + 1);
                    final isSelected =
                        _selectedMonth != null &&
                        _selectedMonth!.year == selectedYear &&
                        _selectedMonth!.month == index + 1;
                    final isCurrentMonth =
                        now.year == selectedYear && now.month == index + 1;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(monthDate);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : primaryColor)
                              : isCurrentMonth
                              ? (isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : primaryColor.withOpacity(0.15))
                              : isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? Colors.white : primaryColor)
                                : isCurrentMonth
                                ? (isDark ? Colors.white60 : primaryColor)
                                : isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            width: isSelected || isCurrentMonth ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        (isDark ? Colors.white : primaryColor)
                                            .withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          DateFormat('MMM').format(monthDate),
                          style: TextStyle(
                            color: isSelected
                                ? (isDark ? primaryColor : Colors.white)
                                : isCurrentMonth
                                ? (isDark ? Colors.white : primaryColor)
                                : isDark
                                ? Colors.white70
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadStats();
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedMonth = null;
    });
    _loadStats();
  }

  Future<void> _exportToExcel(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Creating report...')),
    );
    final vehicle = await ApiService.getVehicleById(widget.vehicleId);
    final vehicleName = (vehicle != null)
        ? '${vehicle['make']} ${vehicle['model']}'
        : 'Vehicle_Report';

    final excelService = ExcelService(settings: settings);

    final result = await excelService.createExcelReport(
      widget.vehicleId,
      vehicleName,
    );

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(result ?? 'An unknown error occurred.'),
        backgroundColor: result != null && result.startsWith('Report generated')
            ? Colors.green
            : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = settings.primaryColor;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 80),
        child: Column(
          children: [
            // --- Month Filter Header ---
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        _selectedMonth == null
                            ? 'All Time'
                            : DateFormat('MMMM yyyy').format(_selectedMonth!),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_selectedMonth != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: _clearFilter,
                          tooltip: 'Clear Filter',
                        ),
                      IconButton(
                        icon: Icon(Icons.edit_calendar, color: primaryColor),
                        onPressed: _pickMonth,
                        tooltip: 'Select Month',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Total Spending Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      _selectedMonth == null
                          ? 'TOTAL LIFETIME SPENDING'
                          : 'TOTAL SPENDING (${DateFormat('MMM yyyy').format(_selectedMonth!)})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${settings.currencySymbol}${_totalSpending.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Pie Chart
            if (_spendingByCategory.isNotEmpty)
              StatsPieChart(spendingData: _spendingByCategory)
            else
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No data for this period',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Spending by Category List
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.pie_chart, color: primaryColor),
                        const SizedBox(width: 10),
                        const Text(
                          'Spending by Category',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (_spendingByCategory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No spending data found.'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _spendingByCategory.length,
                      itemBuilder: (context, index) {
                        final item = _spendingByCategory[index];
                        String category = item['category'];
                        double total = (item['total'] as num).toDouble();

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            category,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Text(
                            '${settings.currencySymbol}${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Visibility(
        visible: _isFabVisible,
        child: FloatingActionButton(
          onPressed: () {
            _exportToExcel(context, settings);
          },
          backgroundColor: primaryColor,
          tooltip: 'Export to Excel',
          child: const Icon(Icons.download_for_offline, color: Colors.white),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return Icons.local_gas_station;
      case 'maintenance':
      case 'services':
        return Icons.build;
      case 'repairs':
        return Icons.car_repair;
      case 'insurance':
        return Icons.shield;
      case 'puc':
        return Icons.cloud_outlined;
      case 'parking':
        return Icons.local_parking;
      case 'tolls':
        return Icons.add_road;
      case 'fines':
        return Icons.gavel;
      default:
        return Icons.category;
    }
  }
}
