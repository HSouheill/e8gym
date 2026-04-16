import 'package:flutter/material.dart';

class UserSidebar extends StatelessWidget {
  final String currentPage;
  final Function(String) onPageChanged;
  final VoidCallback onLogout;

  const UserSidebar({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallDevice = screenWidth < 400;
    final titleFontSize = isSmallDevice ? 20.0 : 24.0;
    final iconSize = isSmallDevice ? 22.0 : 24.0;
    final headerPadding = isSmallDevice ? 20.0 : 24.0;
    final itemFontSize = isSmallDevice ? 16.0 : 18.0;

    return Container(
      width: (screenWidth * 0.75).clamp(220.0, 280.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          right: BorderSide(
            color: Colors.white,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(headerPadding),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallDevice ? 42 : 48,
                  height: isSmallDevice ? 42 : 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.black,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isSmallDevice ? 10 : 14),
                Expanded(
                  child: Text(
                    'E8Gym',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  page: 'dashboard',
                  isSelected: currentPage == 'dashboard',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Profile',
                  page: 'profile',
                  isSelected: currentPage == 'profile',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.location_on,
                  title: 'Change Branch',
                  page: 'change_branch',
                  isSelected: currentPage == 'change_branch',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.lock,
                  title: 'Change Password',
                  page: 'change_password',
                  isSelected: currentPage == 'change_password',
                ),
               
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: EdgeInsets.all(isSmallDevice ? 16 : 20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white,
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: Colors.black, size: 24),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: itemFontSize,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String page,
    required bool isSelected,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallDevice = screenWidth < 400;
    final itemFontSize = isSmallDevice ? 16.0 : 18.0;
    final iconSize = isSmallDevice ? 22.0 : 24.0;
    final navHorizontalMargin = isSmallDevice ? 10.0 : 14.0;
    final navVerticalMargin = isSmallDevice ? 4.0 : 6.0;
    final navVerticalPadding = isSmallDevice ? 12.0 : 14.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: navHorizontalMargin,
        vertical: navVerticalMargin,
      ),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onPageChanged(page),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: navVerticalPadding,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: iconSize,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: itemFontSize,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
