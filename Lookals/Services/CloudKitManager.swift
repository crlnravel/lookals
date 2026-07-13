import Foundation
import CloudKit
import Combine
import SwiftUI

// MARK: - Keranjang Data Onboarding
class OnboardingData: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var interests: [String] = []
    @Published var personality: String = ""
}

// MARK: - CloudKit Manager Utama
class CloudKitManager: ObservableObject {
    // Singleton agar bisa diakses dari file mana saja dengan .shared
    static let shared = CloudKitManager()
    
    // Akses ke Private Database
    private let database = CKContainer(identifier: "iCloud.com.gisel.Lookals").privateCloudDatabase
    
    // State untuk menampung data yang di-fetch (diambil) dari iCloud
    @Published var fetchedName: String = ""
    @Published var fetchedPersonality: String = ""
    @Published var fetchedInterests: [String] = []
    @Published var fetchedProfileImageData: Data? = nil
    
    // MARK: 1. Fungsi SAVE (Untuk Halaman Onboarding / Sign In)
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
    
    // MARK: 2. Fungsi FETCH (Untuk melihat halaman Profile)
    func fetchUserProfile() {
        let query = CKQuery(recordType: "UserProfile", predicate: NSPredicate(value: true))
        
        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { [weak self] result in
            switch result {
            case .success(let matchResults):
                if let match = matchResults.matchResults.first,
                   let record = try? match.1.get() {
                    
                    DispatchQueue.main.async {
                        self?.fetchedName = record["fullName"] as? String ?? "Unknown"
                        self?.fetchedPersonality = record["personality"] as? String ?? "Unknown"
                        self?.fetchedInterests = record["interests"] as? [String] ?? []
                        
                        // Coba ambil foto jika ada
                        if let asset = record["profileImage"] as? CKAsset, let fileURL = asset.fileURL {
                            self?.fetchedProfileImageData = try? Data(contentsOf: fileURL)
                        }
                    }
                }
            case .failure(let error):
                print("Error fetching from CloudKit: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: 3. Fungsi UPDATE (Untuk halaman Edit Profile)
    func updateUserProfile(name: String, personality: String, interests: [String], imageData: Data?, completion: @escaping (Bool) -> Void) {
        let query = CKQuery(recordType: "UserProfile", predicate: NSPredicate(value: true))
        
        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { [weak self] result in
            switch result {
            case .success(let matchResults):
                guard let match = matchResults.matchResults.first,
                      let existingRecord = try? match.1.get() else {
                    
                    // Jika data belum ada, buat baru
                    self?.createNewRecord(name: name, personality: personality, interests: interests, imageData: imageData, completion: completion)
                    return
                }
                
                // Timpa data lama
                existingRecord["fullName"] = name as CKRecordValue
                existingRecord["personality"] = personality as CKRecordValue
                existingRecord["interests"] = interests as CKRecordValue
                
                // Handle Foto (Ubah Data jadi CKAsset)
                if let data = imageData, let asset = self?.createAsset(from: data) {
                    existingRecord["profileImage"] = asset
                }
                
                // Simpan perubahan
                self?.database.save(existingRecord) { _, error in
                    DispatchQueue.main.async {
                        completion(error == nil)
                    }
                }
                
            case .failure(let error):
                print("Fetch Error during update: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
            }
        }
    }
    
    // MARK: - Helpers untuk Foto (CKAsset)
    private func createAsset(from data: Data) -> CKAsset? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        
        do {
            try data.write(to: fileURL)
            return CKAsset(fileURL: fileURL)
        } catch {
            print("Gagal membuat Asset gambar: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func createNewRecord(name: String, personality: String, interests: [String], imageData: Data?, completion: @escaping (Bool) -> Void) {
        let newRecord = CKRecord(recordType: "UserProfile")
        newRecord["fullName"] = name as CKRecordValue
        newRecord["personality"] = personality as CKRecordValue
        newRecord["interests"] = interests as CKRecordValue
        
        if let data = imageData, let asset = createAsset(from: data) {
            newRecord["profileImage"] = asset
        }
        
        database.save(newRecord) { _, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
}
