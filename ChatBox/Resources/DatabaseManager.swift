//
//  DatabaseManager.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 26/09/23.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager{
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    private init(){ }
    
}

//MARK: - User registration

extension DatabaseManager{
    
    public func userExits(with email: String, completion: @escaping((Bool) -> Void)){
        
        database.child(email).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            completion(true)
        })
        
       
        
        
    }
    
    
    /// new user is added to databse
    public func insertUser(with user: ChapAppUser){
        database.child(user.email).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
    }
    
}


struct ChapAppUser{
    let firstName: String
    let lastName: String
    let email: String
//    let imageUrl: String
}
