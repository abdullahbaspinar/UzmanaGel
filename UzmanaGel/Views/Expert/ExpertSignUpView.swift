import SwiftUI
import PhotosUI

struct ExpertSignUpView: View {

    @EnvironmentObject private var session: SessionViewModel
    @ObservedObject var vm: ExpertSignUpViewModel

    @State private var showError = false
    @State private var showKvkkSheet = false
    @State private var hasReadKvkk = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var categorySearchText = ""
    @State private var isCategoryPickerExpanded = false
    @State private var showSmsVerificationSheet = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                stepIndicator
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        switch vm.currentStep {
                        case 1:
                            step1BasicInfo
                        case 2:
                            step2BusinessInfo
                        case 3:
                            step3ProfessionalInfo
                        case 4:
                            step4IdVerification
                        default:
                            EmptyView()
                        }

                        navigationButtons
                            .padding(.top, 8)

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }

            if vm.isLoading {
                loadingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    session.clearExpertSignup(shouldSignOut: true)
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("PrimaryColor"))
                }
            }
        }
        .onChange(of: vm.errorMessage) { _, msg in
            if !showSmsVerificationSheet { showError = (msg != nil) }
        }
        .onChange(of: vm.didSendCode) { _, didSend in
            if didSend && vm.currentStep == 1 && !vm.phoneVerified {
                showSmsVerificationSheet = true
            }
        }
        .onChange(of: vm.isLoading) { _, loading in
            if vm.currentStep == 1 && loading && !vm.phoneVerified && !vm.didSendCode {
                showSmsVerificationSheet = true
            }
        }
        .onChange(of: vm.phoneVerified) { _, verified in
            if verified { showSmsVerificationSheet = false }
        }
        .sheet(isPresented: $showSmsVerificationSheet) {
            SmsVerificationSheetView(vm: vm, isPresented: $showSmsVerificationSheet)
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { vm.clearError() }
        } message: {
            Text(vm.errorMessage ?? "Bilinmeyen hata")
        }
        .onAppear {
            vm.setSession(session)
        }
        .onChange(of: vm.didSignUp) { _, newValue in
            if newValue {
                session.clearExpertSignup(shouldSignOut: false)
                dismiss()
            }
        }
        .onDisappear {
            if !vm.didSignUp {
                session.clearExpertSignup(shouldSignOut: true)
            }
        }
        .onChange(of: vm.certificatePickerItems) { _, _ in
            vm.loadCertificateImages()
        }
        .onChange(of: vm.idFrontPickerItem) { _, _ in
            vm.loadIdFrontImage()
        }
        .onChange(of: vm.idBackPickerItem) { _, _ in
            vm.loadIdBackImage()
        }
    }
}

// MARK: - Header & Step Indicator

private extension ExpertSignUpView {

    var headerSection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color("TertiaryColor"))

                Text("Uzman Başvurusu")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 12)

            Text(stepTitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
    }

    var stepTitle: String {
        switch vm.currentStep {
        case 1: return "Temel Bilgilerinizi Girin"
        case 2: return "İşletme Bilgilerinizi Girin"
        case 3: return "Profesyonel Bilgilerinizi Girin"
        case 4: return "Kimlik Doğrulama"
        default: return ""
        }
    }

    var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...vm.totalSteps, id: \.self) { step in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(step <= vm.currentStep ? Color("PrimaryColor") : Color(.systemGray4))
                            .frame(width: 32, height: 32)

                        if step < vm.currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(step == vm.currentStep ? .white : .secondary)
                        }
                    }

                    Text(stepLabel(for: step))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(step <= vm.currentStep ? Color("PrimaryColor") : .secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                if step < vm.totalSteps {
                    Rectangle()
                        .fill(step < vm.currentStep ? Color("PrimaryColor") : Color(.systemGray4))
                        .frame(height: 2)
                        .frame(maxWidth: 28)
                        .offset(y: -10)
                }
            }
        }
        .padding(.horizontal, 32)
    }

    func stepLabel(for step: Int) -> String {
        switch step {
        case 1: return "Temel"
        case 2: return "İşletme"
        case 3: return "Profesyonel"
        case 4: return "Kimlik"
        default: return ""
        }
    }
}

// MARK: - Step 1: Temel Bilgiler

private extension ExpertSignUpView {

    var step1BasicInfo: some View {
        VStack(spacing: 12) {
            inputField(icon: "person", placeholder: "Ad Soyad") {
                TextField("Ad Soyad", text: $vm.fullName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }

            inputField(icon: "envelope", placeholder: "E-posta") {
                TextField("E-posta", text: $vm.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            inputField(icon: "phone", placeholder: "Telefon (5XX XXX XX XX)") {
                TextField("Telefon (5XX XXX XX XX)", text: $vm.phone)
                    .keyboardType(.phonePad)
                    .autocorrectionDisabled()
            }

            phoneVerificationSection

            passwordField

            confirmPasswordField

            if !vm.password.isEmpty {
                passwordRequirementsView
            }

            passwordHintsView

            kvkkSection
        }
    }

    var passwordField: some View {
        inputField(icon: "lock", placeholder: "Şifre") {
            Group {
                if isPasswordVisible {
                    TextField("Şifre", text: $vm.password)
                } else {
                    SecureField("Şifre", text: $vm.password)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button { isPasswordVisible.toggle() } label: {
                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    var confirmPasswordField: some View {
        inputField(icon: "lock", placeholder: "Şifre Tekrar") {
            Group {
                if isConfirmPasswordVisible {
                    TextField("Şifre Tekrar", text: $vm.confirmPassword)
                } else {
                    SecureField("Şifre Tekrar", text: $vm.confirmPassword)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button { isConfirmPasswordVisible.toggle() } label: {
                Image(systemName: isConfirmPasswordVisible ? "eye" : "eye.slash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Password Requirements

    var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Şifre Gereksinimleri")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            requirementRow("En az 6 karakter", met: vm.password.count >= 6)
            requirementRow("En az 1 büyük harf (A-Z)", met: vm.password.range(of: "[A-Z]", options: .regularExpression) != nil)
            requirementRow("En az 1 küçük harf (a-z)", met: vm.password.range(of: "[a-z]", options: .regularExpression) != nil)
            requirementRow("En az 1 rakam (0-9)", met: vm.password.range(of: "[0-9]", options: .regularExpression) != nil)
            requirementRow("En az 1 özel karakter (!@#$%&*)", met: vm.password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil)

            passwordStrengthBar
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13))
                .foregroundColor(met ? .green : .secondary.opacity(0.5))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(met ? Color("Text") : .secondary)
        }
    }

    var passwordStrengthBar: some View {
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

    var strengthScore: Int {
        var score = 0
        let pw = vm.password
        if pw.count >= 6 { score += 1 }
        if pw.count >= 10 { score += 1 }
        if pw.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if pw.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if pw.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if pw.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { score += 1 }
        return score
    }

    var strengthLabel: String {
        switch strengthScore {
        case 0...1: return "Çok Zayıf"
        case 2: return "Zayıf"
        case 3: return "Orta"
        case 4: return "İyi"
        case 5: return "Güçlü"
        default: return "Çok Güçlü"
        }
    }

    var strengthColor: Color {
        switch strengthScore {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .green
        }
    }

    var strengthProgress: CGFloat {
        CGFloat(strengthScore) / 6.0
    }

    // MARK: - Password Hints

    var passwordHintsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !vm.confirmPassword.isEmpty && vm.password != vm.confirmPassword {
                hintRow("Şifreler eşleşmiyor.", color: .red)
            } else if !vm.confirmPassword.isEmpty && vm.password == vm.confirmPassword && vm.password.count >= 6 {
                hintRow("Şifreler eşleşiyor.", color: .green)
            }

            if !vm.password.isEmpty && vm.password.count >= 6 && hasSequentialChars(vm.password) {
                hintRow("Şifreniz ardışık karakterler içeriyor (ör: 123, abc).", color: .orange)
            }

            if !vm.password.isEmpty && hasRepeatingChars(vm.password) {
                hintRow("Şifreniz tekrar eden karakterler içeriyor (ör: aaa, 111).", color: .orange)
            }
        }
    }

    func hintRow(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: color == .green ? "checkmark.circle.fill" : color == .orange ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
    }

    func hasSequentialChars(_ str: String) -> Bool {
        let lowered = str.lowercased()
        let sequences = ["012", "123", "234", "345", "456", "567", "678", "789",
                         "abc", "bcd", "cde", "def", "efg", "fgh", "ghi", "hij",
                         "ijk", "jkl", "klm", "lmn", "mno", "nop", "opq", "pqr",
                         "qrs", "rst", "stu", "tuv", "uvw", "vwx", "wxy", "xyz"]
        return sequences.contains(where: { lowered.contains($0) })
    }

    func hasRepeatingChars(_ str: String) -> Bool {
        guard str.count >= 3 else { return false }
        let chars = Array(str)
        for i in 0..<(chars.count - 2) {
            if chars[i] == chars[i+1] && chars[i+1] == chars[i+2] {
                return true
            }
        }
        return false
    }

    var kvkkSection: some View {
        HStack(spacing: 10) {
            Button {
                if hasReadKvkk {
                    vm.kvkkAccepted.toggle()
                } else {
                    showKvkkSheet = true
                }
            } label: {
                Image(systemName: vm.kvkkAccepted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(hasReadKvkk ? Color("PrimaryColor") : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Button {
                    showKvkkSheet = true
                } label: {
                    Text("Kullanım şartları ve gizlilik politikası")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                        .italic()
                }
                .buttonStyle(.plain)

                Text("okudum, onaylıyorum.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("SecondaryColor"))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(14)
        .sheet(isPresented: $showKvkkSheet) {
            Kvkk(hasRead: $hasReadKvkk)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    if hasReadKvkk { vm.kvkkAccepted = true }
                }
        }
    }

    var phoneVerificationSection: some View {
        Group {
            if vm.phoneVerified {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    Text("Telefon numaranız doğrulandı")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.12))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - SMS Doğrulama Sayfası (Açılır sayfa)

struct SmsVerificationSheetView: View {
    @ObservedObject var vm: ExpertSignUpViewModel
    @Binding var isPresented: Bool

    private func formattedPhone() -> String {
        let digits = vm.phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)
        guard digits.count == 10 else { return vm.phone }
        return "+90 \(digits.prefix(3)) \(digits.dropFirst(3).prefix(3)) \(digits.suffix(4))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()

                VStack(spacing: 24) {
                    if !vm.didSendCode && vm.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("SMS kodu gönderiliyor...")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        Text("\(formattedPhone()) numarasına gönderilen 6 haneli kodu girin.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if vm.didSendCode || vm.errorMessage != nil {
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "number")
                                    .foregroundColor(.secondary)
                                TextField("6 haneli kod", text: $vm.smsCode)
                                    .keyboardType(.numberPad)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .onChange(of: vm.smsCode) { _, _ in vm.clearError() }
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(white: 0, opacity: 0.08), lineWidth: 1)
                            )

                            if let error = vm.errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.system(size: 13))
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(10)
                            }

                            Button {
                                vm.verifyPhoneCode()
                            } label: {
                                HStack {
                                    if vm.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Doğrula")
                                    }
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(vm.smsCode.filter(\.isNumber).count == 6 ? Color("PrimaryColor") : Color.gray)
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                            .disabled(vm.smsCode.filter(\.isNumber).count != 6 || vm.isLoading)

                            if vm.resendCountdown > 0 {
                                Text("Tekrar kod gönder (\(vm.resendCountdown)s)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            } else {
                                Button {
                                    vm.resendVerificationCode()
                                } label: {
                                    Text("Kodu tekrar gönder")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color("PrimaryColor"))
                                }
                                .buttonStyle(.plain)
                                .disabled(vm.isLoading)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("SMS Doğrulama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        isPresented = false
                    }
                    .foregroundColor(Color("PrimaryColor"))
                }
            }
        }
        .onAppear {
            vm.clearError()
        }
    }
}

// MARK: - Step 2: İşletme Bilgileri

private extension ExpertSignUpView {

    var step2BusinessInfo: some View {
        VStack(spacing: 16) {
            inputField(icon: "building.2", placeholder: "İşletme Adı") {
                TextField("İşletme Adı", text: $vm.businessName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }

            businessTypeSelector

            categorySelector

            inputField(icon: "number", placeholder: "Vergi Numarası (Opsiyonel)") {
                TextField("Vergi Numarası (Opsiyonel)", text: $vm.taxNumber)
                    .keyboardType(.numberPad)
            }
        }
    }

    var businessTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("İşletme Türü")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(BusinessType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.businessType = type
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: type == .individual ? "person.fill" : "building.fill")
                                .font(.system(size: 14))

                            Text(type.displayName)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(vm.businessType == type ? .white : Color("PrimaryColor"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(vm.businessType == type ? Color("PrimaryColor") : Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(vm.businessType == type ? Color.clear : Color.black.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var categorySelector: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isCategoryPickerExpanded.toggle()
                    if !isCategoryPickerExpanded { categorySearchText = "" }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("PrimaryColor"))
                        .rotationEffect(.degrees(isCategoryPickerExpanded ? 180 : 0))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hizmet Kategorileri")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(vm.selectedCategories.isEmpty
                             ? "Kategori seçmek için dokunun"
                             : "\(vm.selectedCategories.count) kategorisi seçildi")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if !vm.selectedCategories.isEmpty {
                        Text("\(vm.selectedCategories.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color("PrimaryColor"))
                            .clipShape(Capsule())
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if isCategoryPickerExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))

                        TextField("Kategori ara...", text: $categorySearchText)
                            .font(.system(size: 14))
                            .autocorrectionDisabled()
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)

                    if !vm.selectedCategories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(vm.selectedCategories).sorted(), id: \.self) { name in
                                    HStack(spacing: 4) {
                                        Text(name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)

                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                _ = vm.selectedCategories.remove(name)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(white: 1, opacity: 0.9))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color("PrimaryColor"))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 6) {
                            ForEach(filteredCategories) { category in
                                categoryRow(category)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 220)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(white: 0, opacity: 0.06), lineWidth: 1)
                )
                .padding(.top, 8)
            }
        }
    }

    private var filteredCategories: [ServiceCategory] {
        let query = categorySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return ServiceCategory.allCategories
        }
        return ServiceCategory.allCategories.filter {
            $0.name.lowercased().contains(query)
        }
    }

    func categoryRow(_ category: ServiceCategory) -> some View {
        let isSelected = vm.selectedCategories.contains(category.name)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    _ = vm.selectedCategories.remove(category.name)
                } else {
                    vm.selectedCategories.insert(category.name)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : Color("PrimaryColor"))
                    .frame(width: 28, alignment: .center)

                Text(category.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(isSelected ? Color("PrimaryColor") : Color(.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 3: Profesyonel Bilgiler

private extension ExpertSignUpView {

    var step3ProfessionalInfo: some View {
        VStack(spacing: 16) {
            inputField(icon: "calendar", placeholder: "Deneyim Yılı") {
                TextField("Deneyim Yılı", text: $vm.experienceYears)
                    .keyboardType(.numberPad)
            }

            educationSelector

            inputField(icon: "graduationcap", placeholder: "Okul / Kurum Adı (Opsiyonel)") {
                TextField("Okul / Kurum Adı (Opsiyonel)", text: $vm.schoolName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }

            expertiseAreasSelector

            certificateSection
        }
    }

    var educationSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Eğitim Düzeyi")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EducationLevel.allCases, id: \.self) { level in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                vm.educationLevel = level
                            }
                        } label: {
                            Text(level.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(vm.educationLevel == level ? .white : .primary)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .background(vm.educationLevel == level ? Color("PrimaryColor") : Color(.secondarySystemBackground))
                                .cornerRadius(18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(vm.educationLevel == level ? Color.clear : Color.black.opacity(0.06), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var expertiseAreasSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Uzmanlık Alanları")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(vm.selectedExpertiseAreas.count) seçili")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("PrimaryColor"))
            }

            if vm.selectedCategories.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                    Text("Önce hizmet kategorisi seçin")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 8)
            } else {
                let areas = ExpertiseArea.areas(for: vm.selectedCategories)

                FlowLayout(spacing: 6) {
                    ForEach(areas) { area in
                        expertiseChip(area)
                    }
                }
            }
        }
    }

    func expertiseChip(_ area: ExpertiseArea) -> some View {
        let isSelected = vm.selectedExpertiseAreas.contains(area.name)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    vm.selectedExpertiseAreas.remove(area.name)
                } else {
                    vm.selectedExpertiseAreas.insert(area.name)
                }
            }
        } label: {
            Text(area.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color("PrimaryColor") : Color(.secondarySystemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color.black.opacity(0.06), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    var certificateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sertifikalar (Opsiyonel)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            Text("Sahip olduğunuz sertifikaların fotoğraflarını ekleyin.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            if !vm.certificateImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.certificateImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: vm.certificateImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button {
                                    vm.removeCertificate(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            }

            PhotosPicker(
                selection: $vm.certificatePickerItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 16))
                    Text("Sertifika Ekle")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color("PrimaryColor"))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color("PrimaryColor").opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("PrimaryColor").opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Step 4: Kimlik Doğrulama

private extension ExpertSignUpView {

    var step4IdVerification: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 36))
                    .foregroundColor(Color("PrimaryColor"))

                Text("Kimlik belgenizin ön ve arka yüzünün net fotoğraflarını yükleyin.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            idCardUpload(
                title: "Kimlik Ön Yüz",
                icon: "creditcard",
                image: vm.idFrontImage,
                pickerSelection: $vm.idFrontPickerItem,
                onRemove: { vm.idFrontImage = nil; vm.idFrontPickerItem = nil }
            )

            idCardUpload(
                title: "Kimlik Arka Yüz",
                icon: "creditcard.fill",
                image: vm.idBackImage,
                pickerSelection: $vm.idBackPickerItem,
                onRemove: { vm.idBackImage = nil; vm.idBackPickerItem = nil }
            )

            VStack(alignment: .leading, spacing: 8) {
                Label("Fotoğraflar net ve okunabilir olmalı", systemImage: "checkmark.circle")
                Label("Kimlik bilgileri tam görünmeli", systemImage: "checkmark.circle")
                Label("Işık yansıması olmamalı", systemImage: "checkmark.circle")
                Label("Bilgileriniz güvenle saklanır", systemImage: "lock.shield")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("PrimaryColor").opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    func idCardUpload(
        title: String,
        icon: String,
        image: UIImage?,
        pickerSelection: Binding<PhotosPickerItem?>,
        onRemove: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color("PrimaryColor"))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                if image != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
            }

            if let image {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3)
                    }
                    .padding(8)
                }
            } else {
                PhotosPicker(selection: pickerSelection, matching: .images) {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.badge.ellipsis")
                            .font(.system(size: 28))
                            .foregroundColor(Color("PrimaryColor"))

                        Text("Fotoğraf Seç")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("PrimaryColor"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .background(Color("PrimaryColor").opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color("PrimaryColor").opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                    )
                }
            }

            if image != nil {
                PhotosPicker(selection: pickerSelection, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 13))
                        Text("Değiştir")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color("PrimaryColor"))
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(image != nil ? Color.green.opacity(0.3) : Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Navigation Buttons

private extension ExpertSignUpView {

    var navigationButtons: some View {
        HStack(spacing: 12) {
            if vm.currentStep > 1 {
                Button {
                    vm.previousStep()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                        Text("GERİ")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(Color("PrimaryColor"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color("PrimaryColor").opacity(0.08))
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }

            Button {
                if vm.currentStep == 1 && !vm.phoneVerified && vm.isStep1FieldsFilled {
                    showSmsVerificationSheet = true
                }
                vm.nextStep()
            } label: {
                HStack(spacing: 6) {
                    Text(vm.currentStep == vm.totalSteps ? "BAŞVURU YAP" : "İLERİ")
                        .font(.system(size: 15, weight: .bold))

                    if vm.currentStep < vm.totalSteps {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(forwardButtonEnabled ? Color("TertiaryColor") : Color.gray)
                .cornerRadius(14)
                .shadow(radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(!forwardButtonEnabled)
        }
    }

    private var forwardButtonEnabled: Bool {
        switch vm.currentStep {
        case 1:
            return vm.isStep1FieldsFilled
        case 2:
            return vm.isStep2Valid
        case 3:
            return vm.isStep3Valid
        case 4:
            return vm.isStep4Valid
        default:
            return true
        }
    }
}

// MARK: - Reusable Components

private extension ExpertSignUpView {

    func inputField<Content: View>(icon: String, placeholder: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 22)

            content()
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

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Başvurunuz gönderiliyor...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}

// MARK: - FlowLayout (Tag Cloud)

struct FlowLayout: Layout {

    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxRowWidth = max(maxRowWidth, x)
        }

        return (positions, CGSize(width: maxRowWidth, height: y + rowHeight))
    }
}

#Preview {
    NavigationStack {
        ExpertSignUpView(vm: ExpertSignUpViewModel())
            .environmentObject(SessionViewModel())
    }
}
