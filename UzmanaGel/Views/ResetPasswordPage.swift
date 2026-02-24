//
//  ResetPasswordPage.swift
//  UzmanaGel
//
//  Created by Abdullah B on 03.02.2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ResetPasswordPage: View {

    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var showCurrent = false
    @State private var showNew = false
    @State private var showConfirm = false

    @State private var isLoading = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertSuggestion = ""
    @State private var showAlert = false
    @State private var isSuccess = false

    private var hasPasswordProvider: Bool {
        guard let providers = Auth.auth().currentUser?.providerData else { return false }
        return providers.contains { $0.providerID == "password" }
    }

    private var isSetPasswordMode: Bool { !hasPasswordProvider }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Spacer().frame(height: 28)

                    headerSection

                    if !isSetPasswordMode {
                        passwordField(
                            placeholder: "Mevcut şifre",
                            text: $currentPassword,
                            isVisible: $showCurrent
                        )

                        Divider().padding(.horizontal, 4)
                    }

                    passwordField(
                        placeholder: "Yeni şifre",
                        text: $newPassword,
                        isVisible: $showNew
                    )

                    passwordField(
                        placeholder: "Yeni şifre tekrar",
                        text: $confirmPassword,
                        isVisible: $showConfirm
                    )

                    Button {
                        Task {
                            if isSetPasswordMode {
                                await setNewPassword()
                            } else {
                                await changePassword()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSetPasswordMode ? "ŞİFRE BELİRLE" : "ŞİFREYİ GÜNCELLE")
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

                    if !newPassword.isEmpty {
                        passwordRequirementsView
                    }

                    validationMessages

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle(isSetPasswordMode ? "Şifre Belirle" : "Şifre Değiştir")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Tamam") {
                if isSuccess { dismiss() }
            }
        } message: {
            Text(alertMessage + (alertSuggestion.isEmpty ? "" : "\n\n💡 Öneri: \(alertSuggestion)"))
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            if isSetPasswordMode {
                Image(systemName: "lock.badge.plus")
                    .font(.system(size: 36))
                    .foregroundColor(Color("PrimaryColor"))
                    .padding(.bottom, 4)

                Text("Şifre Belirle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text("Telefon ile giriş yaptınız. E-posta ve şifre ile de giriş yapabilmek için bir şifre belirleyin.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Şifre Değiştir")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text("Mevcut şifreni doğrula ve yeni şifreni belirle.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Validation Messages

    private var validationMessages: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !isSetPasswordMode && !currentPassword.isEmpty && currentPassword.count < 6 {
                validationRow(
                    icon: "exclamationmark.circle.fill",
                    text: "Mevcut şifreniz 6 karakterden kısa olamaz. Lütfen doğru şifrenizi girdiğinizden emin olun.",
                    color: .red
                )
            }

            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                validationRow(
                    icon: "xmark.circle.fill",
                    text: "Girdiğiniz şifreler birbiriyle eşleşmiyor. Lütfen her iki alana da aynı şifreyi yazdığınızdan emin olun.",
                    color: .red
                )
            } else if !confirmPassword.isEmpty && newPassword == confirmPassword {
                validationRow(
                    icon: "checkmark.circle.fill",
                    text: "Şifreler eşleşiyor.",
                    color: .green
                )
            }

            if !isSetPasswordMode && newPassword == currentPassword && !newPassword.isEmpty && !currentPassword.isEmpty {
                validationRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Yeni şifreniz mevcut şifrenizle aynı olamaz. Güvenliğiniz için farklı bir şifre belirlemeniz gerekmektedir.",
                    color: .orange
                )
            }

            if !newPassword.isEmpty && newPassword.count >= 6 && hasSequentialChars(newPassword) {
                validationRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Şifreniz ardışık karakterler içeriyor (ör: 123, abc). Daha güvenli bir şifre tercih edin.",
                    color: .orange
                )
            }

            if !newPassword.isEmpty && hasRepeatingChars(newPassword) {
                validationRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Şifreniz tekrar eden karakterler içeriyor (ör: aaa, 111). Bu şifrenizi tahmin edilmeye karşı zayıflatır.",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Password Field
    private func passwordField(
        placeholder: String,
        text: Binding<String>,
        isVisible: Binding<Bool>
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .foregroundColor(.secondary)

            Group {
                if isVisible.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
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
    }

    // MARK: - Password Requirements View
    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Şifre Gereksinimleri")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            requirementRow("En az 6 karakter", met: newPassword.count >= 6)
            requirementRow("En az 1 büyük harf (A-Z)", met: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
            requirementRow("En az 1 küçük harf (a-z)", met: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
            requirementRow("En az 1 rakam (0-9)", met: newPassword.range(of: "[0-9]", options: .regularExpression) != nil)
            requirementRow("En az 1 özel karakter (!@#$%&*)", met: newPassword.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil)

            passwordStrengthBar
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13))
                .foregroundColor(met ? .green : .secondary.opacity(0.5))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(met ? Color("Text") : .secondary)
        }
    }

    private var passwordStrengthBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Şifre Gücü:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(strengthLabel)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(strengthColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(strengthColor)
                        .frame(width: geo.size.width * strengthProgress, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: strengthProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(.top, 4)
    }

    private var strengthScore: Int {
        var score = 0
        if newPassword.count >= 6 { score += 1 }
        if newPassword.count >= 10 { score += 1 }
        if newPassword.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if newPassword.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if newPassword.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if newPassword.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { score += 1 }
        return score
    }

    private var strengthLabel: String {
        switch strengthScore {
        case 0...1: return "Çok Zayıf"
        case 2: return "Zayıf"
        case 3: return "Orta"
        case 4: return "İyi"
        case 5: return "Güçlü"
        default: return "Çok Güçlü"
        }
    }

    private var strengthColor: Color {
        switch strengthScore {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .green
        }
    }

    private var strengthProgress: CGFloat {
        CGFloat(strengthScore) / 6.0
    }

    private func validationRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Pattern Detection
    private func hasSequentialChars(_ str: String) -> Bool {
        let lowered = str.lowercased()
        let sequences = ["012", "123", "234", "345", "456", "567", "678", "789",
                         "abc", "bcd", "cde", "def", "efg", "fgh", "ghi", "hij",
                         "ijk", "jkl", "klm", "lmn", "mno", "nop", "opq", "pqr",
                         "qrs", "rst", "stu", "tuv", "uvw", "vwx", "wxy", "xyz"]
        return sequences.contains(where: { lowered.contains($0) })
    }

    private func hasRepeatingChars(_ str: String) -> Bool {
        guard str.count >= 3 else { return false }
        let chars = Array(str)
        for i in 0..<(chars.count - 2) {
            if chars[i] == chars[i+1] && chars[i+1] == chars[i+2] {
                return true
            }
        }
        return false
    }

    // MARK: - Validation
    private var isValid: Bool {
        if isSetPasswordMode {
            return newPassword.count >= 6 && newPassword == confirmPassword
        } else {
            return !currentPassword.isEmpty &&
                   newPassword.count >= 6 &&
                   newPassword == confirmPassword &&
                   newPassword != currentPassword
        }
    }

    // MARK: - Alert Helpers
    private func showError(title: String, message: String, suggestion: String = "") {
        isSuccess = false
        alertTitle = title
        alertMessage = message
        alertSuggestion = suggestion
        showAlert = true
    }

    private func showSuccess(title: String, message: String) {
        isSuccess = true
        alertTitle = title
        alertMessage = message
        alertSuggestion = ""
        showAlert = true
    }

    // MARK: - İlk Kez Şifre Belirleme (Telefon Kullanıcısı)
    private func setNewPassword() async {
        guard let user = Auth.auth().currentUser else {
            showError(
                title: "Oturum Hatası",
                message: "Aktif bir oturum bulunamadı.",
                suggestion: "Uygulamadan çıkış yapıp tekrar giriş yapın."
            )
            return
        }

        let email: String
        if let authEmail = user.email, !authEmail.isEmpty {
            email = authEmail
        } else {
            do {
                let uid = user.uid
                let db = Firestore.firestore()
                let snap = try await db.collection("users").document(uid).getDocument()
                let storedEmail = snap.data()?["email"] as? String ?? ""
                guard !storedEmail.isEmpty else {
                    showError(
                        title: "E-posta Bulunamadı",
                        message: "Şifre belirleyebilmek için hesabınıza bir e-posta adresi bağlı olmalıdır. Profil sayfanızdan e-posta adresinizi ekleyin.",
                        suggestion: "Profil > İletişim Bilgileri bölümünden e-posta ekleyin ve tekrar deneyin."
                    )
                    return
                }
                email = storedEmail
            } catch {
                showError(
                    title: "Bağlantı Hatası",
                    message: "Kullanıcı bilgileri alınırken bir hata oluştu.",
                    suggestion: "İnternet bağlantınızı kontrol edip tekrar deneyin."
                )
                return
            }
        }

        isLoading = true
        defer { isLoading = false }

        let credential = EmailAuthProvider.credential(withEmail: email, password: newPassword)

        do {
            try await user.link(with: credential)
            showSuccess(
                title: "Şifre Belirlendi ✓",
                message: "Şifreniz başarıyla oluşturuldu. Artık \(email) e-posta adresiniz ve bu şifre ile de giriş yapabilirsiniz."
            )
        } catch {
            mapLinkError(error)
        }
    }

    // MARK: - Şifre Değiştirme (Mevcut Şifresi Olan Kullanıcı)
    private func changePassword() async {
        guard let user = Auth.auth().currentUser else {
            showError(
                title: "Oturum Hatası",
                message: "Aktif bir oturum bulunamadı.",
                suggestion: "Uygulamadan çıkış yapıp tekrar giriş yapın."
            )
            return
        }

        guard let email = user.email else {
            showError(
                title: "E-posta Bulunamadı",
                message: "Hesabınıza bağlı bir e-posta adresi bulunamadı.",
                suggestion: "Google veya Apple ile giriş yaptıysanız, ilgili hesap sağlayıcısının güvenlik ayarlarını kullanın."
            )
            return
        }

        isLoading = true
        defer { isLoading = false }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        do {
            try await user.reauthenticate(with: credential)
        } catch {
            mapFirebaseError(error, phase: .reauthentication)
            return
        }

        do {
            try await user.updatePassword(to: newPassword)
            showSuccess(
                title: "Şifre Güncellendi ✓",
                message: "Şifreniz başarıyla değiştirildi. Bir sonraki girişinizde yeni şifrenizi kullanmanız gerekmektedir."
            )
        } catch {
            mapFirebaseError(error, phase: .passwordUpdate)
        }
    }

    // MARK: - Link Hataları (İlk Şifre Belirleme)
    private func mapLinkError(_ error: Error) {
        let code = (error as NSError).code

        switch code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            showError(
                title: "E-posta Kullanımda",
                message: "Bu e-posta adresi zaten başka bir hesaba bağlı olduğu için şifre belirlenemiyor.",
                suggestion: "Farklı bir e-posta adresi kullanmak için önce profil sayfasından e-posta adresinizi güncelleyin."
            )

        case AuthErrorCode.weakPassword.rawValue:
            showError(
                title: "Zayıf Şifre",
                message: "Belirlediğiniz şifre güvenlik gereksinimlerini karşılamıyor. En az 6 karakter uzunluğunda olmalıdır.",
                suggestion: "Büyük harf, küçük harf, rakam ve özel karakter kombinasyonu kullanın."
            )

        case AuthErrorCode.networkError.rawValue:
            showError(
                title: "Bağlantı Hatası",
                message: "Sunucuyla iletişim kurulamadı.",
                suggestion: "İnternet bağlantınızı kontrol edip tekrar deneyin."
            )

        case AuthErrorCode.requiresRecentLogin.rawValue:
            showError(
                title: "Oturum Süresi Doldu",
                message: "Bu işlem için yakın zamanda giriş yapılmış olması gerekiyor.",
                suggestion: "Uygulamadan çıkış yapıp tekrar telefon ile giriş yapın ve ardından hemen şifre belirleme işlemini gerçekleştirin."
            )

        case AuthErrorCode.providerAlreadyLinked.rawValue:
            showError(
                title: "Şifre Zaten Mevcut",
                message: "Hesabınızda zaten bir e-posta/şifre bağlantısı bulunuyor.",
                suggestion: "Şifrenizi değiştirmek istiyorsanız uygulamayı kapatıp tekrar açın."
            )

        case AuthErrorCode.invalidEmail.rawValue:
            showError(
                title: "Geçersiz E-posta",
                message: "Hesabınıza kayıtlı e-posta adresi geçerli bir formatta değil.",
                suggestion: "Profil sayfanızdan e-posta adresinizi düzeltin ve tekrar deneyin."
            )

        default:
            showError(
                title: "Beklenmeyen Hata",
                message: "Şifre belirlenirken bir hata oluştu (Kod: \(code)).",
                suggestion: "Lütfen tekrar deneyin. Sorun devam ederse destek ekibimize başvurun."
            )
        }
    }

    // MARK: - Firebase Şifre Değiştirme Hataları
    private enum ErrorPhase {
        case reauthentication
        case passwordUpdate
    }

    private func mapFirebaseError(_ error: Error, phase: ErrorPhase) {
        let code = (error as NSError).code

        switch code {
        case AuthErrorCode.wrongPassword.rawValue:
            showError(
                title: "Şifre Doğrulanamadı",
                message: "Girdiğiniz mevcut şifre hesabınızdaki şifreyle eşleşmiyor.",
                suggestion: "Şifrenizi hatırlamıyorsanız \"Şifremi Unuttum\" bağlantısını kullanarak sıfırlama e-postası alabilirsiniz."
            )

        case AuthErrorCode.invalidCredential.rawValue:
            showError(
                title: "Kimlik Doğrulama Başarısız",
                message: "Girdiğiniz mevcut şifre doğrulanamadı.",
                suggestion: "Şifrenizin doğru olduğundan emin olun. Sorun devam ederse çıkış yapıp \"Şifremi Unuttum\" ile yeni şifre belirleyin."
            )

        case AuthErrorCode.weakPassword.rawValue:
            showError(
                title: "Zayıf Şifre",
                message: "Yeni şifreniz güvenlik standartlarını karşılamıyor. En az 6 karakter olmalıdır.",
                suggestion: "Büyük harf, küçük harf, rakam ve özel karakter kombinasyonu kullanın. Örnek: Uzm4n@Gel!"
            )

        case AuthErrorCode.requiresRecentLogin.rawValue:
            showError(
                title: "Oturum Süresi Doldu",
                message: "Bu işlem için yakın zamanda giriş yapılmış olması gerekiyor.",
                suggestion: "Uygulamadan çıkış yapıp tekrar giriş yapın ve ardından hemen şifre değiştirin."
            )

        case AuthErrorCode.networkError.rawValue:
            showError(
                title: "Bağlantı Hatası",
                message: "Sunucuyla iletişim kurulamadı.",
                suggestion: "Wi-Fi veya mobil veri bağlantınızı kontrol edip tekrar deneyin."
            )

        case AuthErrorCode.tooManyRequests.rawValue:
            showError(
                title: "Çok Fazla Deneme",
                message: "Çok fazla başarısız deneme yapıldı. İşlem geçici olarak engellendi.",
                suggestion: "En az 5 dakika bekleyip tekrar deneyin."
            )

        case AuthErrorCode.userDisabled.rawValue:
            showError(
                title: "Hesap Askıya Alındı",
                message: "Hesabınız devre dışı bırakılmış.",
                suggestion: "destek@uzmanagel.com adresinden bize ulaşın."
            )

        case AuthErrorCode.internalError.rawValue:
            showError(
                title: "Sunucu Hatası",
                message: "Firebase sunucularında beklenmeyen bir hata oluştu.",
                suggestion: "Birkaç dakika bekleyip tekrar deneyin."
            )

        case AuthErrorCode.invalidUserToken.rawValue, AuthErrorCode.userTokenExpired.rawValue:
            showError(
                title: "Oturum Geçersiz",
                message: "Oturum bilgileriniz geçerliliğini yitirmiş.",
                suggestion: "Uygulamadan çıkış yapıp tekrar giriş yapın."
            )

        default:
            let phaseText = phase == .reauthentication
                ? "mevcut şifreniz doğrulanırken"
                : "yeni şifreniz kaydedilirken"
            showError(
                title: "Beklenmeyen Hata",
                message: "Şifre değiştirme sırasında \(phaseText) bir hata oluştu (Kod: \(code)).",
                suggestion: "Tekrar deneyin. Sorun devam ederse destek ekibimize başvurun."
            )
        }
    }
}

#Preview {
    NavigationStack {
        ResetPasswordPage()
    }
}
