Delta Lite
===========

Delta Lite is a Swift Playground Book that allows you to play classic NES games on your iPad. To accomplish this, it is made up of the following components:

[**DeltaCore**](https://github.com/rileytestut/DeltaCore)  
DeltaCore serves as the “middle-man” between the high-level app code and the specific emulation cores. By working with this framework, you have access to all the core Delta features, such as emulation, controller skins, save states, cheat codes, etc. 

[**NESDeltaCore**](https://github.com/rileytestut/NESDeltaCore)  
NESDeltaCore essentially wraps up the Nestopia emulator into something that can be understood by DeltaCore. Because Swift Playgrounds can only compile Swift code, the Nestopia source code was compiled from C++ to JavaScript via Emscripten, and then Delta Lite runs this JavaScript in a hidden WKWebView.

[**Roxas**](https://github.com/rileytestut/Roxas)    
Roxas is my own framework used across my projects, developed to simplify a variety of common tasks used in iOS development. Unfortunately, it is written in Objective-C, so for Delta Lite I (hastily) converted the most important functionality to Swift files that are included in this repo.

Compilation Instructions
=============
- Clone this repository by running the following command in Terminal:  
```bash
$ git clone git@github.com:rileytestut/DeltaLite.git
```  

- Update Git submodules
```bash
$ cd Delta
$ git submodule update --init --recursive
```  

- Open `DeltaLite/PlaygroundBook.xcodeproj`, and build the `PlaygroundBook` target. This will build a Swift Playground Book that can then be AirDropped to an iPad.