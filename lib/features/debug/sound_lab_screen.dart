import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../services/rl_agent/rl_agent.dart';
import '../../services/sound/sound_service.dart';
import '../../services/tts/voice_service.dart';
import '../parent/widgets/sound_settings.dart';

/// Geliştirici ses laboratuvarı: Bilbil'in sesi, quiz cümleleri, efektler ve
/// müzik tek ekranda, giriş yapmadan denenir. Yalnızca debug sürümünde
/// açılır (giriş ekranında Bilbil'e uzun bas); mağaza sürümünde yoktur.
class SoundLabScreen extends StatefulWidget {
  const SoundLabScreen({super.key});

  @override
  State<SoundLabScreen> createState() => _SoundLabScreenState();
}

class _SoundLabScreenState extends State<SoundLabScreen> {
  late final VoiceService _voice = context.read<VoiceService>();
  late final SoundService _sound = context.read<SoundService>();
  bool _musicPlaying = false;
  bool _turnedMusicOn = false; // ebeveyn ayarı çıkışta geri alınır

  @override
  void dispose() {
    _voice.stop();
    _sound.stopMusic();
    if (_turnedMusicOn) _sound.setMusicOn(false);
    super.dispose();
  }

  Future<void> _say(
    String text, {
    double rate = VoiceService.cheerfulRate,
  }) async {
    await _voice.prepare();
    await _voice.stop();
    await _voice.speak(text, rate: rate);
  }

  Future<void> _toggleMusic() async {
    if (_musicPlaying) {
      await _sound.stopMusic();
    } else {
      if (!_sound.musicOn) {
        _turnedMusicOn = true;
        await _sound.setMusicOn(true);
      }
      await _sound.startMusic();
    }
    setState(() => _musicPlaying = !_musicPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final sentences = <(String, String, double)>[
      ('Övgü', _voice.praise('kedi'), VoiceService.cheerfulRate),
      (
        'Renk',
        _voice.praise('kırmızı', lead: 'Bu renk'),
        VoiceService.cheerfulRate,
      ),
      (
        'Eylem',
        _voice.praise('koşuyor', lead: 'Çocuk'),
        VoiceService.cheerfulRate,
      ),
      ('Yanlış', _voice.tryAgain('elma'), VoiceService.cheerfulRate),
      ('İpucu', 'Bu bir... zürafa!', VoiceService.wordRate),
      (
        'Duyamadım',
        'Seni duyamadım! Bir daha söyler misin?',
        VoiceService.cheerfulRate,
      ),
      for (final c in RLAgent.configs)
        ('${c.label} hız', 'Harika! Bu bir kaplumbağa!', c.ttsRate),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ses Laboratuvarı', style: GoogleFonts.fredoka()),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card('Bilbil\'in Sesi', const VoiceSettings()),
          _card(
            'Quiz Cümleleri',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, text, rate) in sentences)
                  ActionChip(
                    label: Text(
                      label,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    tooltip: text,
                    onPressed: () => _say(text, rate: rate),
                  ),
              ],
            ),
          ),
          _card(
            'Efektler ve Müzik',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (label, effect) in const [
                      ('Doğru', SoundEffect.correct),
                      ('Yanlış', SoundEffect.wrong),
                      ('Ödül', SoundEffect.reward),
                    ])
                      ActionChip(
                        avatar: const Icon(Icons.music_note_rounded, size: 18),
                        label: Text(
                          label,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        onPressed: () => _sound.play(effect),
                      ),
                    ActionChip(
                      key: const Key('lab-music'),
                      avatar: Icon(
                        _musicPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _musicPlaying ? 'Müziği durdur' : 'Müziği çal',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      onPressed: _toggleMusic,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Material(
                  type: MaterialType.transparency,
                  child: SoundSettings(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
