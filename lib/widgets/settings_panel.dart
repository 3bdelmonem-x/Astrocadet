import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../audio/audio_service.dart';
import '../localization/game_localization.dart';
import 'pixel_ui.dart';
import 'sources_dialog.dart';
import 'tutorial_dialog.dart';

/// حجم الخط في اللعبة كلها (بيتغير من الإعدادات)
final ValueNotifier<double> textScale = ValueNotifier<double>(1.15);

const List<double> _scales = [1.0, 1.15, 1.3, 1.45];

/// نافذة الإعدادات الصغيرة اللي بتظهر فوق الشاشة.
void showSettingsPanel(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    builder: (dialogContext) {
      return Dialog(
        alignment: Alignment.topRight,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.fromLTRB(12, 60, 12, 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: ListenableBuilder(
            listenable: Listenable.merge([textScale, audio, gameArabic]),
            builder: (context, _) {
              return PixelPanel(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.settings,
                          color: Colors.cyanAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            gameText('SETTINGS'),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: _rowDecoration(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.text_fields,
                            color: Colors.cyanAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              gameText('TEXT SIZE'),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          _sizeButton('A−', () {
                            final i = _scales.indexOf(textScale.value);
                            if (i > 0) textScale.value = _scales[i - 1];
                          }),
                          const SizedBox(width: 6),
                          _sizeButton('A+', () {
                            final i = _scales.indexOf(textScale.value);
                            if (i < _scales.length - 1) {
                              textScale.value = _scales[i + 1];
                            }
                          }),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: _rowDecoration(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.language,
                            color: Colors.cyanAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              gameText('LANGUAGE'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          _languageButton(
                            'EN',
                            !gameArabic.value,
                            () => setGameArabic(false),
                          ),
                          const SizedBox(width: 5),
                          _languageButton(
                            'عربي',
                            gameArabic.value,
                            () => setGameArabic(true),
                          ),
                        ],
                      ),
                    ),
                    ListenableBuilder(
                      listenable: audio,
                      builder: (context, _) => Row(
                        children: [
                          Expanded(
                            child: PixelButton(
                              label: audio.sfxMuted
                                  ? '${gameText('SFX')}: ${gameText('OFF')}'
                                  : '${gameText('SFX')}: ${gameText('ON')}',
                              color: audio.sfxMuted
                                  ? Colors.white38
                                  : Colors.cyanAccent,
                              height: 30,
                              onTap: audio.toggleSfx,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: PixelButton(
                              label: audio.musicMuted
                                  ? '${gameText('MUSIC')}: ${gameText('OFF')}'
                                  : '${gameText('MUSIC')}: ${gameText('ON')}',
                              color: audio.musicMuted
                                  ? Colors.white38
                                  : Colors.cyanAccent,
                              height: 30,
                              onTap: audio.toggleMusic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    PixelButton(
                      label: '?  ${gameText('HOW TO PLAY')}',
                      color: Colors.amber,
                      height: 32,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        showTutorial(context);
                      },
                    ),
                    const SizedBox(height: 6),
                    PixelButton(
                      label: gameText('SOURCES'),
                      color: Colors.cyanAccent,
                      height: 32,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        showSourcesDialog(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

BoxDecoration _rowDecoration() => BoxDecoration(
  color: const Color(0xFF0D1E36),
  borderRadius: BorderRadius.circular(6),
  border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
);

Widget _languageButton(String label, bool selected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF124344) : const Color(0xFF16263C),
        border: Border.all(
          color: selected ? Colors.greenAccent : Colors.cyan,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.greenAccent : Colors.cyanAccent,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    ),
  );
}

Widget _sizeButton(String text, VoidCallback onTap) {
  return GestureDetector(
    onTap: () {
      audio.sfx('ui_tap');
      onTap();
    },
    child: Container(
      width: 34,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF16263C),
        border: Border.all(color: Colors.cyan, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    ),
  );
}
