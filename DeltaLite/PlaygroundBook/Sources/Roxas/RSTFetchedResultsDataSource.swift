//
//  RSTFetchedResultsDataSource.swift
//  Book_Sources
//
//  Created by Riley Testut on 6/13/18.
//

import UIKit
import CoreData

//  Converted to Swift 4 by Swiftify v4.1.6738 - https://objectivec2swift.com/
private var RSTFetchedResultsDataSourceContext = 0

// Declare custom NSPredicate subclass so we can detect whether NSFetchedResultsController's predicate was changed externally or by us.
class RSTProxyPredicate: NSCompoundPredicate {
    init(predicate: NSPredicate?, externalPredicate: NSPredicate?) {
        var subpredicates = [AnyHashable]()
        if externalPredicate != nil {
            if let aPredicate = externalPredicate {
                subpredicates.append(aPredicate)
            }
        }
        if predicate != nil {
            if let aPredicate = predicate {
                subpredicates.append(aPredicate)
            }
        }
        if let aSubpredicates = subpredicates as? [NSPredicate] {
            super.init(type: .and, subpredicates: aSubpredicates)
        }
        else {
            super.init(type: .and, subpredicates: [])
        }
    }
    
    convenience override init(type: NSCompoundPredicate.LogicalType, subpredicates: [NSPredicate])
    {
        self.init(predicate: subpredicates.first, externalPredicate: subpredicates.last)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RSTFetchedResultsDataSource<ContentType: NSManagedObject, CellType: UIView, ViewType: UIScrollView & RSTCellContentView, DataSourceType: AnyObject, PrefetchContentType: AnyObject>: RSTCellContentDataSource<ContentType, CellType, ViewType, DataSourceType, PrefetchContentType>, NSFetchedResultsControllerDelegate
{
    var fetchedResultsController: NSFetchedResultsController<ContentType> {
        didSet {
            self.updateFetchedResultsController(oldValue)
        }
    }
    
    private var externalPredicate: NSPredicate?
    
    convenience init(fetchRequest: NSFetchRequest<ContentType>, managedObjectContext: NSManagedObjectContext) {
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        self.init(fetchedResultsController: fetchedResultsController)
    }
    
    init(fetchedResultsController: NSFetchedResultsController<ContentType>) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
        
        self.updateFetchedResultsController(nil)
        
//        weak var weakSelf: RSTFetchedResultsDataSource? = self
//        defaultSearchHandler = { searchValue, previousSearchValue in
//            return RSTBlockOperation(executionBlock: { operation in
//                weakSelf?.setPredicate(searchValue?.predicate, refreshContent: false)
//                // Only refresh content if search operation has not been cancelled, such as when the search text changes.
//                if operation != nil && !operation.isCancelled() {
//                    DispatchQueue.main.async(execute: {
//                        weakSelf?.contentView.reloadData()
//                    })
//                }
//            })
//        }
        
    }
    
    deinit {
        fetchedResultsController.removeObserver(self as NSObject, forKeyPath: "fetchRequest.predicate", context: &RSTFetchedResultsDataSourceContext)
    }
    
    private func updateFetchedResultsController(_ oldValue: NSFetchedResultsController<ContentType>?)
    {
        guard self.fetchedResultsController != oldValue else { return }
        
        // Clean up previous _fetchedResultsController.
        oldValue?.removeObserver(self, forKeyPath: "fetchRequest.predicate", context: &RSTFetchedResultsDataSourceContext)
        oldValue?.fetchRequest.predicate = externalPredicate
        externalPredicate = nil
        // Prepare new _fetchedResultsController.
        if self.fetchedResultsController.delegate == nil {
            self.fetchedResultsController.delegate = self
        }
        externalPredicate = self.fetchedResultsController.fetchRequest.predicate
        let proxyPredicate = RSTProxyPredicate(predicate: predicate, externalPredicate: externalPredicate)
        self.fetchedResultsController.fetchRequest.predicate = proxyPredicate
        self.fetchedResultsController.addObserver(self, forKeyPath: "fetchRequest.predicate", options: .new, context: &RSTFetchedResultsDataSourceContext)
        rst_dispatch_sync_on_main_thread({
            self.contentView?.reloadData()
        })
    }
    
    // MARK: - RSTCellContentViewDataSource -
    override func item(at indexPath: IndexPath) -> ContentType {
        let item = fetchedResultsController.object(at: indexPath)
        return item
    }
    
    override func numberOfSections(inContentView contentView: ViewType) -> Int {
        if fetchedResultsController.sections == nil {
            do {
                try fetchedResultsController.performFetch()
            }
            catch {
                print(error)
            }
        }
        let numberOfSections: Int = fetchedResultsController.sections?.count ?? 0
        return numberOfSections
    }
    
    override func contentView(_ contentView: ViewType, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo: NSFetchedResultsSectionInfo? = fetchedResultsController.sections?[section]
        return sectionInfo?.numberOfObjects ?? 0
    }
    
    override func filterContent(with predicate: NSPredicate?) {
        let proxyPredicate = RSTProxyPredicate(predicate: predicate, externalPredicate: externalPredicate)
        fetchedResultsController.fetchRequest.predicate = proxyPredicate
        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            print(error)
        }
    }
    
    // MARK: - KVO -
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        if context != &RSTFetchedResultsDataSourceContext {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        let predicate = change?[.newKey] as? NSPredicate
        if !(predicate is RSTProxyPredicate) {
            externalPredicate = predicate
            let proxyPredicate = RSTProxyPredicate(predicate: self.predicate, externalPredicate: externalPredicate)
            ((object as? NSFetchedResultsController<ContentType>)?.fetchRequest)?.predicate = proxyPredicate
        }
    }
    
    // MARK: - <NSFetchedResultsControllerDelegate> -
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        contentView?.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let changeType: RSTCellContentChangeType = RSTCellContentChangeTypeFromFetchedResultsChangeType(type)
        let change = RSTCellContentChange(type: changeType, sectionIndex: sectionIndex)
        change.rowAnimation = rowAnimation
        add(change)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let changeType: RSTCellContentChangeType = RSTCellContentChangeTypeFromFetchedResultsChangeType(type)
        let change = RSTCellContentChange(type: changeType, currentIndexPath: indexPath, destinationIndexPath: newIndexPath)
        change.rowAnimation = rowAnimation
        add(change)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        contentView?.endUpdates()
    }
}

class RSTFetchedResultsCollectionViewDataSource<ContentType: NSManagedObject> : RSTFetchedResultsDataSource<ContentType, UICollectionViewCell, UICollectionView, UICollectionViewDelegate, NSObject>, UICollectionViewDataSource {}
class RSTFetchedResultsCollectionViewPrefetchingDataSource<ContentType: NSManagedObject, PrefetchContentType: AnyObject> : RSTFetchedResultsDataSource<ContentType, UICollectionViewCell, UICollectionView, UICollectionViewDelegate, PrefetchContentType>, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {}

class RSTFetchedResultsTableViewDataSource<ContentType: NSManagedObject> : RSTFetchedResultsDataSource<ContentType, UITableViewCell, UITableView, UITableViewDelegate, NSObject>, UITableViewDataSource {}
class RSTFetchedResultsTableViewPrefetchingDataSource<ContentType: NSManagedObject, PrefetchContentType: AnyObject> : RSTFetchedResultsDataSource<ContentType, UITableViewCell, UITableView, UITableViewDelegate, PrefetchContentType>, UITableViewDataSource, UITableViewDataSourcePrefetching {}
