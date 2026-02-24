//
//  UserRepository.swift
//  UzmanaGel
//
//  Created by Abdullah B on 5.02.2026.
//

import Foundation
import FirebaseFirestore


final class UserRepository {

    private let db = Firestore.firestore()

    // MARK: - Mükerrer Kontrol

    func isEmailTaken(_ email: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email.lowercased())
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    func isPhoneTaken(_ phone: String) async throws -> Bool {
        let normalized = phone.filter(\.isNumber)
        guard !normalized.isEmpty else { return false }

        let snapshot = try await db.collection("users")
            .whereField("phoneNumber", isEqualTo: normalized)
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    // MARK: - Kullanıcı Oluştur

    func createUserDocument(
        uid: String,
        displayName: String,
        email: String,
        phoneNumber: String?
    ) async throws {

        let data: [String: Any] = [
            "displayName": displayName,
            "email": email.lowercased(),
            "phoneNumber": phoneNumber?.filter(\.isNumber) ?? "",
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    // MARK: - Kullanıcı Getir

    func fetchUser(uid: String) async throws -> AppUser {
        let snap = try await db.collection("users").document(uid).getDocument()
        return try snap.data(as: AppUser.self)
    }
}
