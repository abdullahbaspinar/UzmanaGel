//
//  ProfilePage.swift
//  UzmanaGel
//
//  Created by Abdullah B on 10.02.2026.
//

import SwiftUI
import PhotosUI
import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ProfilePage: View {

    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = "Abdullah Başpınar"
    @State private var email: String = "abdullah@gmail.com"
    @State private var phone: String = "5513432910"

    @State private var ordersCount: Int = 0
    @State private var favoritesCount: Int = 0

    @State private var isEmailVerified: Bool = false
    @State private var isPhoneVerified: Bool = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileUIImage: UIImage?
    @State private var photoURL: String?
    @State private var isUploadingPhoto = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                statsRow
                contactSection
                accountSection
                securitySection

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
       
        .onAppear {
            loadPhotoURL()
            loadFavoritesCount()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }

            Task {
                isUploadingPhoto = true
                defer { isUploadingPhoto = false }

                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    return
                }

                profileUIImage = uiImage
                await uploadProfilePhotoToFirebase(uiImage)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color("PrimaryColor"))
                .frame(height: 220)

            VStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {

                    Group {
                        if let profileUIImage {
                            Image(uiImage: profileUIImage)
                                .resizable()
                                .scaledToFill()
                        } else if let photoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                default:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                    .overlay {
                        if isUploadingPhoto {
                            ProgressView()
                                .tint(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.25))
                                .clipShape(Circle())
                        }
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Text(fullName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Profilini düzenleyebilir, doğrulama işlemlerini yapabilirsin.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
            }
        }
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: ordersCount, title: "Siparişlerim")

            NavigationLink {
                FavoritesPage()
            } label: {
                statCard(value: favoritesCount, title: "Favorilerim")
            }
            .buttonStyle(.plain)
        }
    }

    private func statCard(value: Int, title: String) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("Text"))

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color("Text"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Contact
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("İLETİŞİM BİLGİLERİ")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                contactRow(
                    icon: "envelope",
                    title: email,
                    subtitle: "E-posta",
                    verified: isEmailVerified
                ) {
                    isEmailVerified.toggle()
                }

                Divider().padding(.leading, 50)

                contactRow(
                    icon: "phone",
                    title: phoneFormatted(phone),
                    subtitle: "Telefon",
                    verified: isPhoneVerified
                ) {
                    isPhoneVerified.toggle()
                }
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    private func contactRow(
        icon: String,
        title: String,
        subtitle: String,
        verified: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("TertiaryColor"))
                .frame(width: 22)

            VStack(alignment: .leading) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(subtitle).font(.system(size: 12)).foregroundColor(.secondary)
            }

            Spacer()

            if !verified {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            }

            Button(verified ? "DOĞRULANDI" : "DOĞRULA") {
                onTap()
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(verified ? .gray : .orange)
            .buttonStyle(.plain)
        }
        .padding(14)
    }

    // MARK: - Account
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HESAP AYARLARI")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                settingsRow("person", "Kullanıcı Bilgileri")
                Divider().padding(.leading, 50)
                settingsRow("mappin.and.ellipse", "Kayıtlı Adreslerim")
                Divider().padding(.leading, 50)
                settingsRow("creditcard", "Ödeme Yöntemleri")
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Security
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GÜVENLİK")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                settingsRow("key.shield", "Şifre Değiştir")
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    private func settingsRow(_ icon: String, _ title: String) -> some View {
        Button { } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("TertiaryColor"))
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("Text"))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Firebase Helpers
    private func uploadProfilePhotoToFirebase(_ image: UIImage) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("UID bulunamadı")
            return
        }

        guard let data = image.jpegData(compressionQuality: 0.7) else {
            print("JPEG dönüşüm başarısız")
            return
        }

        let ref = Storage.storage()
            .reference()
            .child("profile_photos/\(uid)/profile.jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()

            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "photoURL": url.absoluteString,
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)

            photoURL = url.absoluteString
        } catch {
            print("UPLOAD ERROR:", error.localizedDescription)
        }
    }

    private func loadPhotoURL() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    print("LOAD PHOTO ERROR:", error.localizedDescription)
                    return
                }

                if let url = snapshot?.data()?["photoURL"] as? String {
                    self.photoURL = url
                }
            }
    }

    private func loadFavoritesCount() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("favorites")
            .getDocuments { snap, error in
                if let error = error {
                    print("LOAD FAVORITES COUNT ERROR:", error.localizedDescription)
                    return
                }
                self.favoritesCount = snap?.documents.count ?? 0
            }
    }

    // MARK: - Helpers
    private func phoneFormatted(_ raw: String) -> String {
        let d = raw.filter(\.isNumber)
        guard d.count == 10 else { return raw }
        return "\(d.prefix(3)) \(d.dropFirst(3).prefix(3)) \(d.dropFirst(6).prefix(2)) \(d.dropFirst(8).prefix(2))"
    }
}

#Preview {
    NavigationStack {
        ProfilePage()
    }
}
