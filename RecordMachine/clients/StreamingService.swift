import Foundation
import Supabase

@Observable
final class StreamingService: Sendable {
    private let supabase = Supabase.client
    
    func getSignedUrl(for track: StreamTrack) async throws -> URL {
        let response: SignedUrlResponse = try await supabase.functions.invoke(
            "generate-signed-url",
            options: FunctionInvokeOptions(
                body: [
                    "objectPath": track.objectPath,
                    "expiresIn": String(3600) // Convert number to string for SDK compatibility
                ]
            )
        )
        
        guard let url = URL(string: response.signedUrl) else {
            throw URLError(.badURL)
        }
        
        return url
    }
}

// Response type from our Edge Function
private struct SignedUrlResponse: Decodable {
    let signedUrl: String
} 
