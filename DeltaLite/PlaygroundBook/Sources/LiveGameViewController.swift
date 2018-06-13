//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  An auxiliary source file which is part of the book-level auxiliary sources.
//  Provides the implementation of the "always-on" live view.
//

import UIKit
import PlaygroundSupport

@objc(Book_Sources_LiveGameViewController)
public class LiveGameViewController: GameViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer
{
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.controllerView.overrideControllerSkinTraits = ControllerSkin.Traits(device: .iphone, displayType: .standard, orientation: .portrait)
    }
    
    public override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if Delta.core(for: .nes) == nil
        {
            NESEmulatorBridge.applicationWindow = self.view.window
            
            Delta.register(NES.core)
        }
    }
    
    public func receive(_ message: PlaygroundValue)
    {
        guard case .data(let bookmark) = message else { return }
        
        do
        {
            var isStale = false
            guard let fileURL = try URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else { return }
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            let gameURL = documentsDirectory.appendingPathComponent(fileURL.lastPathComponent)
            
            if FileManager.default.fileExists(atPath: gameURL.path)
            {
                try FileManager.default.removeItem(at: gameURL)
            }
            
            try FileManager.default.copyItem(at: fileURL, to: gameURL)
            
            let game = Game(fileURL: gameURL, type: .nes)
            self.play(game)
        }
        catch
        {
            print(error)
        }
    }
}

private extension LiveGameViewController
{
    func play(_ game: Game)
    {
        self.game = game
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        self.emulatorCore?.start()
    }
}
