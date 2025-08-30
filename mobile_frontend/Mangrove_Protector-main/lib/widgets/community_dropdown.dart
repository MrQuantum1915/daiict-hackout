import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/models/community_model.dart';

class CommunityDropdown extends StatefulWidget {
  final Function(String?) onChanged;

  const CommunityDropdown({
    super.key,
    required this.onChanged,
  });

  @override
  State<CommunityDropdown> createState() => _CommunityDropdownState();
}

class _CommunityDropdownState extends State<CommunityDropdown> {
  String? _selectedCommunityId;
  List<Community> _communities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final communities = await authProvider.getAllCommunities();
      
      setState(() {
        _communities = communities;
        
        // If there's only one community, select it automatically
        if (_communities.length == 1) {
          _selectedCommunityId = _communities.first.id;
          widget.onChanged(_selectedCommunityId);
        }
      });
    } catch (e) {
      debugPrint('Error loading communities: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_communities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No communities found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Please create a new community to continue',
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Community',
        prefixIcon: Icon(Icons.group),
        border: OutlineInputBorder(),
      ),
      initialValue: _selectedCommunityId,
      items: _communities.map((community) {
        return DropdownMenuItem<String>(
          value: community.id,
          child: Text(community.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCommunityId = value;
        });
        widget.onChanged(value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a community';
        }
        return null;
      },
    );
  }
}

