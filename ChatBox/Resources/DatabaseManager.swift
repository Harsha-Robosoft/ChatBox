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
    
    static func safeEmail(email: String) -> String{
        let safeEmail = email.replacingOccurrences(of: ".", with: "-")
        return safeEmail
    }
    
}

//MARK: - User registration

extension DatabaseManager{
    
    public func userExits(with email: String, completion: @escaping((Bool) -> Void)){
        
        let safeEmail = email.replacingOccurrences(of: ".", with: "-")
        
        print(safeEmail)
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            completion(true)
        })
        
    }
    
    
    /// new user is added to databse
    public func insertUser(with user: ChatAppUser, completion: @escaping((Bool) -> Void)){
        
        print(user.safeEmail)
        
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else{
                print("Failed to write to database")
                completion(false)
                return
            }
            
            /*
             basically what we are doing here is we are creating a 'users' array in firebase database which can hold all the logged in user detail for performing SEARCH OPERATION to start a new conversation so for this searching we are using this 'users' array
             
             reference structure of thus 'users' is as below
             
             users => [
             [
             "name":
             "safe_email":
             ],
             [
             "name":
             "safe_email":
             ]
             ]
             
             
             */
            self.database.child("users").observeSingleEvent(of: .value, with: { snapShot in
                if var userCollection = snapShot.value as? [[String: String]] {
                    // append to user dictionary
                    
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    userCollection.append(newElement)
                    self.database.child("users").setValue(userCollection, withCompletionBlock: { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }else{
                    // create the user array
                    let newCollection: [[String: String]] =  [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
        })
    }
    
    public func fetchAllUser(completion: @escaping((Result<[[String: String]], Error>) -> Void)){
        database.child("users").observeSingleEvent(of: .value, with: { snapShot in
            guard let value = snapShot.value as? [[String: String]] else{
                completion(.failure(DataBaseErrors.unableToFetchAllUser))
                return
            }
            completion(.success(value))
        })
    }
    
    
    enum DataBaseErrors: Error{
        case unableToFetchAllUser
    }
    
}


//MARK: - Sending messages / Conversation

extension DatabaseManager{
    
    /*
     
     "some id" {
     "messages": [
     {
     "id": string
     "type": text, video, image
     "content": string
     "date": date()
     "sender_email": string
     "isRed": true/false
     }
     ]
     }
     
     
     
     
     conversation => [
     [
     "conversation_id": "some id"
     "other_user_email": "email"
     "latest_message" => [
     "date": "date"
     "latest_message": "message"
     "isRed": true/false
     ]
     ]
     ]
     */
    
    
    
    /// create a new conversation with target user email and first message
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping ((Bool) -> Void)){
        
    }
    
    /// fetches and returns all the conversation for the user with passed in email
    public func getAllTheConversations(for email: String, completion: @escaping ((Result<String, Error>) -> Void)){
        
    }
    
    /// Gets all the messages for given conversation
    public func getAllTheMessagesForConversations(with email: String, completion: @escaping ((Result<String, Error>) -> Void)){
        
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping ((Bool) -> Void)){
        
    }
    
}


struct ChatAppUser{
    let firstName: String
    let lastName: String
    let email: String
    //    let imageUrl: String
    
    var safeEmail: String{
        let safeEmail = email.replacingOccurrences(of: ".", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String{
        return "\(safeEmail)_profile_picture.png" 
    }
    
    
}
