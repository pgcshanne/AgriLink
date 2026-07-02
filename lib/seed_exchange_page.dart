import 'package:flutter/material.dart';
import 'package:agrilink/drawer_menu.dart';
import 'package:agrilink/services/api_service.dart';
import 'package:agrilink/services/user_session.dart';

class SeedExchangePage extends StatefulWidget {
  const SeedExchangePage({super.key});

  @override
  State<SeedExchangePage> createState() => _SeedExchangePageState();
}

class _SeedExchangePageState extends State<SeedExchangePage> {
  List<dynamic> _seeds = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndSeeds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndSeeds() async {
    final userId = await UserSession.getUserId();
    setState(() {
      _currentUserId = userId;
    });
    _loadSeeds();
  }

  Future<void> _loadSeeds() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getSeeds(
        cropType: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (response['success'] == true) {
        setState(() {
          _seeds = response['seeds'] ?? [];
        });
      } else {
        _showMessage(response['message'] ?? 'Failed to load seeds');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadSeeds();
  }

  void _onSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadSeeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text(
          'Seed Exchange',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: _loadSeeds,
          ),
        ],
      ),
      drawer: const DrawerMenu(currentPage: 'Seed Exchange'),
      body: RefreshIndicator(
        onRefresh: _loadSeeds,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seed Exchange Community',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Share and exchange seeds with fellow farmers',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Search
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search seeds...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _onSearch(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.search, color: Colors.green[700]),
                      onPressed: _onSearch,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All', _selectedCategory == 'All'),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      'Vegetables',
                      _selectedCategory == 'Vegetables',
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Grains', _selectedCategory == 'Grains'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Fruits', _selectedCategory == 'Fruits'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Herbs', _selectedCategory == 'Herbs'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      '${_seeds.length} Seeds Available',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Seeds List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_seeds.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.eco, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No seeds available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _seeds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final seed = _seeds[index];
                    final isOwner =
                        _currentUserId != null &&
                        int.parse(seed['user_id'].toString()) == _currentUserId;
                    return _buildSeedCard(seed: seed, isOwner: isOwner);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSeedDialog(),
        backgroundColor: Colors.green[600],
        icon: const Icon(Icons.add),
        label: const Text('List Seeds'),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isActive) {
    return GestureDetector(
      onTap: () => _onCategorySelected(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[600] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.green[600]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSeedCard({
    required Map<String, dynamic> seed,
    required bool isOwner,
  }) {
    final int seedId = int.parse(seed['id'].toString());
    final String name = seed['seed_name'] ?? 'Unknown';
    final String farmer = seed['seller_name'] ?? 'Unknown';
    final String location = seed['location'] ?? 'Not specified';
    final String quantity =
        '${seed['quantity']} ${seed['quantity_unit'] ?? 'pcs'}';
    final String type = seed['crop_type'] ?? 'Other';
    final bool isAvailable = seed['status'] == 'available';
    final String? price = seed['price']?.toString();
    final String exchangeType = seed['exchange_type'] ?? 'sell';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwner ? Colors.green[300]! : Colors.grey[300]!,
          width: isOwner ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '📌 Your Listing',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.eco, color: Colors.green[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      farmer,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Reserved',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAvailable
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (price != null && exchangeType == 'sell')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '₱$price',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.inventory, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                quantity,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type,
                  style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  exchangeType == 'sell'
                      ? 'For Sale'
                      : exchangeType == 'free'
                      ? 'Free'
                      : 'Exchange',
                  style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isOwner)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditSeedDialog(seed),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteSeed(seedId),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAvailable ? () => _requestSeed(seedId) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(isAvailable ? 'Request Exchange' : 'Not Available'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _requestSeed(int seedId) async {
    if (_currentUserId == null) {
      _showMessage('Please login first');
      return;
    }

    final response = await ApiService.requestSeed(
      seedId: seedId,
      requesterId: _currentUserId!,
      message: 'I am interested in your seed listing.',
    );

    _showMessage(
      response['message'] ?? 'Request sent',
      isError: response['success'] != true,
    );
  }

  Future<void> _deleteSeed(int seedId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Seed'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || _currentUserId == null) return;

    final response = await ApiService.deleteSeed(
      seedId: seedId,
      userId: _currentUserId!,
    );
    _showMessage(
      response['message'] ?? 'Deleted',
      isError: response['success'] != true,
    );

    if (response['success'] == true) _loadSeeds();
  }

  void _showEditSeedDialog(Map<String, dynamic> seed) {
    final nameController = TextEditingController(text: seed['seed_name']);
    final quantityController = TextEditingController(
      text: seed['quantity'].toString(),
    );
    final priceController = TextEditingController(
      text: seed['price']?.toString() ?? '',
    );
    final locationController = TextEditingController(
      text: seed['location'] ?? '',
    );
    String selectedCropType = seed['crop_type'] ?? 'Vegetables';
    String selectedExchangeType = seed['exchange_type'] ?? 'sell';
    String selectedUnit = seed['quantity_unit'] ?? 'kg';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Seed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Seed Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCropType,
                      decoration: InputDecoration(
                        labelText: 'Crop Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          [
                                'Vegetables',
                                'Grains',
                                'Fruits',
                                'Herbs',
                                'Rice',
                                'Corn',
                                'Other',
                              ]
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedCropType = v!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['kg', 'grams', 'pieces', 'packets']
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setModalState(() => selectedUnit = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedExchangeType == 'sell')
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Price (₱)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentUserId == null) return;
                          final response = await ApiService.updateSeed(
                            seedId: int.parse(seed['id'].toString()),
                            userId: _currentUserId!,
                            seedName: nameController.text,
                            cropType: selectedCropType,
                            quantity: int.tryParse(quantityController.text),
                            quantityUnit: selectedUnit,
                            price: double.tryParse(priceController.text),
                            location: locationController.text,
                          );
                          Navigator.pop(context);
                          _showMessage(
                            response['message'] ?? 'Updated',
                            isError: response['success'] != true,
                          );
                          if (response['success'] == true) _loadSeeds();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Update Seed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSeedDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final locationController = TextEditingController();
    String selectedCropType = 'Vegetables';
    String selectedExchangeType = 'sell';
    String selectedUnit = 'kg';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'List Your Seeds',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Seed Name *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCropType,
                      decoration: InputDecoration(
                        labelText: 'Crop Type *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          [
                                'Vegetables',
                                'Grains',
                                'Fruits',
                                'Herbs',
                                'Rice',
                                'Corn',
                                'Other',
                              ]
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedCropType = v!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['kg', 'grams', 'pieces', 'packets']
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setModalState(() => selectedUnit = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedExchangeType,
                      decoration: InputDecoration(
                        labelText: 'Listing Type *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'sell',
                          child: Text('For Sale'),
                        ),
                        DropdownMenuItem(
                          value: 'exchange',
                          child: Text('For Exchange'),
                        ),
                        DropdownMenuItem(value: 'free', child: Text('Free')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => selectedExchangeType = v!),
                    ),
                    const SizedBox(height: 16),
                    if (selectedExchangeType == 'sell')
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Price (₱)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (selectedExchangeType == 'sell')
                      const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Location *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              quantityController.text.isEmpty ||
                              locationController.text.isEmpty) {
                            _showMessage('Please fill all required fields');
                            return;
                          }
                          if (_currentUserId == null) {
                            _showMessage('Please login first');
                            return;
                          }
                          final response = await ApiService.addSeed(
                            userId: _currentUserId!,
                            seedName: nameController.text,
                            cropType: selectedCropType,
                            quantity: int.parse(quantityController.text),
                            quantityUnit: selectedUnit,
                            exchangeType: selectedExchangeType,
                            price: priceController.text.isNotEmpty
                                ? double.parse(priceController.text)
                                : null,
                            location: locationController.text,
                            isFree: selectedExchangeType == 'free',
                          );
                          Navigator.pop(context);
                          _showMessage(
                            response['message'] ?? 'Seed listed!',
                            isError: response['success'] != true,
                          );
                          if (response['success'] == true) _loadSeeds();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'List Seeds',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
