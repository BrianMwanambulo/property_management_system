import 'package:flutter/material.dart';
import 'package:property_management_system/api/database_service.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/models/maintenance_model.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_viewer/image_viewer.dart';

class MaintenanceDetailScreen extends StatefulWidget {
  final MaintenanceModel maintenanceRequest;

  const MaintenanceDetailScreen({super.key, required this.maintenanceRequest});

  @override
  State<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  String? _selectedAssignee;

  // For property owners/admins to update status
  String? _selectedStatus;
  final List<String> _availableStaff = [
    'Maintenance Team 1',
    'Maintenance Team 2',
    'External Contractor',
    'John Doe (Plumber)',
    'Jane Smith (Electrician)'
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.maintenanceRequest.status;
    _selectedAssignee = widget.maintenanceRequest.assignedTo;
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    setState(() => _isLoading = true);

    try {
      await _databaseService.updateMaintenanceStatus(
        widget.maintenanceRequest.id,
        _selectedStatus!,
        assignedTo: _selectedStatus == 'assigned' || _selectedStatus == 'in_progress'
            ? _selectedAssignee
            : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully!')),
      );

      // Refresh the data
      Navigator.pop(context, true); // Return true to indicate update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this maintenance request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await _databaseService.updateMaintenanceStatus(
          widget.maintenanceRequest.id,
          'cancelled',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled successfully!')),
        );

        Navigator.pop(context, true); // Return true to indicate update
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel request: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImageGallery() {
    if (widget.maintenanceRequest.images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.photo_library, size: 60, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attached Images',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.maintenanceRequest.images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Show image in full screen
                  ImageViewer.showImageSlider(
                    images: widget.maintenanceRequest.images,
                    startingPosition: index,
                  );
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(widget.maintenanceRequest.images[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final statusColors = {
      'pending': Colors.orange,
      'assigned': Colors.blue,
      'in_progress': Colors.blue,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };

    final statusText = {
      'pending': 'PENDING',
      'assigned': 'ASSIGNED',
      'in_progress': 'IN PROGRESS',
      'completed': 'COMPLETED',
      'cancelled': 'CANCELLED',
    };

    return Chip(
      label: Text(
        statusText[status] ?? status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: statusColors[status] ?? Colors.grey,
    );
  }

  Widget _buildPriorityChip(String priority) {
    final priorityColors = {
      'low': Colors.green,
      'medium': Colors.orange,
      'high': Colors.red,
      'urgent': Colors.purple,
    };

    return Chip(
      label: Text(
        priority.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: priorityColors[priority] ?? Colors.grey,
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Request ID', '${widget.maintenanceRequest.id.substring(0, 8)}...'),
            _buildInfoRow('Property', widget.maintenanceRequest.propertyNumber),
            _buildInfoRow('Submitted By', widget.maintenanceRequest.requesterName),
            _buildInfoRow('Category', widget.maintenanceRequest.category.toUpperCase()),
            _buildInfoRow('Priority', '', customWidget: _buildPriorityChip(widget.maintenanceRequest.priority)),
            _buildInfoRow('Status', '', customWidget: _buildStatusChip(widget.maintenanceRequest.status)),
            if (widget.maintenanceRequest.assignedTo != null)
              _buildInfoRow('Assigned To', widget.maintenanceRequest.assignedTo!),
            _buildInfoRow('Submitted On', DateFormat('MMM dd, yyyy - HH:mm').format(widget.maintenanceRequest.createdAt)),
            if (widget.maintenanceRequest.completedAt != null)
              _buildInfoRow('Completed On', DateFormat('MMM dd, yyyy - HH:mm').format(widget.maintenanceRequest.completedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? customWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: customWidget ?? Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.maintenanceRequest.description),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider authProvider) {
    final user = authProvider.user;
    final isTenant = user?.role == 'tenant';
    final isPropertyOwner = user?.role == 'property_owner' || user?.role == 'admin';
    final canCancel = isTenant && widget.maintenanceRequest.status == 'pending';
    final canUpdate = isPropertyOwner && widget.maintenanceRequest.status != 'completed' && widget.maintenanceRequest.status != 'cancelled';

    if (!canCancel && !canUpdate) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canCancel)
            OutlinedButton(
              onPressed: _isLoading ? null : _cancelRequest,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Cancel Request', style: TextStyle(color: Colors.red)),
            ),
          if (canUpdate) ...[
            const SizedBox(height: 16),
            const Text(
              'Update Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            if (_selectedStatus == 'assigned' || _selectedStatus == 'in_progress') ...[
              const SizedBox(height: 16),
              const Text(
                'Assign To',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAssignee,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Select assignee',
                ),
                items: _availableStaff.map((staff) {
                  return DropdownMenuItem(
                    value: staff,
                    child: Text(staff),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssignee = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateStatus,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1565C0),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text('Update Status', style: TextStyle(color: Colors.white)),
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
        title: const Text('Maintenance Request'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              Text(
                widget.maintenanceRequest.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
        
              // Image Gallery
              _buildImageGallery(),
              const SizedBox(height: 24),
        
              // Info Section
              _buildInfoSection(),
              const SizedBox(height: 16),
        
              // Description Section
              _buildDescriptionSection(),
              const SizedBox(height: 16),
        
              // Action Buttons
              _buildActionButtons(authProvider),
            ],
          ),
        ),
      ),
    );
  }
}