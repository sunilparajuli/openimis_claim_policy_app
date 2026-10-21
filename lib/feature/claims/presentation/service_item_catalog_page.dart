import 'package:flutter_riverpod_template/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod_template/core/config/currency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/feature/claims/models/claim_service_item_model.dart';
import 'package:flutter_riverpod_template/feature/claims/repositories/claim_repository.dart';
import 'package:flutter_riverpod_template/feature/shared/utils/styles/app_color.dart';

class ServiceItemCatalogPage extends ConsumerStatefulWidget {
  const ServiceItemCatalogPage({super.key});

  @override
  ConsumerState<ServiceItemCatalogPage> createState() =>
      _ServiceItemCatalogPageState();
}

class _ServiceItemCatalogPageState extends ConsumerState<ServiceItemCatalogPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  late List<MedicalService> _services;
  late List<MedicationItem> _items;

  final Set<String> _mappedServiceCodes = {};
  final Set<String> _mappedItemCodes = {};

  MoneyFormatter get _money => ref.read(moneyFormatterProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final repo = ref.read(claimRepositoryProvider);
    _services = repo.getAvailableServices();
    _items = repo.getAvailableItems();

    // By default, map all standard services and items
    _mappedServiceCodes.addAll(_services.map((s) => s.code));
    _mappedItemCodes.addAll(_items.map((i) => i.code));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(moneyFormatterProvider);

    final filteredServices = _services.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.code.toLowerCase().contains(q) ||
          s.name.toLowerCase().contains(q);
    }).toList();

    final filteredItems = _items.where((i) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return i.code.toLowerCase().contains(q) ||
          i.name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Facility Services & Items Mapping'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          unselectedLabelStyle: const TextStyle(color: Colors.white70),
          tabs: [
            Tab(text: 'Medical Services (${_services.length})'),
            Tab(text: 'Medications / Items (${_items.length})'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Master Data',
            icon: const Icon(Icons.sync),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Master catalog synchronized with openIMIS Server.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppTextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by code or description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Catalog Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Services Tab
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    final s = filteredServices[index];
                    final isMapped = _mappedServiceCodes.contains(s.code);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: SwitchListTile(
                        value: isMapped,
                        activeThumbColor: CustomColors.BrandPurple,
                        title: Text(
                          s.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Code: ${s.code} • Category: ${s.category ?? "General"} • Standard Tariff: ${_money.format(s.price)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onChanged: (enabled) {
                          setState(() {
                            if (enabled) {
                              _mappedServiceCodes.add(s.code);
                            } else {
                              _mappedServiceCodes.remove(s.code);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),

                // 2. Items Tab
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isMapped = _mappedItemCodes.contains(item.code);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: SwitchListTile(
                        value: isMapped,
                        activeThumbColor: CustomColors.BrandPurple,
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Code: ${item.code} • Unit: ${item.unit ?? "unit"} • Price: ${_money.format(item.price)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onChanged: (enabled) {
                          setState(() {
                            if (enabled) {
                              _mappedItemCodes.add(item.code);
                            } else {
                              _mappedItemCodes.remove(item.code);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
