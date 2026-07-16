import 'scene_graph.dart';

/// Enhances a scene graph with optional screenshot context.
class SceneEnhancer {
  /// Creates a scene enhancer.
  const SceneEnhancer();

  /// Appends screenshot context to the scene JSON.
  ///
  /// If [base64Screenshot] is provided, a `"screenshot"` field is added to
  /// the JSON map. The field contains the base64-encoded PNG data and a
  /// note indicating the image accompanies the semantics tree.
  Map<String, Object?> enhanceSceneWithScreenshot(
    SceneGraph scene, {
    String? base64Screenshot,
  }) {
    final json = scene.toJson();
    if (base64Screenshot == null || base64Screenshot.isEmpty) return json;

    json['screenshot'] = <String, Object?>{
      'format': 'png_base64',
      'data': base64Screenshot,
      'note':
          'A screenshot of the current screen accompanies this semantics tree '
          'to help you understand visual layout.',
    };
    return json;
  }

}
