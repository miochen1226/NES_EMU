//
//  NES_EMUApp.swift
//  Shared
//
//  Created by mio on 2021/8/6.
//

import SwiftUI

@main
struct NES_EMUApp: App {
    
    func onBackground()
    {
        nes.stop()
    }
    //let nes = Nes.init()
    init() {
        //nes.loadRom()
        //Cartridge.init().loadFile()
        
        
        
        //NotificationCenter.default.addObserver()
        //    .onReceive(NotificationCenter.default.publisher(for:  NSApplication.willTerminateNotification), perform: { output in
        //    nes.stop()
        //})
        
    }
    
    var body: some Scene {
        WindowGroup
        {
            
#if os(iOS)
            ContentView()
#else
            ContentView().onReceive(NotificationCenter.default.publisher(for:  NSApplication.willTerminateNotification/*willTerminateNotification*/), perform: { output in
                
                handleQuit()
            })
#endif
            
        }
    }
    
    func handleQuit()
    {
        nes.stop()
    }
}
