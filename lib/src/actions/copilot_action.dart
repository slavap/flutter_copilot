import 'package:meta/meta.dart';

/// Action selected by the model.
///
/// A sealed class hierarchy representing every action the LLM can request.
/// Use [fromToolCall] to parse an LLM tool call into the concrete subtype.
/// Each action carries a [name] (the tool name) and an optional [targetId]
/// (the scene node it acts on).
sealed class CopilotAction {
  /// Creates a copilot action.
  const CopilotAction();

  /// Parses an action from an LLM tool call.
  ///
  /// [name] is the tool name returned by the model. [args] is the
  /// tool's argument map. Throws if required arguments are missing or
  /// have unexpected types.
  factory CopilotAction.fromToolCall(String name, Map<String, Object?> args) {
    final normalized = name.trim();
    return switch (normalized) {
      'tap' => TapAction(_requiredString(args, 'id')),
      'long_press' => LongPressAction(_requiredString(args, 'id')),
      'type_text' => TypeTextAction(
          _requiredString(args, 'id'), _requiredString(args, 'text')),
      'clear_text' => ClearTextAction(_requiredString(args, 'id')),
      'replace_text' => ReplaceTextAction(
          _requiredString(args, 'id'), _requiredString(args, 'text')),
      'set_text_selection' => SetTextSelectionAction(
          _requiredString(args, 'id'),
          _requiredInt(args, 'start'),
          _requiredInt(args, 'end'),
        ),
      'keyboard_action' => KeyboardAction(_requiredString(args, 'key')),
      'scroll' => ScrollAction(
          _requiredString(args, 'id'),
          _requiredString(args, 'direction'),
          (args['amount'] as String?) ?? 'medium',
        ),
      'drag' => DragAction(
          _requiredString(args, 'id'),
          _requiredString(args, 'direction'),
          (args['amount'] as String?) ?? 'medium',
        ),
      'long_press_drag' => LongPressDragAction(
          _requiredString(args, 'id'),
          _requiredString(args, 'direction'),
          (args['amount'] as String?) ?? 'medium',
        ),
      'slider_to_value' => SliderToValueAction(
          _requiredString(args, 'id'), _requiredDouble(args, 'value')),
      'adjust_value' => AdjustValueAction(
          _requiredString(args, 'id'),
          _requiredString(args, 'direction'),
          (args['steps'] as num?)?.round() ?? 1,
        ),
      'dismiss' => DismissAction(_requiredString(args, 'id')),
      'system_back' => const SystemBackAction(),
      'request_confirmation' =>
        RequestConfirmationAction(_requiredString(args, 'reason')),
      'wait' => WaitAction(Duration(
          milliseconds: (args['duration_ms'] as num?)?.round() ?? 300)),
      'done' => DoneAction(_requiredString(args, 'summary')),
      'fail' => FailAction(_requiredString(args, 'reason')),
      _ => UnknownAction(normalized, args),
    };
  }

  /// Tool name for this action.
  ///
  /// Matches the tool name in the LLM's tool-call response (e.g. `'tap'`,
  /// `'type_text'`, `'scroll'`).
  String get name;

  /// Public scene node id targeted by this action, when it has one.
  ///
  /// Returns `null` for actions that don't target a specific node, such
  /// as [SystemBackAction], [WaitAction], [DoneAction], and [FailAction].
  String? get targetId {
    return switch (this) {
      TapAction(:final id) => id,
      LongPressAction(:final id) => id,
      TypeTextAction(:final id) => id,
      ClearTextAction(:final id) => id,
      ReplaceTextAction(:final id) => id,
      SetTextSelectionAction(:final id) => id,
      ScrollAction(:final id) => id,
      DragAction(:final id) => id,
      LongPressDragAction(:final id) => id,
      SliderToValueAction(:final id) => id,
      AdjustValueAction(:final id) => id,
      DismissAction(:final id) => id,
      _ => null,
    };
  }
}

/// Taps a visible semantics node.
///
/// Maps to `SemanticsAction.tap`. The node must be interactive and
/// visible on screen.
@immutable
class TapAction extends CopilotAction {
  /// Creates a tap action.
  const TapAction(this.id);

  /// Public scene node id of the node to tap.
  final String id;
  @override
  String get name => 'tap';
}

/// Long-presses a visible semantics node.
@immutable
class LongPressAction extends CopilotAction {
  /// Creates a long-press action.
  const LongPressAction(this.id);

  /// Public scene node id.
  final String id;
  @override
  String get name => 'long_press';
}

/// Types text into a visible text field node.
///
/// Appends [text] to the current content of the field identified by [id].
/// Use [ReplaceTextAction] to overwrite the entire field instead.
@immutable
class TypeTextAction extends CopilotAction {
  /// Creates a text input action.
  const TypeTextAction(this.id, this.text);

  /// Public scene node id of the text field.
  final String id;

  /// Text to enter.
  final String text;
  @override
  String get name => 'type_text';
}

/// Clears text from a visible text field node.
@immutable
class ClearTextAction extends CopilotAction {
  /// Creates a clear-text action.
  const ClearTextAction(this.id);

  /// Public scene node id.
  final String id;
  @override
  String get name => 'clear_text';
}

/// Replaces all text in a visible text field node.
@immutable
class ReplaceTextAction extends CopilotAction {
  /// Creates a replace-text action.
  const ReplaceTextAction(this.id, this.text);

  /// Public scene node id.
  final String id;

  /// Replacement text.
  final String text;
  @override
  String get name => 'replace_text';
}

/// Sets the selection range in a visible text field node.
@immutable
class SetTextSelectionAction extends CopilotAction {
  /// Creates a set-text-selection action.
  const SetTextSelectionAction(this.id, this.start, this.end);

  /// Public scene node id.
  final String id;

  /// Selection start offset.
  final int start;

  /// Selection end offset.
  final int end;
  @override
  String get name => 'set_text_selection';
}

/// Sends a keyboard editing/navigation action to the focused field.
@immutable
class KeyboardAction extends CopilotAction {
  /// Creates a keyboard action.
  const KeyboardAction(this.key);

  /// Supported key name.
  final String key;
  @override
  String get name => 'keyboard_action';
}

/// Scrolls a visible scrollable node.
@immutable
class ScrollAction extends CopilotAction {
  /// Creates a scroll action.
  const ScrollAction(this.id, this.direction, this.amount);

  /// Public scene node id.
  final String id;

  /// Scroll direction.
  final String direction;

  /// Scroll amount.
  final String amount;
  @override
  String get name => 'scroll';
}

/// Drags from the center of a visible node.
@immutable
class DragAction extends CopilotAction {
  /// Creates a drag action.
  const DragAction(this.id, this.direction, this.amount);

  /// Public scene node id.
  final String id;

  /// Drag direction.
  final String direction;

  /// Drag amount.
  final String amount;
  @override
  String get name => 'drag';
}

/// Long-presses, then drags from the center of a visible node.
@immutable
class LongPressDragAction extends CopilotAction {
  /// Creates a long-press-drag action.
  const LongPressDragAction(this.id, this.direction, this.amount);

  /// Public scene node id.
  final String id;

  /// Drag direction after the long press.
  final String direction;

  /// Drag amount.
  final String amount;
  @override
  String get name => 'long_press_drag';
}

/// Drags a slider-like control to a normalized value.
@immutable
class SliderToValueAction extends CopilotAction {
  /// Creates a slider action.
  const SliderToValueAction(this.id, this.value);

  /// Public scene node id.
  final String id;

  /// Normalized value from 0.0 to 1.0.
  final double value;
  @override
  String get name => 'slider_to_value';
}

/// Uses semantic increase/decrease actions on a value control.
@immutable
class AdjustValueAction extends CopilotAction {
  /// Creates an adjust-value action.
  const AdjustValueAction(this.id, this.direction, this.steps);

  /// Public scene node id.
  final String id;

  /// Either increase or decrease.
  final String direction;

  /// Number of semantic steps.
  final int steps;
  @override
  String get name => 'adjust_value';
}

/// Dismisses a visible dismissible node.
@immutable
class DismissAction extends CopilotAction {
  /// Creates a dismiss action.
  const DismissAction(this.id);

  /// Public scene node id.
  final String id;
  @override
  String get name => 'dismiss';
}

/// Requests a system back navigation.
@immutable
class SystemBackAction extends CopilotAction {
  /// Creates a system back action.
  const SystemBackAction();

  @override
  String get name => 'system_back';
}

/// Requests user/app confirmation before continuing.
@immutable
class RequestConfirmationAction extends CopilotAction {
  /// Creates a confirmation request action.
  const RequestConfirmationAction(this.reason);

  /// Why confirmation is needed.
  final String reason;
  @override
  String get name => 'request_confirmation';
}

/// Waits for loading or animation.
@immutable
class WaitAction extends CopilotAction {
  /// Creates a wait action.
  const WaitAction(this.duration);

  /// Time to wait.
  final Duration duration;
  @override
  String get name => 'wait';
}

/// Marks the goal complete.
///
/// Must be the only tool call in a response. The [summary] is included
/// in the [CopilotCompleted] result.
@immutable
class DoneAction extends CopilotAction {
  /// Creates a done action.
  const DoneAction(this.summary);

  /// Completion summary describing what was accomplished.
  final String summary;
  @override
  String get name => 'done';
}

/// Marks the goal impossible.
///
/// Must be the only tool call in a response. The [reason] is included
/// in the [CopilotFailed] result.
@immutable
class FailAction extends CopilotAction {
  /// Creates a fail action.
  const FailAction(this.reason);

  /// Failure reason describing why the goal cannot be achieved.
  final String reason;
  @override
  String get name => 'fail';
}

/// Represents an unsupported model tool call.
@immutable
class UnknownAction extends CopilotAction {
  /// Creates an unknown action.
  const UnknownAction(this.name, this.args);

  /// Unsupported tool name.
  @override
  final String name;

  /// Raw tool arguments.
  final Map<String, Object?> args;
}

String _requiredString(Map<String, Object?> args, String key) {
  final value = args[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw ArgumentError.value(value, key, 'Expected a non-empty string');
}

double _requiredDouble(Map<String, Object?> args, String key) {
  final value = args[key];
  if (value is num) {
    return value.toDouble().clamp(0.0, 1.0).toDouble();
  }
  throw ArgumentError.value(value, key, 'Expected a number from 0.0 to 1.0');
}

int _requiredInt(Map<String, Object?> args, String key) {
  final value = args[key];
  if (value is num) {
    return value.round();
  }
  throw ArgumentError.value(value, key, 'Expected an integer');
}
