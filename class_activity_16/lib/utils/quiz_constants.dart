/// App-wide constants for categories, difficulties, and example prompts.
class QuizConstants {
  // Valid QuizAPI category strings (from QuizAPI docs)
  static const List<String> categories = [
    'Code',
    'Linux',
    'BASH',
    'DevOps',
    'Docker',
    'SQL',
    'CMS',
    'Cloud',
    'MySQL',
  ];

  // Valid difficulty strings — stored and sent uppercase per QuizAPI docs
  static const List<String> difficulties = [
    'EASY',
    'MEDIUM',
    'HARD',
    'EXPERT',
  ];

  static const List<String> examplePrompts = [
    '"easy programming questions"',
    '"medium Linux quiz"',
    '"hard Docker questions"',
    '"beginner SQL quiz"',
    '"intermediate DevOps questions"',
  ];
}
