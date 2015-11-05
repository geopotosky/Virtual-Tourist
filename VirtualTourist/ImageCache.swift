//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Jason on 1/31/15.
//  Reused
//  Copyright (c) 2015 CCSF. All rights reserved.
//

import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    //* - Retrieving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {

        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        var data: NSData?
        
        // First try the memory cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        // Next Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    //* - Saving images
    
    func storeImage(picImage: UIImage?, withIdentifier identifier: String) {
        
        let path = pathForIdentifier(identifier)
        
        // If the image is nil, remove images from the cache
        if picImage == nil {
            inMemoryCache.removeObjectForKey(path)
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
            
            return
        }
        
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(picImage!, forKey: path)
        
        // And save in documents directory
        let data = UIImagePNGRepresentation(picImage!)
        data.writeToFile(path, atomically: true)
    }
    
    //* - Deleting images
    
    func deleteImage(image: UIImage?, withIdentifier identifier: String) {
        
        let path = pathForIdentifier(identifier.lastPathComponent)
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
        
    }
    
    
    //* - Local path creater Helper
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier.lastPathComponent)
        //println("local URL: \(fullURL)")
        return fullURL.path!
    }
    
}