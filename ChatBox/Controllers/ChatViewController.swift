//
//  ChatViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 28/09/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType{
    var sender: MessageKit.SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKit.MessageKind
}
struct Sender: SenderType{
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public let otherUserEmail: String
    public var isNewConversation = false

    var messages = [Message]()
    var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            
            return nil
        }
        return Sender(photoURL: "",
               senderId: email,
               displayName: "Haru")
    }
    
    
    init(with email:String){
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageId = createMessageId() else{
            return
        }
        
        print("sent message: \(text)")
        
        // send message
        if isNewConversation{
            // create new convo in database
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, completion: { [weak self] isSuccess in
                
                if isSuccess{
                    print("sent message")
                }else{
                    print("failed to send message")
                }
                
                
            })
        }else{
            // append to existing convo 
        }
    }
    
    func createMessageId() -> String?{
        // Data, otherUserEmail, SenderEmail, RandomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            
            return nil
        }
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        
        let newIdentifier = "\(otherUserEmail)_\(currentUserEmail)_\(dateString)"
        print("Created messageId: \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender{
            return sender
        }
        fatalError("self sender is nil. email should be cached")
        return Sender(photoURL: "", senderId: "1234", displayName: "lnc")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
