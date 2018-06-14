//
//  RSTOperationQueue.swift
//  Book_Sources
//
//  Created by Riley Testut on 6/13/18.
//

import Foundation

class RSTOperationQueue: OperationQueue {
    private(set) var operationsMapTable = NSMapTable<AnyObject, Operation>.strongToWeakObjects()
    
    // MARK: - NSOperationQueue -
    
    func add(_ operation: Operation?, forKey key: AnyObject?) {
        let previousOperation: Operation? = self.operation(forKey: key)
        previousOperation?.cancel()
        operationsMapTable.setObject(operation, forKey: key)
        if let anOperation = operation {
            addOperation(anOperation)
        }
    }
    
    func operation(forKey key: AnyObject?) -> Operation? {
        let operation = operationsMapTable.object(forKey: key)
        return operation
    }
    
    subscript(_ key: AnyObject) -> Operation? {
        return operation(forKey: key)
    }
    
    // Unavailable
    override func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
    }
    
    override init() {
        super.init()
        
        operationsMapTable = NSMapTable.strongToWeakObjects()
        
    }
    
    // MARK: - RSTOperationQueue -
}
