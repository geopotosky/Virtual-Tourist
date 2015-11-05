//
//  Pictures.swift
//  VirtualTourist
//
//  Created by George Potosky on 8/17/15.
//  Copyright (c) 2015 GeoWorld. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(Pictures)

class Pictures: NSManagedObject {
    
    // Promote from simple properties to Core Data attributes
    @NSManaged var pins: Pins?
    @NSManaged var picURL: String
    
    // Core Data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(picURL: String!, context: NSManagedObjectContext) {
        // Get the entity associated with "Photo" type.
        let entity =  NSEntityDescription.entityForName("Pictures", inManagedObjectContext: context)!
        // Inherited init method
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.picURL = picURL
        
    }
    
    var picImage: UIImage? {
        get { return VTClient.Caches.imageCache.imageWithIdentifier(picURL) }
        set { VTClient.Caches.imageCache.storeImage(newValue, withIdentifier: picURL) }
    }
    
}


