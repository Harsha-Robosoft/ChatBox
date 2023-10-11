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
     image/'user safe email'_profile_picture.png
     
     */
    
    
    // i don't have any idea what the heck is this
    public typealias uploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// uploads picture to firebase and return completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, completion: { [weak self] metadata, error in
            guard error == nil else {
                print(StorageError.failedToUpload)
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self?.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
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
    
    
    ///  upload image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, completion: { [weak self] metadata, error in
            guard error == nil else {
                print(StorageError.failedToUpload)
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
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
    
    
    ///  upload video that will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping uploadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, completion: { [weak self] metadata, error in
            guard error == nil else {
                print(StorageError.failedToUpload)
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
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
    
    func downloadImageURLForProfile(for path: String, completion: @escaping((Result<URL, Error>) -> Void)){
        
        let reference = storage.child(path)
        print(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                print("090",error)
                completion(.failure(StorageError.failedToGetDownloadURL))
                return
            }
            completion(.success(url))
        })
    }
    
}
