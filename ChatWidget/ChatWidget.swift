//
//  ChatWidget.swift
//  ChatWidget
//
//  Created by Harsha R Mundaragi  on 12/10/23.
//

import WidgetKit
import SwiftUI

struct ChatWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.date, style: .time)
    }
}

struct ChatWidget: Widget {
    let kind: String = "ChatWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ChatWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct ChatWidget_Previews: PreviewProvider {
    static var previews: some View {
        ChatWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
