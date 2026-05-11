import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/rewards/reward_service.dart';

class PuzzleScreen extends StatelessWidget {
  final Reward reward;
  static const int rows = 3, cols = 3;
  static const int total = rows * cols;

  // Parçalar ortadan başlayıp dağılarak dolar (daha doğal görünüm)
  static const List<int> _fillOrder = [4, 0, 8, 2, 6, 1, 7, 3, 5];

  const PuzzleScreen({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardService>(
      builder: (context, svc, _) {
        final pieces = svc.puzzlePiecesFor(reward.id);
        final isEarned = svc.isEarned(reward.id);
        final isActive = svc.activeReward?.id == reward.id;
        final isFuture = !isEarned && !isActive;

        final filledSlots = <int>{};
        for (int i = 0; i < pieces; i++) {
          filledSlots.add(_fillOrder[i]);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4FF),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: BackButton(color: AppColors.textPrimary),
            title: Text(
              reward.title,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildPreview(isFuture),
              const SizedBox(height: 14),
              _buildProgress(pieces, isEarned, isFuture),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildPuzzleGrid(filledSlots, isFuture),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildInventory(pieces, isFuture),
              const SizedBox(height: 14),
              _buildFooter(isEarned, isActive, isFuture),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreview(bool isFuture) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              reward.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: reward.color.withOpacity(0.2),
                child: Center(
                    child: Text(reward.emoji,
                        style: const TextStyle(fontSize: 60))),
              ),
            ),
            if (isFuture)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 34),
                      const SizedBox(height: 6),
                      Text(
                        'Önce aktif yapbozu tamamla',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            // Alt gradient + badge label
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  reward.badgeLabel,
                  style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(int pieces, bool isEarned, bool isFuture) {
    final displayed = isEarned ? total : pieces;
    final barColor = isFuture
        ? Colors.grey[300]!
        : isEarned
            ? const Color(0xFF43C659)
            : reward.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: displayed / total,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07), blurRadius: 6)
              ],
            ),
            child: Text(
              '$displayed/$total',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleGrid(Set<int> filledSlots, bool isFuture) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: total,
      itemBuilder: (context, slotIndex) {
        final row = slotIndex ~/ cols;
        final col = slotIndex % cols;
        final isFilled = !isFuture && filledSlots.contains(slotIndex);
        return _PuzzleTile(
          row: row,
          col: col,
          rows: rows,
          cols: cols,
          imagePath: reward.imagePath,
          isFilled: isFilled,
          accentColor: reward.color,
        );
      },
    );
  }

  Widget _buildInventory(int pieces, bool isFuture) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: reward.color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: total,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: total,
        itemBuilder: (context, i) {
          final collected = !isFuture && i < pieces;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: collected
                  ? reward.color.withOpacity(0.15)
                  : const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: collected
                    ? reward.color.withOpacity(0.5)
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: collected
                ? Icon(Icons.check_rounded, color: reward.color, size: 12)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildFooter(bool isEarned, bool isActive, bool isFuture) {
    if (isEarned) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF43C659), Color(0xFF2DA845)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF43C659).withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(reward.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Text(
                'Rozet Kazanıldı!',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 22),
            ],
          ),
        ),
      );
    }

    if (isFuture) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded,
              color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 6),
          Text(
            'Aktif yapbozu tamamlayarak bu ödülü aç',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.extension_rounded,
            color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          'Quiz\'de doğru cevapla parça kazan!',
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PuzzleTile extends StatelessWidget {
  final int row, col, rows, cols;
  final String imagePath;
  final bool isFilled;
  final Color accentColor;

  const _PuzzleTile({
    required this.row,
    required this.col,
    required this.rows,
    required this.cols,
    required this.imagePath,
    required this.isFilled,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.elasticOut,
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: isFilled ? _filled() : _empty(),
    );
  }

  Widget _filled() {
    return ClipRRect(
      key: const ValueKey(true),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth * cols;
            final h = constraints.maxHeight * rows;
            final ax = cols == 1 ? 0.0 : col / (cols - 1) * 2.0 - 1.0;
            final ay = rows == 1 ? 0.0 : row / (rows - 1) * 2.0 - 1.0;
            return ClipRect(
              child: OverflowBox(
                maxWidth: w,
                maxHeight: h,
                alignment: Alignment(ax, ay),
                child: Image.asset(
                  imagePath,
                  width: w,
                  height: h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: accentColor.withOpacity(0.3),
                    child: Center(
                      child:
                          Icon(Icons.pets, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty() {
    return ClipRRect(
      key: const ValueKey(false),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDDE3FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC5CDFF), width: 1.5),
        ),
        child: Center(
          child: Icon(
            Icons.extension_rounded,
            color: const Color(0xFFADB8FF),
            size: 22,
          ),
        ),
      ),
    );
  }
}
