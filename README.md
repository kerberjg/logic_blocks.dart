<div align="center">

# logic_blocks
Human-friendly hierarchical state machine library for Dart, based on the original C# LogicBlocks package from Chickensoft.

```bash
dart pub add logic_blocks
```

<!-- Badges -->
<!-- remember to update these badges when using the template! -->

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](LICENSE)
[![build](https://github.com/kerberjg/logic_blocks.dart/actions/workflows/build.yml/badge.svg)](https://github.com/kerberjg/logic_blocks.dart)
[![example](https://img.shields.io/badge/examples-included-blue)](#-usage-guide)
[![stars](https://img.shields.io/github/stars/kerberjg/logic_blocks.dart.svg)](https://github.com/kerberjg/logic_blocks.dart/stargazers)
<br/>
[![pub package](https://img.shields.io/pub/v/logic_blocks?logo=dart)](https://pub.dev/packages/logic_blocks)
[![pub score](https://img.shields.io/pub/points/logic_blocks?logo=dart)](https://pub.dev/packages/logic_blocks/score)
[![likes](https://img.shields.io/pub/likes/logic_blocks?logo=dart)](https://pub.dev/packages/logic_blocks/likes)

</div>

Human-friendly hierarchical & serializable state machine library. It provides a structured way to model complex state-driven logic in performance-sensitive Dart applications, with a focus on maintainability, testability, and clarity.

Rewritten in Dart, based on [the original C# LogicBlocks package](https://github.com/chickensoft-games/logicblocks) from [🐤Chickensoft](https://github.com/chickensoft-games)

### 💙 Use cases
- 🎮 **Gameplay and runtime systems**: model complex, high-performance behavior with hierarchical states
- 🧭 **Workflow-heavy app features**: represent multi-step UI or domain flows with explicit state transitions
- 🧪 **Testable domain logic**: isolate state behavior into deterministic, strongly-typed state/input/output units


## ✨ Features
- Human-friendly hierarchical state machines for Dart
- API based on Chickensoft LogicBlocks for C#
- States are defined as self-contained types that read like ordinary code using the state pattern
- Designed for performance, adaptability, and error tolerance, making it refactor-friendly for evolving systems
- Strongly-typed state, input, and transition modeling
- Stateful future tracking utilities and test-friendly bindings


#### Coming up next:
- Additional docs and migration notes from C# LogicBlocks
- Example projects showcasing common patterns and best practices

---

## 🔮 Usage Guide

### Getting Started

A `LogicBlock` is a state machine with three moving parts:

- **Inputs** — values you send in to drive the machine (e.g. button taps, network responses)
- **States** — self-contained objects that define *how* each input is handled and *which state* to move to next
- **Outputs** — values produced by states that observers (bindings) receive

```
logic.input(ButtonTapped()) → StateA handles it → output(SpinnerShown()) → transitions to LoadingState
```

---

#### 1. Define inputs, states, and outputs

Using sealed classes lets the Dart type-checker give you exhaustive coverage.

```dart
// Inputs
sealed class AppInput { const AppInput(); }
final class SignInPressed extends AppInput { const SignInPressed(); }
final class SignOutPressed extends AppInput { const SignOutPressed(); }

// Outputs
sealed class AppOutput { const AppOutput(); }
final class ShowSpinner extends AppOutput { const ShowSpinner(); }
final class HideSpinner extends AppOutput { const HideSpinner(); }

// State base class
abstract base class AppState extends StateLogic<AppState> {}
```

---

#### 2. Write state classes

Each state registers its input handlers and lifecycle callbacks in its constructor.

```dart
final class IdleState extends AppState {
  IdleState() {
    // Fired when this state is entered
    onEnter(() => output(const HideSpinner()));

    // Handle a specific input type; return a transition
    on<SignInPressed>((input) => to<LoadingState>());
  }
}

final class LoadingState extends AppState {
  LoadingState() {
    onEnter(() => output(const ShowSpinner()));

    on<SignOutPressed>((input) => to<IdleState>());
  }
}
```

Key methods available inside a state:

| Method | Purpose |
|---|---|
| `on<TInput>(handler)` | Register a typed input handler |
| `onAny(handler)` | Fallback for unhandled inputs |
| `to<TNextState>()` | Transition to another state |
| `toSelf()` | Re-enter the current state |
| `output(value)` | Emit an output to observers |
| `get<T>()` | Read data from the shared blackboard |
| `input(value)` | Enqueue a new input on the logic block |
| `addError(e)` | Report an error (calls `handleError`) |

---

#### 3. Create the logic block

Register all state singletons on the blackboard in the constructor, then declare the initial state.

```dart
class AppLogicBlock extends LogicBlock<AppState> {
  AppLogicBlock() {
    // Pre-create and store all states as singletons
    set(IdleState());
    set(LoadingState());
  }

  @override
  Transition getInitialState() => to<IdleState>();

  // Optional overrides:
  @override
  void onStart() => print('started');

  @override
  void handleError(Object e) => print('error: $e');
}
```

---

#### 4. Start, use, and stop

```dart
final logic = AppLogicBlock();

logic.start();                          // enters IdleState, fires onEnter
print(logic.value);                     // IdleState instance

logic.input(const SignInPressed());     // transitions to LoadingState
print(logic.value);                     // LoadingState instance

logic.stop();                           // exits current state, clears input queue
logic.dispose();                        // stop + release all resources
```

---

#### 5. Enter and exit callbacks

Callbacks only fire when the **type** changes, so self-transitions are silently skipped.

```dart
final class HomeState extends AppState {
  HomeState() {
    // Fires only when coming from a state of a *different* type
    onEnter(() => print('entered Home'));

    // Receives the previous state (null on first entry)
    onEnterWithPrevious((prev) => print('came from $prev'));

    // Fires only when leaving to a state of a *different* type
    onExit(() => print('leaving Home'));

    // Receives the next state (null when stopping)
    onExitWithNext((next) => print('going to $next'));
  }
}
```

---

### Shared data — the Blackboard

The blackboard is a type-keyed store shared across all states. Store anything that should outlive a single state.

```dart
// In the logic block constructor — set initial values:
set(UserSession.empty());

// Inside a state handler — read:
final session = get<UserSession>();
```

`logic.get<T>()` and `logic.set<T>(data)` are also available from outside the block.

---

### Async operations

Wrap any `Future` with `async()` so its result is delivered back as an input, even if the state has already changed by the time it completes.

```dart
final class LoadingState extends AppState {
  LoadingState() {
    onEnter(() {
      async(fetchUser())
        .input((user) => UserLoaded(user))       // success → input
        .errorInput((e) => UserLoadFailed(e));   // error → input
    });
  }
}
```

Await all in-flight futures from outside the block:

```dart
await logic.task;  // resolves when every async() call has completed
```

---

### Observe changes with bindings

`logic.bind()` returns a `LogicBlockBinding`. Register typed callbacks, then call `dispose()` when done.

```dart
final binding = logic.bind();

binding
  ..onState<LoadingState>((_) => spinner.show())
  ..onState<IdleState>((_) => spinner.hide())
  ..onOutput<ShowSpinner>((_) => print('spinner shown'))
  ..onError<Exception>((e) => showSnackbar(e.toString()));

// Clean up when done (e.g. in a widget's dispose):
binding.dispose();
```

State callbacks fire only when the runtime type of the active state *changes* — not on self-transitions.

---

## 🧪 Testing

**Isolate a single state** using `createFakeContext()`:

```dart
test('IdleState emits HideSpinner on enter', () {
  final state = IdleState();
  final ctx = state.createFakeContext();

  state.enter();

  expect(ctx.outputs, [isA<HideSpinner>()]);
});
```

**Test input handling** directly:

```dart
test('IdleState transitions to LoadingState on SignInPressed', () {
  final state = IdleState();
  state.createFakeContext();

  final transition = state.handleInput(const SignInPressed());

  expect(transition.stateType, LoadingState);
});
```

**Test binding callbacks** without a real logic block:

```dart
test('binding fires for matching state type', () {
  final binding = LogicBlockFakeBinding<AppState>();
  var fired = false;

  binding.onState<LoadingState>((_) => fired = true);
  binding.setState(LoadingState());

  expect(fired, isTrue);
});
```

## 📄 License

This project is licensed under the Mozilla Public License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🔥 Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes. Make sure to read the following guidelines before contributing:

- [Code of Conduct](CODE_OF_CONDUCT.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- ["Effective Dart" Style Guide](https://dart.dev/guides/language/effective-dart)
- [**pub.dev** Package Publishing Guidelines](https://dart.dev/tools/pub/publishing)

## 🙏 Credits & Acknowledgements

### Contributors 🧑‍💻💙📝

This package is developed/maintained by the following rockstars!
Your contributions make a difference! 💖

![contributors badge](https://readme-contribs.as93.net/contributors/kerberjg/logic_blocks.dart?textColor=888888)

### Sponsors 🫶✨🥳

Kind thanks to all our sponsors! Thank you for supporting the Dart/Flutter community, and keeping open source alive! 💙

![sponsors badge](https://readme-contribs.as93.net/sponsors/kerberjg?textColor=888888)

---

<!-- Keep the below notice -->

> Based on [`dart_package_template`](https://github.com/kerberjg/dart_package_template) - a high-quality Dart package template with best practices, CI/CD, and more! 💙✨