//
//  OnboardingData.swift
//  Lookals
//
//  Created by Gisella Jayata on 13/07/26.
//


import Foundation
import CloudKit
import Combine

// 1. Keranjang Sementara (Shared State)
class OnboardingData: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var interests: [String] = []
    @Published var personality: String = ""
}

// 2. CloudKit Manager
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    private let database = CKContainer.default().privateCloudDatabase
    
    // Data profil yang berhasil di-fetch akan disimpan di sini
    @Published var fetchedName: String = ""
    @Published var fetchedPersonality: String = ""
    @Published var fetchedInterests: [String] = []
    
    // Fungsi SAVE
    func saveUserProfile(data: OnboardingData, completion: @escaping (Bool) -> Void) {
        let record = CKRecord(recordType: "UserProfile")
        record["fullName"] = data.fullName as CKRecordValue
        record["email"] = data.email as CKRecordValue
        record["personality"] = data.personality as CKRecordValue
        record["interests"] = data.interests as CKRecordValue
        
        database.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving to CloudKit: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Data saved successfully!")
                    completion(true)
                }
            }
        }
    }
    
    // Fungsi FETCH (Untuk halaman Profile)
    func fetchUserProfile() {
        // Query untuk mengambil data tipe "UserProfile"
        let query = CKQuery(recordType: "UserProfile", predicate: NSPredicate(value: true))
        
        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { result in
            switch result {
            case .success(let matchResults):
                // Ambil record pertama yang ditemukan
                if let match = matchResults.matchResults.first,
                   let record = try? match.1.get() {
                    
                    DispatchQueue.main.async {
                        self.fetchedName = record["fullName"] as? String ?? "Unknown"
                        self.fetchedPersonality = record["personality"] as? String ?? "Unknown"
                        self.fetchedInterests = record["interests"] as? [String] ?? []
                    }
                }
            case .failure(let error):
                print("Error fetching from CloudKit: \(error.localizedDescription)")
            }
        }
    }
}