//
//  MBTravel+CoreDataProperties.swift
//  MegaBus
//
//  Created by Javier Fuchs on 9/22/16.
//  Copyright © 2016 Fuchs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MBTravel {

    @NSManaged var arrival_time: String?
    @NSManaged var departure_time: String?
    @NSManaged var id: Int16
    @NSManaged var number_of_stops: Int16
    @NSManaged var price_in_euros: Double
    @NSManaged var provider_logo: String?
    @NSManaged var travel_mode: Int16

}
