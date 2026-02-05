//
//  PhoneAuthViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class PhoneAuthViewModel: ObservableObject {

    // View inputları
    @Published var phone10: String = ""   // kullanıcı 10 hane girecek: 5xxxxxxxxx
    @Published var smsCode: String = ""   // 6 haneli kod

    // Durumlar
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var didLogin: Bool = false

    // Akış kontrolü (ekran geçişi)
    @Published var didSendCode: Bool = false

    // Firebase’in bize verdiği id (gizli)
    private var verificationID: String?

    // ✅ 10 hane -> +90 ekleyip formatla
    private func formattedPhoneE164() -> String? {
        // sadece rakam kalsın
        let digits = phone10.filter { $0.isNumber }

        // 10 hane olmalı ve 5 ile başlamalı
        guard digits.count == 10, digits.first == "5" else { return nil }

        return "+90" + digits
    }

    func sendCode() {
        guard let e164 = formattedPhoneE164() else {
            errorMessage = "Telefon 10 hane olmalı ve 5 ile başlamalı. Örn: 5xxxxxxxxx"
            return
        }

        isLoading = true
        errorMessage = nil

        PhoneAuthProvider.provider().verifyPhoneNumber(e164, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.verificationID = verificationID
                self.didSendCode = true
            }
        }
    }

    func verifyCode() {
        let codeDigits = smsCode.filter { $0.isNumber }

        guard codeDigits.count == 6 else {
            errorMessage = "SMS kodu 6 haneli olmalı."
            return
        }

        guard let verificationID = verificationID else {
            errorMessage = "Önce kod istemelisin."
            return
        }

        isLoading = true
        errorMessage = nil

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: codeDigits)

        Auth.auth().signIn(with: credential) { [weak self] _, error in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.didLogin = true
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
