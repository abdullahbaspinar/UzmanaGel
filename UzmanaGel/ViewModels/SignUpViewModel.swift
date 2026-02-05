//
//  SignUpViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class SignUpViewModel: ObservableObject {

    // View’den gelen inputlar
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var kvkkAccepted: Bool = false

    // View’in izleyeceği durumlar
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var didSignUp: Bool = false

    func signUp() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1) Basit validasyon (boş mu?)
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !trimmedPhone.isEmpty else {
            errorMessage = "Ad Soyad, E-posta ve Telefon boş olamaz."
            return
        }

        // 2) KVKK onayı
        guard kvkkAccepted else {
            errorMessage = "Devam etmek için KVKK onayını vermelisin."
            return
        }

        // 3) Şifre kontrol
        guard !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Şifre alanları boş olamaz."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Şifreler eşleşmiyor."
            return
        }

        // İstersen minimum şifre kuralı
        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalı."
            return
        }

        // 4) Firebase createUser
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: trimmedEmail, password: password) { [weak self] result, error in
            guard let self = self else { return }

            self.isLoading = false

            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            // ✅ Kullanıcı oluşturuldu (Firebase otomatik login yapar)
            // Display name set etmek istersen:
            if let user = result?.user {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = trimmedName
                changeRequest.commitChanges { _ in }
            }

            self.didSignUp = true
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
