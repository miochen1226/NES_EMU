//
//  NES_EMUApp.swift
//  Shared
//
//  Created by mio on 2021/8/6.
//

import SwiftUI

@main
struct NES_EMUApp: App {
    
    var body: some Scene {
        WindowGroup
        {
#if os(iOS)
            ContentView()
#else
            ContentView().frame(minWidth: 256, minHeight: 240).onReceive(NotificationCenter.default.publisher(for:  NSApplication.willTerminateNotification), perform: { output in
                handleStop()
            }).onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification), perform: { newValue in
                handleStop()
            }).onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification), perform:  { newValue in
                handleResume()
            }).onReceive(NotificationCenter.default.publisher(for: NSWindow.didMiniaturizeNotification), perform:  { newValue in
                handleStop()
            })
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didDeminiaturizeNotification), perform:  { newValue in
                handleResume()
            })
#endif
        }
    }
 
    func handleStop()
    {
        nes.stop()
    }
    
    func handleResume()
    {
        nes.start()
    }
}
