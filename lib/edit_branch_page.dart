import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/auth_models.dart';
import 'models/standalone_class_models.dart';

class EditBranchPage extends StatefulWidget {
  final String accessToken;
  final BranchResponse branch;
  
  const EditBranchPage({
    super.key,
    required this.accessToken,
    required this.branch,
  });

  @override
  State<EditBranchPage> createState() => _EditBranchPageState();
}

class _EditBranchPageState extends State<EditBranchPage> {
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingClasses = false;
  
  // Class selection
  List<StandaloneClassResponse> _availableClasses = [];
  List<StandaloneClassResponse> _selectedClasses = [];
  
  // Team member management
  List<TeamMemberModel> _teamMembers = [];
  final TextEditingController _teamMemberNameController = TextEditingController();
  final TextEditingController _teamMemberEmailController = TextEditingController();
  final TextEditingController _teamMemberPhoneController = TextEditingController();
  final TextEditingController _teamMemberRoleController = TextEditingController();
  String _selectedCountryCode = '+1';
  bool _showAddTeamMemberForm = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAvailableClasses();
  }

  void _initializeControllers() {
    _branchNameController.text = widget.branch.branchName;
    _adminNameController.text = widget.branch.adminName;
    _emailController.text = widget.branch.email;
    _phoneNumberController.text = widget.branch.phoneNumber;
    _locationController.text = widget.branch.location ?? '';
    
    // Initialize team members
    _teamMembers = List.from(widget.branch.teamMembers);
    
    // Initialize selected classes (convert from ClassModel to StandaloneClassResponse)
    // Note: This is a simplified conversion - in a real app you'd need proper mapping
    _selectedClasses = [];
  }

  Future<void> _loadAvailableClasses() async {
    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final result = await ApiService.getStandaloneClasses(
        widget.accessToken,
        limit: 100,
      );

      if (result['success']) {
        final data = result['data'];
        final classListResponse = StandaloneClassListResponse.fromJson(data);
        
        setState(() {
          _availableClasses = classListResponse.classes.where((c) => c.isActive).toList();
        });
      } else {
        _showSnackBar(result['message'] ?? 'Failed to load available classes');
      }
    } catch (e) {
      _showSnackBar('An error occurred while loading classes: $e');
    } finally {
      setState(() {
        _isLoadingClasses = false;
      });
    }
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _adminNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _locationController.dispose();
    
    // Team member controllers
    _teamMemberNameController.dispose();
    _teamMemberEmailController.dispose();
    _teamMemberPhoneController.dispose();
    _teamMemberRoleController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Branch: ${widget.branch.branchName}'),
        backgroundColor: const Color(0xFFF8BB0C),
        foregroundColor: Colors.black,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8BB0C), Color(0xFF926E07)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branch Information Section
              _buildSectionCard(
                'Branch Information',
                Icons.business,
                [
                  _buildTextField(
                    controller: _branchNameController,
                    label: 'Branch Name',
                    icon: Icons.business,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Branch name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _adminNameController,
                    label: 'Admin Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Admin name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneNumberController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location',
                    icon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Location is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Classes Section
              _buildSectionCard(
                'Classes',
                Icons.fitness_center,
                [
                  if (_isLoadingClasses)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'Selected Classes (${_selectedClasses.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedClasses.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No classes selected',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedClasses.length,
                            itemBuilder: (context, index) {
                              final classItem = _selectedClasses[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                                                             child: Text(
                                         classItem.name,
                                         style: const TextStyle(
                                           fontWeight: FontWeight.w600,
                                         ),
                                       ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _selectedClasses.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        _buildClassSelectionDropdown(),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Team Members Section
              _buildSectionCard(
                'Team Members',
                Icons.people,
                [
                  Text(
                    'Current Team Members (${_teamMembers.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_teamMembers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No team members added',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _teamMembers.length,
                      itemBuilder: (context, index) {
                        final member = _teamMembers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFF8BB0C),
                                child: Text(
                                  member.fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      member.role,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      member.email,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _teamMembers.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  if (_showAddTeamMemberForm) _buildAddTeamMemberForm(),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAddTeamMemberForm = !_showAddTeamMemberForm;
                      });
                    },
                    icon: Icon(_showAddTeamMemberForm ? Icons.remove : Icons.add),
                    label: Text(_showAddTeamMemberForm ? 'Cancel' : 'Add Team Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8BB0C),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8BB0C),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Save Changes',
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
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFF8BB0C), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFF8BB0C)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF8BB0C), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildClassSelectionDropdown() {
    return DropdownButtonFormField<StandaloneClassResponse>(
      decoration: InputDecoration(
        labelText: 'Add Class',
        prefixIcon: const Icon(Icons.fitness_center, color: Color(0xFFF8BB0C)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF8BB0C), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      value: null,
      items: _availableClasses
          .where((c) => !_selectedClasses.contains(c))
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c.name),
              ))
          .toList(),
      onChanged: (StandaloneClassResponse? value) {
        if (value != null) {
          setState(() {
            _selectedClasses.add(value);
          });
        }
      },
    );
  }

  Widget _buildAddTeamMemberForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _teamMemberNameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _teamMemberRoleController,
                  label: 'Role',
                  icon: Icons.work,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Role is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _teamMemberEmailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _teamMemberPhoneController,
                  label: 'Phone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addTeamMember,
            icon: const Icon(Icons.add),
            label: const Text('Add Member'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8BB0C),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _addTeamMember() {
    if (_teamMemberNameController.text.isEmpty ||
        _teamMemberEmailController.text.isEmpty ||
        _teamMemberPhoneController.text.isEmpty ||
        _teamMemberRoleController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    final newMember = TeamMemberModel(
      fullName: _teamMemberNameController.text,
      email: _teamMemberEmailController.text,
      phoneNumber: _teamMemberPhoneController.text,
      countryCode: _selectedCountryCode,
      role: _teamMemberRoleController.text,
    );

    setState(() {
      _teamMembers.add(newMember);
      _showAddTeamMemberForm = false;
    });

    // Clear form
    _teamMemberNameController.clear();
    _teamMemberEmailController.clear();
    _teamMemberPhoneController.clear();
    _teamMemberRoleController.clear();

    _showSnackBar('Team member added successfully');
  }

  Future<void> _saveChanges() async {
    // Validate required fields
    if (_branchNameController.text.isEmpty ||
        _adminNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _locationController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to update branch
      // For now, just show a success message
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        _showSnackBar('Branch updated successfully');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF8BB0C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
