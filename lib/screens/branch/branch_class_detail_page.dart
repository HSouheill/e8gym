import 'package:flutter/material.dart';
import '../../models/branch_class_models.dart';
import '../../services/api_service.dart';
import '../../utils/background_image_service.dart';

class BranchClassDetailPage extends StatefulWidget {
  final String accessToken;
  final String branchId;
  final String classId;
  final String branchName;
  
  const BranchClassDetailPage({
    super.key,
    required this.accessToken,
    required this.branchId,
    required this.classId,
    required this.branchName,
  });

  @override
  State<BranchClassDetailPage> createState() => _BranchClassDetailPageState();
}

class _BranchClassDetailPageState extends State<BranchClassDetailPage> {
  BranchClassResponse? _class;
  bool _isLoading = true;
  String? _backgroundImageUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _loadClassDetails();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final backgroundUrl = await BackgroundImageService.loadBackgroundImage(
        widget.accessToken,
        dashboardType: 'superadmin',
      );
      
      if (mounted && backgroundUrl != null && backgroundUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = backgroundUrl;
        });
      }
    } catch (e) {
      final cachedUrl = await BackgroundImageService.getCachedBackgroundUrl(
        dashboardType: 'superadmin',
      );
      if (mounted && cachedUrl != null && cachedUrl.isNotEmpty) {
        setState(() {
          _backgroundImageUrl = cachedUrl;
        });
      }
    }
  }

  Future<void> _loadClassDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getBranchClassForSuperAdmin(
        widget.branchId,
        widget.classId,
        widget.accessToken,
      );

      if (result['success'] && result['data'] != null) {
        setState(() {
          _class = BranchClassResponse.fromJson(result['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load class details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading class details: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class Details - ${widget.branchName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadClassDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Base gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white70],
              ),
            ),
          ),
          
          // Static background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/E8Logos/admin_dashboard_background.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Dynamic background image overlay
          if (_backgroundImageUrl != null)
            Positioned.fill(
              child: Image.network(
                _backgroundImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          
          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0x50000000),
              ),
            ),
          ),
          
          // Main content
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadClassDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_class != null)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Header Card
                  _buildClassHeaderCard(),
                  const SizedBox(height: 16),
                  
                  // Class Details Card
                  _buildClassDetailsCard(),
                  const SizedBox(height: 16),
                  
                  // Schedule Card
                  _buildScheduleCard(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassHeaderCard() {
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
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
                        _class!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Branch: ${widget.branchName}',
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
                  _class!.isActive ? 'Active' : 'Inactive',
                  _class!.isActive ? Colors.green : Colors.red,
                  Icons.circle,
                ),
                const SizedBox(width: 12),
                _buildStatusChip(
                  (_class!.isVisible ?? true) ? 'Visible' : 'Hidden',
                  (_class!.isVisible ?? true) ? Colors.blue : Colors.orange,
                  Icons.visibility,
                ),
                if (_class!.isExpired || (_class!.expiresAt != null && DateTime.now().isAfter(_class!.expiresAt!)))
                  ...[
                    const SizedBox(width: 12),
                    _buildStatusChip(
                      'Expired',
                      Colors.red,
                      Icons.warning,
                    ),
                  ],
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

  Widget _buildClassDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (_class!.description.isNotEmpty) ...[
              _buildDetailRow(Icons.description, 'Description', _class!.description),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(Icons.person, 'Instructor', _class!.instructor),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.timer, 'Duration', '${_class!.duration} minutes'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.people, 'Capacity', '${_class!.capacity} members'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.event_seat, 'Booked', '${_class!.bookedCount} bookings'),
            const SizedBox(height: 12),
            if (_class!.expiresAt != null)
              _buildDetailRow(
                Icons.calendar_today,
                'Expires At',
                _formatDate(_class!.expiresAt!),
              ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.calendar_today, 'Created', _formatDate(_class!.createdAt)),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.update, 'Last Updated', _formatDate(_class!.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
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

  Widget _buildScheduleCard() {
    if (_class!.schedule.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'No schedule available',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _class!.schedule.length,
              itemBuilder: (context, index) {
                final schedule = _class!.schedule[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDayName(schedule.dayOfWeek),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${_formatDate(schedule.date)} - ${_formatTime(schedule.startTime)} to ${_formatTime(schedule.endTime)}',
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
}

