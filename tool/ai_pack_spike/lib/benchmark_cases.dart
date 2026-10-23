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
    required this.modelAnswer,
    required this.answer,
    required this.expectAnswersTask,
    required this.expectGrammarIssues,
    required this.tests,
  });

  final String id;
  final String task;
  final String modelAnswer;
  final String answer;
  final bool expectAnswersTask;
  final bool expectGrammarIssues;

  /// What a wrong verdict here would mean, in a few words.
  final String tests;
}

const String _likesTask =
    'Say two things you like and one thing you don\'t like.';
const String _likesModel =
    'I like football and I love music. I don\'t like tennis.';
const String _politeTask = 'A person helps you. Respond politely.';
const String _politeModel = 'Thank you. / Thanks.';
const String _introTask =
    'Introduce yourself: say your name, where you are from and your job.';
const String _introModel = 'Hi, I\'m Sara. I\'m from Egypt and I\'m a nurse.';
const String _emailTask =
    'Reply to a friend who writes that they volunteer at the library on '
    'Saturdays. Show interest, ask a question about it, and say what you '
    'are doing these days.';
const String _emailModel =
    'Hi! That sounds great. Volunteering at the library is a lovely idea. '
    'Do you help the children with their reading, or do you work at the '
    'desk? I\'m enjoying something new too: I\'m learning to cook at the '
    'moment. Every Friday I try a new dish. Tell me more about your '
    'Saturdays when you have time!';
const String _routineTask = 'Describe your morning routine in three sentences.';
const String _routineModel =
    'I get up at seven. I have breakfast with my family. Then I take the bus '
    'to work.';
const String _weekendTask = 'Say what you did last weekend.';
const String _weekendModel =
    'Last weekend I visited my grandmother and we cooked together.';

const List<BenchmarkCase> kBenchmarkCases = [
  BenchmarkCase(
    id: 'likes-synonym',
    task: _likesTask,
    modelAnswer: _likesModel,
    answer: 'I like football and I love music, but I can\'t stand tennis.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'a dislike said with words the keyword list lacks',
  ),
  BenchmarkCase(
    id: 'likes-other-topic',
    task: _likesTask,
    modelAnswer: _likesModel,
    answer: 'I like tea and I love coffee, but I can\'t stand milk.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'a good answer on a different topic from the model answer',
  ),
  BenchmarkCase(
    id: 'likes-no-dislike',
    task: _likesTask,
    modelAnswer: _likesModel,
    answer: 'I like football and I love music. I like tennis too.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'the dislike is missing (negation)',
  ),
  BenchmarkCase(
    id: 'likes-off-topic',
    task: _likesTask,
    modelAnswer: _likesModel,
    answer: 'The weather is nice today.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'off topic',
  ),
  BenchmarkCase(
    id: 'likes-broken-grammar',
    task: _likesTask,
    modelAnswer: _likesModel,
    answer: 'I like swim and I love read books. I no like run.',
    expectAnswersTask: true,
    expectGrammarIssues: true,
    tests: 'right content, several grammar errors',
  ),
  BenchmarkCase(
    id: 'polite-appreciate',
    task: _politeTask,
    modelAnswer: _politeModel,
    answer: 'I appreciate it.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'a polite reply the accepted list does not contain (a real case)',
  ),
  BenchmarkCase(
    id: 'polite-rude',
    task: _politeTask,
    modelAnswer: _politeModel,
    answer: 'Go away.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'grammatical but not polite',
  ),
  BenchmarkCase(
    id: 'intro-complete',
    task: _introTask,
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
    modelAnswer: _introModel,
    answer: 'Hello! My name is Omar.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'two of three parts missing',
  ),
  BenchmarkCase(
    id: 'intro-broken-grammar',
    task: _introTask,
    modelAnswer: _introModel,
    answer: 'My name Omar, I from Iraq, I am engineer.',
    expectAnswersTask: true,
    expectGrammarIssues: true,
    tests: 'all parts present, missing verbs and articles',
  ),
  BenchmarkCase(
    id: 'intro-arabic',
    task: _introTask,
    modelAnswer: _introModel,
    answer: 'اسمي عمر وأنا من العراق وأعمل مهندساً.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'a complete answer, but in Arabic',
  ),
  BenchmarkCase(
    id: 'email-two-of-three',
    task: _emailTask,
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
    modelAnswer: _routineModel,
    answer: 'Yes.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'a one-word non-answer',
  ),
  BenchmarkCase(
    id: 'routine-echo',
    task: _routineTask,
    modelAnswer: _routineModel,
    answer: 'Describe your morning routine in three sentences.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'the prompt repeated back',
  ),
  BenchmarkCase(
    id: 'weekend-tense',
    task: _weekendTask,
    modelAnswer: _weekendModel,
    answer: 'Last weekend I go to the beach with my friends and we swim.',
    expectAnswersTask: true,
    expectGrammarIssues: true,
    tests: 'right content, present tense for a past event',
  ),
  BenchmarkCase(
    id: 'weekend-habit',
    task: _weekendTask,
    modelAnswer: _weekendModel,
    answer: 'Every weekend I go to the beach.',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'a habit, not what happened last weekend',
  ),
  BenchmarkCase(
    id: 'dislike-register',
    task: 'Tell your new colleague about one thing you don\'t like at work.',
    modelAnswer: 'I don\'t like long meetings.',
    answer: 'I can\'t stand long meetings.',
    expectAnswersTask: true,
    expectGrammarIssues: false,
    tests: 'a stronger, informal phrasing (read the explanation for register)',
  ),
  BenchmarkCase(
    id: 'shop-wrong-item',
    task: 'Ask the shop assistant for the price of the shoes.',
    modelAnswer: 'Excuse me, how much are these shoes?',
    answer: 'Excuse me, how much is this shirt?',
    expectAnswersTask: false,
    expectGrammarIssues: false,
    tests: 'the right question about the wrong thing',
  ),
];
