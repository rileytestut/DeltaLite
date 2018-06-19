//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Implements the application delegate for LiveViewTestApp with appropriate configuration points.
//

import UIKit
import PlaygroundSupport
import LiveViewHost
import Book_Sources

@UIApplicationMain
class AppDelegate: LiveViewHost.AppDelegate
{
    static var liveView: LiveGameViewController?
    
    override var liveViewConfiguration: LiveViewConfiguration {
        return .fullScreen
    }
    
    override func setUpLiveView() -> PlaygroundLiveViewable
    {
        let liveView = Book_Sources.instantiateLiveView()
        AppDelegate.liveView = liveView as? LiveGameViewController
        return liveView
    }
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool
    {
        guard super.application(application, didFinishLaunchingWithOptions: launchOptions) else { return false }
        
        self.prepareViewController()
        
        return true
    }
}

private extension AppDelegate
{
    func prepareViewController()
    {
        guard let window = UIApplication.shared.keyWindow, let rootViewController = window.rootViewController, let liveView = rootViewController.view.subviews.first else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let viewController = storyboard.instantiateInitialViewController() as! ViewController
        viewController.definesPresentationContext = true
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        rootViewController.addChildViewController(viewController)
        rootViewController.view.addSubview(viewController.view)
        viewController.didMove(toParentViewController: rootViewController)
        
        NSLayoutConstraint.activate([viewController.view.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
                                     viewController.view.trailingAnchor.constraint(equalTo: liveView.leadingAnchor),
                                     viewController.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
                                     viewController.view.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor)])
    }
}
