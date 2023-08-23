import QuartzCore

public final class TimerAnimation {
    private static let interval = 1.0/60.0

    public typealias Animations = (_ progress: Double, _ time: TimeInterval) -> Void
    public typealias Completion = (_ finished: Bool) -> Void
    
    public init(duration: TimeInterval, animations: @escaping Animations, completion: Completion? = nil) {
        self.duration = duration
        self.animations = animations
        self.completion = completion

        self.startDate = Date()
        
        let timer = Timer(timeInterval: Self.interval, target: self, selector: #selector(handleFrame), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .default)
        self.timer = timer
    }

    deinit {
        invalidate()
    }
    
    public func invalidate() {
        guard running else { return }
        running = false
        completion?(false)
        timer?.invalidate()
        timer = nil
    }

    private let duration: TimeInterval
    private let animations: Animations
    private let completion: Completion?
    private weak var timer: Timer?

    private var running: Bool = true

    private let startDate: Date

    @objc private func handleFrame(_ timer: Timer) {
        guard running else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        if elapsed >= duration {
            animations(1, duration)
            running = false
            completion?(true)
            timer.invalidate()
        } else {
            animations(elapsed / duration, elapsed)
        }
    }
}
