//
//  DropPinViewController.swift
//  VirtualTourist
//
//  Created by George Potosky on 8/8/15.
//  Copyright (c) 2015 GeoWorld. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class DropPinViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    
    //* - Map View Controller outlets
    @IBOutlet weak var mapView: MKMapView!
    
    
    //* - Sharing appDelegate variable
    var appDelegate: AppDelegate!
    
    var pins: [Pins]!
    var LocationPin: [String]!
    var droppedPin = [MKAnnotation]()
    
    var savedRegion: MKCoordinateRegion?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //* - Get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

        //* - Turn OFF switch for map view control
        appDelegate.returningFromPhotoAlbum = false
        
        self.navigationController!.navigationBar.barTintColor = UIColor(red:0.69,green:0.85,blue:0.95,alpha:1.0)

        pins = fetchAllPins()
        
        //* - Display all stored pins
        self.getPins()
        mapView.delegate = self

        
        // This sets up the long tap to drop the pin.
        let longTap: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "didLongTapMap:")
        longTap.delegate = self
        longTap.numberOfTapsRequired = 0
        longTap.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longTap)

        //* - Call the latest saved map region method
        getStoredRegion()
        
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if savedRegion != nil && appDelegate.returningFromPhotoAlbum == false
        {
            mapView.region = savedRegion!
            mapView.setCenterCoordinate(
                savedRegion!.center,
                animated: true
            )
        }

    }


    func getStoredRegion(){
    
        // check for saved map info
        if let mapInfo = NSUserDefaults.standardUserDefaults().dictionaryForKey( "mapInfo" ) as? [ String : CLLocationDegrees ]
        {
            
            let centerLatitude = mapInfo[ "centerLatitude" ]!
            let centerLongitude = mapInfo[ "centerLongitude" ]!
            let spanLatDelta = mapInfo[ "spanLatitudeDelta" ]!
            let spanLongDelta = mapInfo[ "spanLongitudeDelta" ]!
            
            let newMapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: centerLatitude,
                    longitude: centerLongitude
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: spanLatDelta,
                    longitudeDelta: spanLongDelta
                )
            )
            savedRegion = newMapRegion
        }

    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()

    
    /**
    * This is the convenience method for fetching all persistent virtual tourist pins.
    * The method creates a "Fetch Request" and then executes the request on
    * the shared context.
    */
    func fetchAllPins() -> [Pins] {
        let error: NSErrorPointer = nil
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pins")
        
        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        self.mapView.addAnnotations(self.pins)

        
        // Check for Errors
        if error != nil {
            println("Error in fectchAllPins(): \(error)")
        }
        
        // Return the results, cast to an array of Pin objects
        return results as! [Pins]
    }
    
    
    //* - Populate the map with saved pins at startup
    
    func getPins() {

        var annotation = MKPointAnnotation()
        
        //Get Lat and Lon coordinates of dropped pin
        
        println("Number of Pin on Map: \(pins.count)")
        
        if pins.count > 0 {
            var counter = 1
            for pin in pins{
                
                var annotation = MKPointAnnotation()
                
                let lat = CLLocationDegrees(pin.pinLat as Double)
                let lon = CLLocationDegrees(pin.pinLon as Double)
                
                //* - The lat and long are used to create a CLLocationCoordinates2D instance.
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                annotation.coordinate = coordinate
                self.mapView.addAnnotation(annotation)
                
                counter++
            }
        } else {
            println("could not find any Pin entities in the context")
            
        }

    }

    
    //* - CURRENTLY NOT USED: Add a pin to the map by tapping only
    
    func didLongTapMap2(gestureRecognizer: UIGestureRecognizer) {
        // Get the spot that was tapped.
        let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
        
        var viewAtBottomOfHierarchy: UIView = mapView.hitTest(tapPoint, withEvent: nil)!
        if let viewAtBottom = viewAtBottomOfHierarchy as? MKPinAnnotationView {
            return
        } else {
            if .Began == gestureRecognizer.state {
                
                var annotation = MKPointAnnotation()
                annotation.coordinate = touchMapCoordinate
                
                
                //Get Lat and Lon coordinates of dropped pin
                let coordinate = annotation.coordinate as CLLocationCoordinate2D
                let latlong = ["%f, %f", coordinate.latitude, coordinate.longitude]
                
                // Now we add a new pin, using the shared Context
                
                let pinLatitude = coordinate.latitude as Double
                let pinLongitude = coordinate.longitude as Double
                
                // * - Store selected coordinates in shared values
                self.appDelegate.selectedLatitude = pinLatitude
                self.appDelegate.selectedLongitude = pinLongitude
                
                let pin = Pins(pinLat: pinLatitude, pinLon: pinLongitude, context: self.sharedContext)
                self.pins.append(pin)
                
                self.mapView.addAnnotation(annotation)
                
                CoreDataStackManager.sharedInstance().saveContext()
                
            }
        }
    }
    
    
    //* - Add a pin to the map by long tap and drag
    
    func didLongTapMap(gestureRecognizer: UIGestureRecognizer) {
        // Get the spot that was tapped.
        let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
        
        var annotation = MKPointAnnotation()
            
        switch gestureRecognizer.state {
            case .Began:
                
                //* - Add first long tap before dragging
                annotation.coordinate = touchMapCoordinate
                self.mapView.addAnnotation(annotation)
                droppedPin.append(annotation)
                
            case .Changed:
                
                //* - Remove all previous pins and add latest changed pin
                annotation.coordinate = touchMapCoordinate
                droppedPin.append(annotation)
                self.mapView.removeAnnotations(droppedPin)
                self.mapView.addAnnotation(annotation)

            case .Ended:
                
                //* - Remove all previous pins, latest pin, and save
                annotation.coordinate = touchMapCoordinate
                droppedPin.append(annotation)
                self.mapView.removeAnnotations(droppedPin)
                
                self.mapView.addAnnotation(annotation)
                
                //Get Lat and Lon coordinates of dropped pin
                let coordinate = annotation.coordinate as CLLocationCoordinate2D
                let latlong = ["%f, %f", coordinate.latitude, coordinate.longitude]
                
                // Now we add a new pin, using the shared Context
                
                let pinLatitude = coordinate.latitude as Double
                let pinLongitude = coordinate.longitude as Double
                
                // * - Store selected coordinates in shared values
                self.appDelegate.selectedLatitude = pinLatitude
                self.appDelegate.selectedLongitude = pinLongitude
                
                let pin = Pins(pinLat: pinLatitude, pinLon: pinLongitude, context: self.sharedContext)
                self.pins.append(pin)

                CoreDataStackManager.sharedInstance().saveContext()
                
            default:

                return
        }
    }
    
}


extension DropPinViewController: MKMapViewDelegate {
    
    
    //* - Update changed map view when region changes
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        
        // record the map region info
        let mapRegionCenterLatitude: CLLocationDegrees = mapView.region.center.latitude
        let mapRegionCenterLongitude: CLLocationDegrees = mapView.region.center.longitude
        let mapRegionSpanLatitudeDelta: CLLocationDegrees = mapView.region.span.latitudeDelta
        let mapRegionSpanLongitudeDelta: CLLocationDegrees = mapView.region.span.longitudeDelta
        
        // create a dictionary to store in the user defaults
        var mapDictionary = [ String : CLLocationDegrees ]()
        mapDictionary.updateValue( mapRegionCenterLatitude, forKey: "centerLatitude" )
        mapDictionary.updateValue( mapRegionCenterLongitude, forKey: "centerLongitude" )
        mapDictionary.updateValue( mapRegionSpanLatitudeDelta, forKey: "spanLatitudeDelta" )
        mapDictionary.updateValue( mapRegionSpanLongitudeDelta, forKey: "spanLongitudeDelta" )
        
        // save to NSUserDefaults
        NSUserDefaults.standardUserDefaults().setObject( mapDictionary, forKey: "mapInfo" )

    }
    
    
    //* - Create the Pin display
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinColor = .Red
            pinView!.draggable = true
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }

    
    //* - Pin selection Method
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        var annotation = MKPointAnnotation()
        //annotation.coordinate = touchMapCoordinate
        
        //* - Get Lat and Lon coordinates of dropped pin
        let coordinate = view.annotation.coordinate as CLLocationCoordinate2D
        let latlong = ["%f, %f", coordinate.latitude, coordinate.longitude]
        
        //* - Now we add a new pin, using the shared Context
        
        let pinLatitude = coordinate.latitude as Double
        let pinLongitude = coordinate.longitude as Double

        //* - Store selected coordinates in shared values
        self.appDelegate.selectedLatitude = pinLatitude
        self.appDelegate.selectedLongitude = pinLongitude
        
        //* - Loop thru pin objects and find the selected pin coordinates
        if pins.count > 0 {
            var index : Int = 0
            for pin in pins{
                
                let lat = CLLocationDegrees(pin.pinLat as Double)
                let lon = CLLocationDegrees(pin.pinLon as Double)
                
                if pinLatitude == lat && pinLongitude == lon {
                    
                    break;
                }
                
                index++
            }
            
            //* - Send pin object index to collection view
            let controller = storyboard!.instantiateViewControllerWithIdentifier("PinPictureViewController") as! PinPictureViewController
            
            controller.pins = pins[index]

            self.navigationController!.pushViewController(controller, animated: true)

        } else {
            println("Could not find any Pin matches")
            
        }
        
    }
    
    
}
