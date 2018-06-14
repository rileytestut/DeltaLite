//
//  RSTCellContentView.swift
//  Book_Sources
//
//  Created by Riley Testut on 6/13/18.
//

import UIKit
import ObjectiveC

private var updatesCounterKey = 0
private var operationsKey = 0

protocol RSTCellContentView: NSObjectProtocol
{
    associatedtype DataSourceType: AnyObject
    associatedtype CellType: AnyObject
    
    var dataSource: DataSourceType? { get set }
    var dataSourceProtocol: Protocol { get }
    
    var backgroundView: UIView? { get set }
    
    func beginUpdates()
    func endUpdates()
    
    func add(_ change: RSTCellContentChange)
    
    func indexPath(for cell: CellType) -> IndexPath?
    
    func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> CellType
    
    func reloadData()
}

extension UITableView: RSTCellContentView
{
    var dataSourceProtocol: Protocol {
        return UITableViewDataSource.self
    }
    
    func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell
    {
        return self.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    }
    
    func add(_ change: RSTCellContentChange)
    {
        switch change.type
        {
        case .insert:
            if change.sectionIndex != RSTUnknownSectionIndex
            {
                self.insertSections(IndexSet.init(integer: change.sectionIndex), with: change.rowAnimation)
            }
            else
            {
                self.insertRows(at: [change.destinationIndexPath!], with: change.rowAnimation)
            }
            
        case .delete:
            if change.sectionIndex != RSTUnknownSectionIndex
            {
                self.deleteSections(IndexSet.init(integer: change.sectionIndex), with: change.rowAnimation)
            }
            else
            {
                self.deleteRows(at: [change.currentIndexPath!], with: change.rowAnimation)
            }
            
        case .move:
            self.reloadRows(at: [change.currentIndexPath!], with: change.rowAnimation)
            self.moveRow(at: change.currentIndexPath!, to: change.destinationIndexPath!)
            
        case .update:
            self.reloadRows(at: [change.currentIndexPath!], with: change.rowAnimation)
        }
    }
}

extension UICollectionView: RSTCellContentView
{
    var dataSourceProtocol: Protocol {
        return UICollectionViewDataSource.self
    }
    
    private var rst_nestedUpdatesCounter: Int {
        get { return objc_getAssociatedObject(self, &updatesCounterKey) as? Int ?? 0 }
        set { objc_setAssociatedObject(self, &updatesCounterKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
    
    private var rst_operations: [RSTCollectionViewChangeOperation]? {
        get { return objc_getAssociatedObject(self, &operationsKey) as? [RSTCollectionViewChangeOperation] }
        set { objc_setAssociatedObject(self, &operationsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func beginUpdates()
    {
        if self.rst_nestedUpdatesCounter == 0
        {
            self.rst_operations = []
        }
        
        self.rst_nestedUpdatesCounter += 1
    }
    
    func endUpdates()
    {
        guard self.rst_nestedUpdatesCounter > 0 else { return }
        
        self.rst_nestedUpdatesCounter -= 1
        
        guard self.rst_nestedUpdatesCounter == 0 else { return }
        
        guard let operations = self.rst_operations else { return }
        self.rst_operations = nil
        
        var postMoveUpdateOperations = [RSTCollectionViewChangeOperation]()
        for operation in operations where operation.change.type == .move
        {
            let change = RSTCellContentChange(type: .update, currentIndexPath: operation.change.destinationIndexPath, destinationIndexPath: nil)
            
            let updateOperation = RSTCollectionViewChangeOperation(change: change, collectionView: self)
            postMoveUpdateOperations.append(updateOperation)
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.performBatchUpdates({
                postMoveUpdateOperations.forEach { $0.start() }
            }, completion: nil)
        }
        
        self.performBatchUpdates({
            operations.forEach { $0.start() }
        }, completion: nil)
        
        CATransaction.commit()
    }
    
    func add(_ change: RSTCellContentChange)
    {
        if change.currentIndexPath == nil && change.destinationIndexPath == nil && change.sectionIndex == RSTUnknownSectionIndex
        {
            print("wtf")
        }
        
        let operation = RSTCollectionViewChangeOperation(change: change, collectionView: self)
        self.rst_operations?.append(operation)
    }    
}
