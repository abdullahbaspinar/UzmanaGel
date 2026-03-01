//
//  ExpertHomepage.swift
//  UzmanaGel
//
//  Uzman girişi sonrası ana ekran.
//

import SwiftUI

struct ExpertHomepage: View {

    @EnvironmentObject var session: SessionViewModel

    @State private var profile: ExpertProfile?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showMenu = false

    private let userRepo = UserRepository()

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let profile {
                    mainContent(profile: profile)
                } else {
                    errorView
                }
            }
            .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showMenu = true } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showMenu) {
                expertMenuSheet
            }
            .task {
                await loadProfile()
            }
            .refreshable {
                await loadProfile()
            }
        }
    }
}

// MARK: - Content

private extension ExpertHomepage {

    func mainContent(profile: ExpertProfile) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerCard(profile: profile)
                statusBanner(status: profile.status)
                quickActionsSection(profile: profile)
                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    func headerCard(profile: ExpertProfile) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("TertiaryColor").opacity(0.3), Color("PrimaryColor").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "star.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color("TertiaryColor"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Hoş geldin")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Text(profile.displayName.isEmpty ? "Uzman" : profile.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                if !profile.businessName.isEmpty {
                    Text(profile.businessName)
                        .font(.system(size: 12))
                        .foregroundColor(Color("PrimaryColor"))
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    func statusBanner(status: String) -> some View {
        let (icon, text, bgColor, fgColor) = statusStyle(status)

        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(fgColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Başvuru durumu")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text(text)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(fgColor)
            }

            Spacer()
        }
        .padding(14)
        .background(bgColor.opacity(0.15))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(fgColor.opacity(0.3), lineWidth: 1)
        )
    }

    func statusStyle(_ status: String) -> (icon: String, text: String, bg: Color, fg: Color) {
        let lower = status.lowercased()
        if lower == "approved" || lower == "onaylandı" {
            return ("checkmark.circle.fill", "Onaylandı", Color.green, Color.green)
        }
        if lower == "rejected" || lower == "reddedildi" {
            return ("xmark.circle.fill", "Reddedildi", Color.red, Color.red)
        }
        return ("clock.badge.checkmark", "İnceleme aşamasında", Color.orange, Color.orange)
    }

    func quickActionsSection(profile: ExpertProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Panonuz")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            VStack(spacing: 10) {
                actionRow(
                    icon: "doc.text.fill",
                    title: "Başvuru Özeti",
                    subtitle: "\(profile.serviceCategories.joined(separator: ", "))",
                    color: Color("PrimaryColor")
                )

                actionRow(
                    icon: "calendar.badge.clock",
                    title: "Çalışma Detayları",
                    subtitle: "Saatler, bölge, fiyat aralığı",
                    color: Color("TertiaryColor")
                )

                actionRow(
                    icon: "creditcard.fill",
                    title: "Banka Bilgileri",
                    subtitle: "Ödeme alacağınız hesap",
                    color: Color("PrimaryColor")
                )

                actionRow(
                    icon: "photo.on.rectangle.angled",
                    title: "Portföy",
                    subtitle: "Önceki işlerinizden örnekler",
                    color: Color("PrimaryColor")
                )
            }
        }
    }

    func actionRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    var expertMenuSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Hesap")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Button("Kapat") { showMenu = false }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("PrimaryColor"))
            }
            .padding()

            VStack(spacing: 0) {
                Button {
                    showMenu = false
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                            .foregroundColor(Color("PrimaryColor"))
                        Text("Profilim")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.horizontal)

                Button {
                    showMenu = false
                    session.signOut()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 22))
                            .foregroundColor(.red)
                        Text("Çıkış Yap")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Yükleniyor...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundColor(.orange)

            Text(loadError ?? "Profil yüklenemedi")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Tekrar Dene") {
                Task { await loadProfile() }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color("PrimaryColor"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Load

private extension ExpertHomepage {

    func loadProfile() async {
        guard let uid = session.userId else {
            isLoading = false
            loadError = "Oturum bulunamadı."
            return
        }

        isLoading = true
        loadError = nil

        do {
            if let p = try await userRepo.fetchExpertProfile(uid: uid) {
                profile = p
            } else {
                let user = try await userRepo.fetchUser(uid: uid)
                profile = ExpertProfile(
                    id: uid,
                    displayName: user.displayName,
                    email: user.email,
                    phoneNumber: user.phoneNumber ?? "",
                    businessName: "",
                    serviceCategories: [],
                    businessType: "",
                    taxNumber: nil,
                    experienceYears: 0,
                    expertiseAreas: [],
                    certificateURLs: [],
                    educationLevel: "",
                    schoolName: "",
                    status: "Pending",
                    createdAt: nil
                )
            }
        } catch {
            loadError = "Bağlantı hatası. Tekrar deneyin."
        }

        isLoading = false
    }
}

#Preview {
    ExpertHomepage()
        .environmentObject(SessionViewModel())
}
