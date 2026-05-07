import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/rewards/reward_service.dart';
import 'home_screen.dart';
import 'puzzle_screen.dart';
import '../../../parent/screens/parent_pin_screen.dart';

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
    const HomeScreen(), // placeholder — Ebeveynler tapped navigates via push
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
              _buildNavItem(2, Icons.shield_rounded, 'Ebeveynler',
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ParentPinScreen()),
                      )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {VoidCallback? onTap}) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: onTap ?? () => setState(() => _currentIndex = index),
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
        final active = service.activeReward;
        final total = service.totalCorrect;

        return Scaffold(
          backgroundColor: const Color(0xFFEDF4FF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(total, active, service),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: RewardService.allRewards.length,
                    itemBuilder: (context, i) {
                      final reward = RewardService.allRewards[i];
                      final isEarned = service.isEarned(reward.id);
                      final isActive = active?.id == reward.id;
                      final pieces = service.puzzlePiecesFor(reward.id);
                      return _RewardCard(
                        reward: reward,
                        isEarned: isEarned,
                        isActive: isActive,
                        piecesEarned: pieces,
                        onTap: (isEarned || isActive)
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PuzzleScreen(reward: reward),
                                  ),
                                )
                            : null,
                      );
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

  Widget _buildHeader(int total, Reward? active, RewardService service) {
    final pieces = active != null ? service.puzzlePiecesFor(active.id) : 0;
    final total9 = RewardService.puzzlePieceCount;

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
          if (active != null) ...[
            const SizedBox(height: 12),
            Text(
              'Aktif Yapboz: ${active.emoji} ${active.title}',
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
                value: pieces / total9,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$pieces / $total9 parça',
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
  final bool isEarned;
  final bool isActive;
  final int piecesEarned;
  final VoidCallback? onTap;

  const _RewardCard({
    required this.reward,
    required this.isEarned,
    required this.isActive,
    required this.piecesEarned,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: isEarned
              ? Colors.white
              : isActive
                  ? Colors.white
                  : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(24),
          boxShadow: (isEarned || isActive)
              ? [
                  BoxShadow(
                    color: reward.color.withOpacity(0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
          border: isEarned
              ? Border.all(color: reward.color.withOpacity(0.4), width: 2)
              : isActive
                  ? Border.all(
                      color: reward.color.withOpacity(0.3), width: 1.5)
                  : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 10),
                  Text(
                    reward.title,
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isEarned
                          ? reward.color
                          : isActive
                              ? const Color(0xFF555555)
                              : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (isActive && !isEarned) ...[
                    Text(
                      '$piecesEarned/${RewardService.puzzlePieceCount} parça',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: reward.color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: piecesEarned / RewardService.puzzlePieceCount,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(reward.color),
                        minHeight: 6,
                      ),
                    ),
                  ] else if (isEarned)
                    Text(
                      reward.badgeLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      'Kilitli',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
            // Tıklanabilir ok
            if (isActive && !isEarned)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.chevron_right_rounded,
                    size: 18, color: Colors.grey[400]),
              ),
            // Tamamlandı tik
            if (isEarned)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reward.color,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (isEarned) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reward.color.withOpacity(0.12),
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              reward.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Text(reward.emoji, style: const TextStyle(fontSize: 34)),
            ),
          ),
        ),
      );
    }

    if (isActive) {
      // Yapboz ön izleme — kazanılan parça sayısı kadar dolmuş mini grid
      return SizedBox(
        width: 72,
        height: 72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: 9,
            itemBuilder: (_, i) {
              final row = i ~/ 3;
              final col = i % 3;
              final has = i < piecesEarned;
              if (!has) {
                return Container(color: Colors.grey[200]);
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth * 3;
                  final h = constraints.maxHeight * 3;
                  final ax = col / 2 * 2.0 - 1.0;
                  final ay = row / 2 * 2.0 - 1.0;
                  return ClipRect(
                    child: OverflowBox(
                      maxWidth: w,
                      maxHeight: h,
                      alignment: Alignment(ax, ay),
                      child: Image.asset(
                        reward.imagePath,
                        width: w,
                        height: h,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: reward.color.withOpacity(0.3)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    }

    // Future — kilitli
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withOpacity(0.15),
      ),
      child: const Icon(Icons.lock_rounded, size: 30, color: Colors.grey),
    );
  }
}
