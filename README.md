# NES_EMU
Practice implement NES emu with swift ,  just for fun

# Ref
- https://github.com/amaiorano/nes-emu
- NES 模拟器开发教程 14 - APU 方波(https://www.jianshu.com/p/43498c487ce8 )
  
# Change log

## 10/13/2023
- 1.Support Save/Load state to file for Osx version 
  >key '1' for save, '2' for load).
  >File path /Users/mio/Library/Containers/com.mio.NES-EMU/Data/Documents/nesSave.json

## 10/10/2023
- 1.Support Mapper1.
- 2.Fix apu bugs
  > <img src="https://raw.githubusercontent.com/miochen1226/NES_EMU/master/Image/SnapShot/IMG_8586.PNG">
  > <img src="https://raw.githubusercontent.com/miochen1226/NES_EMU/master/Image/SnapShot/IMG_8587.PNG">
  > <img src="https://raw.githubusercontent.com/miochen1226/NES_EMU/master/Image/SnapShot/IMG_8588.PNG">



## 8/11/2023
- 1.Support Mapper4.
- 2.Add Virtual Game Controller for iOS
- 3.[Hack] change sprite limit per line from 8 to 64 
  > <img src="https://raw.githubusercontent.com/miochen1226/NES_EMU/master/Image/SnapShot/2023-08-11.png">
    <a href="https://www.youtube.com/watch?v=kpTZFsyE5VQ">Demo video</a>
## 7/27/2023
-  1.correct pulseWave implementation
-  2.Add keyboard control for OSX
    - "a": Left
    - "d": Right
    - "s": Down
    - "w": Up
    - "o": A
    - "p": B
    - "n": Select
    - "m": Start
## 7/24/2023
- 1.Support display for ios.
  > <img src="https://raw.githubusercontent.com/miochen1226/NES_EMU/master/Image//SnapShot/F1666584-9E5B-4A69-B5C9-2DFF10E65850.jpg">
  > <img src="https://raw.githubusercontent.com/miochen1226/NES_EMU/master/Image//SnapShot/2023-06-25.png">
