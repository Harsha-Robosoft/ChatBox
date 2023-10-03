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
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping ((Bool) -> Void)){
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let ref = database.child(safeEmail)
        
        ref.observeSingleEvent(of: .value, with: { snapShot in
            guard var userNode = snapShot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind{
            case .text(let messageTxt):
                message = messageTxt
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            let mewConversation: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_red": false
                ]
            ]
            
            if var conversation = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user you should append
                conversation.append(mewConversation)
                
                userNode["conversations"] = conversation
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationId: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
                
            }else{
                // create new conversation
                userNode["conversations"] = [
                    mewConversation
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationId: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(name: String,conversationId: String, firstMessage: Message, completion: @escaping((Bool) -> Void)){
//        "some id" {
//            "messages": [
//                {
//                    "id": string
//                    "type": text, video, image
//                    "content": string
//                    "date": date()
//                    "sender_email": string
//                    "isRed": true/false
//                }
//            ]
//        }
        
        var message = ""
        switch firstMessage.kind{
        case .text(let messageTxt):
            message = messageTxt
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_red": false,
            "name": name
        ]
        
        let value: [String: Any] =  [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child(conversationId).setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
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
