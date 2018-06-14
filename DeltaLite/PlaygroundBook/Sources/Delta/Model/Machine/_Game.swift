// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Game.swift instead.

import Foundation
import CoreData

public class _Game: NSManagedObject 
{   
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NESGame> {
        return NSFetchRequest<NESGame>(entityName: "NESGame")
    }

    // MARK: - Properties

    @NSManaged public var artworkURL: URL?

    @NSManaged public var filename: String

    @NSManaged public var identifier: String

    @NSManaged public var name: String

    @NSManaged public var playedDate: Date?

    public var type: GameType = .nes

    // MARK: - Relationships

    @NSManaged public var cheats: Set<NESCheat>

    @NSManaged public var previewSaveState: NESSaveState?

    @NSManaged public var saveStates: Set<NESSaveState>

}

