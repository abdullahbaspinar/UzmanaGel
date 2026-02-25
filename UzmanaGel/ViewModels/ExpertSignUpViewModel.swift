import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import PhotosUI

@MainActor
final class ExpertSignUpViewModel: ObservableObject {

    // MARK: - Step Tracking

    @Published var currentStep = 1
    let totalSteps = 4

    // MARK: - Step 1: Temel Bilgiler

    @Published var fullName = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var kvkkAccepted = false

    // MARK: - Step 2: İşletme Bilgileri

    @Published var businessName = ""
    @Published var selectedCategories: Set<String> = []
    @Published var businessType: BusinessType = .individual
    @Published var taxNumber = ""

    // MARK: - Step 3: Profesyonel Bilgiler

    @Published var experienceYears = ""
    @Published var selectedExpertiseAreas: Set<String> = []
    @Published var educationLevel: EducationLevel = .bachelor
    @Published var schoolName = ""
    @Published var certificateImages: [UIImage] = []
    @Published var certificatePickerItems: [PhotosPickerItem] = []

    // MARK: - Step 4: Kimlik Doğrulama

    @Published var idFrontImage: UIImage?
    @Published var idBackImage: UIImage?
    @Published var idFrontPickerItem: PhotosPickerItem?
    @Published var idBackPickerItem: PhotosPickerItem?

    // MARK: - State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSignUp = false
    @Published var showImagePicker = false

    private let userRepo = UserRepository()

    // MARK: - Step Navigation

    func nextStep() {
        guard validateCurrentStep() else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep < totalSteps {
                currentStep += 1
            } else {
                submitApplication()
            }
        }
    }

    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep > 1 {
                currentStep -= 1
            }
        }
    }

    // MARK: - Validation

    func validateCurrentStep() -> Bool {
        errorMessage = nil

        switch currentStep {
        case 1:
            return validateStep1()
        case 2:
            return validateStep2()
        case 3:
            return validateStep3()
        case 4:
            return validateStep4()
        default:
            return true
        }
    }

    private func validateStep1() -> Bool {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)

        guard !trimmedName.isEmpty else {
            errorMessage = "Ad Soyad boş olamaz."
            return false
        }

        guard trimmedName.count >= 3 else {
            errorMessage = "Ad Soyad en az 3 karakter olmalıdır."
            return false
        }

        guard !trimmedEmail.isEmpty else {
            errorMessage = "E-posta adresi boş olamaz."
            return false
        }

        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            errorMessage = "Geçerli bir e-posta adresi girin."
            return false
        }

        guard !trimmedPhone.isEmpty else {
            errorMessage = "Telefon numarası boş olamaz."
            return false
        }

        guard trimmedPhone.count == 10 else {
            errorMessage = "Telefon numarası 10 haneli olmalıdır. (ör: 5XXXXXXXXX)"
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Şifre boş olamaz."
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalı."
            return false
        }

        guard password == confirmPassword else {
            errorMessage = "Şifreler eşleşmiyor."
            return false
        }

        guard kvkkAccepted else {
            errorMessage = "Devam etmek için KVKK onayını vermelisiniz."
            return false
        }

        return true
    }

    private func validateStep2() -> Bool {
        let trimmedBusiness = businessName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedBusiness.isEmpty else {
            errorMessage = "İşletme adı boş olamaz."
            return false
        }

        guard trimmedBusiness.count >= 2 else {
            errorMessage = "İşletme adı en az 2 karakter olmalıdır."
            return false
        }

        guard !selectedCategories.isEmpty else {
            errorMessage = "En az bir hizmet kategorisi seçmelisiniz."
            return false
        }

        return true
    }

    private func validateStep3() -> Bool {
        let trimmedYears = experienceYears.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedYears.isEmpty, let years = Int(trimmedYears), years >= 0 else {
            errorMessage = "Geçerli bir deneyim yılı girin."
            return false
        }

        guard years <= 60 else {
            errorMessage = "Deneyim yılı 60'tan fazla olamaz."
            return false
        }

        guard !selectedExpertiseAreas.isEmpty else {
            errorMessage = "En az bir uzmanlık alanı seçmelisiniz."
            return false
        }

        return true
    }

    private func validateStep4() -> Bool {
        guard idFrontImage != nil else {
            errorMessage = "Kimlik ön yüz fotoğrafı zorunludur."
            return false
        }

        guard idBackImage != nil else {
            errorMessage = "Kimlik arka yüz fotoğrafı zorunludur."
            return false
        }

        return true
    }

    var isStep4Valid: Bool {
        idFrontImage != nil && idBackImage != nil
    }

    var isStep1Valid: Bool {
        let n = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)
        return n.count >= 3
            && e.contains("@") && e.contains(".")
            && p.count == 10
            && password.count >= 6
            && password == confirmPassword
            && kvkkAccepted
    }

    var isStep2Valid: Bool {
        let b = businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        return b.count >= 2 && !selectedCategories.isEmpty
    }

    var isStep3Valid: Bool {
        guard let years = Int(experienceYears.trimmingCharacters(in: .whitespacesAndNewlines)),
              years >= 0, years <= 60 else { return false }
        return !selectedExpertiseAreas.isEmpty
    }

    // MARK: - ID Image Handling

    func loadIdFrontImage() {
        guard let item = idFrontPickerItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                idFrontImage = image
            }
        }
    }

    func loadIdBackImage() {
        guard let item = idBackPickerItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                idBackImage = image
            }
        }
    }

    // MARK: - Certificate Image Handling

    func loadCertificateImages() {
        Task {
            var images: [UIImage] = []
            for item in certificatePickerItems {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            certificateImages = images
        }
    }

    func removeCertificate(at index: Int) {
        guard index < certificateImages.count else { return }
        certificateImages.remove(at: index)
        if index < certificatePickerItems.count {
            certificatePickerItems.remove(at: index)
        }
    }

    // MARK: - Submit

    func submitApplication() {
        guard validateStep1(), validateStep2(), validateStep3(), validateStep4() else { return }

        isLoading = true
        errorMessage = nil

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)
        let trimmedBusiness = businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        let years = Int(experienceYears.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let trimmedSchool = schoolName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTax = taxNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let emailTaken = try await userRepo.isEmailTaken(trimmedEmail)
                if emailTaken {
                    isLoading = false
                    errorMessage = "Bu e-posta adresi zaten kullanılıyor. Lütfen farklı bir e-posta deneyin veya mevcut hesabınızla giriş yapın."
                    return
                }
            } catch {
                isLoading = false
                errorMessage = "E-posta kontrolü yapılırken bağlantı hatası oluştu."
                return
            }

            do {
                let phoneTaken = try await userRepo.isPhoneTaken(trimmedPhone)
                if phoneTaken {
                    isLoading = false
                    errorMessage = "Bu telefon numarası zaten başka bir hesapta kayıtlı."
                    return
                }
            } catch {
                isLoading = false
                errorMessage = "Telefon kontrolü yapılırken bağlantı hatası oluştu."
                return
            }

            let user: FirebaseAuth.User
            do {
                let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
                user = result.user
            } catch {
                isLoading = false
                errorMessage = mapAuthError(error)
                return
            }

            do {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = trimmedName
                try await changeRequest.commitChanges()
            } catch {
                // devam et
            }

            do {
                try await userRepo.createExpertUserDocument(
                    uid: user.uid,
                    displayName: trimmedName,
                    email: trimmedEmail,
                    phoneNumber: trimmedPhone
                )
            } catch {
                isLoading = false
                errorMessage = "Kullanıcı bilgileri kaydedilemedi. Lütfen tekrar deneyin."
                return
            }

            let profileData: [String: Any] = [
                "displayName": trimmedName,
                "email": trimmedEmail,
                "phoneNumber": trimmedPhone,
                "businessName": trimmedBusiness,
                "serviceCategories": Array(selectedCategories),
                "businessType": businessType.rawValue,
                "taxNumber": trimmedTax,
                "experienceYears": years,
                "expertiseAreas": Array(selectedExpertiseAreas),
                "educationLevel": educationLevel.rawValue,
                "schoolName": trimmedSchool,
                "certificateURLs": [] as [String]
            ]

            do {
                try await userRepo.createExpertProfile(uid: user.uid, profile: profileData)
            } catch {
                isLoading = false
                errorMessage = "Uzman profili kaydedilirken hata oluştu. Giriş yaparak profilinizi tamamlayabilirsiniz."
                didSignUp = true
                return
            }

            isLoading = false
            didSignUp = true
        }
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Auth Error Mapping

    private func mapAuthError(_ error: Error) -> String {
        let code = (error as NSError).code

        switch code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Bu e-posta adresi zaten bir hesaba bağlı. Farklı bir e-posta deneyin veya mevcut hesabınızla giriş yapın."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Geçersiz e-posta formatı. Lütfen doğru bir e-posta adresi girin."
        case AuthErrorCode.weakPassword.rawValue:
            return "Şifreniz güvenlik gereksinimlerini karşılamıyor. En az 6 karakter uzunluğunda olmalı."
        case AuthErrorCode.networkError.rawValue:
            return "İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edip tekrar deneyin."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Çok fazla deneme yapıldı. Lütfen birkaç dakika bekleyip tekrar deneyin."
        default:
            return "Hesap oluşturulurken bir hata oluştu (Kod: \(code)). Lütfen tekrar deneyin."
        }
    }
}
