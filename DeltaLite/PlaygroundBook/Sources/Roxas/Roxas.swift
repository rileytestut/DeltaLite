//
//  Roxas.swift
//  Book_Sources
//
//  Created by Riley Testut on 6/12/18.
//

import UIKit
import CoreData

public let RSTCellContentGenericCellIdentifier = "Cell"

public let RSTSystemTransitionAnimationCurve = UIViewAnimationOptions(rawValue: 7 << 16)

public func CGFloatEqualToFloat(_ float1: CGFloat, _ float2: CGFloat) -> Bool
{
    return float1 == float2
}

public func rst_dispatch_sync_on_main_thread(_ block: () -> Void)
{
    if Thread.isMainThread
    {
        block()
    }
    else
    {
        DispatchQueue.main.sync {
            block()
        }
    }
}

//  Converted to Swift 4 by Swiftify v4.1.6724 - https://objectivec2swift.com/
var RSTUnknownSectionIndex: Int = -1
enum RSTCellContentChangeType : UInt {
    case insert = 1
    case delete = 2
    case move = 3
    case update = 4
}


func RSTCellContentChangeTypeFromFetchedResultsChangeType(_ type: NSFetchedResultsChangeType) -> RSTCellContentChangeType {
    return RSTCellContentChangeType(rawValue: type.rawValue)!
}

func NSFetchedResultsChangeTypeFromCellContentChangeType(_ type: RSTCellContentChangeType) -> NSFetchedResultsChangeType {
    return NSFetchedResultsChangeType(rawValue: type.rawValue)!
}

class RSTCellContentChange: NSObject {
    private(set) var type: RSTCellContentChangeType
    private(set) var currentIndexPath: IndexPath?
    private(set) var destinationIndexPath: IndexPath?
    // Defaults to RSTUnknownSectionIndex if not representing a section.
    private(set) var sectionIndex: Int = 0
    // Animation to use when applied to a UITableView.
    var rowAnimation: UITableViewRowAnimation = .automatic
    
    required init(type: RSTCellContentChangeType, currentIndexPath: IndexPath?, destinationIndexPath: IndexPath?) {
        self.type = type
        self.currentIndexPath = currentIndexPath
        self.destinationIndexPath = destinationIndexPath
        self.sectionIndex = RSTUnknownSectionIndex
    }
    
    required init(type: RSTCellContentChangeType, sectionIndex: Int) {
        self.type = type
        self.sectionIndex = sectionIndex
    }
}

class RSTArrayDataSource<ContentType: NSObject,CellType: UIView, ViewType: UIScrollView & RSTCellContentView ,DataSourceType: AnyObject>: RSTCellContentDataSource<ContentType, CellType, ViewType, DataSourceType, NSObject>
{
    var items: [ContentType] {
        didSet {
            guard self.items != oldValue else { return }
            
            self.setItems(self.items, withChanges: nil)
        }
    }
    private var filteredItems: [ContentType]?
    
    required init(items: [ContentType])
    {
        self.items = items
        
        super.init()
    }
    
    func setItems(_ items: [ContentType], withChanges changes: [RSTCellContentChange]?)
    {
        self.items = items
        
        if self.filteredItems != nil
        {
            self.filterContent(with: self.predicate)
            
            rst_dispatch_sync_on_main_thread {
                self.contentView?.reloadData()
            }
        }
        else
        {
            if let changes = changes
            {
                self.contentView?.beginUpdates()
                changes.forEach(self.add)
                self.contentView?.endUpdates()
            }
            else
            {
                rst_dispatch_sync_on_main_thread {
                    self.contentView?.reloadData()
                }
            }
        }
    }
    
    override func item(at indexPath: IndexPath) -> ContentType
    {
        let items = self.filteredItems ?? self.items
        return items[indexPath.item]
    }
    
    override func numberOfSections(inContentView contentView: ViewType) -> Int {
        return 1
    }
    
    override func contentView(_ contentView: ViewType, numberOfItemsInSection section: Int) -> Int {
        let items = self.filteredItems ?? self.items
        return items.count
    }
    
    override func filterContent(with predicate: NSPredicate?)
    {
        if let predicate = predicate
        {
            self.filteredItems = (self.items as NSArray).filtered(using: predicate) as? [ContentType]
        }
        else
        {
            self.filteredItems = nil
        }
    }
}

class RSTArrayCollectionViewDataSource<ContentType: NSObject> : RSTArrayDataSource<ContentType, UICollectionViewCell, UICollectionView, UICollectionViewDelegate>, UICollectionViewDataSource {}

//class RSTArrayTableViewDataSource<ContentType> : RSTArrayDataSource<ContentType, UICollectionViewCell, UITableView, UITableViewDataSource> {}
