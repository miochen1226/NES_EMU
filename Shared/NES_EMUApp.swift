//
//  NES_EMUApp.swift
//  Shared
//
//  Created by mio on 2021/8/6.
//

import SwiftUI

@main
struct NES_EMUApp: App {
    init() {
        Cartridge.init().loadFile()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
