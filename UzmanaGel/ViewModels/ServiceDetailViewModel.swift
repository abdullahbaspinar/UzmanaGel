import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import CoreLocation

@MainActor
final class ServiceDetailViewModel: ObservableObject {

    // MARK: - Published

    @Published var providerServices: [Service] = []
    @Published var galleryURLs: [URL] = []
    @Published var coverImageURL: URL?
    @Published var addressText: String = ""
    @Published var isFavorite: Bool
    @Published var isLoading = false

    let service: Service

    private let serviceRepo = ServiceRepository()
    private let favRepo = FavoritesRepository()

    // MARK: - Init

    init(service: Service, imageURL: URL?, isFavorite: Bool) {
        self.service = service
        self.coverImageURL = imageURL
        self.isFavorite = isFavorite
    }

    // MARK: - Public

    func load() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            async let s: () = fetchProviderServices()
            async let g: () = fetchGalleryImages()
            async let a: () = resolveAddress()
            _ = await (s, g, a)

            if coverImageURL == nil {
                loadCoverImage()
            }

            isLoading = false
        }
    }

    func toggleFavorite() {
        Task {
            do {
                if isFavorite {
                    try await favRepo.removeFavorite(serviceId: service.serviceId)
                    isFavorite = false
                } else {
                    try await favRepo.addFavorite(serviceId: service.serviceId)
                    isFavorite = true
                }
            } catch {
                print("⚠️ Favori toggle hatası: \(error)")
            }
        }
    }

    func openDirections() {
        guard let geo = service.locationGeo else { return }
        let urlStr = "http://maps.apple.com/?daddr=\(geo.latitude),\(geo.longitude)"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Private

    private func fetchProviderServices() async {
        guard !service.providerId.isEmpty else { return }
        do {
            providerServices = try await serviceRepo.fetchServicesByProviderId(service.providerId)
        } catch {
            print("⚠️ Provider servisleri yüklenemedi: \(error)")
        }
    }

    private func fetchGalleryImages() async {
        let folderRef = Storage.storage().reference()
            .child("service_images/\(service.serviceId)")

        do {
            let result = try await folderRef.listAll()
            var urls: [URL] = []
            for item in result.items {
                if let url = try? await item.downloadURL() {
                    urls.append(url)
                }
            }
            galleryURLs = urls

            if coverImageURL == nil, let first = urls.first {
                coverImageURL = first
            }
        } catch {
            print("📷 Galeri yüklenemedi: \(error.localizedDescription)")
        }
    }

    private func loadCoverImage() {
        let folderRef = Storage.storage().reference()
            .child("service_images/\(service.serviceId)")

        folderRef.list(maxResults: 1) { [weak self] result, error in
            guard let item = result?.items.first else { return }
            item.downloadURL { [weak self] url, _ in
                guard let url else { return }
                DispatchQueue.main.async {
                    self?.coverImageURL = url
                }
            }
        }
    }

    private func resolveAddress() async {
        guard let geo = service.locationGeo else {
            addressText = service.city
            return
        }

        let location = CLLocation(latitude: geo.latitude, longitude: geo.longitude)

        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let pm = placemarks.first {
                let parts = [
                    pm.subLocality,
                    pm.postalCode,
                    pm.subAdministrativeArea.map { "\($0)" },
                    pm.administrativeArea
                ].compactMap { $0 }
                addressText = parts.isEmpty ? service.city : parts.joined(separator: ", ")
            } else {
                addressText = service.city
            }
        } catch {
            addressText = service.city
        }
    }
}
