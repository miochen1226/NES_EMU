//
//  PpuControl2.swift
//  NES_EMU
//
//  Created by mio on 2021/8/10.
//

import Foundation

class PpuMask {
    static let DisplayType                 = BIT(0) // 0 = Color, 1 = Monochrome
    static let BackgroundShowLeft8         = BIT(1) // 0 = BG invisible in left 8-pixel column, 1 = No clipping
    static let SpritesShowLeft8            = BIT(2) // 0 = Sprites invisible in left 8-pixel column, 1 = No clipping
    static let RenderBackground            = BIT(3) // 0 = Background not displayed, 1 = Background visible
    static let RenderSprites               = BIT(4) // 0 = Sprites not displayed, 1 = Sprites visible
    static let ColorIntensityMask          = BIT(5)|BIT(6)|BIT(7) // High 3 bits if DisplayType == 0
    static let FullBackgroundColorMask     = BIT(5)|BIT(6)|BIT(7) // High 3 bits if DisplayType == 1
}
