import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'copilot_config.dart';
import 'copilot_controller.dart';

/// Enables Flutter semantics and provides a [CopilotController] to descendants.
///
/// Wrap your app's root widget with [CopilotApp] to make the copilot
/// available throughout the widget tree. This widget ensures the
/// Flutter semantics tree is active (required for the copilot to
/// observe the UI) and injects a [CopilotController] via
/// [CopilotScope].
///
/// ```dart
/// CopilotApp(
///   config: CopilotConfig(llm: OpenAILlmAdapter(apiKey: 'sk-...')),
///   child: MaterialApp(home: MyHomePage()),
/// )
/// ```
class CopilotApp extends StatefulWidget {
  /// Creates a copilot wrapper for [child].
  ///
  /// [config] provides the LLM adapter, safety policy, and runtime
  /// options. [child] is the app subtree the copilot can observe and
  /// control.
  const CopilotApp({
    required this.child,
    required this.config,
    super.key,
  });

  /// The app or subtree the copilot can observe and control.
  final Widget child;

  /// Runtime configuration for copilot sessions.
  final CopilotConfig config;

  @override
  State<CopilotApp> createState() => _CopilotAppState();
}

class _CopilotAppState extends State<CopilotApp> {
  late CopilotController _controller;
  late CopilotConfig _config;
  late final SemanticsHandle _semanticsHandle;

  @override
  void initState() {
    super.initState();
    _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
    _config = widget.config;
    _controller = CopilotController(_config);
  }

  @override
  void didUpdateWidget(CopilotApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _controller.dispose();
      _config = widget.config;
      _controller = CopilotController(_config);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _semanticsHandle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CopilotScope(
      controller: _controller,
      child: widget.child,
    );
  }
}
