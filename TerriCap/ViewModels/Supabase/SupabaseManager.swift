//
//  SupabaseManager.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/18.
//

import Foundation
import Supabase
import Combine

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Supabase URLとAnon Keyで置き換え
        let url = URL(string: "https://qjgowwlebvnfudoxzxll.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqZ293d2xlYnZuZnVkb3h6eGxsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NTMxNDUsImV4cCI6MjA4NDMyOTE0NX0.WRQo6Z3o0XBrveJpEXd1zLb3-8a0zMjOH-gOWPSI8a8"
        client = SupabaseClient(
                    supabaseURL: url,
                    supabaseKey: key,
                    options: SupabaseClientOptions(
                        auth: .init(
                            redirectToURL: URL(string: "com.runa00.TerriCap://login-callback")!
                        )
                    )
                )
    }
}
