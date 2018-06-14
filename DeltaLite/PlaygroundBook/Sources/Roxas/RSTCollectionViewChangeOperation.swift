//
//  RSTCollectionViewChangeOperation.swift
//  Book_Sources
//
//  Created by Riley Testut on 6/13/18.
//

import UIKit

class RSTCollectionViewChangeOperation: Operation
{
    let change: RSTCellContentChange
    
    private(set) weak var collectionView: UICollectionView?
    
    init(change: RSTCellContentChange, collectionView: UICollectionView?)
    {
        self.change = change
        self.collectionView = collectionView
        
        super.init()
    }
    
    override func main()
    {
        super.main()
        
        switch self.change.type
        {
        case .insert:
            if self.change.sectionIndex != RSTUnknownSectionIndex
            {
                self.collectionView?.insertSections(IndexSet(integer: self.change.sectionIndex))
            }
            else
            {
                self.collectionView?.insertItems(at: [self.change.destinationIndexPath!])
            }
            
        case .delete:
            if self.change.sectionIndex != RSTUnknownSectionIndex
            {
                self.collectionView?.deleteSections(IndexSet(integer: self.change.sectionIndex))
            }
            else
            {
                self.collectionView?.deleteItems(at: [self.change.currentIndexPath!])
            }
            
        case .move:
            self.collectionView?.moveItem(at: self.change.currentIndexPath!, to: self.change.destinationIndexPath!)
            
        case .update:
            self.collectionView?.reloadItems(at: [self.change.currentIndexPath!])
        }
    }
}
