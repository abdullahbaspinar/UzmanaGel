//
//  OTPView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import SwiftUI

struct OTPView: View {

    @ObservedObject var vm: PhoneAuthViewModel
    @State private var showError = false

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            VStack(spacing: 18) {
                Text("SMS Kodunu Gir")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 10)

                HStack(spacing: 10) {
                    Image(systemName: "number")
                        .foregroundColor(.secondary)

                    TextField("123456", text: $vm.smsCode)
                        .keyboardType(.numberPad)
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

                Button {
                    vm.verifyCode()
                } label: {
                    Text("DOĞRULA")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(.systemYellow))
                        .cornerRadius(14)
                        .shadow(radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.top, 10)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)

            if vm.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
        .onChange(of: vm.errorMessage) { _, msg in
            showError = (msg != nil)
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { vm.clearError() }
        } message: {
            Text(vm.errorMessage ?? "Bilinmeyen hata")
        }
    }
}
