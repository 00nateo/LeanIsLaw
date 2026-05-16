import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Theme (mirror of main app)

enum WTheme {
    static let bg          = Color(red: 0.07, green: 0.07, blue: 0.08)
    static let surface     = Color(red: 0.11, green: 0.11, blue: 0.13)
    static let inset       = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let accent      = Color(red: 0.91, green: 0.27, blue: 0.10)
    static let accentGlow  = Color(red: 1.00, green: 0.45, blue: 0.18)
    static let mint        = Color(red: 0.40, green: 0.90, blue: 0.65)
    static let dim         = Color.white.opacity(0.55)
    static let faint       = Color.white.opacity(0.35)
}

// MARK: - Snapshot

struct Snapshot {
    var todayTotal: Int
    var weeklyTotal: Int
    var weeklyGoal: Int
    var daysRemaining: Int
    var dayTotals: [Int]

    var weeklyLeft: Int { max(0, weeklyGoal - weeklyTotal) }
    var avgPerDay: Int { weeklyLeft / max(1, daysRemaining) }
    var dailyTarget: Int { weeklyGoal / 7 }
    var pct: Double { min(1.0, Double(weeklyTotal) / Double(max(1, weeklyGoal))) }

    var todayLeft: Int { max(0, dailyTarget - todayTotal) }
    var todayConsumedPct: Double {
        min(1.0, Double(todayTotal) / Double(max(1, dailyTarget)))
    }
    var todayLeftPct: Double {
        max(0.0, 1.0 - todayConsumedPct)
    }

    static let empty = Snapshot(todayTotal: 0, weeklyTotal: 0, weeklyGoal: 14000,
                                daysRemaining: 7, dayTotals: Array(repeating: 0, count: 7))

    static let placeholder = Snapshot(todayTotal: 1240, weeklyTotal: 8200, weeklyGoal: 14000,
                                      daysRemaining: 3,
                                      dayTotals: [1800, 1950, 2100, 1700, 600, 0, 0])
}

enum Shared {
    static let appGroup = "group.nateo.LeanIsLaw"
    static let key = "snapshot"

    static func load() -> Snapshot {
        let defaults = UserDefaults(suiteName: appGroup) ?? .standard
        guard let data = defaults.data(forKey: key),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return .empty }
        let totals = (dict["dayTotals"] as? [Int]) ?? Array(repeating: 0, count: 7)
        return Snapshot(
            todayTotal: dict["todayTotal"] as? Int ?? 0,
            weeklyTotal: dict["weeklyTotal"] as? Int ?? 0,
            weeklyGoal: dict["weeklyGoal"] as? Int ?? 14000,
            daysRemaining: dict["daysRemaining"] as? Int ?? 7,
            dayTotals: totals
        )
    }
}

// MARK: - Configuration intent

enum WidgetMode: String, AppEnum {
    case consumed
    case remaining

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Display Mode"
    static var caseDisplayRepresentations: [WidgetMode: DisplayRepresentation] = [
        .consumed: DisplayRepresentation(title: "Calories eaten"),
        .remaining: DisplayRepresentation(title: "Calories left today")
    ]
}

struct WidgetConfig: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Lean Is Law"
    static var description = IntentDescription("Choose what to show.")

    @Parameter(title: "Mode", default: .consumed)
    var mode: WidgetMode
}

// MARK: - Timeline

struct LILEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot
    let config: WidgetConfig
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LILEntry {
        LILEntry(date: Date(), snapshot: .placeholder, config: WidgetConfig())
    }
    func snapshot(for configuration: WidgetConfig, in context: Context) async -> LILEntry {
        LILEntry(date: Date(),
                 snapshot: context.isPreview ? .placeholder : Shared.load(),
                 config: configuration)
    }
    func timeline(for configuration: WidgetConfig, in context: Context) async -> Timeline<LILEntry> {
        let entry = LILEntry(date: Date(), snapshot: Shared.load(), config: configuration)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(next))
    }
}

// MARK: - System widget views

struct LILSmallView: View {
    let snap: Snapshot
    let mode: WidgetMode

    var headlineNumber: Int { mode == .consumed ? snap.todayTotal : snap.todayLeft }
    var headlineLabel: String { mode == .consumed ? "today · kcal" : "left today" }
    var progress: Double { mode == .consumed ? snap.todayConsumedPct : snap.todayLeftPct }
    var subTint: Color { mode == .consumed ? WTheme.mint : WTheme.accent }
    var subLabel: String {
        let pct = Int((mode == .consumed ? snap.todayConsumedPct : snap.todayLeftPct) * 100)
        return "\(pct)% \(mode == .consumed ? "DONE" : "LEFT")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LEAN IS LAW")
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(WTheme.accent)
            Text("\(headlineNumber)")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(headlineLabel)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundStyle(WTheme.dim)
            Spacer(minLength: 0)
            ProgressCapsule(value: progress).frame(height: 6)
            HStack {
                Text(subLabel)
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundStyle(subTint)
                Spacer()
                Text("/ \(snap.dailyTarget)")
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundStyle(WTheme.faint)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct LILMediumView: View {
    let snap: Snapshot
    let mode: WidgetMode

    var headlineNumber: Int { mode == .consumed ? snap.weeklyTotal : snap.weeklyLeft }
    var headlineLabel: String { mode == .consumed ? "THIS WEEK" : "LEFT THIS WEEK" }
    var progress: Double { mode == .consumed ? snap.pct : (1.0 - snap.pct) }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(headlineLabel)
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(WTheme.accent)
                Text("\(headlineNumber)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("/ \(snap.weeklyGoal) kcal")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(WTheme.faint)
                Spacer(minLength: 0)
                ProgressCapsule(value: progress).frame(height: 6)
                HStack(spacing: 10) {
                    miniStat(mode == .consumed ? "LEFT" : "EATEN",
                             "\(mode == .consumed ? snap.weeklyLeft : snap.weeklyTotal)",
                             WTheme.accent)
                    miniStat("AVG/D", "\(snap.avgPerDay)", WTheme.mint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    DayMicroBar(total: snap.dayTotals[i],
                                target: snap.dailyTarget,
                                isToday: i == max(0, 6 - snap.daysRemaining))
                }
            }
            .frame(width: 92)
        }
    }

    func miniStat(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundStyle(WTheme.faint)
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DayMicroBar: View {
    let total: Int
    let target: Int
    let isToday: Bool
    var pct: Double { min(1.0, Double(total) / Double(max(1, target))) }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(WTheme.inset)
                Capsule()
                    .fill(isToday ? WTheme.accent : WTheme.mint)
                    .frame(width: geo.size.width * CGFloat(pct))
            }
        }
        .frame(height: 6)
    }
}

struct ProgressCapsule: View {
    let value: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(WTheme.inset)
                Capsule()
                    .fill(LinearGradient(colors: [WTheme.accent, WTheme.accentGlow],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(value))
            }
        }
    }
}

// MARK: - Lock screen views

struct LILCircularView: View {
    let snap: Snapshot
    let mode: WidgetMode

    var value: Double { mode == .consumed ? snap.todayConsumedPct : snap.todayLeftPct }
    var number: Int { mode == .consumed ? snap.todayTotal : snap.todayLeft }
    var label: String { mode == .consumed ? "eaten" : "left" }

    var body: some View {
        Gauge(value: value) {
            Text(label)
        } currentValueLabel: {
            Text("\(number)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(mode == .consumed ? WTheme.accent : WTheme.mint)
    }
}

struct LILInlineView: View {
    let snap: Snapshot
    let mode: WidgetMode
    var body: some View {
        if mode == .consumed {
            Text("🔥 \(snap.todayTotal) eaten · \(snap.todayLeft) left")
        } else {
            Text("🥗 \(snap.todayLeft) kcal left today")
        }
    }
}

struct LILRectangularView: View {
    let snap: Snapshot
    let mode: WidgetMode

    var number: Int { mode == .consumed ? snap.todayTotal : snap.todayLeft }
    var headline: String { mode == .consumed ? "eaten" : "left" }
    var progress: Double { mode == .consumed ? snap.todayConsumedPct : snap.todayLeftPct }
    var sublinePct: Int { Int(progress * 100) }
    var sublineWord: String { mode == .consumed ? "of daily" : "remaining" }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("LEAN IS LAW")
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .tracking(1.2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(number)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(headline)
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text("\(sublinePct)% \(sublineWord)")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .layoutPriority(1)
            }
            ProgressView(value: progress).tint(.white)
        }
    }
}

// MARK: - Entry view + config

struct LeanIsLawWidgetsEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: LILEntry

    var body: some View {
        switch family {
        case .systemMedium:
            LILMediumView(snap: entry.snapshot, mode: entry.config.mode)
                .containerBackground(WTheme.bg, for: .widget)
        case .accessoryCircular:
            LILCircularView(snap: entry.snapshot, mode: entry.config.mode)
                .containerBackground(.clear, for: .widget)
        case .accessoryInline:
            LILInlineView(snap: entry.snapshot, mode: entry.config.mode)
        case .accessoryRectangular:
            LILRectangularView(snap: entry.snapshot, mode: entry.config.mode)
                .containerBackground(.clear, for: .widget)
        default:
            LILSmallView(snap: entry.snapshot, mode: entry.config.mode)
                .containerBackground(WTheme.bg, for: .widget)
        }
    }
}

struct LeanIsLawWidgets: Widget {
    let kind: String = "LeanIsLawWidgets"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetConfig.self, provider: Provider()) { entry in
            LeanIsLawWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Lean Is Law")
        .description("Today's calories and weekly progress.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryInline, .accessoryRectangular
        ])
    }
}

#Preview(as: .accessoryRectangular) {
    LeanIsLawWidgets()
} timeline: {
    LILEntry(date: .now, snapshot: .placeholder, config: WidgetConfig())
}

#Preview(as: .accessoryCircular) {
    LeanIsLawWidgets()
} timeline: {
    LILEntry(date: .now, snapshot: .placeholder, config: WidgetConfig())
}
