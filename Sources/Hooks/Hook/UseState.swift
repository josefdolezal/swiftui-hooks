import SwiftUI

/// A hook to use a `Binding<State>` wrapping current state to be updated by setting a new state to `wrappedValue`.
/// Triggers a view update when the state has been changed.
///
///     let count = useState(0)  // Binding<Int>
///
///     Button("Increment") {
///         count.wrappedValue += 1
///     }
///
/// - Parameter initialState: An initial state.
/// - Returns: A `Binding<State>` wrapping current state.
public func useState<State>(_ initialState: State) -> Binding<State> {
    useHook(StateHook(initialState: initialState))
}

private struct StateHook<State>: Hook {
    let initialState: State
    var updateStrategy: HookUpdateStrategy? = .once

    func makeState() -> Ref {
        Ref(initialState: initialState)
    }

    func value(coordinator: Coordinator) -> Binding<State> {
        Binding(
            get: {
                coordinator.state.state
            },
            set: { newState, transaction in
                assertMainThread()

                guard !coordinator.state.isDisposed else {
                    return
                }

                withTransaction(transaction) {
                    coordinator.state.state = newState
                    coordinator.updateView()
                }
            }
        )
    }

    func dispose(state: Ref) {
        state.isDisposed = true
    }
}

private extension StateHook {
    final class Ref {
        var state: State
        var isDisposed = false

        init(initialState: State) {
            state = initialState
        }
    }
}
