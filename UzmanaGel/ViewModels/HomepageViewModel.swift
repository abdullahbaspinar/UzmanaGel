//
//  HomepageViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 5.02.2026.
//

import Foundation

@MainActor
final class HomepageViewModel: ObservableObject {

    @Published var selectedLocation: String = "Ataşehir, İstanbul"
    @Published var services: [Service] = [
        .init(id: "1", title: "Kombi & Klima", subtitle: "Yıllık bakım ve hızlı onarım", city: "İstanbul", rating: 4.1, providerName: "BYMK Kombi", priceTL: 500, imageName: "service1"),
        .init(id: "2", title: "Boya & Badana", subtitle: "Profesyonel Boya Badana", city: "İstanbul", rating: 4.8, providerName: "Ahmet Usta Boya", priceTL: 1500, imageName: "service2")
    ]
}
