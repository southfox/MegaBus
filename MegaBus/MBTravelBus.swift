//
//  MBTravelBus.swift
//  MegaBus
//
//  Created by Javier Fuchs on 9/21/16.
//  Copyright © 2016 Fuchs. All rights reserved.
//

import Foundation
import CoreData

/// inheritance minimal, to fetch without parameters
public class MBTravelBus: MBTravel {

    public class func fetch() -> NSArray? {
        return try! super.fetchAll(MBCoreDataManager.instance.taskContext, travel_mode: mode.modeBus)
    }
}