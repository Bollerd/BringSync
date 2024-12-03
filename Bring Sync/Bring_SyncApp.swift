//
//  Bring_SyncApp.swift
//  Bring Sync
//
//  Created by Dirk Boller on 07.03.24.
//

import SwiftUI

@main
struct Bring_SyncApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(Model())
        }
    }
}
