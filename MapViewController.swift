//
//  MapViewController.swift
//  ExchangeAGram
//
//  Created by Mark Mroz on 2017-05-23.
//  Copyright © 2017 MarkMroz. All rights reserved.
//

import MapKit
import UIKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FeedItem")
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            let itemArray = try context.fetch(request) as! [FeedItem]
            
            if itemArray.count > 0 {
                for item in itemArray {
                    let location = CLLocationCoordinate2D(latitude: Double(item.latitude), longitude: Double(item.longitude))
                    let span = MKCoordinateSpanMake(0.05, 0.05)
                    let region = MKCoordinateRegionMake(location, span)
                    mapView.setRegion(region, animated: true)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = location
                    annotation.title = item.caption
                    self.mapView.addAnnotation(annotation)
                }
            }
        } catch let e {
            print("Unable to fetch feed items: \(e)")
        }
    }

}
