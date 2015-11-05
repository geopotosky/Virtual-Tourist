//
//  PinPictureViewController.swift
//  VirtualTourist
//
//  Created by George Potosky on 8/9/15.
//  Copyright (c) 2015 GeoWorld. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PinPictureViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    //* - View Outlets
    @IBOutlet weak var pinMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var picActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var processingText: UITextField!
    
    //* - Sharing appDelegate variable
    var appDelegate: AppDelegate!

    //* - Create objects
    var pins: Pins!
    var picArray = [String]()
    
    //* - Selected shared coordinate variables
    var selectedLat : Double!
    var selectedLon : Double!
    
    //* - Alert variable
    var alertMessage: String!

    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //* - Recreate navigation Back button and change name to OK
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "OK", style: UIBarButtonItemStyle.Plain, target: self, action: "back:")
        self.navigationItem.leftBarButtonItem = newBackButton
        
        
        //* - Get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //* - Turn ON switch for map view control
        appDelegate.returningFromPhotoAlbum = true
        
        //* - Get the shared coordinate values
        self.selectedLat = appDelegate.selectedLatitude
        self.selectedLon = appDelegate.selectedLongitude
        
        //* - Set the selected pin coordinates
        let lat = pins.pinLat as Double
        let lon = pins.pinLon as Double
        
        //* - Add selected pin annotation to picture view map
        let initialLocation = CLLocation(latitude: lat, longitude: lon)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.pinMapView.addAnnotation(annotation)
        
        //* - Set the center and zoom location for pin
        zoomInOnMyLocation(initialLocation)
        
        // Start the fetched results controller
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            //* - Call Alert message
            self.alertMessage = "Error performing initial fetch: \(error)"
            self.errorAlertMessage()
        }
        
        fetchedResultsController.delegate = self
        
        //* - Bottom Button updater
        updateBottomButton()
        
    }
    
    // Layout the collection view cells
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that there are 3 cells accrosse
        // with white space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 3
        layout.minimumInteritemSpacing = 3

        let screenWidth = self.collectionView?.bounds.size.width
        let totalSpacing = layout.minimumInteritemSpacing * 3.0
        let imageSize = (screenWidth! - totalSpacing)/3.0
        layout.itemSize = CGSize(width: imageSize, height: imageSize)

        collectionView.collectionViewLayout = layout

    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pins.pics.isEmpty {
            
            //* - Disable button while processing
            //self.navigationItem.leftBarButtonItem?.enabled = false
            bottomButton.enabled = false
            
            //* - Deleting and saving picture delay helper
            self.processingText.hidden = true
            self.picActivityIndicator.hidden = false
            self.picActivityIndicator.startAnimating()
            
            //* - Call the Get Flickr Images function
            VTClient.sharedInstance().getFlickrData(self) { (success, picArray, errorString) in
                if success {
                    
                    if picArray.count > 0 {
                        var counter = 1
                        for tempPic in picArray {
                            
                            let pic = Pictures(picURL: tempPic as! String, context: self.sharedContext)
                            pic.pins = self.pins
                            CoreDataStackManager.sharedInstance().saveContext()

                            counter++
                        }
                    } else {
                        //* - Call Alert message
                        self.alertMessage = "Did not find any Picture URLs in the array"
                        self.errorAlertMessage()
                        
                        
                    }
                    
                    dispatch_async(dispatch_get_main_queue()){
                    //* - Call the Add images to array method
                    self.addNewPictures(picArray!)
                        }
                } else {
                    //* - Call Alert message
                    self.alertMessage = "Flickr Error Message! \(errorString)"
                    self.errorAlertMessage()
                } // End success

            } // End VTClient method
        }
        
    }
    
    
    //* - OK/Back Navigation Button
    
    func back(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }

    
    func addNewPictures(picArray: NSArray!){
        
        if picArray.count == 0 {
            //* - Call Alert message
            self.alertMessage = "Did not find any Pictures in the context"
            self.errorAlertMessage()
            
        } else {
            var counter2 = 1
            for pic in picArray{
                let picPath1 = pic as! String
                let imageURL = NSURL(string: picPath1)
                let urlRequest = NSURLRequest(URL: imageURL!)
                let mainQueue = NSOperationQueue()
                
                NSURLConnection.sendAsynchronousRequest(urlRequest, queue: mainQueue, completionHandler:{(response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                    if data.length > 0 && error == nil {
                        let image = UIImage(data: data)
                
                        //* - Save to local file
                        VTClient.Caches.imageCache.storeImage(image, withIdentifier: picPath1)
                
                        //* - Enable the OK button
                        //self.navigationItem.leftBarButtonItem?.enabled = true

                    }
                    else if data.length == 0 && error == nil {
                        //* - Call Alert message
                        self.alertMessage = "Nothing was downloaded"
                        self.errorAlertMessage()
                    }
                    else
                    {
                        //* - Call Alert message
                        self.alertMessage = "Error happened: \(error)"
                        self.errorAlertMessage()
                    }
                })
                counter2++
            }
            
        }
        
    }

    
    
    //* - Call the Delete picture(s) from the local direction function
    
    func deletePictures(indexPath: NSIndexPath){
        
        let pic = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Pictures
        
        let picPath1 = pic.picURL as String?
        let imageURL = NSURL(string: picPath1!)
        let urlRequest = NSURLRequest(URL: imageURL!)
        let mainQueue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: mainQueue, completionHandler:{(response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if data.length > 0 && error == nil {
                let image = UIImage(data: data)
                
                //* - Save to local file
                VTClient.Caches.imageCache.deleteImage(image, withIdentifier: picPath1!)
                
                //* - Enable the OK button
                //self.navigationItem.leftBarButtonItem?.enabled = true

            }
            else if data.length == 0 && error == nil {
                //* - Call Alert message
                self.alertMessage = "Nothing was downloaded"
                self.errorAlertMessage()
            }
            else
            {
                //* - Call Alert message
                self.alertMessage = "Error happened: \(error)"
                self.errorAlertMessage()
            }
        })

    }
    

    //* - Call the Delete picture(s) from the local direction function
    
    func deleteALLPictures(picPath2: String){
        
        let imageURL = NSURL(string: picPath2)
        let urlRequest = NSURLRequest(URL: imageURL!)
        let mainQueue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: mainQueue, completionHandler:{(response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if data.length > 0 && error == nil {
                let image = UIImage(data: data)

                //* - Save to local file
                VTClient.Caches.imageCache.deleteImage(image, withIdentifier: picPath2)
                
                //* - Enable the OK button
                //self.navigationItem.leftBarButtonItem?.enabled = true
                            }
            else if data.length == 0 && error == nil {
                //* - Call Alert message
                self.alertMessage = "Nothing was downloaded"
                self.errorAlertMessage()
            }
            else
            {
                //* - Call Alert message
                self.alertMessage = "Error happened: \(error)"
                self.errorAlertMessage()
            }
        })
    }

    
    //* - Configure Cell
    
    func configureCell(cell: PicCollectionCell, atIndexPath indexPath: NSIndexPath) {
        
        //* - Deleting and saving picture delay helper
        self.processingText.hidden = true
        self.picActivityIndicator.hidden = true
        self.picActivityIndicator.stopAnimating()
        
        let pic = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Pictures
        
        //* - Check for cached images
        if let localImage = pic.picImage {
                
                cell.pinImage.image = localImage
                
                //* - Turn off placeholder animations
                cell.placeholderImage.hidden = true
                cell.cellActivityIndicator.stopAnimating()
                cell.cellActivityIndicator.hidden = true
            
        }
        else {

            let picPath1 = pic.picURL as String
            let imageURL = NSURL(string: picPath1)
            let urlRequest = NSURLRequest(URL: imageURL!)
            let mainQueue = NSOperationQueue()
            
            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: mainQueue, completionHandler:{(response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                if data.length > 0 && error == nil {
                    let image = UIImage(data: data)

                    dispatch_async(dispatch_get_main_queue(),{
                    cell.pinImage.image = image
                    
                    //* - Turn off placeholder animations
                    cell.placeholderImage.hidden = true
                    cell.cellActivityIndicator.stopAnimating()
                    cell.cellActivityIndicator.hidden = true
                    }) //* - End Dispatch
                }
                else if data.length == 0 && error == nil{
                    //* - Call Alert message
                    self.alertMessage = "Nothing was downloaded"
                    self.errorAlertMessage()
                }
                else
                {
                    //* - Call Alert message
                    self.alertMessage = "Error happened: \(error)"
                    self.errorAlertMessage()
                }
                }) //* - End NSURLResponse
         
        } //End Main IF
            
        if let index = find(self.selectedIndexes, indexPath) {
            cell.pinImage!.alpha = 0.5
        } else {
            cell.pinImage!.alpha = 1.0
        }
        
        //* - Enable bottom button
        bottomButton.enabled = true

    }

    
    //* - UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PicCollectionCell", forIndexPath: indexPath) as! PicCollectionCell
        
        //* - Turn on placeholder animations
        let tempImage = UIImage(named: "placeholder1.jpg")
        cell.placeholderImage.image = tempImage
        cell.placeholderImage.hidden = false
        cell.cellActivityIndicator.hidden = false
        cell.cellActivityIndicator.startAnimating()
        
        dispatch_async(dispatch_get_main_queue(), {
            
            self.configureCell(cell, atIndexPath: indexPath)
            }) //-End Dispatch

        return cell

    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PicCollectionCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            //cell.cellOverlay.backgroundColor = UIColor.purpleColor()
            selectedIndexes.append(indexPath)
        }
            
        // Then reconfigure the cell
        self.configureCell(cell, atIndexPath: indexPath)

        // And update the buttom button
        updateBottomButton()
    }
    
    
    //* - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        println("self.pins: \(self.pins)")
        
        
        let fetchRequest = NSFetchRequest(entityName: "Pictures")
        fetchRequest.predicate = NSPredicate(format: "pins == %@", self.pins);
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
    
    //* - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to
    // create three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        //println("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each picture object that is added, deleted, or changed.
    // We store the index paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            //println("Insert an item")
            // Here we are noting that a new picture instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            //println("Delete an item")
            // Here we are noting that a picture instance has been deleted from Core Data. We keep remember its index
            // path so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath"
            // parameter has value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            //println("Update an item.")
            // We don't expect picture instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            //println("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        //println("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }

    
    //* - Click Button Decision function
    
    @IBAction func buttonButtonClicked() {
        
        bottomButton.enabled = false
        
        if selectedIndexes.isEmpty {
            //self.navigationItem.leftBarButtonItem?.enabled = false
            deleteAllPictures()
        } else {
            deleteSelectedPictures()
            
        }
    }
    
    //* - Delete All Pictures before adding new pictures function
    
    func deleteAllPictures() {
        
        //* - Deleting and saving picture delay helper
        self.processingText.hidden = true
        self.picActivityIndicator.hidden = false
        self.picActivityIndicator.startAnimating()
        
        for pic in self.fetchedResultsController.fetchedObjects as! [Pictures] {

            self.sharedContext.deleteObject(pic)
            
            //* - Delete Images on the local disk
            let picPath2 = pic.picURL
            self.deleteALLPictures(picPath2)
        }
        
        VTClient.sharedInstance().getFlickrData(self) { (success, picArray, errorString) in
            if success {
                
                if picArray.count > 0 {
                    var counter = 1
                    for tempPic in picArray {
                        
                        let pic = Pictures(picURL: tempPic as! String, context: self.sharedContext)
                        pic.pins = self.pins
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                        counter++
                    }
                } else {
                    //* - Call Alert message
                    self.alertMessage = "could not find any Picture URLs in the array"
                    self.errorAlertMessage()
                    
                }
                
                dispatch_async(dispatch_get_main_queue()){
                    //* - Call the Add images to array method
                    self.addNewPictures(picArray!)
                }
            } else {
                //* - Call Alert message
                self.alertMessage = "Flickr Error Message! \(errorString)"
                self.errorAlertMessage()
                
            } // End success
            
        } // End VTClient method
        
    }
    
    //* - Delete Selected Picture function
    
    func deleteSelectedPictures() {
        var picsToDelete = [Pictures]()
        
        for indexPath in selectedIndexes {
            picsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Pictures)
            
            //* - Delete Images on the local disk
            self.deletePictures(indexPath)
            
        }
        
        for pic in picsToDelete {
            sharedContext.deleteObject(pic)
            bottomButton.title = "New Collection"
        }
        
        selectedIndexes = [NSIndexPath]()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    //* - Update the button label based on selection criteria
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    
    //* - Picture View Map Zoom function
    
    func zoomInOnMyLocation(location: CLLocation) {
        
        let regionRadius: CLLocationDistance = 2000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius * 2.0, regionRadius * 2.0)
        pinMapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    //* - Alert Message function
    func errorAlertMessage(){
        dispatch_async(dispatch_get_main_queue()) {
            let actionSheetController: UIAlertController = UIAlertController(title: "Alert!", message: "\(self.alertMessage)", preferredStyle: .Alert)
            //* - Create and add the OK action
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .Default) { action -> Void in
                //self.dismissViewControllerAnimated(true, completion: nil)
            }
            actionSheetController.addAction(okAction)
            
            //* - Present the AlertController
            self.presentViewController(actionSheetController, animated: true, completion: nil)
        }
    }

    
}




