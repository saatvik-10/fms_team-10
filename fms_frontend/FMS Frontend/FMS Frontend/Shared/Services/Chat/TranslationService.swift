import Foundation
import FoundationModels
import Combine

class TranslationService: ObservableObject {
    static let shared = TranslationService()
    
    // We instantiate the LanguageModelSession from FoundationModels
    private var session: LanguageModelSession?
    
    init() {
        self.session = LanguageModelSession()
    }
    
    /// Translates a given text to the specified target language using the on-device language model.
    func translate(_ text: String, to targetLanguage: String) async throws -> String {
        guard let session = session else {
            return text
        }
        
        let prompt = "Translate the following text to \(targetLanguage). Return only the translated text, nothing else:\n\(text)"
        
        // Use FoundationModels respond(to:) to get the translation
        let response = try await session.respond(to: prompt)
        return response.content // Extract the string value from the Response wrapper
    }
}
