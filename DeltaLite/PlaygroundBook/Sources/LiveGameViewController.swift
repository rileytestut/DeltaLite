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
public class LiveGameViewController: DLTAGameViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer
{
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        self.delegate = self
        self.definesPresentationContext = true
    }
    
    public required init() {
        fatalError("init() has not been implemented")
    }
    
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
            self.prepare()
        }
    }
    
    public func receive(_ message: PlaygroundValue)
    {
        guard case .data(let bookmark) = message else { return }
        
        do
        {
            var isStale = false
            guard let fileURL = try URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else { return }
            
            DatabaseManager.shared.importGames(at: [fileURL]) { (importedGames, errors) in
                if errors.count > 0
                {
                    print(errors)
                }
                
                if importedGames.count > 0
                {
                    print("Imported Games:", importedGames)
                }
                
                if let game = importedGames.first
                {
                    self.play(game)
                }
            }
        }
        catch
        {
            print(error)
        }
    }
}

private extension LiveGameViewController
{
    func prepare()
    {
        self.view.window?.tintColor = .deltaPurple
        NESEmulatorBridge.applicationWindow = self.view.window
        
        Delta.register(NES.core)
        
        DatabaseManager.shared.loadPersistentStores { (description, error) in
        }
    }
}

private extension LiveGameViewController
{
    func play(_ game: NESGame)
    {
        self.game = game
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        self.emulatorCore?.start()
    }
}
