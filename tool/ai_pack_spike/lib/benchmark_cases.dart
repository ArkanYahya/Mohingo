/// The answers every candidate is judged on: real Mohingo-style tasks with
/// one model answer each, and a learner answer whose right verdict a teacher
/// would not argue about. Each case names the one thing it tests, so a wrong
/// verdict says what the model cannot do, not only that it was wrong.
///
/// `expectAnswersTask` is what ADR 0013 calls the judgement's `meaningOk`;
/// `expectGrammarIssues` is whether `grammarIssues` should be above zero.
class BenchmarkCase {
  const BenchmarkCase({
    required this.id,
    required this.task,
    required this.parts,
    required this.hypotheses,
    required this.modelAnswer,
    required this.answer,
    required this.expectAnswersTask,
    required this.expectGrammarIssues,
    required this.tests,
  });

  final String id;
  final String task;

  /// What the task asks for, one entry per requirement, in the words the
  /// model is asked about. The verdict is computed from these: an answer
  /// does the task when every part is done. In Mohingo these are the
  /// rubric's `requiredGroups`, read as meanings instead of keywords.
  final List<String> parts;

  /// One statement per part for the natural-language-inference check: the
  /// answer is the premise, this is the hypothesis, and the part is done
  /// when the model finds entailment. A hypothesis starting with
  /// `@sentences:` is checked by code instead (a count is not a meaning).
  final List<String> hypotheses;
  final String modelAnswer;
  final String answer;
  final bool expectAnswersTask;
  final bool expectGrammarIssues;

  /// What a wrong verdict here would mean, in a few words.
  final String tests;
}

const String _likesTask =
    'Say two things you like and one thing you don\'t like.';
const List<String> _likesParts = [
  'two things the speaker likes',
  'one thing the speaker does not like',
];
const List<String> _likesHypotheses = [
  'The speaker says two things they like.',
  'The speaker says one thing they do not like.',
];
const String _likesModel =
    'I like football and I love music. I don\'t like tennis.';
const String _politeTask = 'A person helps you. Respond politely.';
const List<String> _politeParts = ['a polite reply to someone who helped'];
const List<String> _politeHypotheses = ['The speaker thanks someone politely.'];
const String _politeModel = 'Thank you. / Thanks.';
const String _introTask =
    'Introduce yourself: say your name, where you are from and your job.';
const List<String> _introParts = [
  'the speaker\'s name',
  'where the speaker is from',
  'the speaker\'s job',
];
const List<String> _introHypotheses = [
  'The speaker says their name.',
  'The speaker says which country they are from.',
  'The speaker says what their job is.',
];
const String _introModel = 'Hi, I\'m Sara. I\'m from Egypt and I\'m a nurse.';
const String _emailTask =
    'Reply to a friend who writes that they volunteer at the library on '
    'Saturdays. Show interest, ask a question about it, and say what you '
    'are doing these days.';
const List<String> _emailParts = [
  'shows interest in the friend\'s volunteering',
  'asks a question about the volunteering',
  'says what the writer is doing these days',
];
const List<String> _emailHypotheses = [
  'The writer is interested in the friend\'s volunteering.',
  'The writer asks the friend a question about the volunteering.',
  'The writer says what they are doing these days.',
];
const String _emailModel =
    'Hi! That sounds great. Volunteering at the library is a lovely idea. '
    'Do you help the children with their reading, or do you work at the '
    'desk? I\'m enjoying something new too: I\'m learning to cook at the '
    'moment. Every Friday I try a new dish. Tell me more about your '
    'Saturdays when you have time!';
const String _routineTask = 'Describe your morning routine in three sentences.';
const List<String> _routineParts = [
  'describes the speaker\'s morning routine',
  'has three sentences',
];
const List<String> _routineHypotheses = [
  'The speaker describes their morning routine.',
  '@sentences:3',
];
const String _routineModel =
    'I get up at seven. I have breakfast with my family. Then I take the bus '
    'to work.';
const String _weekendTask = 'Say what you did last weekend.';
const List<String> _weekendParts = [
  'says what the speaker did last weekend, as past events',
];
const List<String> _weekendHypotheses = [
  'The speaker says what they did last weekend.',
];
const String _weekendModel =
    'Last weekend I visited my grandmother and we cooked together.';

const List<BenchmarkCase> kBenchmarkCases = [
  BenchmarkCase(
    id: 'likes-synonym',
    task: _likesTask,
    parts: _likesParts,
    hypotheses: _likesHypotheses,
    modelAnswer: _likesModel,
    answer: 'I like football and I love music, but I can\'t stand tennis.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'a dislike said with words the keyword list lacks',
  ),
  BenchmarkCase(
    id: 'likes-other-topic',
    task: _likesTask,
    parts: _likesParts,
    hypotheses: _likesHypotheses,
    modelAnswer: _likesModel,
    answer: 'I like tea and I love coffee, but I can\'t stand milk.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'a good answer on a different topic from the model answer',
  ),
  BenchmarkCase(
    id: 'likes-no-dislike',
    task: _likesTask,
    parts: _likesParts,
    hypotheses: _likesHypotheses,
    modelAnswer: _likesModel,
    answer: 'I like football and I love music. I like tennis too.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'the dislike is missing (negation)',
  ),
  BenchmarkCase(
    id: 'likes-off-topic',
    task: _likesTask,
    parts: _likesParts,
    hypotheses: _likesHypotheses,
    modelAnswer: _likesModel,
    answer: 'The weather is nice today.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'off topic',
  ),
  BenchmarkCase(
    id: 'likes-broken-grammar',
    task: _likesTask,
    parts: _likesParts,
    hypotheses: _likesHypotheses,
    modelAnswer: _likesModel,
    answer: 'I like swim and I love read books. I no like run.',
    expectAnswersTask: true,
    expectGrammarIssues: true,
    tests: 'right content, several grammar errors',
  ),
  BenchmarkCase(
    id: 'polite-appreciate',
    task: _politeTask,
    parts: _politeParts,
    hypotheses: _politeHypotheses,
    modelAnswer: _politeModel,
    answer: 'I appreciate it.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'a polite reply the accepted list does not contain (a real case)',
  ),
  BenchmarkCase(
    id: 'polite-rude',
    task: _politeTask,
    parts: _politeParts,
    hypotheses: _politeHypotheses,
    modelAnswer: _politeModel,
    answer: 'Go away.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'grammatical but not polite',
  ),
  BenchmarkCase(
    id: 'intro-complete',
    task: _introTask,
    parts: _introParts,
    hypotheses: _introHypotheses,
    modelAnswer: _introModel,
    answer:
        'Hello! My name is Omar, I come from Iraq and I work as an engineer.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'all three parts, different wording',
  ),
  BenchmarkCase(
    id: 'intro-one-part',
    task: _introTask,
    parts: _introParts,
    hypotheses: _introHypotheses,
    modelAnswer: _introModel,
    answer: 'Hello! My name is Omar.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'two of three parts missing',
  ),
  BenchmarkCase(
    id: 'intro-broken-grammar',
    task: _introTask,
    parts: _introParts,
    hypotheses: _introHypotheses,
    modelAnswer: _introModel,
    answer: 'My name Omar, I from Iraq, I am engineer.',
    expectAnswersTask: true,
    expectGrammarIssues: true,
    tests: 'all parts present, missing verbs and articles',
  ),
  BenchmarkCase(
    id: 'intro-arabic',
    task: _introTask,
    parts: _introParts,
    hypotheses: _introHypotheses,
    modelAnswer: _introModel,
    answer: 'اسمي عمر وأنا من العراق وأعمل مهندساً.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'a complete answer, but in Arabic',
  ),
  BenchmarkCase(
    id: 'email-two-of-three',
    task: _emailTask,
    parts: _emailParts,
    hypotheses: _emailHypotheses,
    modelAnswer: _emailModel,
    answer:
        'That sounds great! Do you like working at the library? Does it open '
        'early on Saturdays? Tell me more when you have time.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'interest and a question, but nothing about these days',
  ),
  BenchmarkCase(
    id: 'email-vague',
    task: _emailTask,
    parts: _emailParts,
    hypotheses: _emailHypotheses,
    modelAnswer: _emailModel,
    answer:
        'That sounds great! Do you like it? I am happy for you. See you '
        'soon.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'polite filler that skips the third part',
  ),
  BenchmarkCase(
    id: 'email-complete',
    task: _emailTask,
    parts: _emailParts,
    hypotheses: _emailHypotheses,
    modelAnswer: _emailModel,
    answer:
        'Really? That\'s wonderful. Do you help children with their reading? '
        'I\'m learning to cook at the moment and I try a new dish every '
        'Friday.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'all three parts in other words',
  ),
  BenchmarkCase(
    id: 'email-broken-grammar',
    task: _emailTask,
    parts: _emailParts,
    hypotheses: _emailHypotheses,
    modelAnswer: _emailModel,
    answer:
        'That sounds great! Do you like the library? I enjoy to cook now. Me '
        'cook every Friday a new dish.',
    expectAnswersTask: true,
    expectGrammarIssues: true,
    tests: 'all parts present, several errors',
  ),
  BenchmarkCase(
    id: 'routine-complete',
    task: _routineTask,
    parts: _routineParts,
    hypotheses: _routineHypotheses,
    modelAnswer: _routineModel,
    answer:
        'I wake up at six and drink coffee. After that I take a shower. I '
        'leave home at eight.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'three sentences, none shared with the model answer',
  ),
  BenchmarkCase(
    id: 'routine-yes',
    task: _routineTask,
    parts: _routineParts,
    hypotheses: _routineHypotheses,
    modelAnswer: _routineModel,
    answer: 'Yes.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'a one-word non-answer',
  ),
  BenchmarkCase(
    id: 'routine-echo',
    task: _routineTask,
    parts: _routineParts,
    hypotheses: _routineHypotheses,
    modelAnswer: _routineModel,
    answer: 'Describe your morning routine in three sentences.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'the prompt repeated back',
  ),
  BenchmarkCase(
    id: 'weekend-tense',
    task: _weekendTask,
    parts: _weekendParts,
    hypotheses: _weekendHypotheses,
    modelAnswer: _weekendModel,
    answer: 'Last weekend I go to the beach with my friends and we swim.',
    expectAnswersTask: true,
    expectGrammarIssues: true,
    tests: 'right content, present tense for a past event',
  ),
  BenchmarkCase(
    id: 'weekend-habit',
    task: _weekendTask,
    parts: _weekendParts,
    hypotheses: _weekendHypotheses,
    modelAnswer: _weekendModel,
    answer: 'Every weekend I go to the beach.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'a habit, not what happened last weekend',
  ),
  BenchmarkCase(
    id: 'dislike-register',
    task: 'Tell your new colleague about one thing you don\'t like at work.',
    parts: ['one thing the speaker does not like at work'],
    hypotheses: ['The speaker says one thing they do not like at work.'],
    modelAnswer: 'I don\'t like long meetings.',
    answer: 'I can\'t stand long meetings.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'a stronger, informal phrasing (read the explanation for register)',
  ),
  BenchmarkCase(
    id: 'shop-wrong-item',
    task: 'Ask the shop assistant for the price of the shoes.',
    parts: ['asks for a price', 'the thing asked about is the shoes'],
    hypotheses: [
      'The speaker asks how much something costs.',
      'The speaker is talking about shoes.',
    ],
    modelAnswer: 'Excuse me, how much are these shoes?',
    answer: 'Excuse me, how much is this shirt?',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'the right question about the wrong thing',
  ),
];
