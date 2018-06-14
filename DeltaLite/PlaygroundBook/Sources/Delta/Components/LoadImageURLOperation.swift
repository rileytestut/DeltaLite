//
//  LoadImageURLOperation.swift
//  Delta
//
//  Created by Riley Testut on 10/28/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

import UIKit
import ImageIO

extension LoadImageURLOperation
{
    enum Error: Swift.Error
    {
        case doesNotExist
        case invalid
        case downloadFailed(Swift.Error)
    }
}

class LoadImageURLOperation: Operation
{
    let url: URL
    
    var resultHandler: ((UIImage?, Swift.Error?) -> Void)?
    
    var resultsCache = NSCache<NSURL, UIImage>()
    
    init(url: URL)
    {
        self.url = url
    }
    
    override func main()
    {
        if let result = self.resultsCache.object(forKey: self.url as NSURL)
        {
            self.resultHandler?(result, nil)
            return
        }
        
        guard let imageSource = CGImageSourceCreateWithURL(self.url as CFURL, nil) else {
            self.resultHandler?(nil, Error.doesNotExist)
            return
        }
        
        guard let quartzImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            self.resultHandler?(nil, Error.invalid)
            return
        }
        
        let image = UIImage(cgImage: quartzImage)
        
        // Force decompression of image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), true, 1.0)
        image.draw(at: CGPoint.zero)
        UIGraphicsEndImageContext()
        
        self.resultsCache.setObject(image, forKey: self.url as NSURL)
        
        self.resultHandler?(image, nil)
    }
}
