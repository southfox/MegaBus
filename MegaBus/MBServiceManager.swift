//
//  MBServiceManager.swift
//  MegaBus
//
//  Created by Javier Fuchs on 9/21/16.
//  Copyright © 2016 Fuchs. All rights reserved.
//

import Foundation
import CoreData

///
/// Service shared instance for the MegaBus Handy API Calls
///

public class MBServiceManager: NSObject {
    
    /// Alias for closures
    /// Success closure
    public typealias ServiceSuccess = ( result : AnyObject?) -> ()
    /// failure closure
    public typealias ServiceFailure = ( error : NSError) -> ()

    /// Constants used into the instance
    struct Constants {
        
        /// plist with the services availabel
        static let servicesPlist = "MBMegaBus"
        /// key inside plist where the services where listed
        static let environment = "ServiceManager"
        
        struct serviceURI {
            static let flights = "flights" // fetch flights schedules
            static let buses = "buses" // fetch buses schedules
            static let trains = "trains" // fetch trains schedules
        }
        
    }
    
    /// Private internal singleton to configure the services only once, not accessible from outside world
    private static let instance = MBServiceManager()
    
    /// services
    private var services : NSDictionary?
    
    /// connectivity
    private var online : Bool?
    
    /// init
    private override init() {
        super.init()
        
        configureServices()
        
        configureReachability()
    }
    
    /// Configuration of the services using a plist file
    private func configureServices() {
        guard let path = NSBundle.mainBundle().pathForResource(Constants.servicesPlist, ofType: "plist"),
            let servicesReaded = NSDictionary(contentsOfFile: path),
            let serviceEnvironment = servicesReaded[Constants.environment] as? NSDictionary else {
                assert(false, "Check if \(Constants.servicesPlist) is available in bundle")
                return
        }
        services = serviceEnvironment
        
        print(services)
    }
    
    /// Configuration of the reachability services
    private func configureReachability() {
        let reach = Reachability.init(hostName: "www.google.com")
        reach.reachableBlock = {  (r) in
            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                if let strong = self {
                    strong.online = true
                }
            })
        }
        reach.unreachableBlock = {  (r) in
            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                if let strong = self {
                    strong.online = false
                }
            })
        }
        reach.startNotifier()
    }
    
    /// that satisfy `uri` and fill the tokens inside.
    private class func buildPath(uri: String) -> String? {
        guard let services = instance.services else {
            assert(false, "Check if services where configured")
        }
        for (k,v) in services {
            if let key = k as? String {
                if uri == key {
                    if let value = v as? String {
                        return value
                    }
                }
            }
        }
        return nil
    }
    
    /// Name of the application
    public static var appName : String = {
        guard let info = NSBundle.mainBundle().infoDictionary,
            bundleName = info["CFBundleName"] as? String else {
                return ""
        }
        return bundleName
    }()
    
    /// returns true if the status is offline
    public class func isOffline() -> Bool {
        return !self.isOnline()
    }
    
    /// returns true if it's online
    public class func isOnline() -> Bool {
        if let online = instance.online {
            return online
        }
        return false
    }
    
    /// status code for the error
    public class func responseStatusCodeFromResponseError(error : NSError) -> Int {
        if let response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? NSHTTPURLResponse {
            return response.statusCode ?? 0
        }
        return 0
    }
    
    /// coredata task context
    lazy var mco: NSManagedObjectContext = {
        let _mco: NSManagedObjectContext = MBCoreDataManager.instance.taskContext
        return _mco
    }()

    
    /// Get data using path
    /// parameters: 3
    /// - path (uri from plist)
    /// - success closure with AnyObject (NSArray)
    /// On success returns a json containing an array of dictionaries with price and schedule information.
    /// [
    ///     {"id":1,
    ///       "provider_logo":"http://cdn-goeuro.com/static_content/web/logos/{size}/air_berlin.png",
    ///       "price_in_euros":"38.88",
    ///       "departure_time":"1:23",
    ///       "arrival_time":"19:55",
    ///       "number_of_stops":0
    ///      },
    ///      ...
    /// ]
    /// - failure closure with NSErrro
    private func getDataUsingPath(path: String, success: ServiceSuccess, failure: ServiceFailure) {
        guard let serviceUrl = NSURL.init(string: path) else {
            failure(error: NSError.requestError())
            return
        }
        
        let request = NSMutableURLRequest.init(URL: serviceUrl)
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            if let httpError = error {
                failure(error: httpError)
                return
            }
            guard let httpResponse = response as? NSHTTPURLResponse,
                      httpData = data else {
                failure(error: NSError.responseError(nil))
                return
            }
            
            if httpResponse.statusCode == 200 {
                let dictionary = try! NSJSONSerialization.JSONObjectWithData(httpData, options: .AllowFragments)
                success(result: dictionary)
            }
            else {
                failure(error: NSError.responseError(httpResponse.statusCode))
            }
            
        });
        
        task.resume()
        
    }
    
    
    /// call the get service and create MBTravel instances in CoreData
    /// parameters: 4
    /// - path (uri from plist)
    /// - travel mode: Buses, Flights, Trains
    /// - success closure with AnyObject (NSArray of MBTravel)
    /// - failure closure with NSErrro
    private class func fetchTravelWithPath(uri: String, travelMode: MBTravel.mode, success: ServiceSuccess, failure: ServiceFailure) {
        guard let path = self.buildPath(uri) else {
            failure(error: NSError.pathError())
            return
        }
        instance.getDataUsingPath(path, success: { (result) in
            guard let array = result as? NSArray else {
                failure(error: NSError.contentError())
                return
            }
            
            instance.mco.performBlockAndWait() {
                let travelObjects = NSMutableArray()
                do {
                    try MBTravel.deleteAll(instance.mco, travel_mode: travelMode)
                    for dictionary in array {
                        if let dictionaryTravel = dictionary as? NSDictionary,
                           let travel = MBTravel.create(inManageContextObject: instance.mco, dictionary: dictionaryTravel) {
                            travel.travel_mode = travelMode.rawValue
                            travelObjects.addObject(travel)
                        }
                    }
                    try instance.mco.save()
                }
                catch {
                    failure(error: NSError.fetchError())
                }
                success(result: travelObjects)
            }
            
        }, failure: failure)
    }
    
    /// REST: Fetch Busses
    public class func fetchBusWithSuccess(success: ServiceSuccess, failure: ServiceFailure) {
        fetchTravelWithPath(Constants.serviceURI.buses, travelMode: MBTravel.mode.modeBus, success: success, failure: failure)
    }
    
    /// REST: Fetch Trains
    public class func fetchTrainWithSuccess(success: ServiceSuccess, failure: ServiceFailure) {
        fetchTravelWithPath(Constants.serviceURI.trains, travelMode: MBTravel.mode.modeTrain, success: success, failure: failure)
    }
    
    /// REST: Fetch Flights
    public class func fetchFlightWithSuccess(success: ServiceSuccess, failure: ServiceFailure) {
        fetchTravelWithPath(Constants.serviceURI.flights, travelMode: MBTravel.mode.modeFlight, success: success, failure: failure)
    }
    
}
