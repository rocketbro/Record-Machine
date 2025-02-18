import Foundation
import Supabase

@Observable
@MainActor
final class AuthManager {
    private(set) var currentUser: User?
    private(set) var session: Session?
    private(set) var isAuthenticated = false
    
    init() {
        setupAuth()
    }
    
    private func setupAuth() {
        // Try to restore existing session
        Task {
            do {
                let session = try await Supabase.client.auth.session
                self.session = session
                self.currentUser = session.user
                self.isAuthenticated = true
            } catch {
                print("No existing session found")
            }
        }
        
        // Listen for auth state changes
        Task {
            let authStateChanges = Supabase.client.auth.authStateChanges
            for await (event, session) in authStateChanges {
                switch event {
                case .initialSession:
                    self.session = session
                    self.currentUser = session?.user
                    self.isAuthenticated = session != nil
                    print("Initial session: \(session?.user.id.uuidString ?? "none")")
                    
                case .signedIn:
                    self.session = session
                    self.currentUser = session?.user
                    self.isAuthenticated = true
                    print("Signed in: \(session?.user.id.uuidString ?? "unknown")")
                    
                case .signedOut:
                    self.session = nil
                    self.currentUser = nil
                    self.isAuthenticated = false
                    print("Signed out")
                    
                case .tokenRefreshed:
                    self.session = session
                    self.currentUser = session?.user
                    print("Token refreshed")
                    
                case .userUpdated:
                    self.session = session
                    self.currentUser = session?.user
                    print("User updated")
                    
                case .passwordRecovery:
                    print("Password recovery")
                    
                case .userDeleted:
                    self.session = nil
                    self.currentUser = nil
                    self.isAuthenticated = false
                    print("User account deleted")
                    
                case .mfaChallengeVerified:
                    self.session = session
                    self.currentUser = session?.user
                    self.isAuthenticated = true
                    print("MFA challenge verified for user: \(session?.user.id.uuidString ?? "unknown")")
                }
            }
        }
    }
    
    func signOut() async throws {
        try await Supabase.client.auth.signOut()
    }
} 
