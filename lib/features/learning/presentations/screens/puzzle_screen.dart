import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../services/rewards/reward_service.dart';

class PuzzleScreen extends StatelessWidget {
  final Reward reward;
  static const int rows = 3, cols = 3;

  const PuzzleScreen({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardService>(
      builder: (context, svc, _) {
        final pieces = svc.puzzlePiecesFor(reward.id);
        final total = RewardService.puzzlePieceCount;
        final isEarned = svc.isEarned(reward.id);
        final isActive = svc.activeReward?.id == reward.id;
        final isFuture = !isEarned && !isActive;

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4FF),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: BackButton(color: const Color(0xFF444444)),
            title: Text(
              '${reward.emoji} ${reward.title}',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF444444),
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildHeader(pieces, total, isEarned, isActive, isFuture),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _buildGrid(pieces, isEarned, isFuture),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFooter(isEarned, isActive, isFuture),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      int pieces, int total, bool isEarned, bool isActive, bool isFuture) {
    Color accent;
    String title;
    String subtitle;

    if (isEarned) {
      accent = const Color(0xFF43C659);
      title = 'Yapboz Tamamlandı! 🎉';
      subtitle = reward.description;
    } else if (isFuture) {
      accent = Colors.grey;
      title = 'Kilitli';
      subtitle = 'Önce aktif yapbozu tamamla';
    } else {
      accent = reward.color;
      title = 'Yapbozu Tamamla';
      subtitle = 'Her doğru cevap bir parça kazandırır';
    }

    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF888888)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (!isFuture)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: isEarned ? 1.0 : pieces / total,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEarned ? '$total/$total' : '$pieces/$total',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        if (isFuture)
          Icon(Icons.lock_rounded, size: 36, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildGrid(int pieces, bool isEarned, bool isFuture) {
    final total = RewardService.puzzlePieceCount;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: total,
      itemBuilder: (context, i) {
        final row = i ~/ cols;
        final col = i % cols;
        final pieceEarned = isEarned || i < pieces;
        return _PuzzlePiece(
          row: row,
          col: col,
          rows: rows,
          cols: cols,
          imagePath: reward.imagePath,
          earned: pieceEarned,
          locked: isFuture,
          color: reward.color,
        );
      },
    );
  }

  Widget _buildFooter(bool isEarned, bool isActive, bool isFuture) {
    if (isEarned) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43C659), Color(0xFF2DA845)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43C659).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(reward.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              'Rozet Kazanıldı!',
              style: GoogleFonts.fredoka(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
          ],
        ),
      );
    }

    if (isFuture) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            Text(
              'Aktif yapbozu tamamlayarak aç',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // isActive
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFAAAAAA)),
        const SizedBox(width: 6),
        Text(
          'Quiz\'de doğru cevapla parça kazan!',
          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFAAAAAA)),
        ),
      ],
    );
  }
}

class _PuzzlePiece extends StatelessWidget {
  final int row, col, rows, cols;
  final String imagePath;
  final bool earned;
  final bool locked;
  final Color color;

  const _PuzzlePiece({
    required this.row,
    required this.col,
    required this.rows,
    required this.cols,
    required this.imagePath,
    required this.earned,
    required this.locked,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.elasticOut,
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: earned ? _earnedPiece() : _emptyPiece(),
    );
  }

  Widget _earnedPiece() {
    return ClipRRect(
      key: const ValueKey(true),
      borderRadius: BorderRadius.circular(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth * cols;
          final h = constraints.maxHeight * rows;
          final ax = cols == 1 ? 0.0 : col / (cols - 1) * 2.0 - 1.0;
          final ay = rows == 1 ? 0.0 : row / (rows - 1) * 2.0 - 1.0;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRect(
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
                    color: color.withOpacity(0.3),
                    child: Center(
                      child: Icon(Icons.pets, color: color, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyPiece() {
    return ClipRRect(
      key: const ValueKey(false),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: locked ? Colors.grey[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked ? Colors.grey[200]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            locked ? Icons.lock_rounded : Icons.extension_rounded,
            color: locked ? Colors.grey[300] : Colors.grey[350],
            size: 26,
          ),
        ),
      ),
    );
  }
}