//
//  MyWesApp.swift
//  MyWes
//
//  Created by Edomias Abebe on 8/10/26.
//

import SwiftUI

@main
struct MyWesApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
