//
//  CompleteProfileView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 23.02.2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CompleteProfileView: View {

    @EnvironmentObject var session: SessionViewModel

    @State private var fullName = ""
    @State private var email = ""

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let userRepo = UserRepository()

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer().frame(height: 40)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 56))
                    .foregroundColor(Color("PrimaryColor"))

                VStack(spacing: 6) {
                    Text("Profilini Tamamla")
                        .font(.system(size: 24, weight: .bold))

                    Text("Devam etmek için ad soyad ve e-posta bilgilerini gir.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "person")
                            .foregroundColor(.secondary)
                            .frame(width: 22)

                        TextField("Ad Soyad", text: $fullName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .cornerRadius(14)

                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)
                            .frame(width: 22)

                        TextField("E-posta", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .cornerRadius(14)
                }

                if let phone = Auth.auth().currentUser?.phoneNumber, !phone.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text("Telefon: \(phone)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    Task { await saveProfile() }
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView().tint(.white)
                        }
                        Text("KAYDET VE DEVAM ET")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color("PrimaryColor"))
                    .cornerRadius(14)
                    .shadow(radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(!isValid || isLoading)
                .opacity(isValid && !isLoading ? 1 : 0.6)
                .padding(.top, 6)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var isValid: Bool {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.count >= 2 && mail.contains("@") && mail.contains(".")
    }

    private func saveProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Oturum bilgisi bulunamadı."
            showError = true
            return
        }

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let phone = Auth.auth().currentUser?.phoneNumber?.replacingOccurrences(of: "+90", with: "") ?? ""

        isLoading = true
        defer { isLoading = false }

        do {
            let emailTaken = try await userRepo.isEmailTaken(trimmedEmail)
            if emailTaken {
                errorMessage = "Bu e-posta adresi zaten başka bir hesapta kullanılıyor."
                showError = true
                return
            }
        } catch {
            errorMessage = "E-posta kontrolü yapılırken bir hata oluştu. Lütfen tekrar deneyin."
            showError = true
            return
        }

        do {
            try await userRepo.createUserDocument(
                uid: uid,
                displayName: trimmedName,
                email: trimmedEmail,
                phoneNumber: phone
            )

            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = trimmedName
            try await changeRequest?.commitChanges()

            session.profileCompleted()
        } catch {
            errorMessage = "Profil kaydedilirken bir hata oluştu: \(error.localizedDescription)"
            showError = true
        }
    }
}
