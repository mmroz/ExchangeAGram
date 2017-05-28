//
//  FeedViewController.swift
//  ExchangeAGram
//
//  Created by Mark Mroz on 2017-05-20.
//  Copyright © 2017 MarkMroz. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData
import MapKit

class FeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, CustomFilterDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var feedArray: [AnyObject] = []
    
    var locationManager: CLLocationManager!
    
    // MARK: - App Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundImage = UIImage(named: "AutumnBackground")
        if let backgroundImage = backgroundImage {
            self.view.backgroundColor = UIColor(patternImage: backgroundImage)
        }
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 100.0
        locationManager.startUpdatingLocation()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FeedItem")
        let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        do {
            feedArray = try managedObjectContext.fetch(request)
        } catch {
            print(Error.self)
        }
        collectionView.reloadData()
    }
    
    // MARK: - Button Tapped Actions
    
    @IBAction func snapBarButtonItemTapped(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            
            let cameraController = UIImagePickerController()
            cameraController.delegate = self
            cameraController.sourceType = UIImagePickerControllerSourceType.camera
            
            let mediaTypes:[AnyObject] = [kUTTypeImage]
            cameraController.mediaTypes = mediaTypes as! [String]
            cameraController.allowsEditing = false
            
            self.present(cameraController, animated: true, completion: nil)
        } else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            let photoLibraryController = UIImagePickerController()
            photoLibraryController.delegate = self
            photoLibraryController.sourceType = UIImagePickerControllerSourceType.photoLibrary
            
            let mediaTypes:[AnyObject] = [kUTTypeImage]
            photoLibraryController.mediaTypes = mediaTypes as! [String]
            photoLibraryController.allowsEditing = false
            
            self.present(photoLibraryController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Alert", message: "Your device does not support the camera or photo Library", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func profileBarButtonItemTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "profileSegue", sender: nil)
    }
    
    
    // MARK: - UICollectionView Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return feedArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell:FeedCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! FeedCell
        let thisItem = feedArray[indexPath.section] as! FeedItem
        cell.imageView.image = UIImage(data: thisItem.image! as Data)
        cell.captionLabel.text = thisItem.caption
        return cell
    }
    
    
    // MARK: - UIImagePickerController Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        let thumbNailData = UIImageJPEGRepresentation(image, 0.1)
        let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let entityDescription = NSEntityDescription.entity(forEntityName: "FeedItem", in: managedObjectContext)
        let feedItem = FeedItem(entity: entityDescription!, insertInto: managedObjectContext)
        
        feedItem.image = imageData as NSData?
        feedItem.caption = "test caption"
        feedItem.thumbNail = thumbNailData as NSData?
        
        feedItem.latitude = locationManager.location!.coordinate.latitude
        feedItem.longitude = locationManager.location!.coordinate.longitude
        
        let UUID = NSUUID().uuidString
        feedItem.uniqueID = UUID
        
        feedItem.filtered = false
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        feedArray.append(feedItem)
        
        self.collectionView.reloadData()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let thisItem = feedArray[indexPath.row] as! FeedItem
        
        let filterVC = FilterViewController()
        filterVC.delegate = self
        filterVC.thisFeedItem = thisItem
        self.navigationController?.pushViewController(filterVC, animated: false)
    }
    
    // MARK: - Location Manager Delegate
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        print("locations = \(locations)")
    }
    
    // MARK: - CustomFilterDelegate
    
    func onSaveCompleted(feedItem: FeedItem) {
        self.feedArray.append(feedItem)
        self.collectionView.reloadData()
    }

}
