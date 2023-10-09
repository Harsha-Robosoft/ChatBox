//
//  ProfileModel.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 09/10/23.
//

import Foundation

enum ProfileViewModelType{
    case info, logout
}

struct ProfileViewModel{
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> ())?
}
