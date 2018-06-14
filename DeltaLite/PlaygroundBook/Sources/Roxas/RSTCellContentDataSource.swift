//
//  RSTCellContentDataSource.swift
//  Book_Sources
//
//  Created by Riley Testut on 6/13/18.
//

import UIKit

private typealias PrefetchCompletionHandlerWrapper = @convention(block) (AnyObject?, Error?) -> Void

//  Converted to Swift 4 by Swiftify v4.1.6724 - https://objectivec2swift.com/
@objcMembers
class RSTCellContentDataSource<ContentType: NSObject, CellType: UIView, ViewType: UIScrollView & RSTCellContentView, DataSourceType: AnyObject, PrefetchContentType: AnyObject>: NSObject
{
    private(set) weak var contentView: ViewType? {
        didSet {
            guard contentView != oldValue else { return }
            
            if contentView?.dataSource === self as! ViewType.DataSourceType {
                // Must set ourselves as dataSource again to refresh respondsToSelector: cache.
                contentView?.dataSource = nil
                contentView?.dataSource = self as? ViewType.DataSourceType
            }
        }
    }
    
    weak var proxy: DataSourceType?

    var cellIdentifierHandler: ((_ indexPath: IndexPath) -> String) = { _ in return RSTCellContentGenericCellIdentifier }

    var cellConfigurationHandler: (CellType, ContentType, IndexPath) -> Void = { (_, _, _) in }

    var predicate: NSPredicate? {
        didSet {
            guard self.predicate != oldValue else { return }
            setPredicate(predicate, refreshContent: true)
        }
    }

    var placeholderView: UIView? {
        didSet {
            if self.placeholderView != nil && contentView?.backgroundView == self.placeholderView {
                contentView?.backgroundView = placeholderView
            }
            self.placeholderView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            if contentView != nil {
                // Show placeholder only if there are no items to display.
                var shouldShowPlaceholderView = true
                for i in 0..<numberOfSections(inContentView: contentView!) {
                    if contentView(contentView!, numberOfItemsInSection: i) > 0 {
                        shouldShowPlaceholderView = false
                        break
                    }
                }
                if shouldShowPlaceholderView {
                    showPlaceholderView()
                } else {
                    hidePlaceholderView()
                }
            }
        }
    }

    var rowAnimation: UITableViewRowAnimation = .automatic
    
    var prefetchItemCache = NSCache<ContentType, PrefetchContentType>()
    var prefetchHandler: ((ContentType, IndexPath, @escaping (PrefetchContentType?, Error?) -> Void) -> Operation?)?
    var prefetchCompletionHandler: ((CellType, PrefetchContentType?, IndexPath, Error?) -> Void)?
    
    private var isPlaceholderViewVisible = false
    
    private let prefetchOperationQueue: RSTOperationQueue
    private let prefetchCompletionHandlers = NSMapTable<AnyObject, NSMutableDictionary>.strongToStrongObjects()
    
    private var _previousSeparatorStyle: UITableViewCellSeparatorStyle?
    private var _previousBackgroundView: UIView?
    private var _previousScrollEnabled: Bool?
    private var _sectionsCount = 0
    private var _itemsCount = 0
    
    override init()
    {
        self.prefetchOperationQueue = RSTOperationQueue()
        self.prefetchOperationQueue.name = "com.rileytestut.Roxas.RSTCellContentDataSource.prefetchOperationQueue"
        self.prefetchOperationQueue.qualityOfService = .userInitiated
        
        super.init()
    }
    
    func dataSourceProtocolContains(_ aSelector: Selector) -> Bool {
        guard let dataSourceProtocol = self.contentView?.dataSourceProtocol else { return false }
        
        let dataSourceSelector: objc_method_description = protocol_getMethodDescription(dataSourceProtocol, aSelector, false, true)
        let containsSelector: Bool = dataSourceSelector.name != nil
        return containsSelector
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        if dataSourceProtocolContains(aSelector) {
            return (self.proxy as? NSObjectProtocol)?.responds(to: aSelector) ?? false
        }
        return false
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if dataSourceProtocolContains(aSelector) {
            return proxy
        }
        return nil
    }
    
    func showPlaceholderView() {
        if isPlaceholderViewVisible {
            return
        }
        if placeholderView == nil || contentView == nil {
            return
        }
        isPlaceholderViewVisible = true
        if (contentView is UITableView) {
            let tableView = contentView as? UITableView
            _previousSeparatorStyle = tableView?.separatorStyle
            tableView?.separatorStyle = .none
        }
        _previousScrollEnabled = contentView?.isScrollEnabled
        contentView?.isScrollEnabled = false
        _previousBackgroundView = contentView?.backgroundView
        contentView?.backgroundView = placeholderView
    }
    
    func hidePlaceholderView() {
        if !isPlaceholderViewVisible {
            return
        }
        isPlaceholderViewVisible = false
        if (contentView is UITableView) {
            let tableView = contentView as? UITableView
            if let style = _previousSeparatorStyle {
                tableView?.separatorStyle = style
            }
        }
        contentView?.isScrollEnabled = _previousScrollEnabled ?? true
        contentView?.backgroundView = _previousBackgroundView
    }
    
    func prefetchItem(at indexPath: IndexPath, completionHandler: ((_ prefetchItem: PrefetchContentType?, _ error: Error?) -> Void)? = nil) {
        if prefetchHandler == nil || self.prefetchCompletionHandler == nil {
            return
        }
        let item = self.item(at: indexPath)

        if completionHandler != nil {
            // Each completionHandler is mapped to an item, and then to the indexPath originally requested.
            // This allows us to prevent multiple fetches for the same item, but also handle the case where the prefetch item is needed by multiple cells, or the cell has moved.
            var completionHandlers = prefetchCompletionHandlers.object(forKey: item)
            if completionHandlers == nil {
                completionHandlers = NSMutableDictionary()
                prefetchCompletionHandlers.setObject(completionHandlers, forKey: item)
            }
            let handler: PrefetchCompletionHandlerWrapper = { (item, error) in
                completionHandler?(item as? PrefetchContentType, error)
            }
            completionHandlers?[indexPath] = handler
        }
        // If prefetch operation is currently in progress, return.
        if prefetchOperationQueue[item] != nil {
            return
        }
        
        let prefetchCompletionHandler: ((PrefetchContentType?, Error?) -> Void) = { prefetchItem, error in
            if prefetchItem != nil {
                self.prefetchItemCache.setObject(prefetchItem!, forKey: item)
            }
            let completionHandlers = self.prefetchCompletionHandlers.object(forKey: item)
            completionHandlers?.enumerateKeysAndObjects({ indexPath, completionHandler, stop in
                let completionHandler = unsafeBitCast(completionHandler as AnyObject, to: PrefetchCompletionHandlerWrapper.self)
                completionHandler(prefetchItem, error)
            })
            self.prefetchCompletionHandlers.removeObject(forKey: item)
        }
        let cachedItem = prefetchItemCache.object(forKey: item)
        if cachedItem != nil {
            // Prefetch item has been cached, so use it immediately.
            rst_dispatch_sync_on_main_thread({
                prefetchCompletionHandler(cachedItem, nil)
            })
        } else {
            // Prefetch item has not been cached, so perform operation to retrieve it.
            let operation: Operation? = prefetchHandler?(item, indexPath, { prefetchItem, error in
                DispatchQueue.main.async(execute: {
                    prefetchCompletionHandler(prefetchItem, error)
                })
            })
            if operation != nil {
                prefetchOperationQueue.add(operation, forKey: item)
            }
        }
    }
    
    func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        if indexPath.section >= numberOfSections(inContentView: contentView!) {
            return false
        }
        if indexPath.item >= contentView(contentView!, numberOfItemsInSection: indexPath.section) {
            return false
        }
        return true
    }
    
    // MARK: Filtering
    func filterContent(with predicate: NSPredicate?, refreshContent: Bool) {
        filterContent(with: predicate)
        if refreshContent {
            rst_dispatch_sync_on_main_thread({
                self.contentView?.reloadData()
            })
        }
    }

    func add(_ change: RSTCellContentChange) {
        self.contentView?.add(change)
    }
    
    func numberOfSections(inContentView contentView: ViewType) -> Int {
        doesNotRecognizeSelector(#function)
        return 0
    }
    
    func contentView(_ contentView: ViewType, numberOfItemsInSection section: Int) -> Int {
        doesNotRecognizeSelector(#function)
        return 0
    }
    
    func item(at indexPath: IndexPath) -> ContentType {
        doesNotRecognizeSelector(#function)
        fatalError()
    }
    
    func filterContent(with predicate: NSPredicate?) {
        doesNotRecognizeSelector(#function)
    }

    
    func _numberOfSections(inContentView contentView: ViewType) -> Int {
        self.contentView = contentView
        let sections: Int = numberOfSections(inContentView: contentView)
        if sections == 0 {
            showPlaceholderView()
        }
        _itemsCount = 0
        _sectionsCount = sections
        return sections
    }
    
    func _contentView(_ contentView: ViewType, numberOfItemsInSection section: Int) -> Int {
        let items: Int = self.contentView(contentView, numberOfItemsInSection: section)
        _itemsCount += items
        if section == _sectionsCount - 1 {
            if _itemsCount == 0 {
                showPlaceholderView()
            } else {
                hidePlaceholderView()
            }
            _itemsCount = 0
            _sectionsCount = 0
        }
        return items
    }
    
    func _contentView(_ contentView: ViewType, cellForItemAt indexPath: IndexPath) -> CellType {
        let identifier = cellIdentifierHandler(indexPath)
        let item = self.item(at: indexPath)
        let cell = contentView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CellType
        cellConfigurationHandler(cell, item, indexPath)
        // We store the completionHandler, and it's not guaranteed to be nil'd out (since prefetch may take a long time), so we use a weak reference to self inside the block to prevent strong reference cycle.
        let weakSelf: RSTCellContentDataSource? = self
        prefetchItem(at: indexPath, completionHandler: { (prefetchItem: PrefetchContentType?, error: Error?) in
            let cellIndexPath: IndexPath? = contentView.indexPath(for: cell as! ViewType.CellType)
            if cellIndexPath != nil {
                var cellItem: Any? = nil
                if let aPath = cellIndexPath {
                    cellItem = weakSelf?.item(at: aPath)
                }
                if item.isEqual(cellItem) {
                    // Cell is in use, but its current index path still corresponds to the same item, so update.
                    weakSelf?.prefetchCompletionHandler?(cell, prefetchItem, cellIndexPath!, error)
                } else {
                    // Cell is in use, but its new index path does *not* correspond to the same item, so ignore.
                }
            } else {
                // Cell is currently being configured for use, so update.
                weakSelf?.prefetchCompletionHandler?(cell, prefetchItem, indexPath, error)
            }
        })
        return cell
    }
    
    func _contentView(_ contentView: ViewType, prefetchItemsAtIndexPaths indexPaths: [IndexPath]) {
        for indexPath: IndexPath in indexPaths {
            if !isValidIndexPath(indexPath) {
                continue
            }
            prefetchItem(at: indexPath, completionHandler: nil)
        }
    }
    
    func _contentView(_ contentView: ViewType, cancelPrefetchingItemsForIndexPaths indexPaths: [IndexPath]) {
        for indexPath: IndexPath in indexPaths {
            if !isValidIndexPath(indexPath) {
                continue
            }
            let item = self.item(at: indexPath)
            let operation: Operation? = prefetchOperationQueue[item]
            operation?.cancel()
        }
    }
    
    // MARK: - <UITableViewDataSource> -
    @objc(numberOfSectionsInTableView:) func numberOfSections(in tableView: UITableView) -> Int {
        return _numberOfSections(inContentView: tableView as! ViewType)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _contentView(tableView as! ViewType, numberOfItemsInSection: section)
    }
    
    @objc(tableView:cellForRowAtIndexPath:) func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return _contentView(tableView as! ViewType, cellForItemAt: indexPath) as! UITableViewCell
    }
    
    // MARK: - <UITableViewDataSourcePrefetching> -
    @objc(tableView:prefetchRowsAtIndexPaths:) func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        _contentView(tableView as! ViewType, prefetchItemsAtIndexPaths: indexPaths)
    }
    
    @objc(tableView:cancelPrefetchingForRowsAtIndexPaths:) func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        _contentView(tableView as! ViewType, cancelPrefetchingItemsForIndexPaths: indexPaths)
    }
    
    // MARK: - <UICollectionViewDataSource> -
    @objc(numberOfSectionsInCollectionView:) func numberOfSections(in collectionView: UICollectionView) -> Int {
        return _numberOfSections(inContentView: collectionView as! ViewType)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _contentView(collectionView as! ViewType, numberOfItemsInSection: section)
    }
    
    @objc(collectionView:cellForItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return _contentView(collectionView as! ViewType, cellForItemAt: indexPath) as! UICollectionViewCell
    }
    
    // MARK: - <UICollectionViewDataSourcePrefetching> -
    @objc(collectionView:prefetchItemsAtIndexPaths:) func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        _contentView(collectionView  as! ViewType, prefetchItemsAtIndexPaths: indexPaths)
    }
    
    @objc(collectionView:cancelPrefetchingForItemsAtIndexPaths:) func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        _contentView(collectionView as! ViewType, cancelPrefetchingItemsForIndexPaths: indexPaths)
    }
    
    func setPredicate(_ predicate: NSPredicate?, refreshContent: Bool) {
        self.predicate = predicate
        filterContent(with: self.predicate, refreshContent: refreshContent)
    }
}

extension RSTCellContentDataSource
{
    
}
