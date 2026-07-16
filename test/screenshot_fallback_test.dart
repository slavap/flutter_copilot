import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  final graph = SceneGraph(
    nodes: const <SceneNode>[
      SceneNode(
        id: 'n1',
        semanticsId: 1,
        rect: Rect.fromLTWH(0, 0, 100, 48),
        label: 'Submit',
        actions: <SceneAction>{SceneAction.tap},
      ),
    ],
    idToSemanticsId: const <String, int>{'n1': 1},
  );

  const enhancer = SceneEnhancer();

  group('enhanceSceneWithScreenshot', () {
    test('returns original JSON when screenshot is null', () {
      final result = enhancer.enhanceSceneWithScreenshot(graph);
      expect(result.containsKey('screenshot'), isFalse);
      expect(result['nodes'], isNotNull);
    });

    test('returns original JSON when screenshot is empty string', () {
      final result = enhancer.enhanceSceneWithScreenshot(
        graph,
        base64Screenshot: '',
      );
      expect(result.containsKey('screenshot'), isFalse);
    });

    test('appends screenshot field when base64 data provided', () {
      const fakeBase64 = 'iVBORw0KGgoAAAANSU';
      final result = enhancer.enhanceSceneWithScreenshot(
        graph,
        base64Screenshot: fakeBase64,
      );

      expect(result.containsKey('screenshot'), isTrue);
      final screenshot = result['screenshot'] as Map<String, Object?>;
      expect(screenshot['format'], 'png_base64');
      expect(screenshot['data'], fakeBase64);
      expect(screenshot['note'], isA<String>());
      expect(
        (screenshot['note'] as String).contains('screenshot'),
        isTrue,
      );
    });

    test('preserves existing scene fields alongside screenshot', () {
      const fakeBase64 = 'dGVzdA==';
      final result = enhancer.enhanceSceneWithScreenshot(
        graph,
        base64Screenshot: fakeBase64,
      );

      expect(result['nodes'], isNotNull);
      expect(result['captured_at'], isNotNull);
      expect(result['screenshot'], isNotNull);
    });
  });

  group('enhanceSceneWithScreenshot', () {
    test('returns plain JSON without screenshot', () {
      final result = enhancer.enhanceSceneWithScreenshot(graph);
      expect(result.containsKey('screenshot'), isFalse);
    });

    test('includes screenshot data when provided', () {
      const fakeBase64 = 'c2FtcGxl';
      final result = enhancer.enhanceSceneWithScreenshot(
        graph,
        base64Screenshot: fakeBase64,
      );
      expect(result.containsKey('screenshot'), isTrue);
      final screenshot = result['screenshot'] as Map<String, Object?>;
      expect(screenshot['data'], fakeBase64);
    });
  });
}
