/// String values aligned with API enums / web `workSchema` (Pass 5).
abstract final class WorkFieldOptions {
  static const workTypes = <({String value, String label})>[
    (value: 'educational_non_fiction_scientific_text', label: 'Educational / scientific text'),
    (value: 'fiction_text', label: 'Fiction text'),
    (value: 'news_articles_journalistic_text', label: 'News / journalistic text'),
    (value: 'book_content_visual_arts', label: 'Book content (visual arts)'),
    (value: 'standalone_visual_works', label: 'Standalone visual works'),
    (value: 'newspaper_magazines_inserts', label: 'Newspaper / magazines / inserts'),
    (value: 'song_text', label: 'Song text'),
    (value: 'musical_score', label: 'Musical score'),
    (value: 'other_work_type', label: 'Other work type'),
  ];

  static const workFormats = <({String value, String label})>[
    (value: 'digital_copy', label: 'Digital copy'),
    (value: 'hard_copy', label: 'Hard copy'),
    (value: 'hard_digital_copy', label: 'Hard + digital copy'),
    (value: 'audio', label: 'Audio'),
    (value: 'video', label: 'Video'),
    (value: 'other', label: 'Other'),
  ];

  static const identifierTypes = <({String value, String label})>[
    (value: 'isbn', label: 'ISBN'),
    (value: 'issn', label: 'ISSN'),
    (value: 'isni', label: 'ISNI'),
    (value: 'iswc', label: 'ISWC'),
    (value: 'url', label: 'URL'),
    (value: 'other', label: 'Other'),
  ];

  static const targetMarkets = <({String value, String label})>[
    (value: 'school_market', label: 'School market'),
    (value: 'tertiary_education_market', label: 'Tertiary education'),
    (value: 'general_trade_book_market', label: 'General trade book'),
    (value: 'general_public', label: 'General public'),
    (value: 'other', label: 'Other'),
  ];
}
