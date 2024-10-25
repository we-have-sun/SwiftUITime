import SwiftUI

struct ContentView: View {
    @State var startDate: Date?
    @State var isPaused: Bool = false
    @State var pauseDate: Date?
    @State var accumulatedTime: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 50) {
            DigitalClock()
            TimelineView(MetricsTimelineSchedule(from: .now)) { _ in
                VStack(spacing: 16.0) {
                    ElapsedTimeView(elapsedTime: elapsedTime())
                    HStack(spacing: 16.0) {
                        Button {
                            if startDate == nil {
                                // Initial start
                                startDate = .now
                                isPaused = false
                            } else if isPaused {
                                // Resume from pause
                                if let pauseDate {
                                    accumulatedTime += pauseDate.timeIntervalSince(startDate!)
                                }
                                startDate = .now
                                pauseDate = nil
                                isPaused = false
                            } else {
                                // Pause
                                pauseDate = .now
                                isPaused = true
                            }
                        } label: {
                            Text(buttonTitle)
                        }
                        
                        Button {
                            startDate = nil
                            pauseDate = nil
                            isPaused = false
                            accumulatedTime = 0
                        } label: {
                            Text("Stop")
                                .foregroundStyle(Color.red)
                        }
                    }
                }
            }
        }
    }
    
    private var buttonTitle: String {
        if startDate == nil {
            return "Start"
        } else if isPaused {
            return "Resume"
        } else {
            return "Pause"
        }
    }
    
    private func elapsedTime() -> TimeInterval {
        guard let startDate else {
            return 0
        }
        
        if isPaused, let pauseDate {
            return pauseDate.timeIntervalSince(startDate) + accumulatedTime
        }
        
        return -startDate.timeIntervalSinceNow + accumulatedTime
    }
}

struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    
    init(from startDate: Date) {
        self.startDate = startDate
    }
    
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var baseSchedule = PeriodicTimelineSchedule(
            from: self.startDate,
            by: (mode == .lowFrequency ? 1.0 : 1.0 / 120)
        )
            .entries(from: startDate, mode: mode)
        
        return AnyIterator<Date> {
            return baseSchedule.next()
        }
    }
}

struct ElapsedTimeView: View {
    var elapsedTime: TimeInterval = 0
    @State private var timeFormatter = ElapsedTimeFormatter()
    
    var body: some View {
        Text(NSNumber(value: elapsedTime), formatter: timeFormatter)
            .font(.system(.largeTitle, design: .monospaced))
    }
}

final class ElapsedTimeFormatter: Formatter {
    let componentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    override func string(for value: Any?) -> String? {
        guard let time = value as? TimeInterval else {
            return nil
        }
        
        guard let formattedString = componentsFormatter.string(from: time) else {
            return nil
        }
        
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        // Changed format to include three digits (%.3d) instead of two
        return String(format: "%@%@%.3d", formattedString, decimalSeparator, milliseconds)
    }
}

struct DigitalClock: View {
    var body: some View {
        // Update to 0.1 for deciseconds or 0.01 for centiseconds
        TimelineView(.periodic(from: .now, by: 0.001)) { timeline in
            let time = timeline.date
            let formatter = DateFormatter()
            // Get the milliseconds
            let milliseconds = Calendar.current.component(.nanosecond, from: time) / 1_000_000
            
            HStack(spacing: 0) {
                Text(time.formatted(.dateTime.hour().minute().second()))
                    .font(.largeTitle)
                    .monospacedDigit()
                Text(String(format: ".%03d", milliseconds))
                    .font(.largeTitle)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    ContentView()
}
