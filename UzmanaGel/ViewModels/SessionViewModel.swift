//
//  SessionViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class SessionViewModel: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var userId: String? = nil

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        startListening()
    }

    func startListening() {
        // Firebase kullanıcı durumu değişince burası çalışır
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.isAuthenticated = (user != nil)
                self.userId = user?.uid
            }
        }
    }

    func stopListening() {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
            self.handle = nil
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("SignOut error:", error.localizedDescription)
        }
    }
}
