# Activity 16 — Trivia Quiz App

A Flutter trivia quiz app for MAD Class Activity 16.  
Fetches questions from **QuizAPI** and uses **Gemini 2.5 Flash** for two advanced undergraduate features.

---

## Run commands

```bash
# Debug
flutter run \
  --dart-define=QUIZ_API_KEY=YOUR_QUIZ_KEY \
  --dart-define=GEMINI_API_KEY=YOUR_GEMINI_KEY

# Release APK
flutter build apk --release \
  --dart-define=QUIZ_API_KEY=YOUR_QUIZ_KEY \
  --dart-define=GEMINI_API_KEY=YOUR_GEMINI_KEY
```

---

## Folder structure

```
lib/
  main.dart
  models/
    question.dart       — QuizAPI JSON parsing + HTML entity decode
    quiz_config.dart    — Quiz settings model
  services/
    trivia_service.dart — QuizAPI HTTP + auth + error handling
    gemini_service.dart — Gemini 2.5 Flash (both advanced features)
  screens/
    start_screen.dart   — NL search + config preview
    quiz_screen.dart    — Gameplay, feedback, score tracking
    result_screen.dart  — Score + Smart Review Summary
  widgets/
    answer_button.dart       — Color + icon feedback, 56px touch target
    feedback_banner.dart     — Correct/wrong banner with SVG icons
    review_summary_card.dart — AI summary card with loading state
    quiz_config_card.dart    — Parsed quiz settings preview
  utils/
    quiz_constants.dart — Category / difficulty lists, example prompts
    quiz_sanitizer.dart — JSON extraction + config validation

assets/
  images/
    celebration.svg  — Trophy on results screen (motivates replay)
    loading.svg      — Search icon on start screen (clarifies purpose)
  icons/
    correct.svg      — Green check (non-color feedback for accessibility)
    incorrect.svg    — Red X   (non-color feedback for accessibility)
```

---

## Advanced features

### Feature 1 — Smart Review Summary
- **Where:** `ResultScreen` -> `ReviewSummaryCard` -> `GeminiService.generateReviewSummary()`
- **How it works:** After the quiz, performance data (score, missed categories, missed difficulties) is sent to Gemini 2.5 Flash, which returns a 3-5 sentence supportive study summary with a next-study recommendation.
- **Fallback:** If Gemini fails or the key is missing, a local summary is generated from the same data so the screen is never blank.

### Feature 2 — Natural Language Question Search
- **Where:** `StartScreen` -> `GeminiService.parseQuizIntent()` -> `QuizConfigCard`
- **How it works:** The user types what they want to practice ("easy Linux questions"). Gemini converts this to a structured JSON config (category, difficulty, type, limit). The result is validated and shown in a card before starting.
- **Fallback:** If Gemini fails or the key is missing, defaults to Code / EASY / 10 questions.

---

## Manual testing checklist

| # | Test | Expected |
|---|------|----------|
| 1 | App launches | StartScreen with NL field, no crash |
| 2 | Assets visible | Trophy SVG on results, search SVG on start |
| 3 | NL field renders | Text field with placeholder and example chips |
| 4 | Tap a chip | Fills text field with that prompt |
| 5 | "Find Quiz" with valid input | QuizConfigCard appears with parsed settings |
| 6 | "Find Quiz" with empty input | Falls back to defaults, QuizConfigCard shown |
| 7 | Bad/no GEMINI_API_KEY | Falls back to defaults silently |
| 8 | "Start Quiz" navigates | Quiz loads, AppBar shows question count |
| 9 | Loading state | Spinner shown while fetching questions |
| 10 | Offline / bad QUIZ_API_KEY | Error screen with message + Retry button |
| 11 | Retry button | Refetches questions |
| 12 | Tap an answer | Only that answer changes color; others remain |
| 13 | Tap correct answer | Button turns green + check icon + "Correct!" banner |
| 14 | Tap wrong answer | Button turns red + X icon + "Wrong! Correct answer was..." |
| 15 | Wrong answer reveals correct | Correct answer button highlights green simultaneously |
| 16 | Second tap blocked | No state change after first selection |
| 17 | "Next Question" advances | Next question shown, all buttons reset to idle |
| 18 | Score increments | AppBar score increases on correct answers only |
| 19 | Progress bar advances | Linear bar grows with each question |
| 20 | Last question shows "See Results" | Button label changes on final question |
| 21 | Results screen renders | Score %, fraction, label, celebration SVG all visible |
| 22 | Review card loads | Purple card shows spinner then summary text |
| 23 | Gemini summary fallback | Remove GEMINI_API_KEY -> local summary appears |
| 24 | "Play Again" resets | Back to StartScreen, stack cleared |
| 25 | Release APK builds | flutter build apk --release succeeds |

### Common bugs to watch for
- **No questions returned:** Check that `category` exactly matches QuizAPI values (e.g. `Code` not `Programming`).
- **Empty correct answer:** Happens when `correct_answer` key does not map to any non-null `answers` entry — `Question.tryParse()` returns null and skips the question.
- **Answers reshuffle on rebuild:** Prevented by `_shuffledAnswersCache`; verify cache is keyed by question index.
- **Gemini returns markdown fences:** `QuizSanitizer.extractJson()` strips surrounding text before json.decode.

### Testing without internet
Run the app with no network: the QuizAPI call will time out after 15 seconds and show the error screen with a Retry button. The Gemini features fall back to local logic immediately.
