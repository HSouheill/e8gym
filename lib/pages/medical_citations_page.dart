import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalCitationsPage extends StatelessWidget {
  const MedicalCitationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Medical Information Sources',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8BB0C), Color(0xFFE6A500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_information,
                    color: Colors.black,
                    size: 32,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Medical Information Sources',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All health and medical information provided in this app is sourced from authoritative medical organizations and peer-reviewed research.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // BMI Information Section
            _buildSection(
              title: 'Body Mass Index (BMI) Calculations',
              icon: Icons.monitor_weight,
              children: [
                _buildCitation(
                  title: 'World Health Organization (WHO)',
                  subtitle: 'BMI Classification Standards',
                  url: 'https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight',
                  description: 'Official BMI classification standards used globally for adults.',
                ),
                _buildCitation(
                  title: 'Centers for Disease Control and Prevention (CDC)',
                  subtitle: 'BMI Calculator and Information',
                  url: 'https://www.cdc.gov/healthyweight/assessing/bmi/index.html',
                  description: 'Comprehensive BMI information and health implications.',
                ),
                _buildCitation(
                  title: 'National Heart, Lung, and Blood Institute',
                  subtitle: 'BMI Guidelines',
                  url: 'https://www.nhlbi.nih.gov/health/educational/lose_wt/BMI/bmicalc.htm',
                  description: 'BMI calculation methods and health risk assessments.',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Health Information Section
            _buildSection(
              title: 'General Health Information',
              icon: Icons.health_and_safety,
              children: [
                _buildCitation(
                  title: 'American Heart Association',
                  subtitle: 'Physical Activity Guidelines',
                  url: 'https://www.heart.org/en/healthy-living/fitness/fitness-basics/aha-recs-for-physical-activity-in-adults',
                  description: 'Exercise recommendations for cardiovascular health.',
                ),
                _buildCitation(
                  title: 'Mayo Clinic',
                  subtitle: 'Healthy Lifestyle Guidelines',
                  url: 'https://www.mayoclinic.org/healthy-lifestyle',
                  description: 'Evidence-based health and wellness information.',
                ),
                _buildCitation(
                  title: 'Harvard T.H. Chan School of Public Health',
                  subtitle: 'Nutrition and Health Resources',
                  url: 'https://www.hsph.harvard.edu/nutritionsource/',
                  description: 'Research-based nutrition and health guidance.',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Disclaimer Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red[400],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Important Medical Disclaimer',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The health information provided in this app is for educational purposes only and should not be considered as medical advice. Always consult with qualified healthcare professionals before making any health-related decisions or starting new exercise programs.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contact Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Questions About Medical Information?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you have questions about the medical information in this app, please consult with your healthcare provider or contact us at:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _launchEmail('support@e8gym.online'),
                    child: const Text(
                      'support@e8gym.online',
                      style: TextStyle(
                        color: Color(0xFFF8BB0C),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFF8BB0C),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildCitation({
    required String title,
    required String subtitle,
    required String url,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFF8BB0C),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _launchUrl(url),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8BB0C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.open_in_new,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Question about Medical Information in E8Gym App',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}
