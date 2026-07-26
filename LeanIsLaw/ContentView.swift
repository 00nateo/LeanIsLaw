import SwiftUI
import Combine
import UIKit
import WidgetKit

// MARK: - Haptics

enum Haptics {
    static let light = UIImpactFeedbackGenerator(style: .light)
    static let medium = UIImpactFeedbackGenerator(style: .medium)
    static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    static let soft = UIImpactFeedbackGenerator(style: .soft)
    static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    static let selection = UISelectionFeedbackGenerator()
    static let notify = UINotificationFeedbackGenerator()

    static func tap()      { light.impactOccurred() }
    static func tick()     { soft.impactOccurred(intensity: 0.6) }
    static func bump()     { medium.impactOccurred() }
    static func thud()     { heavy.impactOccurred() }
    static func snap()     { rigid.impactOccurred() }
    static func pick()     { selection.selectionChanged() }
    static func success()  { notify.notificationOccurred(.success) }
    static func warn()     { notify.notificationOccurred(.warning) }
    static func fail()     { notify.notificationOccurred(.error) }
}

struct HapticTap: ViewModifier {
    var style: () -> Void = Haptics.tap
    func body(content: Content) -> some View {
        content.simultaneousGesture(TapGesture().onEnded { style() })
    }
}
extension View {
    func hapticTap(_ action: @escaping () -> Void = Haptics.tap) -> some View {
        modifier(HapticTap(style: action))
    }
}

// MARK: - Theme

enum Theme {
    static let bg          = Color(red: 0.07, green: 0.07, blue: 0.08)
    static let surface     = Color(red: 0.11, green: 0.11, blue: 0.13)
    static let surfaceHi   = Color(red: 0.16, green: 0.16, blue: 0.18)
    static let inset       = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let accent      = Color(red: 0.91, green: 0.27, blue: 0.10) // TE orange
    static let accentGlow  = Color(red: 1.00, green: 0.45, blue: 0.18)
    static let mint        = Color(red: 0.40, green: 0.90, blue: 0.65)
    static let dim         = Color.white.opacity(0.55)
    static let faint       = Color.white.opacity(0.35)
}

// MARK: - Neumorphic primitives (adapted from costachung/neumorphic)
//
// Soft outer shadow: dual offset shadows (dark bottom-right, light top-left)
// over a subtle linear-gradient surface — the raised neumorphic look.
// Soft inner shadow: simulated inner shadow used for "pressed" / inset
// surfaces (text fields, stat tiles, recessed chips).

struct Neumorph: ViewModifier {
    var radius: CGFloat = 22
    var pressed: Bool = false
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.surfaceHi, Theme.surface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .shadow(color: .black.opacity(pressed ? 0.0 : 0.7), radius: 12, x: 9, y: 9)
                    .shadow(color: Color.white.opacity(pressed ? 0.0 : 0.05), radius: 9, x: -7, y: -7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing),
                        lineWidth: 1)
            )
    }
}

struct SoftInset: ViewModifier {
    var radius: CGFloat = 16
    var fill: Color = Theme.inset
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [fill, Theme.surface.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
            )
            .overlay( // dark inner shadow, top-left
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.black.opacity(0.85), lineWidth: 3)
                    .blur(radius: 3)
                    .offset(x: 2, y: 2)
                    .mask(RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(LinearGradient(colors: [.black, .clear],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing)))
            )
            .overlay( // light inner shadow, bottom-right
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 2)
                    .blur(radius: 2)
                    .offset(x: -1, y: -1)
                    .mask(RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(LinearGradient(colors: [.clear, .black],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing)))
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct SoftInsetCircle: ViewModifier {
    var fill: Color = Theme.inset
    func body(content: Content) -> some View {
        content
            .background(
                Circle().fill(
                    LinearGradient(colors: [fill, Theme.surface.opacity(0.85)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing))
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.8), lineWidth: 3)
                    .blur(radius: 2.5)
                    .offset(x: 1.5, y: 1.5)
                    .mask(Circle().fill(LinearGradient(colors: [.black, .clear],
                                                      startPoint: .topLeading,
                                                      endPoint: .bottomTrailing)))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: 1.5)
                    .blur(radius: 1.5)
                    .offset(x: -1, y: -1)
                    .mask(Circle().fill(LinearGradient(colors: [.clear, .black],
                                                      startPoint: .topLeading,
                                                      endPoint: .bottomTrailing)))
            )
            .clipShape(Circle())
    }
}

struct SoftAccent: ViewModifier {
    var radius: CGFloat = 16
    var tint: Color = Theme.accent
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.accentGlow, tint],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .shadow(color: .black.opacity(0.55), radius: 10, x: 7, y: 7)
                    .shadow(color: tint.opacity(0.45), radius: 12, x: -4, y: -4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Color.white.opacity(0.35), Color.clear],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        lineWidth: 1)
            )
    }
}

extension View {
    func neumorph(_ r: CGFloat = 22) -> some View { modifier(Neumorph(radius: r)) }
    func softInset(_ r: CGFloat = 16, fill: Color = Theme.inset) -> some View {
        modifier(SoftInset(radius: r, fill: fill))
    }
    func softInsetCircle(fill: Color = Theme.inset) -> some View {
        modifier(SoftInsetCircle(fill: fill))
    }
    func softAccent(_ r: CGFloat = 16, tint: Color = Theme.accent) -> some View {
        modifier(SoftAccent(radius: r, tint: tint))
    }
}

// A button style that "presses" the soft outer shadow into a soft inner shadow.
struct SoftButtonStyle<S: InsettableShape>: ButtonStyle {
    var shape: S
    var radius: CGFloat = 16
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    shape.fill(
                        LinearGradient(colors: [Theme.surfaceHi, Theme.surface],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing))
                    if configuration.isPressed {
                        shape.fill(Theme.inset.opacity(0.6))
                    }
                }
                .shadow(color: .black.opacity(configuration.isPressed ? 0 : 0.55),
                        radius: 8, x: 6, y: 6)
                .shadow(color: Color.white.opacity(configuration.isPressed ? 0 : 0.05),
                        radius: 6, x: -4, y: -4)
            )
            .overlay(
                shape.strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Model

struct Entry: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var calories: Int
    var protein: Int?
    var carbs: Int?
    var fat: Int?
}

final class Store: ObservableObject {
    @Published var entries: [Entry] = [] { didSet { save() } }
    @Published var weeklyGoals: [String: Int] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(weeklyGoals) {
                UserDefaults.standard.set(data, forKey: "weeklyGoals")
            }
        }
    }
    @Published var weeklyGoal: Int {
        didSet {
            UserDefaults.standard.set(weeklyGoal, forKey: "weeklyGoal")
            weeklyGoals[Store.weekKey(weekStart)] = weeklyGoal
            writeWidgetSnapshot()
        }
    }

    init() {
        self.weeklyGoal = UserDefaults.standard.object(forKey: "weeklyGoal") as? Int ?? 14000
        if let data = UserDefaults.standard.data(forKey: "weeklyGoals"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.weeklyGoals = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "entries"),
           let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
            self.entries = decoded
        }
        backfillWeeklyGoals()
    }

    static func weekKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    func goalForWeek(_ start: Date) -> Int {
        weeklyGoals[Store.weekKey(start)] ?? weeklyGoal
    }

    private func backfillWeeklyGoals() {
        let cal = Calendar.current
        var changed = false
        var seen = Set<Date>()
        for e in entries {
            if let ws = cal.dateInterval(of: .weekOfYear, for: e.date)?.start {
                seen.insert(ws)
            }
        }
        seen.insert(weekStart)
        for ws in seen {
            let key = Store.weekKey(ws)
            if weeklyGoals[key] == nil {
                weeklyGoals[key] = weeklyGoal
                changed = true
            }
        }
        if !changed { writeWidgetSnapshot() }
    }

    func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "entries")
        }
        writeWidgetSnapshot()
    }

    func writeWidgetSnapshot() {
        let cal = Calendar.current
        let todayTotal = entries.filter { cal.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.calories }
        let dayTotals: [Int] = (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: weekStart)!
            return entries.filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.calories }
        }
        let payload: [String: Any] = [
            "todayTotal": todayTotal,
            "weeklyTotal": weeklyTotal,
            "weeklyGoal": weeklyGoal,
            "daysRemaining": daysRemaining,
            "dayTotals": dayTotals
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            let defaults = UserDefaults(suiteName: "group.nateo.LeanIsLaw") ?? .standard
            defaults.set(data, forKey: "snapshot")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func add(_ e: Entry) { entries.append(e) }
    func update(_ e: Entry) {
        if let i = entries.firstIndex(where: { $0.id == e.id }) { entries[i] = e }
    }
    func remove(_ e: Entry) { entries.removeAll { $0.id == e.id } }

    var weekStart: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }
    var weekEntries: [Entry] { entries.filter { $0.date >= weekStart } }
    var weeklyTotal: Int { weekEntries.reduce(0) { $0 + $1.calories } }
    var weeklyLeft: Int { weeklyGoal - weeklyTotal }

    var daysRemaining: Int {
        let cal = Calendar.current
        let dayIndex = (cal.component(.weekday, from: Date()) - cal.firstWeekday + 7) % 7
        return max(1, 7 - dayIndex)
    }
    var avgNeededPerDay: Int { weeklyLeft / max(1, daysRemaining) }

    // Weekly history: from earliest entry's week (or this week) up to current week
    func weeks() -> [(start: Date, total: Int, goal: Int, success: Bool, isCurrent: Bool)] {
        let cal = Calendar.current
        guard let earliest = entries.map(\.date).min() else {
            let g = goalForWeek(weekStart)
            return [(weekStart, weeklyTotal, g, weeklyTotal <= g && weeklyTotal > 0, true)]
        }
        let firstWeek = cal.dateInterval(of: .weekOfYear, for: earliest)?.start ?? weekStart
        var result: [(Date, Int, Int, Bool, Bool)] = []
        var cursor = firstWeek
        while cursor <= weekStart {
            let end = cal.date(byAdding: .day, value: 7, to: cursor)!
            let items = entries.filter { $0.date >= cursor && $0.date < end }
            let total = items.reduce(0) { $0 + $1.calories }
            let current = cal.isDate(cursor, inSameDayAs: weekStart)
            let goal = goalForWeek(cursor)
            let success = total > 0 && total <= goal
            result.append((cursor, total, goal, success, current))
            cursor = end
        }
        return result.reversed()
    }

    func days() -> [(date: Date, total: Int, items: [Entry])] {
        let cal = Calendar.current
        let start = weekStart
        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: start)!
            let items = entries.filter { cal.isDate($0.date, inSameDayAs: day) }
                .sorted { $0.date < $1.date }
            return (day, items.reduce(0) { $0 + $1.calories }, items)
        }
    }
}

// MARK: - Root

struct ContentView: View {
    @StateObject private var store = Store()
    @State private var tab: Int = 0
    @State private var keyboardUp: Bool = false
    @State private var dayOpen: Bool = false
    @State private var dragOffset: CGFloat = 0

    private let tabCount = 3

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    TodayView(store: store, keyboardUp: $keyboardUp, dayOpen: $dayOpen)
                        .frame(width: w)
                    CalendarView(store: store)
                        .frame(width: w)
                    TDEEView(store: store)
                        .frame(width: w)
                }
                .frame(width: w, alignment: .leading)
                .offset(x: -CGFloat(tab) * w + dragOffset)
                .animation(.spring(response: 0.19, dampingFraction: 0.78), value: tab) // TAB SLIDE SPEED — lower response = faster
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 18)
                        .onChanged { value in
                            // Resist over-swiping at the edges
                            var dx = value.translation.width
                            if tab == 0 && dx > 0 { dx = dx * 0.35 }
                            if tab == tabCount - 1 && dx < 0 { dx = dx * 0.35 }
                            dragOffset = dx
                        }
                        .onEnded { value in
                            let predicted = value.predictedEndTranslation.width
                            let threshold = w / 4
                            withAnimation(.spring(response: 0.19, dampingFraction: 0.78)) { // SWIPE-COMMIT SPEED
                                if predicted < -threshold, tab < tabCount - 1 {
                                    tab += 1
                                    Haptics.bump()
                                } else if predicted > threshold, tab > 0 {
                                    tab -= 1
                                    Haptics.bump()
                                }
                                dragOffset = 0
                            }
                        }
                )

                TabBar(selection: $tab)
                    .offset(y: (keyboardUp || dayOpen) ? 180 : 0)
                    .opacity((keyboardUp || dayOpen) ? 0 : 1)
                    .allowsHitTesting(!keyboardUp && !dayOpen)
                    .animation(.snappy(duration: 0.22, extraBounce: 0.08), value: dayOpen)
                    .animation(.snappy(duration: 0.22, extraBounce: 0.08), value: keyboardUp)
            }
        }
        .preferredColorScheme(.dark)
        .background(Theme.bg.ignoresSafeArea())
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { keyboardUp = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { keyboardUp = false }
        }
    }
}

struct TabBar: View {
    @Binding var selection: Int
    let items: [(String, String)] = [
        ("flame.fill", "TODAY"),
        ("calendar", "WEEKS"),
        ("figure.run", "TDEE")
    ]
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                Button {
                    Haptics.bump()
                    withAnimation(.spring(response: 0.19, dampingFraction: 0.78)) { selection = i } // TAB TAP SPEED
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.0)
                            .font(.system(size: 17, weight: .heavy))
                        Text(item.1)
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .tracking(1.5)
                    }
                    .foregroundStyle(selection == i ? .white : Theme.faint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            if selection == i {
                                Color.clear.softAccent(14)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .neumorph(20)
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }
}

struct TodayView: View {
    @ObservedObject var store: Store
    @Binding var keyboardUp: Bool
    @Binding var dayOpen: Bool
    @State private var path = NavigationPath()
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var showMacros = false
    @State private var showGoal = false
    @State private var showMealSheet = false
    @State private var pickedImage: UIImage? = nil
    @State private var pickerSource: CameraPicker.Source? = nil
    @State private var inputHidden: Bool = false
    @State private var lastScrollY: CGFloat = 0
    @FocusState private var focused: Bool
    @Namespace private var dayNS

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: Date.self) { date in
                    DayEditor(date: date, store: store)
                        .navigationTransition(.zoom(sourceID: date, in: dayNS))
                        .toolbar(.hidden, for: .navigationBar)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
        .onChange(of: path.count) { _, n in
            dayOpen = n > 0
        }
    }

    var content: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    summary
                    weekStrip
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 180)
            }
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in
                if keyboardUp { return }
                let delta = y - lastScrollY
                if abs(delta) < 6 { return }
                if delta > 0, !inputHidden, y > 40 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { inputHidden = true }
                } else if delta < 0, inputHidden {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { inputHidden = false }
                }
                lastScrollY = y
            }

            VStack(spacing: 0) {
                bigInput
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .padding(.bottom, keyboardUp ? 8 : 84)
                    .background(
                        LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg, Theme.bg],
                                       startPoint: .top, endPoint: .bottom)
                            .allowsHitTesting(false)
                            .ignoresSafeArea(edges: .bottom)
                    )
            }
            .offset(y: inputHidden && !keyboardUp ? 260 : 0)
            .opacity(inputHidden && !keyboardUp ? 0 : 1)

        }
        .sheet(isPresented: $showGoal) {
            GoalView(goal: $store.weeklyGoal)
                .presentationDetents([.medium])
                .presentationBackground(Theme.bg)
        }
        .sheet(isPresented: $showMealSheet, onDismiss: {
            pickedImage = nil
            pickerSource = nil
        }) {
            mealSheet
                .presentationDetents([.large])
                .presentationBackground(Theme.bg)
                .sheet(item: Binding(
                    get: { pickerSource.map { PickerSourceWrapper(source: $0) } },
                    set: { pickerSource = $0?.source }
                )) { wrapper in
                    CameraPicker(source: wrapper.source) { img in
                        pickedImage = img.downscaled(toLongestEdge: 1024)
                        pickerSource = nil
                    } onCancel: {
                        pickerSource = nil
                    }
                    .ignoresSafeArea()
                }
        }
        .onTapGesture { focused = false }
    }

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("LEAN IS LAW")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(Theme.accent)
                Text(Date(), format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button { Haptics.tap(); showGoal = true } label: {
                Image(systemName: "target")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
            }
            .neumorph(16)
        }
        .padding(.top, 6)
    }

    var evaluated: Int? { evaluateExpression(caloriesText) }
    var hasOperator: Bool { caloriesText.contains(where: { "+-*/×÷−".contains($0) }) }

    var bigInput: some View {
        let expanded = focused
        let inputSize: CGFloat = expanded ? 48 : 34
        return VStack(spacing: expanded ? 12 : 6) {
            if expanded {
                HStack {
                    Text("ADD CALORIES")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Theme.faint)
                    Spacer()
                    if hasOperator, let v = evaluated, v > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "equal").font(.system(size: 9, weight: .heavy))
                            Text("\(v) kcal")
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .tracking(1)
                        }
                        .foregroundStyle(Theme.mint)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if hasOperator && expanded {
                    Text(displayExpression)
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.dim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                HStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        if caloriesText.isEmpty {
                            Text(expanded ? "0" : "Add calories")
                                .font(.system(size: inputSize, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.faint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        if hasOperator {
                            Text(evaluated.map(String.init) ?? "—")
                                .font(.system(size: inputSize, weight: .black, design: .rounded))
                                .foregroundStyle(evaluated != nil ? .white : Theme.accent)
                                .contentTransition(.numericText())
                                .onTapGesture { Haptics.tap(); focused = true }
                        }
                        TextField("", text: $caloriesText)
                            .keyboardType(.numberPad)
                            .focused($focused)
                            .font(.system(size: inputSize, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .tint(Theme.accent)
                            .opacity(hasOperator ? 0 : 1)
                    }
                    Spacer(minLength: 0)
                    Button {
                        Haptics.tap()
                        focused = false
                        showMealSheet = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: expanded ? 22 : 18, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: expanded ? 64 : 50, height: expanded ? 64 : 50)
                            .accessibilityIdentifier("mealCameraButton")
                    }
                    .buttonStyle(.plain)
                    .neumorph(expanded ? 20 : 16)
                    AddButton(enabled: (evaluated ?? 0) > 0, compact: !expanded, action: addEntry)
                }
            }

            if expanded {
                mathChips.transition(.opacity)

                Button {
                    Haptics.tick()
                    withAnimation(.spring(response: 0.3)) { showMacros.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Text(showMacros ? "HIDE MACROS" : "ADD MACROS")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .tracking(2)
                        Image(systemName: showMacros ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .heavy))
                    }
                    .foregroundStyle(Theme.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }

                if showMacros {
                    HStack(spacing: 10) {
                        macroField("P", text: $proteinText, tint: .red)
                        macroField("C", text: $carbsText, tint: .yellow)
                        macroField("F", text: $fatText, tint: .blue)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, expanded ? 16 : 10)
        .neumorph(expanded ? 28 : 22)
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: expanded)
        .contentShape(Rectangle())
        .onTapGesture {
            if !expanded { Haptics.tap(); focused = true }
        }
    }

    var summary: some View {
        VStack(spacing: 16) {
            HStack {
                Text("THIS WEEK")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.faint)
                Spacer()
                Text("\(store.daysRemaining)d left")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.dim)
            }

            HStack(alignment: .bottom, spacing: 8) {
                Text("\(store.weeklyTotal)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("/ \(store.weeklyGoal)")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.dim)
                    .padding(.bottom, 10)
                Spacer()
            }

            ProgressBar(value: Double(store.weeklyTotal), max: Double(store.weeklyGoal))
                .frame(height: 12)

            HStack(spacing: 10) {
                stat(label: "LEFT", value: "\(max(0, store.weeklyLeft))", tint: Theme.accent)
                stat(label: "AVG/DAY", value: "\(max(0, store.avgNeededPerDay))", tint: Theme.mint)
            }
        }
        .padding(18)
        .neumorph(28)
    }

    func stat(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Theme.faint)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .softInset(16)
    }

    var weekStrip: some View {
        VStack(spacing: 12) {
            HStack {
                Text("DAYS")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.faint)
                Spacer()
                Text("tap to edit")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.faint)
            }

            VStack(spacing: 10) {
                ForEach(store.days(), id: \.date) { day in
                    NavigationLink(value: day.date) {
                        DayBar(date: day.date, total: day.total,
                               dailyTarget: store.weeklyGoal / 7) { }
                    }
                    .buttonStyle(.plain)
                    .matchedTransitionSource(id: day.date, in: dayNS)
                    .simultaneousGesture(TapGesture().onEnded { Haptics.bump() })
                }
            }
        }
    }

    @ViewBuilder var mealSheet: some View {
        if let img = pickedImage {
            MealAnalysisSheet(
                image: img,
                onSave: { entry in
                    withAnimation(.spring(response: 0.4)) { store.add(entry) }
                    showMealSheet = false
                },
                onCancel: { showMealSheet = false }
            )
        } else {
            VStack(spacing: 18) {
                HStack {
                    Text("MEAL PHOTO")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Theme.faint)
                    Spacer()
                    Button("Close") { showMealSheet = false }
                        .foregroundStyle(Theme.dim)
                        .accessibilityIdentifier("mealSheetClose")
                }
                .padding(.horizontal, 4)

                VStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            Haptics.tap()
                            pickerSource = .camera
                        } label: {
                            sourceRow(icon: "camera.fill", label: "TAKE PHOTO")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("pickerCamera")
                    }
                    Button {
                        Haptics.tap()
                        pickerSource = .photoLibrary
                    } label: {
                        sourceRow(icon: "photo.on.rectangle", label: "PHOTO LIBRARY")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("pickerLibrary")
                }
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg.ignoresSafeArea())
        }
    }

    func sourceRow(icon: String, label: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Theme.faint)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .neumorph(18)
    }

    func addEntry() {
        guard let cals = evaluated, cals > 0 else { Haptics.fail(); return }
        Haptics.snap()
        let e = Entry(date: Date(), calories: cals,
                      protein: Int(proteinText), carbs: Int(carbsText), fat: Int(fatText))
        withAnimation(.spring(response: 0.4)) { store.add(e) }
        caloriesText = ""; proteinText = ""; carbsText = ""; fatText = ""
        focused = false
        Haptics.success()
    }

    var displayExpression: String {
        caloriesText
            .replacingOccurrences(of: "*", with: "×")
            .replacingOccurrences(of: "/", with: " ÷ ")
            .replacingOccurrences(of: "+", with: " + ")
            .replacingOccurrences(of: "-", with: " − ")
    }

    func appendToken(_ s: String) {
        // Prevent two operators in a row
        if let last = caloriesText.last, "+-*/.".contains(last),
           s.count == 1, "+-*/.".contains(s.first!) {
            caloriesText.removeLast()
        }
        caloriesText.append(s)
    }

    func applyFraction(_ divisor: Int) {
        // If current expression evaluates, wrap as (expr)/divisor
        guard evaluated != nil else { Haptics.fail(); return }
        if hasOperator {
            caloriesText = "(\(caloriesText))/\(divisor)"
        } else {
            caloriesText = "\(caloriesText)/\(divisor)"
        }
    }

    var mathChips: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                MathChip(label: "+", tint: Theme.accent) { Haptics.tick(); appendToken("+") }
                MathChip(label: "−", tint: Theme.accent) { Haptics.tick(); appendToken("-") }
                MathChip(label: "×", tint: Theme.accent) { Haptics.tick(); appendToken("*") }
                MathChip(label: "÷", tint: Theme.accent) { Haptics.tick(); appendToken("/") }
                MathChip(icon: "delete.left.fill", tint: Theme.dim) {
                    Haptics.tick()
                    if !caloriesText.isEmpty { caloriesText.removeLast() }
                }
            }
            HStack(spacing: 6) {
                SplitChip(label: "½", divisor: 2) { applyFraction(2); Haptics.bump() }
                SplitChip(label: "⅓", divisor: 3) { applyFraction(3); Haptics.bump() }
                SplitChip(label: "¼", divisor: 4) { applyFraction(4); Haptics.bump() }
                SplitChip(label: "⅔", divisor: 0) {
                    guard evaluated != nil else { Haptics.fail(); return }
                    caloriesText = hasOperator ? "(\(caloriesText))*2/3" : "\(caloriesText)*2/3"
                    Haptics.bump()
                }
                SplitChip(label: "¾", divisor: 0) {
                    guard evaluated != nil else { Haptics.fail(); return }
                    caloriesText = hasOperator ? "(\(caloriesText))*3/4" : "\(caloriesText)*3/4"
                    Haptics.bump()
                }
                Button {
                    Haptics.warn()
                    caloriesText = ""
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Theme.dim)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .softInset(10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MathChip: View {
    var label: String? = nil
    var icon: String? = nil
    let tint: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Group {
                if let label = label {
                    Text(label)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .heavy))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 42)
            .neumorph(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SplitChip: View {
    let label: String
    let divisor: Int
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Theme.mint)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(colors: [Theme.surfaceHi, Theme.surface],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: .black.opacity(0.55), radius: 6, x: 4, y: 4)
                            .shadow(color: .white.opacity(0.04), radius: 5, x: -3, y: -3)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.mint.opacity(0.10))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.mint.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

func macroField(_ label: String, text: Binding<String>, tint: Color) -> some View {
    VStack(spacing: 4) {
        Text(label)
            .font(.system(size: 11, weight: .heavy, design: .monospaced))
            .foregroundStyle(tint.opacity(0.9))
        TextField("0", text: text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .tint(tint)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .softInset(12)
    }
}

struct PickerSourceWrapper: Identifiable {
    let source: CameraPicker.Source
    var id: String { source == .camera ? "camera" : "library" }
}

func evaluateExpression(_ raw: String) -> Int? {
    let trimmed = raw.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return nil }
    // normalize
    var s = trimmed
        .replacingOccurrences(of: "×", with: "*")
        .replacingOccurrences(of: "÷", with: "/")
        .replacingOccurrences(of: "−", with: "-")
    // only allow safe characters
    let allowed = CharacterSet(charactersIn: "0123456789+-*/.() ")
    if s.unicodeScalars.contains(where: { !allowed.contains($0) }) { return nil }
    // trailing operator → strip for preview
    while let last = s.last, "+-*/.(".contains(last) { s.removeLast() }
    if s.isEmpty { return nil }
    // Force floating-point division
    let expr = NSExpression(format: s.replacingOccurrences(of: "/", with: "*1.0/"))
    guard let n = expr.expressionValue(with: nil, context: nil) as? NSNumber else { return nil }
    let d = n.doubleValue
    if !d.isFinite { return nil }
    return Int(d.rounded())
}

// MARK: - Components

struct AddButton: View {
    let enabled: Bool
    var compact: Bool = false
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        let size: CGFloat = compact ? 56 : 84
        let icon: CGFloat = compact ? 24 : 34
        let corner: CGFloat = compact ? 16 : 22
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        enabled
                        ? AnyShapeStyle(LinearGradient(colors: [Theme.accentGlow, Theme.accent],
                                                      startPoint: .topLeading,
                                                      endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .frame(width: size, height: size)
                    .shadow(color: enabled ? Color.black.opacity(pressed ? 0.2 : 0.55) : .clear,
                            radius: pressed ? 4 : 10, x: pressed ? 2 : 7, y: pressed ? 2 : 7)
                    .shadow(color: enabled ? Theme.accent.opacity(pressed ? 0.2 : 0.45) : .clear,
                            radius: pressed ? 4 : 12, x: pressed ? -1 : -4, y: pressed ? -1 : -4)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), .clear],
                                    startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5)
                    )
                Image(systemName: "plus")
                    .font(.system(size: icon, weight: .black))
                    .foregroundStyle(.white)
            }
            .scaleEffect(pressed ? 0.94 : 1.0)
        }
        .disabled(!enabled)
        .buttonStyle(PressStyle(pressed: $pressed))
    }
}

struct PressStyle: ButtonStyle {
    @Binding var pressed: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, new in
                withAnimation(.spring(response: 0.2)) { pressed = new }
            }
    }
}

struct ProgressBar: View {
    let value: Double
    let max: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(colors: [Theme.inset, Theme.surface.opacity(0.85)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.6), lineWidth: 2)
                            .blur(radius: 2)
                            .offset(x: 1, y: 1)
                            .mask(Capsule().fill(LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
                    .clipShape(Capsule())
                Capsule()
                    .fill(LinearGradient(colors: [Theme.accent, Theme.accentGlow],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(min(1, value / Swift.max(1, max))))
                    .shadow(color: Theme.accent.opacity(0.6), radius: 6)
            }
        }
    }
}

struct DayBar: View {
    let date: Date
    let total: Int
    let dailyTarget: Int
    var onTap: () -> Void = {}

    var isToday: Bool { Calendar.current.isDateInToday(date) }
    var isFuture: Bool { date > Date() && !isToday }
    var pct: Double { Swift.min(1.0, Double(total) / Double(Swift.max(1, dailyTarget))) }

    var body: some View {
        HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(weekday)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(isToday ? Theme.accent : Theme.dim)
                    Text(dayNum)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(isFuture ? Theme.faint : .white)
                }
                .frame(width: 56, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.inset).frame(height: 10)
                        Capsule()
                            .fill(isToday
                                  ? LinearGradient(colors: [Theme.accent, Theme.accentGlow], startPoint: .leading, endPoint: .trailing)
                                  : LinearGradient(colors: [Theme.mint.opacity(0.7), Theme.mint], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(pct), height: 10)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 22)

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("\(total)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(total > 0 ? .white : Theme.faint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("/\(dailyTarget)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.dim)
                        .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .neumorph(18)
        .opacity(isFuture ? 0.55 : 1.0)
    }

    var weekday: String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date).uppercased()
    }
    var dayNum: String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }
}

// MARK: - Day editor

struct DayWrap: Identifiable { let date: Date; var id: TimeInterval { date.timeIntervalSince1970 } }

struct DayEditor: View {
    let date: Date
    @ObservedObject var store: Store
    @Environment(\.dismiss) private var dismiss
    var onClose: (() -> Void)? = nil

    @State private var newCals = ""
    @FocusState private var focused: Bool

    private func close() {
        if let onClose = onClose { onClose() } else { dismiss() }
    }

    var items: [Entry] {
        store.entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }
    var total: Int { items.reduce(0) { $0 + $1.calories } }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: 30, y: 12)
            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(headerLabel)
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(Theme.accent)
                        Text(date, format: .dateTime.weekday(.wide).month().day())
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Button { Haptics.tap(); close() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                    }
                    .neumorph(14)
                }

                HStack(alignment: .bottom, spacing: 6) {
                    Text("\(total)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("kcal")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.dim)
                        .padding(.bottom, 10)
                    Spacer()
                }

                HStack(spacing: 12) {
                    TextField("", text: $newCals, prompt: Text("Add calories").foregroundColor(Theme.faint))
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(Theme.accent)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .softInset(16)

                    Button {
                        guard let c = Int(newCals), c > 0 else { Haptics.fail(); return }
                        Haptics.snap()
                        let when = Calendar.current.isDateInToday(date) ? Date() : noonOf(date)
                        store.add(Entry(date: when, calories: c))
                        newCals = ""; focused = false
                        Haptics.success()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .softAccent(16)
                    }
                }

                ScrollView {
                    VStack(spacing: 10) {
                        if items.isEmpty {
                            Text("No entries yet")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.faint)
                                .padding(.top, 40)
                        }
                        ForEach(items) { e in
                            EntryRow(entry: e,
                                     onUpdate: { store.update($0) },
                                     onDelete: { store.remove(e) })
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .preferredColorScheme(.dark)
    }

    var headerLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "TODAY" }
        if cal.isDateInYesterday(date) { return "YESTERDAY" }
        return "EDITING"
    }

    func noonOf(_ d: Date) -> Date {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: d) ?? d
    }
}

struct EntryRow: View {
    @State var entry: Entry
    let onUpdate: (Entry) -> Void
    let onDelete: () -> Void
    @State private var editing = false
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.date, style: .time)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(Theme.faint)
                .frame(width: 60, alignment: .leading)

            if editing {
                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(Theme.accent)
                    .onSubmit(commit)
            } else {
                Text("\(entry.calories)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("kcal")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.faint)
            }

            Spacer()

            if editing {
                Button(action: { Haptics.success(); commit() }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Theme.mint)
                        .frame(width: 36, height: 36)
                        .softInsetCircle()
                }
            } else {
                Button { Haptics.tap(); text = "\(entry.calories)"; editing = true; focused = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Theme.dim)
                        .frame(width: 36, height: 36)
                        .softInsetCircle()
                }
            }
            Button(action: { Haptics.warn(); onDelete() }) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.inset))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .neumorph(16)
    }

    func commit() {
        if let v = Int(text), v > 0 {
            entry.calories = v
            onUpdate(entry)
        }
        editing = false
        focused = false
    }
}

// MARK: - Goal

struct GoalView: View {
    @Binding var goal: Int
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 22) {
                HStack {
                    Text("WEEKLY GOAL")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Button { Haptics.tap(); dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                    }
                    .neumorph(14)
                }

                HStack(alignment: .bottom) {
                    TextField("", text: $text)
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(Theme.accent)
                    Text("kcal/wk")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.dim)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .softInset(20)

                HStack(spacing: 10) {
                    ForEach([10500, 12600, 14000, 15400, 17500], id: \.self) { preset in
                        Button { Haptics.pick(); text = "\(preset)" } label: {
                            Text("\(preset / 1000)k")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .neumorph(12)
                        }
                    }
                }

                Button {
                    if let v = Int(text), v > 0 { goal = v; Haptics.success() } else { Haptics.fail() }
                    dismiss()
                } label: {
                    Text("SAVE")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .softAccent(18)
                }

                Spacer()
            }
            .padding(20)
            .onAppear { text = "\(goal)"; focused = true }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Calendar (Weekly history)

struct CalendarView: View {
    @ObservedObject var store: Store
    @State private var celebrate: Bool = false

    var weeks: [(start: Date, total: Int, goal: Int, success: Bool, isCurrent: Bool)] { store.weeks() }
    var successCount: Int { weeks.filter { $0.success && !$0.isCurrent }.count }
    var streak: Int {
        var n = 0
        for w in weeks where !w.isCurrent {
            if w.success { n += 1 } else { break }
        }
        return n
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WEEK HISTORY")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .tracking(3)
                                .foregroundStyle(Theme.accent)
                            Text("Track your wins")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.top, 6)

                    HStack(spacing: 12) {
                        TrophyCard(icon: "flame.fill", label: "STREAK",
                                   value: "\(streak)", suffix: streak == 1 ? "wk" : "wks",
                                   tint: Theme.accent)
                        TrophyCard(icon: "checkmark.seal.fill", label: "WINS",
                                   value: "\(successCount)", suffix: "total",
                                   tint: Theme.mint)
                    }

                    VStack(spacing: 10) {
                        ForEach(weeks, id: \.start) { w in
                            WeekRow(week: w)
                        }
                    }

                    if weeks.allSatisfy({ $0.isCurrent || $0.total == 0 }) {
                        Text("Log some calories to start tracking weekly wins")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.faint)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 110)
            }
        }
    }
}

struct TrophyCard: View {
    let icon: String
    let label: String
    let value: String
    let suffix: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(tint)
                .shadow(color: tint.opacity(0.6), radius: 8)
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(suffix)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.dim)
                    .padding(.bottom, 8)
            }
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Theme.faint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .neumorph(20)
    }
}

struct WeekRow: View {
    let week: (start: Date, total: Int, goal: Int, success: Bool, isCurrent: Bool)
    @State private var expanded = false

    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: week.start) ?? week.start
    }

    var statusIcon: String {
        if week.isCurrent { return "hourglass" }
        return week.success ? "checkmark.seal.fill" : "xmark.seal.fill"
    }
    var statusTint: Color {
        if week.isCurrent { return Theme.dim }
        return week.success ? Theme.mint : Theme.accent
    }
    var statusLabel: String {
        if week.isCurrent { return "IN PROGRESS" }
        if week.total == 0 { return "NO DATA" }
        return week.success ? "GOAL MET" : "OVER GOAL"
    }
    var diff: Int { week.total - week.goal }

    var body: some View {
        Button {
            Haptics.tick()
            withAnimation(.spring(response: 0.35)) { expanded.toggle() }
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(statusTint.opacity(0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: statusIcon)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(statusTint)
                            .shadow(color: statusTint.opacity(0.5), radius: 6)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(rangeLabel)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(statusLabel)
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .tracking(1.5)
                            .foregroundStyle(statusTint)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(week.total)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/ \(week.goal)")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.faint)
                    }
                }
                ProgressBar(value: Double(week.total), max: Double(week.goal))
                    .frame(height: 8)
                if expanded { WeekCelebration(week: week) }
            }
            .padding(14)
            .neumorph(20)
        }
        .buttonStyle(.plain)
    }

    var rangeLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "\(f.string(from: week.start)) – \(f.string(from: endDate))"
    }
}

struct WeekCelebration: View {
    let week: (start: Date, total: Int, goal: Int, success: Bool, isCurrent: Bool)

    var body: some View {
        VStack(spacing: 10) {
            Divider().background(Color.white.opacity(0.08))
            if week.isCurrent {
                celebrationBlock(icon: "hourglass", tint: Theme.dim,
                                 title: "Week still cooking",
                                 message: "Keep stacking those wins, you got this")
            } else if week.total == 0 {
                celebrationBlock(icon: "tray", tint: Theme.faint,
                                 title: "No data logged",
                                 message: "Quiet week — that's okay")
            } else if week.success {
                let diff = week.goal - week.total
                celebrationBlock(icon: icon(for: diff),
                                 tint: Theme.mint,
                                 title: praise(for: diff),
                                 message: "\(diff) kcal under goal · ~\(format(lbs: Double(diff) / 3500.0)) lbs")
            } else {
                let over = week.total - week.goal
                celebrationBlock(icon: "bolt.fill", tint: Theme.accent,
                                 title: "Tough week",
                                 message: "\(over) over · reset and crush next week")
            }
        }
    }

    func icon(for diff: Int) -> String {
        switch diff {
        case ..<500:  return "checkmark.seal.fill"
        case ..<1500: return "flame.fill"
        case ..<3000: return "star.fill"
        case ..<5000: return "crown.fill"
        default:      return "trophy.fill"
        }
    }
    func praise(for diff: Int) -> String {
        switch diff {
        case ..<500: return "Goal locked in"
        case ..<1500: return "On fire"
        case ..<3000: return "Crushing it"
        case ..<5000: return "Royalty"
        default: return "Legendary"
        }
    }
    func format(lbs: Double) -> String { String(format: "%.2f", lbs) }

    func celebrationBlock(icon: String, tint: Color, title: String, message: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .shadow(color: tint.opacity(0.55), radius: 8)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(tint)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - TDEE

enum Sex: String, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
}

enum Activity: String, CaseIterable, Identifiable {
    case sedentary, light, moderate, active, athlete
    var id: String { rawValue }
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light:     return 1.375
        case .moderate:  return 1.55
        case .active:    return 1.725
        case .athlete:   return 1.9
        }
    }
    var label: String {
        switch self {
        case .sedentary: return "DESK"
        case .light:     return "LIGHT"
        case .moderate:  return "MOD"
        case .active:    return "HIGH"
        case .athlete:   return "BEAST"
        }
    }
    var sub: String {
        switch self {
        case .sedentary: return "little/no exercise"
        case .light:     return "1–3 days/wk"
        case .moderate:  return "3–5 days/wk"
        case .active:    return "6–7 days/wk"
        case .athlete:   return "2x/day, hard"
        }
    }
}

struct TDEEView: View {
    @ObservedObject var store: Store
    @AppStorage("tdee_sex")      private var sexRaw: String = Sex.male.rawValue
    @AppStorage("tdee_age")      private var age: Int = 30
    @AppStorage("tdee_heightCm") private var heightCm: Double = 178
    @AppStorage("tdee_weightLb") private var weightLb: Double = 180
    @AppStorage("tdee_activity") private var actRaw: String = Activity.moderate.rawValue

    var sex: Sex { Sex(rawValue: sexRaw) ?? .male }
    var activity: Activity { Activity(rawValue: actRaw) ?? .moderate }

    var weightKg: Double { weightLb * 0.453592 }
    var bmr: Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        return sex == .male ? base + 5 : base - 161
    }
    var tdee: Int { Int(bmr * activity.multiplier) }
    var weeklyMaintenance: Int { tdee * 7 }
    var weeklyDeficit: Int { weeklyMaintenance - store.weeklyGoal }
    var dailyDeficit: Int { weeklyDeficit / 7 }
    var projectedLbs: Double { Double(weeklyDeficit) / 3500.0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TDEE CALCULATOR")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .tracking(3)
                                .foregroundStyle(Theme.accent)
                            Text("Burn the math")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.top, 6)

                    tdeeBigCard

                    deficitCard

                    SegmentedPicker(
                        title: "SEX",
                        options: Sex.allCases.map { ($0.rawValue, $0.label) },
                        selection: Binding(get: { sexRaw }, set: { sexRaw = $0; Haptics.pick() })
                    )

                    StepperRow(label: "AGE", value: $age, range: 13...100, step: 1, suffix: "yrs",
                               format: { "\($0)" })
                    DoubleStepperRow(label: "HEIGHT", value: $heightCm, range: 120...230, step: 1,
                                     suffix: "cm",
                                     format: { String(format: "%.0f", $0) })
                    DoubleStepperRow(label: "WEIGHT", value: $weightLb, range: 70...500, step: 1,
                                     suffix: "lbs",
                                     format: { String(format: "%.0f", $0) })

                    activityPicker
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 180)
            }

            Color.clear
                .frame(height: 20)
                .padding(.bottom, 120)
                .background(
                    LinearGradient(stops: [
                        .init(color: Theme.bg.opacity(0), location: 0.0),
                        .init(color: Theme.bg, location: 0.15),
                        .init(color: Theme.bg, location: 1.0)
                    ], startPoint: .top, endPoint: .bottom)
                        .allowsHitTesting(false)
                        .ignoresSafeArea(edges: .bottom)
                )
                .allowsHitTesting(false)
        }
    }

    var tdeeBigCard: some View {
        VStack(spacing: 10) {
            Text("YOUR TDEE")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Theme.faint)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(tdee)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("kcal/day")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.dim)
                    .padding(.bottom, 12)
                Spacer()
            }
            HStack(spacing: 10) {
                miniStat("BMR", "\(Int(bmr))", Theme.mint)
                miniStat("WEEKLY", "\(weeklyMaintenance)", Theme.accent)
            }
        }
        .padding(18)
        .neumorph(28)
    }

    func miniStat(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Theme.faint)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .softInset(14)
    }

    var activityPicker: some View {
        VStack(spacing: 10) {
            HStack {
                Text("ACTIVITY")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.faint)
                Spacer()
                Text(activity.sub)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.dim)
            }
            HStack(spacing: 6) {
                ForEach(Activity.allCases) { a in
                    Button {
                        Haptics.pick()
                        actRaw = a.rawValue
                    } label: {
                        Group {
                            if actRaw == a.rawValue {
                                Text(a.label)
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .tracking(1)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .softAccent(12)
                            } else {
                                Text(a.label)
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .tracking(1)
                                    .foregroundStyle(Theme.dim)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .softInset(12)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .neumorph(22)
    }

    var deficitCard: some View {
        let positive = weeklyDeficit > 0
        let tint: Color = positive ? Theme.mint : Theme.accent
        return VStack(spacing: 14) {
            HStack {
                Text("WEEKLY DEFICIT")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.faint)
                Spacer()
                Image(systemName: positive ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(tint)
            }
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(abs(weeklyDeficit))")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                Text(positive ? "under maintenance" : "over maintenance")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.dim)
                    .padding(.bottom, 10)
                Spacer()
            }
            HStack(spacing: 10) {
                miniStat("DAILY", "\(abs(dailyDeficit))", tint)
                miniStat("GOAL/WK", "\(store.weeklyGoal)", Theme.dim)
            }
            projectionStrip(positive: positive, tint: tint)
        }
        .padding(18)
        .neumorph(28)
    }

    func projectionStrip(positive: Bool, tint: Color) -> some View {
        let weeks = 4
        let projection4 = abs(projectedLbs) * Double(weeks)
        return HStack(spacing: 14) {
            Image(systemName: positive ? "chart.line.downtrend.xyaxis" : "chart.line.uptrend.xyaxis")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .shadow(color: tint.opacity(0.55), radius: 8)
            VStack(alignment: .leading, spacing: 3) {
                Text(positive ? "PROJECTED LOSS" : "PROJECTED GAIN")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(tint)
                Text(String(format: "%.2f lbs this week", abs(projectedLbs)))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(String(format: "%.1f lbs in %d weeks", projection4, weeks))
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.dim)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

struct SegmentedPicker: View {
    let title: String
    let options: [(value: String, label: String)]
    @Binding var selection: String

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.faint)
                Spacer()
            }
            HStack(spacing: 6) {
                ForEach(options, id: \.value) { opt in
                    Button { selection = opt.value } label: {
                        Group {
                            if selection == opt.value {
                                Text(opt.label)
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .softAccent(12)
                            } else {
                                Text(opt.label)
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(Theme.dim)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .softInset(12)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .neumorph(22)
    }
}

struct StepperRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let suffix: String
    let format: (Int) -> String

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.faint)
                HStack(alignment: .bottom, spacing: 4) {
                    Text(format(value))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text(suffix)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.dim)
                        .padding(.bottom, 4)
                }
            }
            Spacer()
            StepButton(icon: "minus") {
                if value - step >= range.lowerBound {
                    withAnimation(.spring(response: 0.2)) { value -= step }
                    Haptics.tap()
                } else { Haptics.fail() }
            }
            StepButton(icon: "plus") {
                if value + step <= range.upperBound {
                    withAnimation(.spring(response: 0.2)) { value += step }
                    Haptics.tap()
                } else { Haptics.fail() }
            }
        }
        .padding(16)
        .neumorph(22)
    }
}

struct DoubleStepperRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let suffix: String
    let format: (Double) -> String

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.faint)
                HStack(alignment: .bottom, spacing: 4) {
                    Text(format(value))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text(suffix)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.dim)
                        .padding(.bottom, 4)
                }
            }
            Spacer()
            StepButton(icon: "minus") {
                if value - step >= range.lowerBound {
                    withAnimation(.spring(response: 0.2)) { value -= step }
                    Haptics.tap()
                } else { Haptics.fail() }
            }
            StepButton(icon: "plus") {
                if value + step <= range.upperBound {
                    withAnimation(.spring(response: 0.2)) { value += step }
                    Haptics.tap()
                } else { Haptics.fail() }
            }
        }
        .padding(16)
        .neumorph(22)
    }
}

struct StepButton: View {
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .neumorph(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview { ContentView() }
