import SwiftUI
import AuthenticationServices

struct SignInView: View {
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
                    // Use credential.identityToken to sign in with Supabase
                    if let identityToken = credential?.identityToken,
                       let token = String(data: identityToken, encoding: .utf8) {
                        Task {
                            try await Supabase.client.auth.signInWithIdToken(
                                credentials: .init(
                                    provider: .apple,
                                    idToken: token
                                )
                            )
                        }
                    }
                case .failure(let error):
                    print(error)
                }
            }
        )
        .frame(height: 44)
    }
}
