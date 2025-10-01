import CasePaths
import ComposableArchitecture
import Testing
@testable import ReportIssueSwift62Bug

// Passes on `main` and fails on `remove-main-actor-now`
@Test func receiveAction_IgnoredAction() async {
  await withExpectedIssue {
    let clock = TestClock()

    let store = await TestStore(initialState: ReducerWithDelay.State(count: 0)) {
      ReducerWithDelay(clock: clock)
    }

    await store.send(.incrementAfterDelay)
    await clock.advance(by: .seconds(2))
  }
}

struct ReducerWithDelay: Reducer, Sendable {
  let clock: any Clock<Duration>

  struct State: Equatable {
    var count: Int
  }

  @CasePathable
  enum Action: Equatable {
    case incrementAfterDelay
    case increment
  }

  init(clock: some Clock<Duration>) {
    self.clock = clock
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .incrementAfterDelay:
        return .run { send in
          try await clock.sleep(for: .seconds(1))
          await send(.increment)
        }

      case .increment:
        state.count += 1
        return .none
      }
    }
  }
}
