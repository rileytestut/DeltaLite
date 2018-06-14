//
//  UIViewController+TransitionState.swift
//  Book_Sources
//
//  Created by Riley Testut on 6/13/18.
//

import UIKit

extension UIViewController
{
    var isAppearing: Bool {
        let transitionCoordinator: UIViewControllerTransitionCoordinator? = self.transitionCoordinator
        let toViewController: UIViewController? = transitionCoordinator?.viewController(forKey: .to)
        let fromViewController: UIViewController? = transitionCoordinator?.viewController(forKey: .from)
        let isAppearing: Bool? = toViewController?.isEqual(toViewControllerOrAncestor: self)
        return isAppearing ?? false && !(fromViewController is UIAlertController)
    }
    
    var isDisappearing: Bool {
        let transitionCoordinator: UIViewControllerTransitionCoordinator? = self.transitionCoordinator
        let fromViewController: UIViewController? = transitionCoordinator?.viewController(forKey: .from)
        let toViewController: UIViewController? = transitionCoordinator?.viewController(forKey: .to)
        let isDisappearing: Bool? = fromViewController?.isEqual(toViewControllerOrAncestor: self)
        return isDisappearing ?? false && !(toViewController is UIAlertController)
    }
    
    private func isEqual(toViewControllerOrAncestor viewController: UIViewController?) -> Bool {
        var viewController = viewController
        var isEqual = false
        while viewController != nil {
            if self == viewController {
                isEqual = true
                break
            }
            viewController = viewController?.parent
        }
        return isEqual
    }
}
