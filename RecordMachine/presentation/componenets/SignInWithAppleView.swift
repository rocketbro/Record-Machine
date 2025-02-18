import SwiftUI
import AuthenticationServices
import Supabase

struct SignInWithAppleView: View {
    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(let authResults):
                    // Get authorization credentials
                    let credential = authResults.credential as? ASAuthorizationAppleIDCredential
                    
                    // Get user's full name
                    let fullName = [
                        credential?.fullName?.givenName,
                        credential?.fullName?.familyName
                    ].compactMap { $0 }.joined(separator: " ")
                    
                    // Use credential.identityToken to sign in with Supabase
                    if let identityToken = credential?.identityToken,
                       let token = String(data: identityToken, encoding: .utf8) {
                        Task {
                            do {
                                // Sign in with Apple
                                let authResponse = try await Supabase.client.auth.signInWithIdToken(
                                    credentials: .init(
                                        provider: .apple,
                                        idToken: token
                                    )
                                )
                                
                                print("User ID: \(authResponse.user.id)")
                                
                                // Update the user's metadata if we have a name
                                if !fullName.isEmpty {
                                    try await Supabase.client.auth.update(
                                        user: UserAttributes(
                                            data: [
                                                "display_name": .string(fullName)
                                            ]
                                        )
                                    )
                                }
                            } catch {
                                print("Error signing in or updating user: \(error)")
                                if let httpError = error as? HTTPError {
                                    print("Response URL: \(httpError.response.url?.absoluteString ?? "No URL")")
                                    print("Status Code: \(httpError.response.statusCode)")
                                }
                            }
                        }
                    }
                case .failure(let error):
                    print("Sign in failed: \(error)")
                }
            }
        )
        .frame(height: 44)
    }
}
