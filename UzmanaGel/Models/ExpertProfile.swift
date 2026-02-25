import Foundation
import FirebaseFirestore

enum BusinessType: String, Codable, CaseIterable {
    case individual = "sahis"
    case company = "sirket"

    var displayName: String {
        switch self {
        case .individual: return "Şahıs"
        case .company: return "Şirket"
        }
    }
}

enum ApplicationStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
}

struct ExpertProfile: Codable, Identifiable {

    @DocumentID var id: String?

    var displayName: String
    var email: String
    var phoneNumber: String

    var businessName: String
    var serviceCategories: [String]
    var businessType: String
    var taxNumber: String?

    var experienceYears: Int
    var expertiseAreas: [String]
    var certificateURLs: [String]
    var educationLevel: String
    var schoolName: String

    var status: String
    var createdAt: Timestamp?
}

struct ServiceCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String

    static let allCategories: [ServiceCategory] = [
        .init(name: "Temizlik", icon: "sparkles"),
        .init(name: "Tadilat & Renovasyon", icon: "hammer"),
        .init(name: "Boya & Badana", icon: "paintbrush"),
        .init(name: "Tesisatçı", icon: "wrench.and.screwdriver"),
        .init(name: "Elektrikçi", icon: "bolt"),
        .init(name: "Nakliyat", icon: "box.truck"),
        .init(name: "Bahçe Bakım", icon: "leaf"),
        .init(name: "Klima & Kombi", icon: "thermometer.snowflake"),
        .init(name: "Marangoz", icon: "square.stack.3d.up"),
        .init(name: "Çilingir", icon: "key"),
        .init(name: "Güzellik & Bakım", icon: "scissors"),
        .init(name: "Eğitim & Özel Ders", icon: "book"),
        .init(name: "Fotoğraf & Video", icon: "camera"),
        .init(name: "Yazılım & Teknoloji", icon: "desktopcomputer"),
        .init(name: "Sağlık & Terapi", icon: "heart"),
        .init(name: "Hukuk & Danışmanlık", icon: "building.columns"),
        .init(name: "Oto Bakım & Tamir", icon: "car"),
        .init(name: "Veteriner", icon: "pawprint"),
        .init(name: "Organizasyon", icon: "party.popper"),
        .init(name: "Diğer", icon: "ellipsis.circle")
    ]
}

struct ExpertiseArea: Identifiable, Hashable {
    let id = UUID()
    let name: String

    static func areas(for categories: Set<String>) -> [ExpertiseArea] {
        var result: [ExpertiseArea] = []

        let mapping: [String: [String]] = [
            "Temizlik": ["Ev Temizliği", "Ofis Temizliği", "İnşaat Sonrası Temizlik", "Halı Yıkama", "Koltuk Yıkama", "Cam Temizliği"],
            "Tadilat & Renovasyon": ["Mutfak Tadilat", "Banyo Tadilat", "Zemin Kaplama", "Alçıpan", "Seramik Döşeme", "Duvar Yıkım & Yapım"],
            "Boya & Badana": ["İç Cephe Boya", "Dış Cephe Boya", "Dekoratif Boya", "Lake Boya", "Duvar Kağıdı"],
            "Tesisatçı": ["Su Tesisatı", "Kalorifer Tesisatı", "Doğalgaz Tesisatı", "Kanalizasyon", "Petek Temizliği"],
            "Elektrikçi": ["Ev Elektrik", "Endüstriyel Elektrik", "Aydınlatma", "Güvenlik Sistemleri", "Akıllı Ev"],
            "Nakliyat": ["Evden Eve Nakliyat", "Ofis Taşıma", "Şehirler Arası Nakliyat", "Parça Eşya Taşıma", "Depolama"],
            "Bahçe Bakım": ["Çim Biçme", "Budama", "Peyzaj Düzenleme", "Sulama Sistemi", "Zararlı İlaçlama"],
            "Klima & Kombi": ["Klima Montaj", "Klima Bakım", "Kombi Bakım", "Kombi Tamiri", "Merkezi Isıtma"],
            "Marangoz": ["Mobilya Tamiri", "Özel Mobilya", "Kapı & Pencere", "Parke Döşeme", "Mutfak Dolabı"],
            "Çilingir": ["Kapı Açma", "Kilit Değişimi", "Çelik Kapı", "Oto Çilingir", "Kasa Açma"],
            "Güzellik & Bakım": ["Kuaför", "Cilt Bakımı", "Manikür & Pedikür", "Masaj", "Epilasyon"],
            "Eğitim & Özel Ders": ["Matematik", "Fen Bilimleri", "Yabancı Dil", "Müzik", "Sınav Hazırlık"],
            "Fotoğraf & Video": ["Düğün Fotoğraf", "Ürün Çekimi", "Drone Çekim", "Video Düzenleme", "Etkinlik Çekim"],
            "Yazılım & Teknoloji": ["Web Geliştirme", "Mobil Uygulama", "Bilgisayar Tamiri", "Ağ Kurulumu", "Veri Kurtarma"],
            "Sağlık & Terapi": ["Fizyoterapi", "Diyetisyen", "Psikoloji", "Evde Bakım", "Yaşlı Bakım"],
            "Hukuk & Danışmanlık": ["İş Hukuku", "Aile Hukuku", "Gayrimenkul", "Vergi Danışmanlık", "Şirket Kuruluş"],
            "Oto Bakım & Tamir": ["Motor Bakım", "Boya & Kaporta", "Lastik Değişim", "Cam Filmi", "Detaylı Temizlik"],
            "Veteriner": ["Ev Hayvanı Bakım", "Aşılama", "Tıraş & Bakım", "Acil Müdahale"],
            "Organizasyon": ["Düğün Organizasyon", "Doğum Günü", "Kurumsal Etkinlik", "Catering", "Ses & Işık"],
            "Diğer": ["Kurye", "Tercüme", "Özel Şoför", "Ev Tadilat Danışmanlık"]
        ]

        for cat in categories {
            if let areas = mapping[cat] {
                result.append(contentsOf: areas.map { ExpertiseArea(name: $0) })
            }
        }

        if result.isEmpty {
            result = mapping.values.flatMap { $0 }.map { ExpertiseArea(name: $0) }
        }

        return result
    }
}

enum EducationLevel: String, CaseIterable {
    case primary = "İlköğretim"
    case highSchool = "Lise"
    case associate = "Ön Lisans"
    case bachelor = "Lisans"
    case master = "Yüksek Lisans"
    case doctorate = "Doktora"
}
