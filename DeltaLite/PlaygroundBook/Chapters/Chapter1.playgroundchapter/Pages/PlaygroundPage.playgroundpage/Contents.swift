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
let game = #fileLiteral(resourceName: "")

settings.inputs.a = "x"
settings.inputs.b = "z"

settings.inputs.up = .up
settings.inputs.down = .down
settings.inputs.left = .left
settings.inputs.right = .right

settings.inputs.start = .return
settings.inputs.select = .tab

settings.inputs.menu = "p"

//settings.gameFilter = .sepia(intensity: 1.0)

play(game)
