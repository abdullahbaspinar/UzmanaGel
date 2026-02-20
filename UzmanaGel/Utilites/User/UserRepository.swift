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

    // 🔹 KULLANICI OLUŞTUR
    func createUserDocument(
        uid: String,
        displayName: String,
        email: String,
        phoneNumber: String?
    ) async throws {

        let data: [String: Any] = [
            "displayName": displayName,
            "email": email,
            "phoneNumber": phoneNumber ?? "",
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    // KULLANICI GETİR
    func fetchUser(uid: String) async throws -> AppUser {
        let snap = try await db.collection("users").document(uid).getDocument()
        return try snap.data(as: AppUser.self)
    }
}
