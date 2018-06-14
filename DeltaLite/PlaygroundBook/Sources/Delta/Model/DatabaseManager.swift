//
//  DatabaseManager.swift
//  Delta
//
//  Created by Riley Testut on 10/4/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

import Foundation
import CoreData

private extension Archive
{
    func extract(_ entry: Entry) throws -> Data
    {
        var data = Data()
        _ = try self.extract(entry) { data.append($0) }
        
        return data
    }
}

extension DatabaseManager
{
    enum ImportError: Error, Hashable
    {
        case doesNotExist(URL)
        case invalid(URL)
        case unsupported(URL)
        case unknown(URL, NSError)
        case saveFailed(Set<URL>, NSError)
        
        var hashValue: Int {
            switch self
            {
            case .doesNotExist: return 0
            case .invalid: return 1
            case .unsupported: return 2
            case .unknown: return 3
            case .saveFailed: return 4
            }
        }
        
        static func ==(lhs: ImportError, rhs: ImportError) -> Bool
        {
            switch (lhs, rhs)
            {
            case (let .doesNotExist(url1), let .doesNotExist(url2)) where url1 == url2: return true
            case (let .invalid(url1), let .invalid(url2)) where url1 == url2: return true
            case (let .unsupported(url1), let .unsupported(url2)) where url1 == url2: return true
            case (let .unknown(url1, error1), let .unknown(url2, error2)) where url1 == url2 && error1 == error2: return true
            case (let .saveFailed(urls1, error1), let .saveFailed(urls2, error2)) where urls1 == urls2 && error1 == error2: return true
            case (.doesNotExist, _): return false
            case (.invalid, _): return false
            case (.unsupported, _): return false
            case (.unknown, _): return false
            case (.saveFailed, _): return false
            }
        }
    }
}

final class DatabaseManager: NSPersistentContainer
{
    static let shared = DatabaseManager()
    
    private var validationManagedObjectContext: NSManagedObjectContext?
    
    private init()
    {
        guard
            let modelURL = Bundle(for: DatabaseManager.self).url(forResource: "Delta", withExtension: "momd"),
            let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        else { fatalError("Core Data model cannot be found. Aborting.") }
        
        super.init(name: "Delta", managedObjectModel: managedObjectModel)
        
        self.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension DatabaseManager
{
    override func newBackgroundContext() -> NSManagedObjectContext
    {
        let context = super.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    override func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void)
    {
        super.loadPersistentStores { (description, error) in
            self.prepareDatabase {
                block(description, error)
            }
        }
    }
}

//MARK: - Preparation -
private extension DatabaseManager
{
    func prepareDatabase(completion: @escaping () -> Void)
    {
        self.validationManagedObjectContext = self.newBackgroundContext()
        
        NotificationCenter.default.addObserver(self, selector: #selector(DatabaseManager.validateManagedObjectContextSave(with:)), name: .NSManagedObjectContextDidSave, object: nil)
        
        self.performBackgroundTask { (context) in
            
            do
            {
                try context.save()
            }
            catch
            {
                print("Failed to import standard controller skins:", error)
            }
            
            completion()
        }
    }
}

//MARK: - Importing -
/// Importing
extension DatabaseManager
{
    func importGames(at urls: Set<URL>, completion: ((Set<NESGame>, Set<ImportError>) -> Void)?)
    {
        var errors = Set<ImportError>()
        
        let zipFileURLs = urls.filter { $0.pathExtension.lowercased() == "zip" }
        if zipFileURLs.count > 0
        {
            self.extractCompressedGames(at: Set(zipFileURLs)) { (extractedURLs, extractErrors) in
                let gameURLs = urls.filter { $0.pathExtension.lowercased() != "zip" } + extractedURLs
                self.importGames(at: Set(gameURLs)) { (importedGames, importErrors) in
                    let allErrors = importErrors.union(extractErrors)
                    completion?(importedGames, allErrors)
                }
            }
            
            return
        }
        
        self.performBackgroundTask { (context) in
            
            var identifiers = Set<String>()
            
            for url in urls
            {
                guard FileManager.default.fileExists(atPath: url.path) else {
                    errors.insert(.doesNotExist(url))
                    continue
                }
                
                let gameType = GameType.nes
                
                guard let identifier = SHA1.hexString(fromFile: url.path) else {
                    errors.insert(.invalid(url))
                    continue
                }
                
                let filename = identifier + "." + url.pathExtension
                
                let game = NESGame(context: context)
                game.identifier = identifier
                game.type = gameType
                game.filename = filename
                game.name = url.deletingPathExtension().lastPathComponent
                
                do
                {
                    let destinationURL = DatabaseManager.gamesDirectoryURL.appendingPathComponent(filename)
                    
                    if FileManager.default.fileExists(atPath: destinationURL.path)
                    {
                        // Game already exists, so we choose not to override it and just delete the new game instead
                        // try FileManager.default.removeItem(at: url)
                    }
                    else
                    {
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                    }
                    
                    identifiers.insert(game.identifier)
                }
                catch let error as NSError
                {
                    print("Import Games error:", error)
                    game.managedObjectContext?.delete(game)
                    
                    errors.insert(.unknown(url, error))
                }
            }

            do
            {
                try context.save()
            }
            catch let error as NSError
            {
                print("Failed to save import context:", error)
                
                identifiers.removeAll()
                
                errors.insert(.saveFailed(urls, error))
            }
            
            DatabaseManager.shared.viewContext.perform {
                let predicate = NSPredicate(format: "%K IN (%@)", #keyPath(NESGame.identifier), identifiers)
                let games = NESGame.instancesWithPredicate(predicate, inManagedObjectContext: DatabaseManager.shared.viewContext, type: NESGame.self)
                completion?(Set(games), errors)
            }
        }
    }
    
    private func extractCompressedGames(at urls: Set<URL>, completion: @escaping ((Set<URL>, Set<ImportError>) -> Void))
    {
        DispatchQueue.global().async {
            
            var outputURLs = Set<URL>()
            var errors = Set<ImportError>()
            
            for url in urls
            {
                var archiveContainsValidGameFile = false
                
                do
                {
                    guard let archive = Archive(url: url, accessMode: .read) else {
                        throw ImportError.invalid(url)
                    }
                    
                    for entry in archive
                    {
                        // Ensure entry is not in a subdirectory
                        guard !entry.path.contains("/") else { continue }
                        
                        let fileExtension = (entry.path as NSString).pathExtension

                        guard GameType(fileExtension: fileExtension) != nil else { continue }
                        
                        // At least one entry is a valid game file, so we set archiveContainsValidGameFile to true
                        // This will result in this archive being considered valid, and thus we will not return an ImportError.invalid error for the archive
                        // However, if this game file does turn out to be invalid when extracting, we'll return an ImportError.invalid error specific to this game file
                        archiveContainsValidGameFile = true
                        
                        // Must use temporary directory, and not the directory containing zip file, since the latter might be read-only (such as when importing from Safari)
                        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(entry.path)
                        
                        do
                        {
                            let data = try archive.extract(entry)
                            try data.write(to: outputURL, options: .atomic)
                            
                            outputURLs.insert(outputURL)
                        }
                        catch let error as NSError
                        {
                            print(error)
                            
                            if FileManager.default.fileExists(atPath: outputURL.path)
                            {
                                do
                                {
                                    try FileManager.default.removeItem(at: outputURL)
                                }
                                catch
                                {
                                    print(error)
                                }
                            }
                            
                            errors.insert(.invalid(outputURL))
                        }
                    }
                }
                catch
                {
                    print(error)
                }
                
                if !archiveContainsValidGameFile
                {
                    errors.insert(.invalid(url))
                }
            }
            
            completion(outputURLs, errors)
        }
    }
}

//MARK: - File URLs -
/// File URLs
extension DatabaseManager
{
    override class func defaultDirectoryURL() -> URL
    {
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let databaseDirectoryURL = documentsDirectoryURL.appendingPathComponent("Database")
        self.createDirectory(at: databaseDirectoryURL)
        
        return databaseDirectoryURL
    }
    
    class var gamesDatabaseURL: URL
    {
        let gamesDatabaseURL = self.defaultDirectoryURL().appendingPathComponent("openvgdb.sqlite")
        return gamesDatabaseURL
    }

    class var gamesDirectoryURL: URL
    {
        let gamesDirectoryURL = DatabaseManager.defaultDirectoryURL().appendingPathComponent("Games")
        self.createDirectory(at: gamesDirectoryURL)
        
        return gamesDirectoryURL
    }
    
    class var saveStatesDirectoryURL: URL
    {
        let saveStatesDirectoryURL = DatabaseManager.defaultDirectoryURL().appendingPathComponent("Save States")
        self.createDirectory(at: saveStatesDirectoryURL)
        
        return saveStatesDirectoryURL
    }
    
    class func saveStatesDirectoryURL(for game: NESGame) -> URL
    {
        let gameDirectoryURL = DatabaseManager.saveStatesDirectoryURL.appendingPathComponent(game.identifier)
        self.createDirectory(at: gameDirectoryURL)
        
        return gameDirectoryURL
    }
    
    class var controllerSkinsDirectoryURL: URL
    {
        let controllerSkinsDirectoryURL = DatabaseManager.defaultDirectoryURL().appendingPathComponent("Controller Skins")
        self.createDirectory(at: controllerSkinsDirectoryURL)
        
        return controllerSkinsDirectoryURL
    }
    
    class func controllerSkinsDirectoryURL(for gameType: GameType) -> URL
    {
        let gameTypeDirectoryURL = DatabaseManager.controllerSkinsDirectoryURL.appendingPathComponent(gameType.rawValue)
        self.createDirectory(at: gameTypeDirectoryURL)
        
        return gameTypeDirectoryURL
    }
    
    class func artworkURL(for game: NESGame) -> URL
    {
        let gameURL = game.fileURL
        
        let artworkURL = gameURL.deletingPathExtension().appendingPathExtension("jpg")
        return artworkURL
    }
}

//MARK: - Notifications -
private extension DatabaseManager
{
    @objc func validateManagedObjectContextSave(with notification: Notification)
    {
        guard (notification.object as? NSManagedObjectContext) != self.validationManagedObjectContext else { return }
        
        let insertedObjects = (notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>) ?? []
        let updatedObjects = (notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>) ?? []
        let deletedObjects = (notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? []
        
        let allObjects = insertedObjects.union(updatedObjects).union(deletedObjects)

        if allObjects.contains(where: { $0 is NESGame })
        {
//            self.validationManagedObjectContext?.perform {
//                self.updateRecentGameShortcuts()
//            }
        }
    }
}

//MARK: - Private -
private extension DatabaseManager
{
    class func createDirectory(at url: URL)
    {
        do
        {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        catch
        {
            print(error)
        }
    }
}
