//
//  StorageManager.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 28/09/23.
//

import Foundation
import FirebaseStorage

final class StorageManager{
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    private init(){ }
    
    
    /*
     
     filename sample
     /image/'user safe email'_profile_picture.png
     
     */
    
    
    // i don't have any idea what the heck is this
    public typealias uploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// uploads picture to firebase and return completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion) {
        storage.child("image/\(fileName)").putData(data, completion: { metadata, error in
            guard error == nil else {
                print(StorageError.failedToUpload)
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("image/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url, error == nil else {
                    print(StorageError.failedToGetDownloadURL)
                    completion(.failure(StorageError.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("downloaded url return: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    
    public enum StorageError: Error{
        case failedToUpload, failedToGetDownloadURL
    }
    
}
