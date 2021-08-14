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
        ScreenCanvasView().frame(width: 256, height: 240).border(Color.purple, width: 0).onReceive(timer) { input in
            DataHolder.shared.canvasView?.step()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
