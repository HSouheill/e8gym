import 'package:flutter/material.dart';
import '../screens/user/medical_citations_page.dart';

class MedicalCitationWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final EdgeInsets? padding;
  final bool showFullButton;

  const MedicalCitationWidget({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.padding,
    this.showFullButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MedicalCitationsPage(),
          ),
        );
      },
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              icon ?? Icons.info_outline,
              color: Colors.blue[300],
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) const SizedBox(height: 2),
                  ],
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.blue[200],
                        fontSize: 10,
                      ),
                    ),
                  if (showFullButton)
                    Text(
                      'View medical information sources',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                ],
              ),
            ),
            if (!showFullButton)
              Icon(
                Icons.open_in_new,
                color: Colors.blue[300],
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}

class MedicalDisclaimerWidget extends StatelessWidget {
  final String? customMessage;
  final EdgeInsets? padding;

  const MedicalDisclaimerWidget({
    super.key,
    this.customMessage,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning,
            color: Colors.red[400],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              customMessage ?? 
              'This information is for educational purposes only and should not be considered medical advice. Consult healthcare professionals for medical decisions.',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BMICitationWidget extends StatelessWidget {
  final String bmiValue;
  final String category;
  final bool showDisclaimer;

  const BMICitationWidget({
    super.key,
    required this.bmiValue,
    required this.category,
    this.showDisclaimer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MedicalCitationWidget(
          title: 'BMI: $bmiValue',
          subtitle: category,
          icon: Icons.monitor_weight,
          showFullButton: true,
        ),
        if (showDisclaimer) ...[
          const SizedBox(height: 8),
          const MedicalDisclaimerWidget(),
        ],
      ],
    );
  }
}
