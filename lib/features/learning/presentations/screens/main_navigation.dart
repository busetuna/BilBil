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
      backgroundColor: AppColors.background,
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
        final pieces =
            active != null ? service.puzzlePiecesFor(active.id) : 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── Üst banner (SliverAppBar) ───────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFF9B91FF),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Aktif ödülün resmi banner arka planı
                      if (active != null)
                        Image.asset(active.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF9B91FF)))
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFB8B0FF), Color(0xFF9B91FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.55),
                            ],
                          ),
                        ),
                      ),
                      // İçerik
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ödül Koleksiyonu',
                              style: GoogleFonts.fredoka(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (active != null) ...[
                              Text(
                                '${active.emoji} ${active.title} — $pieces/${RewardService.puzzlePieceCount} parça',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9)),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pieces / RewardService.puzzlePieceCount,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.25),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  minHeight: 7,
                                ),
                              ),
                            ] else
                              Text(
                                'Tüm rozetleri kazandın! 👑',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Koleksiyon grid ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final reward = RewardService.allRewards[i];
                      final isEarned = service.isEarned(reward.id);
                      final isActive = active?.id == reward.id;
                      final p = service.puzzlePiecesFor(reward.id);
                      return _RewardCard(
                        reward: reward,
                        isEarned: isEarned,
                        isActive: isActive,
                        piecesEarned: p,
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
                    childCount: RewardService.allRewards.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Resim kartı ─────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (isEarned || isActive)
                        ? reward.color.withOpacity(0.25)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Tam resim
                    _buildCardImage(),

                    // Alt gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Alt başlık chip
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? reward.color
                              : isActive
                                  ? reward.color.withOpacity(0.85)
                                  : Colors.grey.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          reward.title,
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Kilitli overlay
                    if (!isEarned && !isActive)
                      Container(
                        color: Colors.black.withOpacity(0.45),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded,
                                  color: Colors.white70, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                'Kilitli',
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Kazanıldı rozeti
                    if (isEarned)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: reward.color,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),

                    // Aktif yapboz rozeti
                    if (isActive && !isEarned)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.extension_rounded,
                                  size: 10, color: reward.color),
                              const SizedBox(width: 2),
                              Text(
                                'Aktif',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: reward.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Progress / status bar ────────────────────────────────────────
          const SizedBox(height: 7),
          if (isActive && !isEarned) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: piecesEarned / RewardService.puzzlePieceCount,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(reward.color),
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$piecesEarned/${RewardService.puzzlePieceCount}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: reward.color,
                  ),
                ),
              ],
            ),
          ] else if (isEarned) ...[
            Row(
              children: [
                Icon(Icons.verified_rounded, size: 13, color: reward.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    reward.badgeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: reward.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'Önce aktif yapbozu tamamla',
                  style: GoogleFonts.poppins(
                      fontSize: 9, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardImage() {
    if (isEarned || isActive) {
      return Image.asset(
        reward.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: reward.color.withOpacity(0.15),
          child: Center(
              child: Text(reward.emoji,
                  style: const TextStyle(fontSize: 48))),
        ),
      );
    }
    // Kilitli — gri tonlu
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]),
      child: Image.asset(
        reward.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: Center(
              child: Text(reward.emoji,
                  style: const TextStyle(fontSize: 48))),
        ),
      ),
    );
  }
}
