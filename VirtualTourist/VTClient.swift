//
//  VTClient.swift
//  VirtualTourist
//
//  Created by George Potosky on 8/20/15.
//  Copyright (c) 2015 GeoWorld. All rights reserved.
//


import Foundation
import UIKit
import CoreData


class VTClient : NSObject {
    
    //* - Shared session
    var session: NSURLSession

    
    //* - Get the app delegate
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //* - Initialize pin object
    var pins: Pins!
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
        
    }
    
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    
    
    //* - Start Flickr API
    
    func getFlickrData(hostViewController: UIViewController, completionHandler: (success: Bool, picArray: NSArray!, errorString: String?) -> Void) {
    
        //* - Assign latitude and longitude shared values
        let latitude = appDelegate.selectedLatitude
        let longitude = appDelegate.selectedLongitude
        
        let methodArguments = [
            MethodArguments.method: Constants.METHOD_NAME,
            MethodArguments.api_key: Constants.API_KEY,
            MethodArguments.bbox: self.createBoundingBoxString(),
            MethodArguments.safe_search: Constants.SAFE_SEARCH,
            MethodArguments.extras: Constants.EXTRAS,
            MethodArguments.format: Constants.DATA_FORMAT,
            MethodArguments.nojsoncallback: Constants.NO_JSON_CALLBACK
        ]
        
        self.getImageFromFlickrBySearch2(methodArguments) { (success, picArray, errorString) in
        //* - Chain completion handlers for each request, if applicable, so that they run one after the other */

            if success {
                completionHandler(success: true, picArray: picArray, errorString: errorString)
            } else {
                completionHandler(success: success, picArray: nil, errorString: errorString)
            }
        }
        
    }

    
    
    //* ---------------------------- Flickr API ------------------------- */
    
    
    /* Lat and Lon Function */
    func createBoundingBoxString() -> String {
        
        /* Define the latitude and longitude constants */
        let latitude = appDelegate.selectedLatitude
        let longitude = appDelegate.selectedLongitude
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - Constants.BOUNDING_BOX_HALF_WIDTH, Constants.LON_MIN)
        let bottom_left_lat = max(latitude - Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MIN)
        let top_right_lon = min(longitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LON_MAX)
        let top_right_lat = min(latitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    
    func getImageFromFlickrBySearch2(methodArguments: [String : AnyObject], completionHandler: (success: Bool, picArray: NSArray!, errorString: String?) -> Void) {
        
        var withPageDictionary = methodArguments
            
        //* - Initialize session and url
        let session = NSURLSession.sharedSession()
        let urlString = Constants.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        //* - Initialize task for getting data
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            if let error = downloadError {
                completionHandler(success: false, picArray: nil, errorString: "Could not complete the request \(error)")
            } else {
            //* - Success! Parse the data
            var parsingError: NSError? = nil
            let parsedResult: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
    
            if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
    
                dispatch_async(dispatch_get_main_queue(),{
                if let photosArray = photosDictionary["photo"] as? [[String:AnyObject]] {
                    
                    //* - Create a temporary picture array object to store URLs
                    var picArray = [String]()
                    
                    var count = 0
                    for photo in photosArray {
                        //* - Grab 21 random images
                        if count <= 20 {
                        // Grabs 1 image
                            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                            let photoDictionary = photosArray[randomPhotoIndex] as [String:AnyObject]
    
                            //* - Get the image url
                            let imageUrlString = photoDictionary["url_m"] as? String
                            picArray.append(imageUrlString!)
                            count += 1
                            
                        }
                    }
                    completionHandler(success: true, picArray: picArray, errorString: nil)
                }
                })
            }
        }
        }
        //* - Resume (execute) the task
        task.resume()
    }

    
    //* - Helper function: Given a dictionary of parameters, convert to a string for a url
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    //* ------------------------ End Flickr API -------------------------- */
    
    
    
    //* - Shared Instance
    
    class func sharedInstance() -> VTClient {
        
        struct Singleton {
            static var sharedInstance = VTClient()
        }
        
        return Singleton.sharedInstance
    }
    
    
    //* - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    
}