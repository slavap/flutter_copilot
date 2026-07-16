import 'action_result.dart';
import 'custom_action.dart';

/// Interface for executing custom actions.
///
/// Implement this to handle custom tool calls emitted by the model.
/// Register instances via [CopilotConfig.customActions].
abstract class CustomActionHandler {
  /// Executes [action] and returns an [ActionResult].
  Future<ActionResult> execute(CustomAction action);
}
