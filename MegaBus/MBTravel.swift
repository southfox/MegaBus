//
//  MBTravel.swift
//  MegaBus
//
//  Created by Javier Fuchs on 9/20/16.
//  Copyright © 2016 Fuchs. All rights reserved.
//

import Foundation
import CoreData

public class MBTravel: NSManagedObject {

    
    public enum mode: Int16 {
        case modeNone = 0
        case modeBus
        case modeFlight
        case modeTrain
    }
    
    public struct Constants {
        static let name = "MBTravel"
        public struct fields {
            static let id = "id"
            static let provider_logo = "provider_logo"
            static let price_in_euros = "price_in_euros"
            static let departure_time = "departure_time"
            static let arrival_time = "arrival_time"
            static let number_of_stops = "number_of_stops"
            static let travel_mode = "travel_mode"
        }
        static let numberOfStopsDescription = "Number of Stops"
    }
    
    /// create instnace of MBTravel in db and fill information with the dictionary
    public class func create(inManageContextObject mco: NSManagedObjectContext, dictionary: NSDictionary?) -> MBTravel?
    {
        guard let
            object = NSEntityDescription.insertNewObjectForEntityForName(Constants.name, inManagedObjectContext: mco) as? MBTravel,
            travelDict = dictionary,
            _id              = travelDict[Constants.fields.id] as? Int,
            _provider_logo   = travelDict[Constants.fields.provider_logo] as? String,
            _price_in_euros  = travelDict[Constants.fields.price_in_euros],
            _departure_time  = travelDict[Constants.fields.departure_time] as? String,
            _arrival_time    = travelDict[Constants.fields.arrival_time] as? String,
            _number_of_stops = travelDict[Constants.fields.number_of_stops] as? Int
            else {
                return nil
        }
        object.id = Int16(_id)
        object.provider_logo = _provider_logo
        // Little trick, price in euros came in Double or String sometimes
        if let strPrice = _price_in_euros as? String,
           let doublePrice = Double(strPrice) {
            object.price_in_euros = doublePrice
        } else if let doublePrice = _price_in_euros as? Double {
            object.price_in_euros = doublePrice
        }
        object.departure_time = _departure_time
        object.arrival_time = _arrival_time
        object.number_of_stops = Int16(_number_of_stops)
        
        return object
    }
    
    /// Returning the schedule, used in UI
    public func schedule() -> String {
        guard let departure = departure_time,
                arrival = arrival_time else {
            return "N/A"
        }
        if number_of_stops == 0 {
            return "\(departure) - \(arrival)"
        }
        return "\(departure) - \(arrival) (+\(number_of_stops))"
        
    }
    
    /// Handy lazy var for the date formatter
    private lazy var dateFormatter : NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }()
    
    /// Handy hour/minutes tuple returned
    private func durationInHoursMinutes() -> (hours: Int, minutes: Int) {
        guard let departure = departureDate(),
                  arrival = arrivalDate()
            else {
            return (0,0)
        }
        
        let hourMinute: NSCalendarUnit = [.Hour, .Minute]
        let difference = NSCalendar.currentCalendar().components(hourMinute, fromDate: departure, toDate: arrival, options: [])
    
        return (difference.hour, difference.minute)
    }

    /// Used for the sort comparisson to order asc/desc the duration
    public func durationInMinutes() -> Int {
        let hm = durationInHoursMinutes()
        return hm.hours*60 + hm.minutes
    }

    /// Used in the UI, the cell needs to show the duration using format '00:00'h
    public func duration() -> String {
        let hm = durationInHoursMinutes()
        return String.localizedStringWithFormat("%d:%02dh", hm.hours, hm.minutes)
    }
    
    /// Used for comparisons in sort
    public func arrivalDate() -> NSDate? {
        guard let arrival = arrival_time,
                  date = dateFormatter.dateFromString(arrival)
            else {
            return nil
        }
        return date
    }
    
    /// Used for comparisons in sort
    public func departureDate() -> NSDate? {
        guard let departure = departure_time,
                  date = dateFormatter.dateFromString(departure)
            else {
            return nil
        }
        return date
    }
    
    /// Remove all the record from the db for the travel mode indicated
    public class func deleteAll(mco: NSManagedObjectContext, travel_mode : mode?) throws {
        do {
            let fetchRequest = NSFetchRequest(entityName: Constants.name)
            
            if let travelMode = travel_mode {
                let predicate = NSPredicate(format: "travel_mode = %d", travelMode.rawValue)
                fetchRequest.predicate = predicate
            }
            
            let array = try mco.executeFetchRequest(fetchRequest)
            for object in array {
                mco.deleteObject(object as! NSManagedObject)
            }
        }
        catch {
            throw NSError.fetchError()
        }
    }
    
    /// fetch all the records from the db for the travel mode indicated
    public class func fetchAll(mco: NSManagedObjectContext, travel_mode : mode?) throws -> NSArray? {
        do {
            let fetchRequest = NSFetchRequest(entityName: Constants.name)
            
            if let travelMode = travel_mode {
                let predicate = NSPredicate(format: "travel_mode = %d", travelMode.rawValue)
                fetchRequest.predicate = predicate
            }
            
            let array = try mco.executeFetchRequest(fetchRequest)
            return array
        }
        catch {
            throw NSError.fetchError()
        }
    }
    
}
