import SwiftUI
import UIKit

struct MealAnalysisSheet: View {
    let image: UIImage
    let onSave: (Entry) -> Void
    let onCancel: () -> Void

    @State private var stage: MealAnalyzerStage = .idle
    @State private var result: MealAnalysis? = nil
    @State private var errorText: String? = nil

    @State private var name: String = ""
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var carbsText: String = ""
    @State private var fatText: String = ""

    private var evaluatedCalories: Int? { evaluateExpression(caloriesText) }
    private var canSave: Bool { (evaluatedCalories ?? 0) > 0 }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    thumbnail
                    if result == nil && errorText == nil {
                        progressView
                    }
                    if let err = errorText {
                        errorBanner(err)
                    }
                    if result != nil || errorText != nil {
                        editor
                    }
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .task { await runAnalysis() }
    }

    var header: some View {
        HStack {
            Text("MEAL PHOTO")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Theme.faint)
            Spacer()
            Button("Cancel") { onCancel() }
                .foregroundStyle(Theme.dim)
                .accessibilityIdentifier("mealSheetCancel")
        }
    }

    var thumbnail: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 220)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityIdentifier("mealThumbnail")
    }

    @ViewBuilder var progressView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(.white)
            Text(stageLabel)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Theme.dim)
                .accessibilityIdentifier("mealSheetStage")
            if case .downloading(let fraction) = stage {
                ProgressView(value: fraction)
                    .progressViewStyle(.linear)
                    .tint(Theme.accent)
                    .frame(maxWidth: 220)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .neumorph(20)
    }

    var stageLabel: String {
        switch stage {
        case .idle: return "PREPARING…"
        case .downloading(let f): return "DOWNLOADING MODEL  \(Int(f * 100))%"
        case .loadingWeights: return "LOADING WEIGHTS…"
        case .generating: return "ANALYZING PHOTO…"
        }
    }

    func errorBanner(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ANALYSIS FAILED")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Theme.accent)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Button {
                Haptics.tap()
                errorText = nil
                Task { await runAnalysis() }
            } label: {
                Text("RETRY")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .neumorph(10)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neumorph(16)
    }

    var editor: some View {
        VStack(spacing: 14) {
            if let r = result, r.confidence < 0.6 {
                lowConfidenceBanner(confidence: r.confidence)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("MEAL")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Theme.faint)
                TextField("Name", text: $name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(Theme.accent)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .softInset(12)
                    .accessibilityIdentifier("mealNameField")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("CALORIES")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(Theme.faint)
                    Spacer()
                    if let v = evaluatedCalories, caloriesText.contains(where: { "+-*/×÷−".contains($0) }) {
                        Text("= \(v)")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.mint)
                    }
                }
                TextField("0", text: $caloriesText)
                    .keyboardType(.numbersAndPunctuation)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(Theme.accent)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .softInset(14)
                    .accessibilityIdentifier("mealCaloriesField")
            }

            HStack(spacing: 10) {
                macroField("P", text: $proteinText, tint: .red)
                macroField("C", text: $carbsText, tint: .yellow)
                macroField("F", text: $fatText, tint: .blue)
            }

            Button {
                guard let cals = evaluatedCalories, cals > 0 else { Haptics.fail(); return }
                Haptics.success()
                let e = Entry(
                    date: Date(),
                    calories: cals,
                    protein: Int(proteinText),
                    carbs: Int(carbsText),
                    fat: Int(fatText)
                )
                onSave(e)
            } label: {
                Text("SAVE")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(canSave ? .white : Theme.faint)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.plain)
            .neumorph(16)
            .disabled(!canSave)
            .accessibilityIdentifier("mealSaveButton")
        }
    }

    func lowConfidenceBanner(confidence: Double) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.accent)
            Text("Low confidence (\(Int(confidence * 100))%). Double-check the numbers.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(12)
        .neumorph(12)
        .accessibilityIdentifier("mealLowConfidence")
    }

    func runAnalysis() async {
        errorText = nil
        result = nil
        stage = .idle
        do {
            let analysis = try await MealAnalyzer.shared.analyze(image) { s in
                stage = s
            }
            result = analysis
            name = analysis.name
            caloriesText = String(analysis.calories)
            proteinText = analysis.protein.map(String.init) ?? ""
            carbsText = analysis.carbs.map(String.init) ?? ""
            fatText = analysis.fat.map(String.init) ?? ""
        } catch {
            print("[MealAnalyzer] failed: \(error)")
            let desc = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            errorText = "\(desc)\n\n\(String(describing: error))"
        }
    }
}
