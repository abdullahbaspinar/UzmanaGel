//
//  ResetPasswordPage.swift
//  UzmanaGel
//
//  Created by Abdullah B on 03.02.2026.
//

import SwiftUI

struct ResetPasswordPage: View {

    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var showNew = false
    @State private var showConfirm = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer().frame(height: 28)

                VStack(spacing: 6) {
                    Text("Yeni Şifre")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Yeni şifreni belirle ve tekrar gir.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // New Password
                HStack(spacing: 10) {
                    Image(systemName: "lock")
                        .foregroundColor(.secondary)

                    Group {
                        if showNew {
                            TextField("Yeni şifre", text: $newPassword)
                        } else {
                            SecureField("Yeni şifre", text: $newPassword)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button {
                        showNew.toggle()
                    } label: {
                        Image(systemName: showNew ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .cornerRadius(14)

                // Confirm Password
                HStack(spacing: 10) {
                    Image(systemName: "lock")
                        .foregroundColor(.secondary)

                    Group {
                        if showConfirm {
                            TextField("Yeni şifre tekrar", text: $confirmPassword)
                        } else {
                            SecureField("Yeni şifre tekrar", text: $confirmPassword)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button {
                        showConfirm.toggle()
                    } label: {
                        Image(systemName: showConfirm ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .cornerRadius(14)

                // Update Button
                Button {
                    print("Şifre güncellenecek (Firebase sonra)")
                    dismiss()
                } label: {
                    Text("ŞİFREYİ GÜNCELLE")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(.systemYellow))
                        .cornerRadius(14)
                        .shadow(radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.6)
                .padding(.top, 6)

                if !confirmPassword.isEmpty && newPassword != confirmPassword {
                    Text("Şifreler eşleşmiyor.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
    }

    private var isValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }
}
