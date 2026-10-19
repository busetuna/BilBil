import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/sound/sound_service.dart';
import '../../../services/tts/voice_service.dart';

// Ebeveyn ayarları ve geliştirici ses laboratuvarı aynı bileşenleri kullanır.

/// Ses efektleri (doğru/yanlış/ödül) ve quiz'deki arka plan müziği.
class SoundSettings extends StatelessWidget {
  const SoundSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final sound = context.watch<SoundService>();
    final title = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );
    final subtitle = GoogleFonts.poppins(
      fontSize: 11,
      color: AppColors.textSecondary,
    );
    return Column(
      children: [
        SwitchListTile(
          key: const Key('effects-switch'),
          value: sound.effectsOn,
          onChanged: sound.setEffectsOn,
          activeThumbColor: AppColors.primary,
          title: Text('Ses efektleri', style: title),
          subtitle: Text('Doğru, yanlış ve ödül sesleri', style: subtitle),
        ),
        SwitchListTile(
          key: const Key('music-switch'),
          value: sound.musicOn,
          onChanged: sound.setMusicOn,
          activeThumbColor: AppColors.primary,
          title: Text('Arka plan müziği', style: title),
          subtitle: Text(
            'Quiz sırasında kısık sesle çalar; çocuk konuşurken durur.',
            style: subtitle,
          ),
        ),
      ],
    );
  }
}

/// Ses seçimi, ton ayarı ve "Dinle". Sesler telefonun Türkçe sentetik
/// sesleridir; isimleri anlamsız olduğu için harfle gösterilir.
class VoiceSettings extends StatefulWidget {
  const VoiceSettings({super.key});

  @override
  State<VoiceSettings> createState() => _VoiceSettingsState();
}

class _VoiceSettingsState extends State<VoiceSettings> {
  double? _pitch; // kaydırılırken yerel değer

  @override
  void initState() {
    super.initState();
    context.read<VoiceService>().prepare(); // sesleri yükle
  }

  static String _label(int i, TtsVoice v) {
    final letter = String.fromCharCode('A'.codeUnitAt(0) + i % 26);
    final online = v.name.contains('network') ? ' · internet gerekir' : '';
    return 'Ses $letter$online';
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceService>();
    final voices = voice.voices;
    final selected = voices.any((v) => v.name == voice.voiceName)
        ? voice.voiceName
        : null;
    final textStyle = GoogleFonts.poppins(fontSize: 13);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bilbil\'in konuşma sesini seç ve dinle.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          key: const Key('voice-dropdown'),
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('Otomatik (telefonun sesi)', style: textStyle),
            ),
            for (final (i, v) in voices.indexed)
              DropdownMenuItem(
                value: v.name,
                child: Text(_label(i, v), style: textStyle),
              ),
          ],
          onChanged: (name) async {
            await voice.setVoice(name);
            await voice.preview();
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Sakin', style: textStyle),
            Expanded(
              child: Slider(
                key: const Key('pitch-slider'),
                min: VoiceService.minPitch,
                max: VoiceService.maxPitch,
                divisions: 8,
                value: _pitch ?? voice.pitch,
                activeColor: AppColors.primary,
                onChanged: (p) => setState(() => _pitch = p),
                onChangeEnd: (p) async {
                  await voice.setPitch(p);
                  setState(() => _pitch = null);
                  await voice.preview();
                },
              ),
            ),
            Text('Neşeli', style: textStyle),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('voice-preview'),
            onPressed: voice.preview,
            icon: Icon(Icons.volume_up_rounded, color: AppColors.primary),
            label: Text(
              'Dinle',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (voices.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Telefonda Türkçe ses bulunamadı; varsayılan ses kullanılıyor.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
