import 'dart:math';
import 'dart:ui';

import '../../models/card_config.dart';

/// Rangi za kadi.
class CardPalette {
  const CardPalette({
    required this.id,
    required this.name,
    required this.background,
    required this.primary,
    required this.accent,
    required this.text,
    this.panel,
  });

  final String id;
  final String name;

  /// Gradient ya nyuma (juu -> chini).
  final List<Color> background;

  /// Rangi kuu ya mapambo na kichwa.
  final Color primary;
  final Color accent;
  final Color text;

  /// Rangi ya "panel" ya ndani kwa layout ya "framed".
  final Color? panel;

  bool get isDark => background.first.computeLuminance() < 0.25;
}

const palettes = <CardPalette>[
  CardPalette(
    id: 'dhahabu_usiku',
    name: 'Dhahabu ya Usiku',
    background: [Color(0xFF0F1B2D), Color(0xFF1C2E4A)],
    primary: Color(0xFFD4AF37),
    accent: Color(0xFFF1D98A),
    text: Color(0xFFF5ECD7),
    panel: Color(0xFF13233A),
  ),
  CardPalette(
    id: 'waridi',
    name: 'Waridi',
    background: [Color(0xFFFFF4F5), Color(0xFFF9D5DC)],
    primary: Color(0xFF9E2A4B),
    accent: Color(0xFFD88C9A),
    text: Color(0xFF4A1F2C),
    panel: Color(0xFFFFFBFB),
  ),
  CardPalette(
    id: 'kijani_asili',
    name: 'Kijani cha Asili',
    background: [Color(0xFFF4F7EF), Color(0xFFDCE8D0)],
    primary: Color(0xFF2F5D3A),
    accent: Color(0xFFB08D57),
    text: Color(0xFF1F3324),
    panel: Color(0xFFFCFDF9),
  ),
  CardPalette(
    id: 'zambarau_kifalme',
    name: 'Zambarau ya Kifalme',
    background: [Color(0xFF2A0F3D), Color(0xFF4B1D6B)],
    primary: Color(0xFFE8C872),
    accent: Color(0xFFC9A0DC),
    text: Color(0xFFF6EEFF),
    panel: Color(0xFF33134A),
  ),
  CardPalette(
    id: 'bahari',
    name: 'Bahari ya Hindi',
    background: [Color(0xFFEAF5F8), Color(0xFFBFE0EA)],
    primary: Color(0xFF0B4F6C),
    accent: Color(0xFFE0A458),
    text: Color(0xFF0B2E3C),
    panel: Color(0xFFF8FCFD),
  ),
  CardPalette(
    id: 'pembe',
    name: 'Pembe (Ivory)',
    background: [Color(0xFFFFFDF8), Color(0xFFF2EBDD)],
    primary: Color(0xFF8C6D3A),
    accent: Color(0xFFC9AE7C),
    text: Color(0xFF2B2B2B),
    panel: Color(0xFFFFFFFF),
  ),
  CardPalette(
    id: 'kitenge',
    name: 'Kitenge',
    background: [Color(0xFFFFF4E0), Color(0xFFFFDFAE)],
    primary: Color(0xFFB23A16),
    accent: Color(0xFF1E6B5C),
    text: Color(0xFF3A1A0C),
    panel: Color(0xFFFFFAF0),
  ),
  CardPalette(
    id: 'burgundy',
    name: 'Burgundy na Dhahabu',
    background: [Color(0xFF4A0E1F), Color(0xFF6E1A2F)],
    primary: Color(0xFFE6C17A),
    accent: Color(0xFFF3D9A4),
    text: Color(0xFFFBEFE6),
    panel: Color(0xFF581326),
  ),
  CardPalette(
    id: 'zumaridi',
    name: 'Zumaridi',
    background: [Color(0xFF0D3B2E), Color(0xFF155E46)],
    primary: Color(0xFFF0D58C),
    accent: Color(0xFFBFE3CF),
    text: Color(0xFFEAF6EF),
    panel: Color(0xFF104636),
  ),
  CardPalette(
    id: 'lavenda',
    name: 'Lavenda',
    background: [Color(0xFFF8F3FC), Color(0xFFE4D8F3)],
    primary: Color(0xFF5B3E8A),
    accent: Color(0xFFC9A0DC),
    text: Color(0xFF2E1F47),
    panel: Color(0xFFFFFFFF),
  ),
  CardPalette(
    id: 'machweo',
    name: 'Machweo',
    background: [Color(0xFFFFE8D6), Color(0xFFFFB4A2)],
    primary: Color(0xFF8C2F39),
    accent: Color(0xFFF4A261),
    text: Color(0xFF4A161C),
    panel: Color(0xFFFFF6EF),
  ),
  CardPalette(
    id: 'mahafali',
    name: 'Mahafali',
    background: [Color(0xFF101820), Color(0xFF1B2A38)],
    primary: Color(0xFFF2AA4C),
    accent: Color(0xFF7FB7BE),
    text: Color(0xFFFFFFFF),
    panel: Color(0xFF15212C),
  ),
];

/// Jozi za fonts: script (jina la mwalikwa), title (kichwa), body (maelezo).
class FontPair {
  const FontPair(this.id, this.script, this.title, this.body, {this.titleUpper = false});
  final String id;
  final String script;
  final String title;
  final String body;
  final bool titleUpper;
}

const fontPairs = <FontPair>[
  FontPair('classic', 'GreatVibes', 'PlayfairDisplay', 'Lato'),
  FontPair('royal', 'GreatVibes', 'Cinzel', 'CormorantGaramond', titleUpper: true),
  FontPair('romantic', 'DancingScript', 'CormorantGaramond', 'CormorantGaramond'),
  FontPair('modern', 'DancingScript', 'Montserrat', 'Montserrat', titleUpper: true),
  FontPair('elegant', 'GreatVibes', 'Marcellus', 'Lato', titleUpper: true),
  FontPair('friendly', 'DancingScript', 'PlayfairDisplay', 'Poppins'),
];

/// Mapambo yanayochorwa na `OrnamentPainter`.
const ornamentIds = <String>['gold_frame', 'florals', 'kitenge', 'arch', 'stars', 'waves', 'confetti', 'deco'];

const ornamentNames = <String, String>{
  'gold_frame': 'Fremu ya Dhahabu',
  'florals': 'Maua',
  'kitenge': 'Kitenge',
  'arch': 'Tao',
  'stars': 'Nyota',
  'waves': 'Mawimbi',
  'confetti': 'Shamrashamra',
  'deco': 'Art Deco',
};

const layoutIds = <String>['centered', 'framed', 'banner'];

CardPalette paletteById(String id) => palettes.firstWhere((p) => p.id == id, orElse: () => palettes.first);
FontPair fontPairById(String id) => fontPairs.firstWhere((f) => f.id == id, orElse: () => fontPairs.first);

/// Template zilizochaguliwa kwa mkono (zinaonekana kwanza kwenye studio).
class CardTemplate {
  const CardTemplate(this.id, this.name, this.palette, this.ornament, this.fonts, this.layout);
  final String id;
  final String name;
  final String palette;
  final String ornament;
  final String fonts;
  final String layout;

  CardConfig apply(CardConfig base) => base.copyWith(
    mode: CardMode.template,
    paletteId: palette,
    ornamentId: ornament,
    fontPairId: fonts,
    layoutId: layout,
  );
}

const curatedTemplates = <CardTemplate>[
  CardTemplate('t1', 'Usiku wa Dhahabu', 'dhahabu_usiku', 'gold_frame', 'royal', 'centered'),
  CardTemplate('t2', 'Waridi la Upendo', 'waridi', 'florals', 'classic', 'framed'),
  CardTemplate('t3', 'Kitenge cha Sherehe', 'kitenge', 'kitenge', 'friendly', 'banner'),
  CardTemplate('t4', 'Tao la Kifalme', 'zambarau_kifalme', 'arch', 'elegant', 'centered'),
  CardTemplate('t5', 'Bustani', 'kijani_asili', 'florals', 'romantic', 'centered'),
  CardTemplate('t6', 'Pwani', 'bahari', 'waves', 'modern', 'centered'),
  CardTemplate('t7', 'Burgundy ya Kifahari', 'burgundy', 'deco', 'royal', 'framed'),
  CardTemplate('t8', 'Pembe Safi', 'pembe', 'gold_frame', 'romantic', 'framed'),
  CardTemplate('t9', 'Shamrashamra', 'machweo', 'confetti', 'friendly', 'banner'),
  CardTemplate('t10', 'Kofia ya Mahafali', 'mahafali', 'stars', 'modern', 'centered'),
  CardTemplate('t11', 'Zumaridi', 'zumaridi', 'arch', 'classic', 'centered'),
  CardTemplate('t12', 'Lavenda', 'lavenda', 'florals', 'elegant', 'framed'),
];

/// Mapambo yanayofaa kila aina ya tukio (yanapewa uzito zaidi kwenye generator).
const _ornamentsByType = <String, List<String>>{
  'harusi': ['gold_frame', 'florals', 'arch', 'deco'],
  'sendoff': ['florals', 'gold_frame', 'kitenge', 'arch'],
  'kitchen_party': ['florals', 'kitenge', 'confetti', 'waves'],
  'birthday': ['confetti', 'stars', 'waves', 'kitenge'],
  'graduation': ['stars', 'deco', 'gold_frame', 'waves'],
  'corporate': ['waves', 'deco', 'gold_frame'],
};

/// Inatengeneza design mpya za kadi kwa kuchanganya rangi, mapambo, fonts na layout.
/// Kuna michanganyiko zaidi ya 2,000, kwa hiyo kila mteja anapata kadi tofauti.
class CardGenerator {
  CardGenerator([int? seed]) : _rng = Random(seed);
  final Random _rng;

  T _pick<T>(List<T> items) => items[_rng.nextInt(items.length)];

  CardConfig generate(CardConfig base, {String? eventType}) {
    final preferred = _ornamentsByType[eventType];
    final ornament = preferred != null && _rng.nextDouble() < 0.75 ? _pick(preferred) : _pick(ornamentIds);
    return base.copyWith(
      mode: CardMode.template,
      paletteId: _pick(palettes).id,
      ornamentId: ornament,
      fontPairId: _pick(fontPairs).id,
      layoutId: _pick(layoutIds),
    );
  }

  /// Design [count] tofauti (hakuna mbili zinazofanana kabisa).
  List<CardConfig> generateMany(CardConfig base, int count, {String? eventType}) {
    final seen = <String>{};
    final out = <CardConfig>[];
    var attempts = 0;
    while (out.length < count && attempts < count * 20) {
      attempts++;
      final c = generate(base, eventType: eventType);
      final key = '${c.paletteId}|${c.ornamentId}|${c.fontPairId}|${c.layoutId}';
      if (seen.add(key)) out.add(c);
    }
    return out;
  }
}
