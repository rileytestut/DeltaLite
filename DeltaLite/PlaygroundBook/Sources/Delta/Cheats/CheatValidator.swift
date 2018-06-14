//
//  CheatValidator.swift
//  Delta
//
//  Created by Riley Testut on 7/27/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

import Foundation
import CoreData

extension CheatValidator
{
    enum Error: Swift.Error
    {
        case invalidCode
        case invalidName
        case duplicateName
        case duplicateCode
    }
}

struct CheatValidator
{
    let format: CheatFormat
    let managedObjectContext: NSManagedObjectContext
    
    func validate(_ cheat: NESCheat) throws
    {
        guard let name = cheat.name, let game = cheat.game else { throw Error.invalidName }
        
        let code = cheat.code
        
        // Find all cheats that are for the same game, don't have the same identifier as the current cheat, but have either the same name or code
        let predicate = NSPredicate(format: "%K == %@ AND %K != %@ AND (%K == %@ OR %K == %@)", #keyPath(NESCheat.game), game, #keyPath(NESCheat.identifier), cheat.identifier, #keyPath(NESCheat.code), code, #keyPath(NESCheat.name), name)
        
        let cheats = NESCheat.instancesWithPredicate(predicate, inManagedObjectContext: self.managedObjectContext, type: NESCheat.self)
        for cheat in cheats
        {
            if cheat.name == name
            {
                throw Error.duplicateName
            }
            else if cheat.code == code
            {
                throw Error.duplicateCode
            }
        }
        
        // Remove newline characters (code should already be formatted)
        let sanitizedCode = (cheat.code as NSString).replacingOccurrences(of: "\n", with: "")
        
        if sanitizedCode.count % self.format.format.count != 0
        {
            throw Error.invalidCode
        }
    }
}
