import 'package:flutter/material.dart';
import 'package:property_management_system/api/database_service.dart';
import 'package:property_management_system/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/models/property_model.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _isEditing = false;
  int _currentImageIndex = 0;
  List<UserModel> _tenants = [];
  UserModel? _selectedTenant;

  // Form controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _ownerNameController = TextEditingController();
  String _selectedType = 'commercial';
  bool _isOccupied = false;

  @override
  void initState() {
    super.initState();
    // Initialize form values with property data
    _nameController.text = widget.property.name;
    _addressController.text = widget.property.address;
    _monthlyRentController.text = widget.property.monthlyRent.toString();
    _ownerNameController.text = widget.property.ownerName;
    _selectedType = widget.property.type;
    _isOccupied = widget.property.isOccupied;
    _selectedTenant = widget.property.tenant;
    getUsers();
  }

  void getUsers() async {
    setState(() {
      _isLoading = true;
    });
    _tenants = await DatabaseService().getAllTenants();
    if (widget.property.tenant != null) {
      _selectedTenant = _tenants.firstWhere(
        (t) => t.uid == widget.property.tenant!.uid,
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _monthlyRentController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProperty() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _databaseService.updateProperty(widget.property.id, {
        'name': _nameController.text,
        'address': _addressController.text,
        'monthlyRent': double.parse(_monthlyRentController.text),
        'tenant': _selectedTenant?.toFirestore(),
        'tenantId': _selectedTenant?.uid,
        'type': _selectedType,
        'isOccupied': _isOccupied,
        'lastUpdated': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property updated successfully!')),
      );

      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update property: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProperty() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this property? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await _databaseService.deleteProperty(widget.property.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property deleted successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete property: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildImageGallery() {
    if (widget.property.images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.business, size: 60, color: Colors.grey),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.property.images.length,
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() => _currentImageIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(widget.property.images[index]),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.property.images.asMap().entries.map((entry) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentImageIndex == entry.key
                    ? const Color(0xFF1565C0)
                    : Colors.grey[300],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertyInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Property Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Property Name', widget.property.name),
            _buildInfoRow('Address', widget.property.address),
            _buildInfoRow('Property Type', widget.property.type.toUpperCase()),
            _buildInfoRow(
              'Monthly Rent',
              'K ${widget.property.monthlyRent.toStringAsFixed(2)}',
            ),
            _buildInfoRow(
              'Tenant',
              widget.property.tenant?.name ?? "No tenant",
            ),
            _buildInfoRow(
              'Status',
              widget.property.isOccupied ? 'Occupied' : 'Vacant',
              statusColor: widget.property.isOccupied
                  ? Colors.green
                  : Colors.orange,
            ),
            _buildInfoRow(
              'Added On',
              '${widget.property.createdAt.day}/${widget.property.createdAt.month}/${widget.property.createdAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: statusColor,
                fontWeight: statusColor != null ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Property',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Property Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monthlyRentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Rent (K)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserModel>(
              initialValue: _selectedTenant,
              validator: (value) {
                if (value == null) {
                  return 'Please enter the owner name';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: _tenants.isEmpty
                    ? "No Tenants Available"
                    : 'Tenant (Optional)',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _tenants
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (e) {
                _selectedTenant = e;
                setState(() {
                  _isOccupied = true;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Property Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'container', child: Text('Container')),
                DropdownMenuItem(value: 'shop', child: Text('Shop')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Occupied', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Switch(
                  value: _isOccupied,
                  onChanged: (value) {
                    setState(() {
                      _isOccupied = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider authProvider) {
    final isAuthorized =
        authProvider.user?.role == 'admin' ||
        authProvider.user?.uid == widget.property.ownerUid;

    if (!isAuthorized) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (!_isEditing) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _isEditing = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Edit Property',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: _deleteProperty,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProperty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _isEditing = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Property' : 'Property Details'),
        actions: _isEditing
            ? []
            : [
                if (authProvider.user?.role == 'admin' ||
                    authProvider.user?.uid == widget.property.ownerUid)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // _buildImageGallery(),
                    const SizedBox(height: 24),
                    _isEditing ? _buildEditForm() : _buildPropertyInfo(),
                    const SizedBox(height: 16),
                    _buildActionButtons(authProvider),
                  ],
                ),
              ),
      ),
    );
  }
}
