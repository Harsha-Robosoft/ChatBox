//
//  ChatModel.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 09/10/23.
//

import Foundation
import MessageKit

struct Message: MessageType{
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}
extension MessageKind{
    var messageKindString: String{
        switch self{
        case .text(_):
            return "test"
        case .attributedText(_):
            return "attributed_test"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}
struct Sender: SenderType{
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}
struct Media: MediaItem{
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}
