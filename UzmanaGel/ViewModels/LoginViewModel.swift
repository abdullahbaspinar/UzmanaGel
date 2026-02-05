//
//  LoginViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 1.02.2026.
//

import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn
import FirebaseCore

@MainActor
final class LoginViewModel : ObservableObject {
    
    //viewden gelen inputlar
    @Published var email : String = ""
    @Published var password : String = ""
     
    
    //viewin yapacakları
    @Published var isLoading : Bool = false
    @Published var errorMessage : String? = nil
    @Published var didLogin : Bool = false  //login başarılı mı
    
    func signInWithGoogle(presenting: UIViewController) {
        isLoading = true
        errorMessage = nil

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            isLoading = false
            errorMessage = "Google ClientID bulunamadı."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self.isLoading = false
                self.errorMessage = "Google token alınamadı."
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { _, error in
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.didLogin = true
            }
        }
    }
    
    
    func login() {
           let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

           guard !trimmedEmail.isEmpty, !password.isEmpty else {
               errorMessage = "E-posta ve şifre boş olamaz."
               return
           }
        //firebase --login
        
        isLoading = true
        errorMessage = nil
        Auth.auth().signIn(withEmail: trimmedEmail, password: password) {
            [weak self] result , error in guard let self else {return}
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = self.mapAuthError(error)
                return
            }
            //başarılı ise
            self.didLogin = true
        }
        }
    
    private func mapAuthError(_ error: Error) -> String {
     let nsError = error as NSError
        let code = AuthErrorCode(rawValue: nsError.code)
        
        switch code {
        case .userNotFound:
                return "Bu e-posta ile kayıtlı kullanıcı bulunamadı"
            case .wrongPassword:
                return "Şifre hatalı. Tekrar deneyin."
            case .invalidEmail:
                return "E-posta formatı hatalı."
            case .userDisabled:
                return "Bu hesap devre dışı bırakılmış."
            case .tooManyRequests:
                return "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin."
            case .networkError:
                return "İnternet bağlantısı hatası. Bağlantını kontrol et."
            default:
                return "Giriş yapılamadı. Lütfen bilgilerini kontrol et."
        }
        
    }
    func clearError(){
        errorMessage = nil
    }
    
    
}
