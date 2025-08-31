import 'package:flutter/material.dart';
import 'models/auth_models.dart';
import 'edit_branch_page.dart';

class BranchDetailPage extends StatefulWidget {
  final String accessToken;
  final BranchResponse branch;
  
  const BranchDetailPage({
    super.key,
    required this.accessToken,
    required this.branch,
  });

  @override
  State<BranchDetailPage> createState() => _BranchDetailPageState();
}

class _BranchDetailPageState extends State<BranchDetailPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Branch: ${widget.branch.branchName}'),
        backgroundColor: const Color(0xFFF8BB0C),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editBranch(),
            tooltip: 'Edit Branch',
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
              // Branch Header Card
              _buildBranchHeaderCard(),
              const SizedBox(height: 16),
              
              // Branch Details Card
              _buildBranchDetailsCard(),
              const SizedBox(height: 16),
              
              // Classes Card
              _buildClassesCard(),
              const SizedBox(height: 16),
              
              // Team Members Card
              _buildTeamMembersCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchHeaderCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8BB0C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.branch.branchName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Admin: ${widget.branch.adminName}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
                         Row(
               children: [
                 _buildStatusChip(
                   'Branch',
                   const Color(0xFFF8BB0C),
                   Icons.business,
                 ),
                 const SizedBox(width: 12),
                 _buildStatusChip(
                   'Admin: ${widget.branch.adminName}',
                   Colors.blue,
                   Icons.person,
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Branch Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.email, 'Email', widget.branch.email),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.phone, 'Phone', widget.branch.phoneNumber),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, 'Location', widget.branch.location ?? 'Not specified'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.calendar_today, 'Created', _formatDate(widget.branch.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF8BB0C), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassesCard() {
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
                const Icon(Icons.fitness_center, color: Color(0xFFF8BB0C)),
                const SizedBox(width: 8),
                const Text(
                  'Classes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.branch.classes.length} classes',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.branch.classes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No classes assigned to this branch',
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
                itemCount: widget.branch.classes.length,
                itemBuilder: (context, index) {
                  final classItem = widget.branch.classes[index];
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
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 classItem.name,
                                 style: const TextStyle(
                                   fontWeight: FontWeight.w600,
                                   color: Colors.black87,
                                 ),
                               ),
                               Text(
                                 'Duration: ${classItem.duration} minutes',
                                 style: const TextStyle(
                                   fontSize: 12,
                                   color: Colors.black54,
                                 ),
                               ),
                             ],
                           ),
                         ),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.green,
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: const Text(
                             'Active',
                             style: TextStyle(
                               color: Colors.white,
                               fontSize: 10,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMembersCard() {
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
                const Icon(Icons.people, color: Color(0xFFF8BB0C)),
                const SizedBox(width: 8),
                const Text(
                  'Team Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.branch.teamMembers.length} members',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.branch.teamMembers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No team members assigned to this branch',
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
                itemCount: widget.branch.teamMembers.length,
                itemBuilder: (context, index) {
                  final member = widget.branch.teamMembers[index];
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
                                   color: Colors.black87,
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
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editBranch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBranchPage(
          accessToken: widget.accessToken,
          branch: widget.branch,
        ),
      ),
    );
  }
}
