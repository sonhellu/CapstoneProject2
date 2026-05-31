String nativeLanguageFromNationality(
  String? nationality, {
  String fallback = 'English',
}) {
  final key = _normalize(nationality);
  if (key.isEmpty) return fallback;

  if (_vietnameseCountries.contains(key)) return 'Vietnamese';
  if (_koreanCountries.contains(key)) return 'Korean';
  if (_japaneseCountries.contains(key)) return 'Japanese';
  if (_chineseCountries.contains(key)) return 'Chinese';
  if (_myanmarCountries.contains(key)) return 'Myanmar';
  if (_thaiCountries.contains(key)) return 'Thai';
  if (_frenchCountries.contains(key)) return 'French';
  if (_spanishCountries.contains(key)) return 'Spanish';
  if (_englishCountries.contains(key)) return 'English';

  return fallback;
}

String nativeLanguageFromProfile(
  Map<String, dynamic>? data, {
  String fallback = 'English',
}) {
  if (data == null) return fallback;
  final storedNative = data['nativeLanguage'] as String?;
  return nativeLanguageFromNationality(
    data['nationality'] as String?,
    fallback: (storedNative != null && storedNative.trim().isNotEmpty)
        ? storedNative.trim()
        : fallback,
  );
}

String defaultLearningLanguageForNative(String nativeLanguage) {
  final native = nativeLanguage.trim();
  if (native == 'Korean') return 'Vietnamese';
  return 'Korean';
}

String learningLanguageFromProfile(
  Map<String, dynamic>? data, {
  required String nativeLanguage,
}) {
  final stored = data?['learningLanguage'] as String?;
  final value = stored?.trim() ?? '';
  if (value.isEmpty || value == nativeLanguage) {
    return defaultLearningLanguageForNative(nativeLanguage);
  }
  return value;
}

String _normalize(String? value) {
  return (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

const _vietnameseCountries = {'viet nam', 'vietnam', 'vietnamese'};

const _koreanCountries = {
  'korea, republic of',
  'korea, democratic people\'s republic of',
  'south korea',
  'north korea',
  'korean',
};

const _japaneseCountries = {'japan', 'japanese'};

const _chineseCountries = {
  'china',
  'hong kong',
  'macao',
  'taiwan, province of china',
  'taiwan',
  'chinese',
};

const _myanmarCountries = {'myanmar'};

const _thaiCountries = {'thailand', 'thai'};

const _frenchCountries = {
  'france',
  'french',
  'belgium',
  'benin',
  'burkina faso',
  'cameroon',
  'canada',
  'chad',
  'congo',
  'gabon',
  'guadeloupe',
  'guernsey',
  'haiti',
  'jersey',
  'luxembourg',
  'madagascar',
  'mali',
  'martinique',
  'mayotte',
  'monaco',
  'new caledonia',
  'reunion',
  'saint barthelemy',
  'saint martin (french part)',
  'saint pierre and miquelon',
  'senegal',
  'switzerland',
  'wallis and futuna',
};

const _spanishCountries = {
  'spain',
  'spanish',
  'argentina',
  'bolivia, plurinational state of',
  'chile',
  'colombia',
  'costa rica',
  'cuba',
  'dominican republic',
  'ecuador',
  'el salvador',
  'guatemala',
  'honduras',
  'mexico',
  'nicaragua',
  'panama',
  'paraguay',
  'peru',
  'puerto rico',
  'uruguay',
  'venezuela, bolivarian republic of',
};

const _englishCountries = {
  'american',
  'australia',
  'bahamas',
  'barbados',
  'belize',
  'bermuda',
  'british',
  'canada',
  'cayman islands',
  'english',
  'fiji',
  'gibraltar',
  'guam',
  'ireland',
  'isle of man',
  'jamaica',
  'malta',
  'new zealand',
  'northern mariana islands',
  'singapore',
  'united kingdom of great britain and northern ireland',
  'united states minor outlying islands',
  'united states of america',
  'virgin islands (british)',
  'virgin islands (u.s.)',
};
