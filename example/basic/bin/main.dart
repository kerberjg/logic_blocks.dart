import 'dart:io';

import 'package:logic_blocks/logic_blocks.dart';

sealed class _AppInput {
  const _AppInput();
}

final class _SignInPressed extends _AppInput {
  const _SignInPressed();
}

final class _SignOutPressed extends _AppInput {
  const _SignOutPressed();
}

sealed class _AppOutput {
  const _AppOutput();
}

final class _ShowSpinner extends _AppOutput {
  const _ShowSpinner();
}

final class _HideSpinner extends _AppOutput {
  const _HideSpinner();
}

abstract base class _AppState extends StateLogic<_AppState> {}

final class _IdleState extends _AppState {
  _IdleState() {
    onEnter(() => output(const _HideSpinner()));
    on<_SignInPressed>((_) => to<_LoadingState>());
  }
}

final class _LoadingState extends _AppState {
  _LoadingState() {
    onEnter(() => output(const _ShowSpinner()));
    on<_SignOutPressed>((_) => to<_IdleState>());
  }
}

final class _AppLogicBlock extends LogicBlock<_AppState> {
  _AppLogicBlock() {
    set(_IdleState());
    set(_LoadingState());
  }

  @override
  Transition getInitialState() => to<_IdleState>();
}

void main() {
  final logic = _AppLogicBlock();
  final binding = logic.bind()
    ..onState<_IdleState>((_) => stdout.writeln('idle'))
    ..onState<_LoadingState>((_) => stdout.writeln('loading'))
    ..onOutput<_HideSpinner>((_) => stdout.writeln('hide spinner'))
    ..onOutput<_ShowSpinner>((_) => stdout.writeln('show spinner'));

  logic
    ..start()
    ..input(const _SignInPressed())
    ..input(const _SignOutPressed())
    ..dispose();

  binding.dispose();
}
