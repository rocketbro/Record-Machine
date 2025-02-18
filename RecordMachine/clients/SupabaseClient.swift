import Foundation
import Supabase

enum Supabase {
    static let client = SupabaseClient(
        supabaseURL: URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"]!)!,
        supabaseKey: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]!
    )
}
