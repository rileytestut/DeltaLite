//
//  RSTPlaceholderView.swift
//  Book_Sources
//
//  Created by Riley Testut on 6/13/18.
//

import UIKit

@objc(RSTPlaceholderView)
class RSTPlaceholderView: UIView
{
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var detailTextLabel: UILabel!
    
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var stackView: UIStackView!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    private func initialize()
    {
        let views = Bundle.main.loadNibNamed("RSTPlaceholderView", owner: self, options: nil)!
        
        let nibView = views[0] as! UIView
        nibView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        nibView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(nibView)
        
        self.activityIndicatorView.isHidden = true
        self.imageView.isHidden = true
    }
}
