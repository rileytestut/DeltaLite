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

func play(_ gameURL: URL)
{
    let proxy = PlaygroundPage.current.liveView as! PlaygroundRemoteLiveViewProxy
    
    do
    {
        let bookmark = try gameURL.bookmarkData()
        proxy.send(.data(bookmark))
    }
    catch
    {
        print(error)
    }
}

//#-end-hidden-code
let game = #fileLiteral(resourceName: "")
play(game)
