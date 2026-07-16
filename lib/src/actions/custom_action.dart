import 'copilot_action.dart';

/// Represents a custom action parsed from an [UnknownAction].
///
/// Custom actions allow developers to extend the copilot's action set
/// without forking the package. When the model emits a tool call whose
/// name matches a registered handler, an [UnknownAction] is intercepted
/// and wrapped as a [CustomAction] for the handler to execute.
class CustomAction {
  /// Creates a custom action.
  const CustomAction({required this.name, required this.args});

  /// Tool name that matched the registered handler.
  final String name;

  /// Raw tool arguments from the model.
  final Map<String, Object?> args;

  /// Wraps an [UnknownAction] into a [CustomAction].
  factory CustomAction.fromUnknown(UnknownAction action) {
    return CustomAction(name: action.name, args: action.args);
  }
}
