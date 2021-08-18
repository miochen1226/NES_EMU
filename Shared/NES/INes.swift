//
//  INes.swift
//  NES_EMU
//
//  Created by mio on 2021/8/15.
//

import Foundation
protocol INes {
    func SignalCpuNmi()
    func SignalCpuIrq()
    func GetNameTableMirroring()->RomHeader.NameTableMirroring
    func HACK_OnScanline()
}
