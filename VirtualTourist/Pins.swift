//
//  Pins.swift
//  VirtualTourist
//
//  Created by George Potosky on 8/9/15.
//  Copyright (c) 2015 GeoWorld. All rights reserved.
//

import Foundation
import CoreData

@objc(Pins)


class Pins : NSManagedObject {
    
    // We will store pin latitude and longitude values in these attributes
    @NSManaged var pinLat: Double
    @NSManaged var pinLon: Double
    @NSManaged var pics: [Pictures]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(pinLat: Double, pinLon: Double, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Pins", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.pinLat = pinLat
        self.pinLon = pinLon
        
    }
    
}

