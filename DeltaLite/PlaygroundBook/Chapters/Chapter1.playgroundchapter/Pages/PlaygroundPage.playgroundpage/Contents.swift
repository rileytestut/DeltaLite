//#-hidden-code
//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  The Swift file containing the source code edited by the user of this playground book.
//
//#-end-hidden-code
//#-hidden-code

import Foundation
import PlaygroundSupport
import CoreImage

let proxy = PlaygroundPage.current.liveView as! PlaygroundRemoteLiveViewProxy
let settings = Settings.shared

func play(_ gameURL: URL)
{
    do
    {
        let bookmark = try gameURL.bookmarkData()
        let settingsData = try PropertyListEncoder().encode(settings)
        proxy.send(.dictionary(["game": .data(bookmark), "settings": .data(settingsData)]))
    }
    catch
    {
        print(error)
    }
}

//#-end-hidden-code
/*:
 # Delta Lite
*/

//: ## Choose Game
//: Tap the image icon to choose a game from the Files app.
let game = #fileLiteral(resourceName: "")

//: ## External Keyboard Controls
//: Change the values below to customize external keyboard controls.
settings.inputs.a = "x"
settings.inputs.b = "z"
settings.inputs.up = .up
settings.inputs.down = .down
settings.inputs.left = .left
settings.inputs.right = .right
settings.inputs.start = .return
settings.inputs.select = .tab
settings.inputs.menu = "p"

//: ## Custom Filters
//: For fun, uncomment these lines to add filter effects, or create your own custom filters with [Core Image](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/)!
settings.gameFilter = nil
//settings.gameFilter = .sepia(intensity: 1.0)
//settings.gameFilter = .blur(radius: 5.0)
//settings.gameFilter = .invert
//settings.gameFilter = .grayscale(intensity: 1.0)
//settings.gameFilter = .custom(ciFilter: CIFilter(name: "CICrystallize", withInputParameters: ["inputRadius": 5])!)

play(game)

//: ## View Source
//: Check out the complete source code for this Swift Playground Book [on GitHub](https://github.com/rileytestut/DeltaLite).
