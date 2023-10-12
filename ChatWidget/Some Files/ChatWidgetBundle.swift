//
//  ChatWidgetBundle.swift
//  ChatWidget
//
//  Created by Harsha R Mundaragi  on 12/10/23.
//

import WidgetKit
import SwiftUI

@main
struct ChatWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChatWidget()
        ChatWidgetLiveActivity()
    }
}
