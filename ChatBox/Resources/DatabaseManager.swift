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
    
    enum DataBaseErrors: Error{
        case unableToFetchAllUser
        case unableToFetchData
    }
    
}

//MARK: - This is to get user first and last name when user sign in with fire base to save it to user defaults

extension DatabaseManager{
    
    public func getDataFor(path: String, completion: @escaping ((Result<Any, Error>) -> Void)){
        self.database.child(path).observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else{
                completion(.failure(DataBaseErrors.unableToFetchData))
                return
            }
            completion(.success(value))
        })
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
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentUserName = UserDefaults.standard.value(forKey: "name") as? String else {
                  
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let ref = database.child(safeEmail)
        
        ref.observeSingleEvent(of: .value, with: { [weak self] snapShot in
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
            
            let newConversation: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversation: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentUserName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            //MARK: - Update recipient conversation entry
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snap in
                if var conversations = snap.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversation)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversationId)
                }else{
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversation])
                    
                }
            })
            
            
            //MARK: -  Update current user conversation entry
            if var conversation = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user you should append
                conversation.append(newConversation)
                
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
                    newConversation
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
            "is_read": false,
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
    public func getAllTheConversations(for email: String, completion: @escaping ((Result<[Conversation], Error>) -> Void)){
        database.child("\(email)/conversations").observe(.value, with: { snapShot in
            guard let value = snapShot.value as? [[String: Any]] else{
                completion(.failure(DataBaseErrors.unableToFetchAllUser))
                return
            }
                        
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRed = latestMessage["is_read"] as? Bool else{
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRed: isRed)
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        })
    }
    
    /// Gets all the messages for given conversation
    public func getAllTheMessagesForConversations(with email: String, completion: @escaping ((Result<[Message], Error>) -> Void)){
        database.child("\(email)/messages").observe(.value, with: { snapShot in
            guard let value = snapShot.value as? [[String: Any]] else{
                completion(.failure(DataBaseErrors.unableToFetchAllUser))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let messageId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let content = dictionary["content"] as? String,
                      let date = dictionary["date"] as? String,
//                      let type = dictionary["type"] as? String,
//                      let isRed = dictionary["is_read"] as? Bool,
                      let dateString = ChatViewController.dateFormatter.date(from: date) else{
                    return nil
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageId,
                               sentDate: dateString,
                               kind: .text(content))
                
            })
            completion(.success(messages))
        })
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to_conversation conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping ((Bool) -> Void)){
        // add new message to message
        // update sender latest message
        // update recipient latest message
        
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(email: myEmail)
        
        
        
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snap in
            guard var currentMessage = snap.value as? [[String: Any]] else{
                completion(false)
                return
            }
            
            
            var message = ""
            switch newMessage.kind{
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
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
        
            currentMessage.append(newMessageEntry)
            self?.database.child("\(conversation)/messages").setValue(currentMessage, withCompletionBlock: { [weak self] error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                
                self?.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self] snapShot in
                    guard var currentUserConversation = snapShot.value as? [[String: Any]] else{
                        completion(false)
                        return
                    }
                    
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    var targetConversation: [String: Any]?
                    var position = 0
                    
                    for conversationDictionary in currentUserConversation{
                        if let currentId = conversationDictionary["id"] as? String,
                           currentId == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else{
                        completion(false)
                        return
                    }
                    currentUserConversation[position] = finalConversation
                    
                    self?.database.child("\(currentEmail)/conversations").setValue(currentUserConversation, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        //MARK: - update the latest message for recipient user
                        //
                        
//                        self?.updateTindata(otherUserEmail: otherUserEmail,
//                                            dateString: dateString,
//                                            message: message,
//                                            conversation: conversation,
//                                            completion: completion)
                        
                        self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self] snapShot in
                            guard var otherUserConversation = snapShot.value as? [[String: Any]] else{
                                completion(false)
                                return
                            }


                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            var targetConversation: [String: Any]?
                            var position = 0

                            for conversationDictionary in otherUserConversation{
                                if let currentId = conversationDictionary["id"] as? String,
                                   currentId == conversation {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }

                            targetConversation?["latest_message"] = updatedValue
                            guard let finalConversation = targetConversation else{
                                completion(false)
                                return
                            }
                            otherUserConversation[position] = finalConversation

                            self?.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversation, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }

                                completion(true)
                            })
                        })
                        //
//                        completion(true)
                    })
                })
            })
        })
    }
    
    
    
//    func updateTindata(otherUserEmail: String, dateString: String, message: String, conversation: String, completion: @escaping ((Bool) -> Void)){
//        self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self] snapShot in
//            guard var otherUserConversation = snapShot.value as? [[String: Any]] else{
//                completion(false)
//                return
//            }
//
//
//            let updatedValue: [String: Any] = [
//                "date": dateString,
//                "is_read": false,
//                "message": message
//            ]
//            var targetConversation: [String: Any]?
//            var position = 0
//
//            for conversationDictionary in otherUserConversation{
//                if let currentId = conversationDictionary["id"] as? String,
//                   currentId == conversation {
//                    targetConversation = conversationDictionary
//                    break
//                }
//                position += 1
//            }
//
//            targetConversation?["latest_message"] = updatedValue
//            guard let finalConversation = targetConversation else{
//                completion(false)
//                return
//            }
//            otherUserConversation[position] = finalConversation
//
//            self?.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversation, withCompletionBlock: { error, _ in
//                guard error == nil else {
//                    completion(false)
//                    return
//                }
//
//                completion(true)
//            })
//        })
//    }
    
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
