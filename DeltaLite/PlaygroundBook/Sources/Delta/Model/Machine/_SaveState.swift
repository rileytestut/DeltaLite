// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SaveState.swift instead.

import Foundation
import CoreData

public class _SaveState: NSManagedObject 
{   
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NESSaveState> {
        return NSFetchRequest<NESSaveState>(entityName: "NESSaveState")
    }

    // MARK: - Properties

    @NSManaged public var creationDate: Date

    @NSManaged public var filename: String

    @NSManaged public var identifier: String

    @NSManaged public var modifiedDate: Date

    @NSManaged public var name: String?

    @NSManaged public var type: SaveStateType

    // MARK: - Relationships

    @NSManaged public var game: NESGame?

    @NSManaged public var previewGame: NESGame?

}

