//
//  ConversationModel.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 09/10/23.
//

import Foundation

struct Conversation{
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage{
    let date: String
    let text: String
    let isRed: Bool
}
