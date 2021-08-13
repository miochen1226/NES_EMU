//
//  ContentView.swift
//  Shared
//
//  Created by mio on 2021/8/6.
//

import SwiftUI


struct ContentView: View {
    @State var timer = Timer.publish (every: 0.1, on: .current, in: .common).autoconnect()
    var body: some View {
        Text("Hello, world!")
            .padding()
        
        MyImageView().frame(width: 256, height: 240).border(Color.purple, width: 0).onReceive(timer) { input in
            NSLog("timer")
            DataHolder.shared.chartView?.step()
        }
        //Image("ui-icons-fbdb93-256x240").frame(width: 256, height: 240).border(Color.purple, width: 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
