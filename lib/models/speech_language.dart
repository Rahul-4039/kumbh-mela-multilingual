/// ISO 639-1 language option for Whisper transcription.
class SpeechLanguage {
  const SpeechLanguage({
    required this.code,
    required this.label,
    this.promptHint = '',
  });

  /// Empty code means Whisper auto-detects the spoken language.
  final String code;
  final String label;

  /// Short native-script hint passed as the API prompt for better accuracy.
  final String promptHint;

  bool get isAutoDetect => code.isEmpty;

  static const SpeechLanguage autoDetect = SpeechLanguage(
    code: '',
    label: 'Auto-detect',
    promptHint:
        'नमस्ते। வணக்கம்। నమస్కారం। Transcribe in the original spoken '
        'language using its native script. Do not translate to English.',
  );

  static const List<SpeechLanguage> options = [
    autoDetect,
    SpeechLanguage(
      code: 'hi',
      label: 'Hindi',
      promptHint: 'नमस्ते, यह हिंदी में लिखा गया पाठ है।',
    ),
    SpeechLanguage(
      code: 'ta',
      label: 'Tamil',
      promptHint: 'வணக்கம், இது தமிழில் எழுதப்பட்ட உரை.',
    ),
    SpeechLanguage(
      code: 'te',
      label: 'Telugu',
      promptHint: 'నమస్కారం, ఇది తెలుగులో రాసిన పాఠ్యం.',
    ),
    SpeechLanguage(
      code: 'mr',
      label: 'Marathi',
      // Marathi and Hindi share Devanagari script, so Whisper sometimes
      // slips into Hindi spellings/word-forms. Distinctly Marathi verb
      // endings (आहे, करत आहे, नाही) bias the model toward Marathi rather
      // than the visually similar Hindi equivalents (है, कर रहा है, नहीं).
      promptHint:
          'नमस्कार, मी मराठीत बोलत आहे. हा मजकूर शुद्ध मराठी भाषेत लिहिलेला '
          'आहे, हिंदीत नाही. कृपया मराठी शब्दलेखन आणि व्याकरण वापरून लिहा.',
    ),
    SpeechLanguage(
      code: 'bn',
      label: 'Bengali',
      promptHint: 'নমস্কার, এটি বাংলায় লেখা পাঠ্য।',
    ),
    SpeechLanguage(
      code: 'kn',
      label: 'Kannada',
      promptHint: 'ನಮಸ್ಕಾರ, ಇದು ಕನ್ನಡದಲ್ಲಿ ಬರೆದ ಪಠ್ಯ.',
    ),
    SpeechLanguage(
      code: 'ml',
      label: 'Malayalam',
      promptHint: 'നമസ്കാരം, ഇത് മലയാളത്തിൽ എഴുതിയ വാചകമാണ്.',
    ),
    SpeechLanguage(
      code: 'gu',
      label: 'Gujarati',
      promptHint: 'નમસ્તે, આ ગુજરાતીમાં લખાયેલ ટેક્સ્ટ છે.',
    ),
    SpeechLanguage(
      code: 'pa',
      label: 'Punjabi',
      promptHint: 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ, ਇਹ ਪੰਜਾਬੀ ਵਿੱਚ ਲਿਖਿਆ ਟੈਕਸਟ ਹੈ।',
    ),
    SpeechLanguage(
      code: 'en',
      label: 'English',
      promptHint: 'Hello, this is text written in English.',
    ),
  ];

  static SpeechLanguage fromCode(String code) {
    return options.firstWhere(
      (language) => language.code == code,
      orElse: () => autoDetect,
    );
  }
}
