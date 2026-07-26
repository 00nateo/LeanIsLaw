import Foundation
import UIKit
import CoreImage
import MLX
import MLXLMCommon
import MLXVLM
import MLXHuggingFace
import HuggingFace
import Tokenizers

// Picked from VLMRegistry (known-good repo ids).
// Alternatives: .qwen3VL4BInstruct4Bit (~2.5 GB, newer), .qwen2VL2BInstruct4Bit (~1.2 GB, weakest),
// .gemma3_4B_qat_4bit (~2.5 GB, strong vision).
private let kMealModelConfig: ModelConfiguration = VLMRegistry.qwen2VL2BInstruct4Bit

nonisolated struct MealAnalysis: Codable, Equatable, Sendable {
    var name: String
    var calories: Int
    var protein: Int?
    var carbs: Int?
    var fat: Int?
    var confidence: Double
}

nonisolated enum MealAnalyzerError: LocalizedError {
    case imageConversionFailed
    case emptyResponse
    case jsonNotFound(raw: String)
    case decodingFailed(raw: String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "Couldn't convert the photo for analysis."
        case .emptyResponse: return "The model returned no text."
        case .jsonNotFound(let raw): return "No JSON in model output: \(raw.prefix(120))…"
        case .decodingFailed(_, let err): return "Couldn't parse meal JSON: \(err.localizedDescription)"
        }
    }
}

nonisolated enum MealAnalyzerStage: Equatable, Sendable {
    case idle
    case downloading(fraction: Double)
    case loadingWeights
    case generating
}

actor MealAnalyzer {
    static let shared = MealAnalyzer()

    private var container: ModelContainer?
    private var loadTask: Task<ModelContainer, Error>?
    private(set) var stage: MealAnalyzerStage = .idle

    private let prompt = """
    Look at this meal photo and estimate its nutrition. Reply with ONLY a single \
    JSON object — no prose, no markdown fences. Schema:
    {"name": string, "calories": integer, "protein": integer, "carbs": integer, \
    "fat": integer, "confidence": number between 0 and 1}
    Macros are grams. If you cannot identify food, set confidence to 0.
    """

    func analyze(
        _ image: UIImage,
        onStage: @Sendable @escaping (MealAnalyzerStage) -> Void = { _ in }
    ) async throws -> MealAnalysis {
        let ciImage = try ciImage(from: image)
        let container = try await loadContainer(onStage: onStage)

        await MainActor.run { onStage(.generating) }
        stage = .generating

        let userPrompt = prompt
        let raw: String = try await container.perform { context in
            let input = UserInput(chat: [
                .user(userPrompt, images: [.ciImage(ciImage)])
            ])
            let lmInput = try await context.processor.prepare(input: input)
            let stream = try MLXLMCommon.generate(
                input: lmInput,
                parameters: GenerateParameters(temperature: 0.1),
                context: context
            )
            var collected = ""
            for await event in stream {
                if case .chunk(let s) = event { collected += s }
            }
            return collected
        }

        stage = .idle
        await MainActor.run { onStage(.idle) }

        return try parse(raw)
    }

    private func loadContainer(
        onStage: @Sendable @escaping (MealAnalyzerStage) -> Void
    ) async throws -> ModelContainer {
        if let container { return container }
        if let task = loadTask { return try await task.value }

        let task = Task { () throws -> ModelContainer in
            let c: ModelContainer = try await #huggingFaceLoadModelContainer(
                configuration: kMealModelConfig,
                progressHandler: { progress in
                    let fraction = progress.totalUnitCount > 0
                        ? Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                        : 0
                    Task { @MainActor in onStage(.downloading(fraction: fraction)) }
                }
            )
            await MainActor.run { onStage(.loadingWeights) }
            return c
        }
        loadTask = task
        do {
            let c = try await task.value
            container = c
            loadTask = nil
            return c
        } catch {
            loadTask = nil
            throw error
        }
    }

    private func ciImage(from image: UIImage) throws -> CIImage {
        if let ci = image.ciImage { return ci }
        if let cg = image.cgImage { return CIImage(cgImage: cg) }
        if let data = image.jpegData(compressionQuality: 0.9),
           let ci = CIImage(data: data) { return ci }
        throw MealAnalyzerError.imageConversionFailed
    }

    private func parse(_ raw: String) throws -> MealAnalysis {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw MealAnalyzerError.emptyResponse }
        guard let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}"),
              start <= end else {
            throw MealAnalyzerError.jsonNotFound(raw: trimmed)
        }
        let jsonSlice = String(trimmed[start...end])
        guard let data = jsonSlice.data(using: .utf8) else {
            throw MealAnalyzerError.jsonNotFound(raw: jsonSlice)
        }
        do {
            return try JSONDecoder().decode(MealAnalysis.self, from: data)
        } catch {
            throw MealAnalyzerError.decodingFailed(raw: jsonSlice, underlying: error)
        }
    }
}
