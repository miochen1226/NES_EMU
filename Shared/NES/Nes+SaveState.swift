//
//  Nes+SaveState.swift
//  NES_EMU
//
//  Created by mio on 2023/10/13.
//

import Foundation

class StateSave : Codable {
    var cpu:Cpu!
    var ppu:Ppu!
    var cpuInternalRam:CpuInternalRam!
    var cartridge:Cartridge!
    
    init(cpu: Cpu, ppu: Ppu, cpuInternalRam: CpuInternalRam, cartridge: Cartridge) {
        self.cpu = cpu
        self.ppu = ppu
        self.cpuInternalRam = cpuInternalRam
        self.cartridge = cartridge
    }
    
    enum CodingKeys: String, CodingKey {
        case cpu
        case ppu
        case cpuInternalRam
        case cartridge
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cpu = try values.decode(Cpu.self, forKey: .cpu)
        ppu = try values.decode(Ppu.self, forKey: .ppu)
        cpuInternalRam = try values.decode(CpuInternalRam.self, forKey: .cpuInternalRam)
        cartridge = try values.decode(Cartridge.self, forKey: .cartridge)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cpu, forKey: .cpu)
        try container.encode(ppu, forKey: .ppu)
        try container.encode(cpuInternalRam, forKey: .cpuInternalRam)
        try container.encode(cartridge, forKey: .cartridge)
    }
}

//Save/Load state
extension Nes {
    func saveState() {
        stop()
        saveStateFile()
        start()
    }
    
    func loadState() {
        stop()
        loadFromFile()
        start()
    }
    
    func saveStateFile(){
        let cpu = self.cpu as! Cpu
        let ppu = self.ppu as! Ppu
        let stateSave = StateSave.init(cpu: cpu, ppu: ppu,cpuInternalRam: self.cpuInternalRam, cartridge: self.cartridge)
        let jsonData = try? JSONEncoder().encode(stateSave)
        saveToFile(data: jsonData)
    }
    
    func getSavedURL() -> URL? {
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask).first {
            let pathWithFilename = documentDirectory.appendingPathComponent("nesSave.json")
            return pathWithFilename
        }
        
        return nil
    }
    
    func loadFromFile() {
        if let saveUrl = getSavedURL() {
            do {
                let data = try Data(contentsOf: saveUrl, options: .mappedIfSafe)
                if let stateSave = try? JSONDecoder().decode(StateSave.self, from: data) {
                    loadState(stateSave: stateSave)
                }
            }
            catch {
               // handle error
            }
        }
    }
    
    func saveToFile(data:Data?) {
        if let saveUrl = getSavedURL() {
            do {
                try data?.write(to: saveUrl)
            }
            catch {
                // handle error
            }
        }
    }
    
    func loadState(stateSave:StateSave) {
        cpu = stateSave.cpu
        ppu = stateSave.ppu
        cpuInternalRam = stateSave.cpuInternalRam
        cartridge.mapper = stateSave.cartridge.mapper
        cartridge.savBanks = stateSave.cartridge.savBanks
        
        cpu.setApu(apu: apu)
        cpu.setControllerPorts(controllerPorts: controllerPorts)
        cpu.initialize(cpuMemoryBus: cpuMemoryBus)
        ppu.initialize(ppuMemoryBus: ppuMemoryBus, nes: self,renderer: renderer)
        
        cpuMemoryBus.initialize(cpu: cpu, ppu: ppu, cartridge: cartridge,cpuInternalRam: cpuInternalRam)
        ppuMemoryBus.initialize(ppu: ppu, cartridge: cartridge)
    }
    
    
    
    /*
    func saveStateFile(url:URL) {
        stop()
        let stateSave = StateSave.init(cpu: self.cpu, ppu: self.ppu,cpuInternalRam: self.cpuInternalRam, cartridge: self.cartridge)
        let jsonData = try? JSONEncoder().encode(stateSave)
        let filePath = url.appendingPathComponent("StateSave.json")

        do {
         try jsonData?.write(to: filePath)
        } catch {
         print("Error writing to JSON file: \(error)")
        }
        start()
    }
    func openFolder() {
        let openPanel = NSOpenPanel()       // Authorize access in sandboxed mode
        openPanel.message = NSLocalizedString("Select folder where to create file\n(Necessary to manage security on this computer)", comment: "enableFileMenuItems")
        openPanel.prompt = NSLocalizedString("Select", comment: "enableFileMenuItems")
        openPanel.canChooseFiles = false    // Only select or create Directory here ; you can select the real Desktop
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.begin() {                              // In the completion, Save the file
            (result2) -> Void in
            if result2 == NSApplication.ModalResponse.OK {
                let savePanel = NSSavePanel()
                savePanel.title = NSLocalizedString("File to create", comment: "enableFileMenuItems")
                savePanel.nameFieldStringValue = ""
                savePanel.prompt = NSLocalizedString("Create", comment: "enableFileMenuItems")
                savePanel.allowedFileTypes = ["json"]   // if you want to specify file signature
                let fileManager = FileManager.default
        
                savePanel.begin() { (result) -> Void in
                    if result == NSApplication.ModalResponse.OK {
                        let fileWithExtensionURL = savePanel.url!  //  May test that file does not exist already
                        if fileManager.fileExists(atPath: fileWithExtensionURL.path) {
                        }
                        else {
                            // Now, write the file
                            self.saveStateFile(url: openPanel.url!)
                        }
                    }
                }
            }
        }
    }
    */
}
