/// App-wide constants for categories, difficulties, and example prompts.
class QuizConstants {
  // Valid QuizAPI category strings
  static const List<String> categories = [
    'Linux',
    'BASH',
    'DevOps',
    'Docker',
    'SQL',
    'CMS',
    'Code',
    'Cloud',
    'MySQL',
  ];

  // Valid difficulty strings (stored uppercase internally)
  static const List<String> difficulties = [
    'EASY',
    'MEDIUM',
    'HARD',
  ];

  // Sample prompts shown under the NL search field to guide the user
  static const List<String> examplePrompts = [
    '"easy programming questions"',
    '"medium Linux quiz"',
    '"hard Docker questions"',
    '"beginner SQL quiz"',
    '"intermediate DevOps questions"',
  ];
}
