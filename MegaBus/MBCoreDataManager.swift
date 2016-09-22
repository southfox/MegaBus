//
//  MBCoreDataManager.swift
//  MegaBus
//
//  Created by Javier Fuchs on 9/21/16.
//  Copyright © 2016 Fuchs. All rights reserved.
//

import Foundation
import CoreData

public class MBCoreDataManager : NSObject {
    // MARK: Properties
    
    struct Constants {
        static let extensionFile = "momd"
    }
    
    /// public singleton
    public static let instance = MBCoreDataManager()
    
    
    /// The managed object model for the application.
    lazy var managedObjectModel: NSManagedObjectModel = {
        /*
         This property is not optional. It is a fatal error for the application
         not to be able to find and load its model.
         */
        let bundleName = NSBundle.mainBundle().infoDictionary![kCFBundleNameKey as String] as! String

        let modelURL = NSBundle.mainBundle().URLForResource(bundleName, withExtension: Constants.extensionFile)!
        
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    /// The directory the application uses to store the Core Data store file.
    lazy var applicationSupportDirectory: NSURL = {
        let fileManager = NSFileManager.defaultManager()
        
        let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        
        let applicationSupportDirectoryURL = urls.last!
        
        let bundleID = NSBundle.mainBundle().bundleIdentifier

        let applicationSupportDirectory = applicationSupportDirectoryURL.URLByAppendingPathComponent(bundleID!)
        
        do {
            let properties = try applicationSupportDirectory.resourceValuesForKeys([NSURLIsDirectoryKey])
            if let isDirectory = properties[NSURLIsDirectoryKey] as? Bool where isDirectory == false {
                let description = NSLocalizedString("Could not access the application data folder.",
                                                    comment: "Failed to initialize applicationSupportDirectory.")
                
                let reason = NSLocalizedString("Found a file in its place.",
                                               comment: "Failed to initialize applicationSupportDirectory.")
                
                fatalError("fatal reason:\(reason), description:\(description), \(#file):\(#line):\(#column):\(#function)")
            }
        }
        catch let error as NSError where error.code != NSFileReadNoSuchFileError {
            fatalError("fatal reason:No such file or directory, description: could not read file, \(#file):\(#line):\(#column):\(#function)")
        }
        catch {
            let path = applicationSupportDirectory.path!
            
            do {
                try fileManager.createDirectoryAtPath(path, withIntermediateDirectories:true, attributes:nil)
            }
            catch {
                fatalError("fatal reason: some permissions issues, description: could not create application documents directory at \(path), \(#file):\(#line):\(#column):\(#function)")
            }
        }
        
        return applicationSupportDirectory
    }()
    
    /// URL for the main Core Data store file.
    lazy var storeURL: NSURL = {
        let bundleID = NSBundle.mainBundle().bundleIdentifier
        return self.applicationSupportDirectory.URLByAppendingPathComponent(bundleID!)
    }()
    
    
    // Creates a new Core Data stack and returns a managed object context associated with a private queue.
    public func createPrivateQueueContext() throws -> NSManagedObjectContext {
        
        // Uses the same store and model, but a new persistent store coordinator and context.
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        /*
         Attempting to add a persistent store may yield an error--pass it out of
         the function for the caller to deal with.
         */
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil,
                                                                  URL: self.storeURL, options: options)
    
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        
        context.performBlockAndWait() {
            
            context.persistentStoreCoordinator = coordinator
            
            // Avoid using default merge policy in multi-threading environment:
            // when we delete (and save) a record in one context,
            // and try to save edits on the same record in the other context before merging the changes,
            // an exception will be thrown because Core Data by default uses NSErrorMergePolicy.
            // Setting a reasonable mergePolicy is a good practice to avoid that kind of exception.
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            // In OS X, a context provides an undo manager by default
            // Disable it for performance benefit
            context.undoManager = nil
        }
        
        return context
    }
    
    public var taskContext: NSManagedObjectContext {
        if _taskContext != nil {
            return _taskContext!
        }
        
        do {
            _taskContext = try self.createPrivateQueueContext()
        } catch {
            // Report any error we got.
            fatalError("fatal reason: could not process taskContext data, description: failed to initialize the applicaiton's saved data, \(#file):\(#line):\(#column):\(#function)")
        }
        
        return _taskContext!
    }
    var _taskContext: NSManagedObjectContext? = nil
    
    public func save() {
        if let mco: NSManagedObjectContext = self.taskContext
        {
            do {
                try mco.save()
            }
            catch {
                print("Error: \(error)\nCould not save Core Data context.")
                return
            }
//            mco.reset()
        }
    }

    public func rollback() {
        if let mco: NSManagedObjectContext = self.taskContext
        {
            mco.rollback()
            mco.reset()
        }
    }
    
}