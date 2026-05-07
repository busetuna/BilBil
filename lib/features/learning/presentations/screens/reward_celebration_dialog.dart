import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/rewards/reward_service.dart';

void showRewardCelebration(BuildContext context, Reward reward) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: RewardCelebrationCard(
        reward: reward,
        onCollect: () => Navigator.pop(dialogContext),
      ),
    ),
  );
}

class RewardCelebrationCard extends StatefulWidget {
  final Reward reward;
  final VoidCallback onCollect;

  const RewardCelebrationCard({
    super.key,
    required this.reward,
    required this.onCollect,
  });

  @override
  State<RewardCelebrationCard> createState() => _RewardCelebrationCardState();
}

class _RewardCelebrationCardState extends State<RewardCelebrationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bounceAnim = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );
    _bounceController.forward();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceAnim,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD6EFFA),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            _buildConfetti(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: widget.onCollect,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.75),
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Harika!',
                    style: GoogleFonts.fredoka(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  Text(
                    'Yeni Ödül!',
                    style: GoogleFonts.fredoka(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildBadgeCircle(),
                  const SizedBox(height: 20),
                  Text(
                    widget.reward.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF6B35),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onCollect,
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.white, size: 20),
                      label: Text(
                        'KOLEKSİYONA EKLE',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43C659),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
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

  Widget _buildBadgeCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 190,
          height: 190,
          child: CustomPaint(painter: _SunburstPainter()),
        ),
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                widget.reward.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  widget.reward.emoji,
                  style: const TextStyle(fontSize: 60),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              widget.reward.badgeLabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF6B35),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfetti() {
    const dots = [
      _ConfettiDot(left: 18, top: 50, color: Color(0xFFFF6B35), size: 11),
      _ConfettiDot(left: 36, top: 100, color: Color(0xFF43C659), size: 8),
      _ConfettiDot(left: 14, top: 160, color: Color(0xFF1565C0), size: 9),
      _ConfettiDot(right: 18, top: 50, color: Color(0xFF9C27B0), size: 10),
      _ConfettiDot(right: 36, top: 110, color: Color(0xFFFFC107), size: 13),
      _ConfettiDot(right: 14, top: 170, color: Color(0xFFE91E63), size: 8),
      _ConfettiDot(left: 60, top: 28, color: Color(0xFFFFC107), size: 7),
      _ConfettiDot(right: 60, top: 28, color: Color(0xFF43C659), size: 7),
    ];

    return Positioned.fill(
      child: Stack(
        children: dots
            .map((d) => Positioned(
                  left: d.left,
                  right: d.right,
                  top: d.top,
                  bottom: d.bottom,
                  child: Container(
                    width: d.size,
                    height: d.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: d.color,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ConfettiDot {
  final double? left, right, top, bottom;
  final Color color;
  final double size;

  const _ConfettiDot({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.color,
    required this.size,
  });
}

class _SunburstPainter extends CustomPainter {
  const _SunburstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const totalRays = 16;
    const twoPi = pi * 2;
    const sweepAngle = twoPi / totalRays;

    for (int i = 0; i < totalRays; i++) {
      final startAngle = i * sweepAngle;
      final paint = Paint()
        ..color = i.isEven ? const Color(0xFFFFF9C4) : const Color(0xFFFFF176)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter _) => false;
}