//
//  UserRepository.swift
//  UzmanaGel
//
//  Created by Abdullah B on 5.02.2026.
//

import Foundation
import FirebaseFirestore

/// Firestore bağlantısı: GoogleService-Info.plist içindeki Firebase projesi kullanılır.
/// Database location (eur3 vb.) proje oluşturulurken Console'da seçilir; istemci aynı projeye bağlanır.
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

    // MARK: - Uzman İşlemleri

    func createExpertUserDocument(
        uid: String,
        displayName: String,
        email: String,
        phoneNumber: String
    ) async throws {

        let data: [String: Any] = [
            "displayName": displayName,
            "email": email.lowercased(),
            "phoneNumber": phoneNumber.filter(\.isNumber),
            "role": "expert",
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    func createExpertProfile(uid: String, profile: [String: Any]) async throws {
        var data = profile
        data["createdAt"] = Timestamp(date: Date())
        data["status"] = "Pending"

        try await db.collection("expert_profiles").document(uid).setData(data, merge: true)
    }

    /// Kayıtlı uzman profilini Firestore (expert_profiles) koleksiyonundan getirir.
    func fetchExpertProfile(uid: String) async throws -> ExpertProfile? {
        let snap = try await db.collection("expert_profiles").document(uid).getDocument()
        guard snap.exists else { return nil }
        return try snap.data(as: ExpertProfile.self)
    }

    /// Uzman profilinde belirtilen alanları günceller (merge). Banka bilgileri vb. güvenle saklanır.
    func updateExpertProfile(uid: String, fields: [String: Any]) async throws {
        try await db.collection("expert_profiles").document(uid).setData(fields, merge: true)
    }

    func fetchUserRole(uid: String) async throws -> String? {
        let snap = try await db.collection("users").document(uid).getDocument()
        return snap.data()?["role"] as? String
    }
}
