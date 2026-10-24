import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/data/onnx_entailment_model.dart';

void main() {
  test('labels come from id2label in index order, lower-cased', () {
    expect(
      OnnxEntailmentModel.labelsFromConfig({
        'id2label': {'2': 'CONTRADICTION', '0': 'ENTAILMENT', '1': 'NEUTRAL'},
      }),
      ['entailment', 'neutral', 'contradiction'],
    );
    expect(
      () => OnnxEntailmentModel.labelsFromConfig({}),
      throwsFormatException,
    );
  });

  test('softmax sums to one and keeps the order', () {
    final p = OnnxEntailmentModel.softmax([2.0, 1.0, 0.0]);
    expect(p.reduce((a, b) => a + b), closeTo(1, 1e-9));
    expect(p[0], greaterThan(p[1]));
    expect(p[1], greaterThan(p[2]));
    expect(OnnxEntailmentModel.softmax([]), isEmpty);
  });

  test('the entailment class is found by its label, not its index', () {
    expect(
      OnnxEntailmentModel.entailmentOf(
        [0.1, 0.2, 0.7],
        ['contradiction', 'neutral', 'entailment'],
      ),
      0.7,
    );
    expect(
      OnnxEntailmentModel.entailmentOf(
        [0.7, 0.2, 0.1],
        ['entailment', 'neutral', 'contradiction'],
      ),
      0.7,
    );
    expect(OnnxEntailmentModel.entailmentOf([0.5, 0.5], ['a', 'b']), 0);
  });

  test('without the runtime (every flutter test) the model reports null and '
      'stays unavailable', () async {
    final model = OnnxEntailmentModel();
    expect(
      await model.entailment('I like tea.', 'The speaker likes tea.'),
      isNull,
    );
    expect(model.isReady, isFalse);
    expect(await model.entailment('again', 'again'), isNull);
    await model.close();
  });
}
