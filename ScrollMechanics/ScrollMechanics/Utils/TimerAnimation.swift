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
        
#if os(iOS)
        let displayLink = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))
        displayLink.add(to: .main, forMode: RunLoop.Mode.common)
        self.displayLink = displayLink
#else
        let timer = Timer(timeInterval: Self.interval, target: self, selector: #selector(handleFrame), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .default)
        self.timer = timer
#endif
    }

    deinit {
        invalidate()
    }
    
    public func invalidate() {
        guard running else { return }
        running = false
        completion?(false)
#if os(iOS)
        displayLink?.invalidate()
#else
        timer?.invalidate()
        timer = nil
#endif
    }

    private let duration: TimeInterval
    private let animations: Animations
    private let completion: Completion?
    
#if os(iOS)
    private weak var displayLink: CADisplayLink?
#else
    private weak var timer: Timer?
#endif

    private var running: Bool = true

    private let startDate: Date

    @objc private func handleFrame(_ sender: Any?) {
        guard running else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        if elapsed >= duration {
            animations(1, duration)
            running = false
            completion?(true)
            
#if os(iOS)
            displayLink?.invalidate()
#else
            timer?.invalidate()
#endif
        } else {
            animations(elapsed / duration, elapsed)
        }
    }
}
