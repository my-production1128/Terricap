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
        let url = URL(string: "https://ragxleihrerbkpmcehdv.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJhZ3hsZWlocmVyYmtwbWNlaGR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1ODk0MTMsImV4cCI6MjA3OTE2NTQxM30.ULXZ_ExxeSyr64UTQqYREH0WBnhlBb6yikaWX5WWV2k"
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
