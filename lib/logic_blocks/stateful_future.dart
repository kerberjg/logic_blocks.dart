// Fluent API — returning `this` is intentional.
// ignore_for_file: avoid_returning_this
part of 'logic_block.dart';

/// A wrapper around a [Future] that delivers its result as an input to a
/// logic block.
///
/// Use [StateLogic.async] to create instances. Chain [input] and
/// [errorInput] to define which inputs to fire on success or failure.
///
/// If the logic block has been stopped or disposed by the time the future
/// completes, the input is silently discarded.
///
/// Inputs are delivered even if the originating state has been replaced
/// (detached), because async work should not be lost on state transitions.
/// Whatever state is active when the future completes will receive the input.
class StatefulFuture<T> {
  StatefulFuture._(this._adapter, Future<T> future) {
    final continuation = future.then(
      (value) => _onSuccess?.call(value),
      onError: (Object error) => _onError?.call(error),
    );

    _adapter.trackFuture(continuation);
  }

  /// Delivers [input] to the logic block, preserving its generic type.
  void _inputIfRunning<TInput extends Object>(TInput input) {
    if (!_adapter.isStarted) return;
    _adapter.context!.input<TInput>(input);
  }

  final _ContextAdapter _adapter;
  void Function(T)? _onSuccess;
  void Function(Object)? _onError;

  /// Registers a callback that converts the future's success value into an
  /// input for the logic block.
  StatefulFuture<T> input<TInput extends Object>(
    TInput Function(T value) toInput,
  ) {
    _onSuccess = (value) => _inputIfRunning<TInput>(toInput(value));
    return this;
  }

  /// Registers a callback that converts the future's error into an input
  /// for the logic block.
  StatefulFuture<T> errorInput<TInput extends Object>(
    TInput Function(Object error) toInput,
  ) {
    _onError = (error) => _inputIfRunning<TInput>(toInput(error));
    return this;
  }
}
