//
//  VirtualConteollerView.swift
//  NES_EMU (iOS)
//
//  Created by mio on 2023/8/9.
//

import SwiftUI

struct VirtualControllerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = GameViewController
    
    func makeUIViewController(context: Self.Context) -> GameViewController
    {
        return GameViewController()
    }
        
    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        
    }
    

}
