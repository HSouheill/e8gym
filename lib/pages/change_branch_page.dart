import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/auth_models.dart';

class ChangeBranchPage extends StatefulWidget {
  final String accessToken;
  final BranchResponse? currentBranch;

  const ChangeBranchPage({
    super.key,
    required this.accessToken,
    this.currentBranch,
  });

  @override
  State<ChangeBranchPage> createState() => _ChangeBranchPageState();
}

class _ChangeBranchPageState extends State<ChangeBranchPage> {
  // State
  bool _isLoading = true;
  bool _isChanging = false;
  String? _errorMessage;
  List<BranchResponse> _branches = [];
  BranchResponse? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getAllBranches(widget.accessToken);
      
      if (result['success']) {
        final data = result['data'];
        final branchesData = data['branches'] as List?;
        
        if (branchesData != null) {
          final branches = branchesData
              .map((branchData) => BranchResponse.fromJson(branchData))
              .toList();
          
          setState(() {
            _branches = branches;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No branches found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load branches';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeBranch() async {
    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a branch'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.currentBranch != null && _selectedBranch!.id == widget.currentBranch!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already a member of this branch'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isChanging = true;
    });

    try {
      final request = ChangeBranchRequest(branchId: _selectedBranch!.id);
      final result = await ApiService.changeUserBranch(request, widget.accessToken);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Branch changed successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate back after successful branch change
        Navigator.of(context).pop(_selectedBranch);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to change branch'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error changing branch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isChanging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0x50000000),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Change Branch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Current Branch Info
                if (widget.currentBranch != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Branch:',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                widget.currentBranch!.branchName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.currentBranch!.location,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Content
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BB0C)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBranches,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8BB0C),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_branches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              color: Colors.white70,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No branches available',
              style: TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFF8BB0C),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select a branch to change your membership. You will have access to classes and services at the selected branch.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Branches List
        Expanded(
          child: ListView.builder(
            itemCount: _branches.length,
            itemBuilder: (context, index) {
              final branch = _branches[index];
              final isSelected = _selectedBranch?.id == branch.id;
              final isCurrentBranch = widget.currentBranch?.id == branch.id;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: isSelected 
                      ? const Color(0xFFF8BB0C).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: isCurrentBranch ? null : () {
                      setState(() {
                        _selectedBranch = branch;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFFF8BB0C)
                              : isCurrentBranch
                                  ? Colors.green
                                  : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Branch Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isCurrentBranch
                                  ? Colors.green.withOpacity(0.2)
                                  : const Color(0xFFF8BB0C).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isCurrentBranch
                                    ? Colors.green
                                    : const Color(0xFFF8BB0C),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isCurrentBranch ? Icons.check : Icons.location_on,
                              color: isCurrentBranch
                                  ? Colors.green
                                  : const Color(0xFFF8BB0C),
                              size: 24,
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Branch Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        branch.branchName,
                                        style: TextStyle(
                                          color: isCurrentBranch
                                              ? Colors.green
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentBranch)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Current',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  branch.location,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                if (branch.adminName.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Admin: ${branch.adminName}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Selection Indicator
                          if (isSelected && !isCurrentBranch)
                            const Icon(
                              Icons.radio_button_checked,
                              color: Color(0xFFF8BB0C),
                              size: 24,
                            )
                          else if (!isCurrentBranch)
                            const Icon(
                              Icons.radio_button_unchecked,
                              color: Colors.white70,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Change Branch Button
        if (_selectedBranch != null && _selectedBranch!.id != widget.currentBranch?.id)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isChanging ? null : _changeBranch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8BB0C),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isChanging
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Change to ${_selectedBranch?.branchName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
