import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/rewards/reward_service.dart';
import 'home_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const _RewardsScreen(),
    const _ParentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF4FF),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa'),
              _buildNavItem(1, Icons.emoji_events_rounded, 'Ödüller'),
              _buildNavItem(2, Icons.shield_rounded, 'Ebeveynler'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsScreen extends StatelessWidget {
  const _RewardsScreen();

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardService>(
      builder: (context, service, _) {
        final next = service.nextReward;
        final total = service.totalCorrect;

        return Scaffold(
          backgroundColor: const Color(0xFFEDF4FF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(total, next),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: RewardService.allRewards.length,
                    itemBuilder: (context, i) {
                      final reward = RewardService.allRewards[i];
                      final earned = service.isEarned(reward.id);
                      return _RewardCard(reward: reward, earned: earned, totalCorrect: total);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int total, Reward? next) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB8B0FF), Color(0xFF9B91FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B91FF).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ödüllerim',
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toplam $total doğru cevap',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            Text(
              'Sıradaki: ${next.emoji} ${next.title}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (total / next.requiredCorrect).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$total / ${next.requiredCorrect} doğru',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Tüm rozetleri kazandın! 👑',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final bool earned;
  final int totalCorrect;

  const _RewardCard({
    required this.reward,
    required this.earned,
    required this.totalCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: earned ? Colors.white : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: reward.color.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
        border: earned
            ? Border.all(color: reward.color.withOpacity(0.4), width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rozet görseli
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: earned
                        ? reward.color.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.15),
                  ),
                  child: earned
                      ? ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              reward.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Text(
                                reward.emoji,
                                style: const TextStyle(fontSize: 34),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      : const Icon(Icons.lock_rounded, size: 32, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  reward.title,
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: earned ? reward.color : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  earned
                      ? reward.description
                      : '${reward.requiredCorrect} doğru cevap',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: earned
                        ? Colors.grey[600]
                        : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          // "Yeni!" etiketi
          if (earned && totalCorrect == reward.requiredCorrect)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: reward.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'YENİ!',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParentScreen extends StatelessWidget {
  const _ParentScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF4FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_rounded,
              size: 80,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Ebeveyn Paneli',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yakında geliyor! 👨‍👩‍👧',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}