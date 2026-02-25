//
//  SessionViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SessionViewModel: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var userId: String? = nil
    @Published var needsProfileSetup: Bool = false
    @Published var isCheckingProfile: Bool = false
    @Published var userRole: String = "user"

    var isExpert: Bool { userRole == "expert" }

    private var handle: AuthStateDidChangeListenerHandle?
    private let userRepo = UserRepository()

    init() {
        startListening()
    }

    func startListening() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    self.isAuthenticated = true
                    self.userId = user.uid
                    await self.checkProfileCompletion(uid: user.uid)
                } else {
                    self.isAuthenticated = false
                    self.userId = nil
                    self.needsProfileSetup = false
                    self.userRole = "user"
                }
            }
        }
    }

    private func checkProfileCompletion(uid: String) async {
        isCheckingProfile = true
        defer { isCheckingProfile = false }

        do {
            let user = try await userRepo.fetchUser(uid: uid)
            let name = user.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            needsProfileSetup = name.isEmpty || name == "Telefon Kullanıcısı"
            userRole = user.role ?? "user"
        } catch {
            needsProfileSetup = true
            userRole = "user"
        }
    }

    func profileCompleted() {
        needsProfileSetup = false
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
