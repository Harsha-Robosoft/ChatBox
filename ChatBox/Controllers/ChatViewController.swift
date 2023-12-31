//
//  ChatViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 28/09/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit


final class ChatViewController: MessagesViewController {
    
    private var senderProfileUrl: URL?
    private var otherUserProfileUrl: URL?
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public let otherUserEmail: String
    private var conversationId: String?
    public var isNewConversation = false

    var messages = [Message]()
    var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        return Sender(photoURL: "",
               senderId: safeEmail,
               displayName: "Me")
    }
    
    
    init(with email:String, id: String?){
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId{
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
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
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    private func setupInputButton(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside({ [weak self] _ in
            self?.presentActionSheet()
        })
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentActionSheet(){
        let ac = UIAlertController(title: "Attach media.",
                                   message: "What would like to attach?",
                                   preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        ac.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        ac.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in

        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    private func presentPhotoInputActionSheet(){
        let ac = UIAlertController(title: "Attach photo.",
                                   message: "Where would you like to attach a photo from?",
                                   preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        ac.addAction(UIAlertAction(title: "Photo library", style: .default, handler: { [weak self] _ in

            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    private func presentVideoInputActionSheet(){
        let ac = UIAlertController(title: "Attach video.",
                                   message: "Where would you like to attach a video from?",
                                   preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeLow
            self?.present(picker, animated: true)
            
        }))
        ac.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in

            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeLow
            self?.present(picker, animated: true)
            
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool){
        DatabaseManager.shared.getAllTheMessagesForConversations(with: id, completion: { [weak self] result in
            switch result{
            case .success(let messages):
                guard !messages.isEmpty else{
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom{
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("failed fetch the message for conversation: \(error)")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let messageId = createMessageId(),
        let conversationId = conversationId,
        let name = title,
        let selfSender = selfSender else{
            picker.dismiss(animated: true)
            return
        }
        
        if let image = info[.editedImage] as? UIImage,
           let imageData = image.pngData(){
            // this is for Uploading image
            let fileName = "photo_message_"+messageId.replacingOccurrences(of: " ", with: "-")+".png"
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result{
                case .success(let urlString):
                    // Ready to send image
                    print("uploaded message photo URL: \(urlString)")
                    guard let url = URL(string: urlString),
                          let placeHolder = UIImage(systemName: "plus") else {
                        return
                    }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    DatabaseManager.shared.sendMessage(to_conversation: conversationId,
                                                       otherUserEmail: strongSelf.otherUserEmail,
                                                       name: name,
                                                       newMessage: message,
                                                       completion: { success in
                        if success{
                            print("sent photo message")
                        }else{
                            print("error while sending photo message")
                        }
                    })
                    
                case .failure(let error):
                    print("unable to get url with error: \(error)")
                }
            })
        }
        else if let videoUrl = info[.mediaURL] as? URL{
            // this is for uploading video
            let fileName = "photo_message_"+messageId.replacingOccurrences(of: " ", with: "-")+".mov"
            
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result{
                case .success(let urlString):
                    // Ready to send image
                    print("uploaded message video URL: \(urlString)")
                    guard let url = URL(string: urlString),
                          let placeHolder = UIImage(systemName: "plus") else {
                        return
                    }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    DatabaseManager.shared.sendMessage(to_conversation: conversationId,
                                                       otherUserEmail: strongSelf.otherUserEmail,
                                                       name: name,
                                                       newMessage: message,
                                                       completion: { success in
                        if success{
                            print("sent photo message")
                        }else{
                            print("error while sending photo message")
                        }
                    })
                    
                case .failure(let error):
                    print("unable to get url with error: \(error)")
                }
            })
            
            
        }
        
        
        
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = selfSender,
        let messageId = createMessageId() else{
            return
        }
        
        print("sent message: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        // send message
        if isNewConversation{
            // create new convo in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: title ?? "user", firstMessage: message, completion: { [weak self] isSuccess in
                
                if isSuccess{
                    print("sent message")
                    self?.isNewConversation = false
//                    let conversationId = "conversation_\(firstMessage.messageId)"
                    let newConversationId = "conversation_\(message.messageId)"
                    self?.conversationId = newConversationId
                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                }else{
                    self?.messageInputBar.inputTextView.text = nil
                    self?.showAlert(aleartString: "Unable to send message please try again.")
                    print("failed to send message")
                }
            })
        }else{
            // append to existing convo
            guard let conversation = conversationId,
                  let name = title else {
                return
            }
            DatabaseManager.shared.sendMessage(to_conversation: conversation, otherUserEmail: otherUserEmail,name: name, newMessage: message, completion: { [weak self] success in
                if success{
                    self?.messageInputBar.inputTextView.text = nil
                    print("continuous message sent")
                }else{
                    print("failed to send continuous message")
                    
                    
                }
            })
        }
    }
    
    func createMessageId() -> String?{
        // Data, otherUserEmail, SenderEmail, RandomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            
            return nil
        }
        
        let safeCurrentUserEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentUserEmail)_\(dateString)"
        print("Created messageId: \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate{
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender{
            return sender
        }
        fatalError("self sender is nil. email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else{
            return
        }
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            imageView.sd_setImage(with: imageUrl)
        
        case .text(_):
            break
        case .attributedText(_):
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
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        let message = messages[indexPath.section]
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
        
        case .text(_):
            break
        case .attributedText(_):
            break
        case .video(let media):
            guard let videoUrl = media.url else{
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
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
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId{
            // our sent message
            return .link
        }else{
            // received message
            return .gray
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId{
            // our image
            if let currentUserUrl = senderProfileUrl{
                avatarView.sd_setImage(with: currentUserUrl)
            }else{
                
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(email: email)
                
                let path = "images/\(safeEmail)_profile_picture.png"
                
                // Fetch url
                StorageManager.shared.downloadImageURLForProfile(for: path, completion: { [weak self] result in
                    switch result{
                        
                    case .success(let url):
                        self?.senderProfileUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print("error to fetch current user image url: \(error)")
                    }
                })
            }
        }else{
            // other user image
            if let otherUserUrl = otherUserProfileUrl{
                avatarView.sd_setImage(with: otherUserUrl)
            }else{
                let email = otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(email: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                // Fetch url
                StorageManager.shared.downloadImageURLForProfile(for: path, completion: { [weak self] result in
                    switch result{
                    case .success(let url):
                        self?.otherUserProfileUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print("error to fetch other user profile image url: \(error)")
                    }
                })
                
            }
        }
    }
}
