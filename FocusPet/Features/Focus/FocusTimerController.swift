import Combine
import Foundation

@MainActor
final class FocusTimerController: ObservableObject {
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var remainingSeconds: Int?
    @Published private(set) var isRunning = false

    let timerMode: TimerMode
    let plannedDurationSeconds: Int?

    private var timer: Timer?

    init(timerMode: TimerMode, plannedDurationSeconds: Int?) {
        self.timerMode = timerMode
        self.plannedDurationSeconds = plannedDurationSeconds
        self.remainingSeconds = plannedDurationSeconds
    }

    deinit {
        timer?.invalidate()
    }

    func start(onCountdownFinished: @escaping () -> Void) {
        guard !isRunning else { return }
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }

            self.elapsedSeconds += 1

            if self.timerMode == .countDown {
                let nextValue = max((self.remainingSeconds ?? 0) - 1, 0)
                self.remainingSeconds = nextValue

                if nextValue == 0 {
                    self.stop()
                    onCountdownFinished()
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        stop()
        elapsedSeconds = 0
        remainingSeconds = plannedDurationSeconds
    }
}
