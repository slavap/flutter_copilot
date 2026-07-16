import 'package:flutter/material.dart';

import '../state/app_state.dart';

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    required this.state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  final AppState state;

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.state;
  }
}
