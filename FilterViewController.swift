//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by Mark Mroz on 2017-05-21.
//  Copyright © 2017 MarkMroz. All rights reserved.
//

import UIKit

public protocol CustomFilterDelegate {
    func onSaveCompleted(feedItem : FeedItem)
}


class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    // Constants
    
    let kIntensity = 0.7
    let placeHolderImage = UIImage(named: "Placeholder")
    let tmp = NSTemporaryDirectory()
    
    // Properties
    var context:CIContext = CIContext(options: nil)
    var thisFeedItem: FeedItem!
    var collectionView: UICollectionView!
    var filters:[CIFilter] = []
    
    // MARK: - Delegate
    
    var delegate : CustomFilterDelegate!
    
    
    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 150.0, height: 150.0)
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.backgroundColor = UIColor.white
        
        collectionView.register(FilterCell.self, forCellWithReuseIdentifier: "MyCell")
        
        self.view.addSubview(collectionView)
        
        filters = photoFilters()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UICollectionView Data Source

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    // MARK: - CollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:FilterCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath) as! FilterCell
        
            if let thumbNail = thisFeedItem.thumbNail {
                cell.imageView.image = placeHolderImage
            
                let concurrentQueue = DispatchQueue(label: "filter queue", attributes: .concurrent)
            
                concurrentQueue.async(execute: { () -> Void in
                    
                    let filterImage = self.getCachedImage(imageNumber: indexPath.row)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        cell.imageView.image = filterImage
                    })
                })
            }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        createUIAlertController(indexPath: indexPath)
        
    }
    
    
    
    // MARK: -  Helpers
    
    func photoFilters () -> [CIFilter] {
        let blur = CIFilter(name: "CIGaussianBlur") ?? CIFilter()
        let instant = CIFilter(name: "CIPhotoEffectInstant") ?? CIFilter()
        let noir = CIFilter(name: "CIPhotoEffectNoir") ?? CIFilter()
        let transfer = CIFilter(name: "CIPhotoEffectTransfer") ?? CIFilter()
        let unsharpen = CIFilter(name: "CIUnsharpMask") ?? CIFilter()
        let monochrome = CIFilter(name: "CIColorMonochrome") ?? CIFilter()
        
        let colorControls = CIFilter(name: "CIColorControls") ?? CIFilter()
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)
        
        let sepia = CIFilter(name: "CISepiaTone") ?? CIFilter()
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)
        
        let composite = CIFilter(name: "CIHardLightBlendMode") ?? CIFilter()
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        let vignette = CIFilter(name: "CIVignette") ?? CIFilter()
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        vignette.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)
        
        return [blur, instant, noir, transfer, unsharpen, monochrome, colorControls, sepia, composite, vignette]
    }
    
    func filteredImageFromImage (imageData: NSData, filter: CIFilter) -> UIImage {
        
        let unfilteredImage = CIImage(data: imageData as Data)
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey)
        let filteredImage:CIImage = filter.outputImage!
        
        let extent = filteredImage.extent
        let cgImage: CGImage = context.createCGImage(filteredImage, from: extent)!
        
        let finalImage = UIImage(cgImage: cgImage)
        
        return finalImage
        
    }
    
    // MARK: - UIAlertController
    
    func createUIAlertController (indexPath : IndexPath) {
        let alert = UIAlertController(title: "Photo Options", message: "Please choose an option", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField { (textField) -> Void in
            textField.placeholder = "Add Caption!"
            textField.isSecureTextEntry = false
        }
        
        
        let photoAction = UIAlertAction(title: "Post Photo to Facebook with Caption", style: UIAlertActionStyle.destructive) { (UIAlertAction) -> Void in
            
            let text:String = {
                let textField = alert.textFields![0] as UITextField
                
                if let text = textField.text {
                    return text
                } else {
                    return ""
                }
            }()
            
            self.shareToFacebook(indexPath: indexPath)
            self.saveFilterToCoreData(indexPath: indexPath, caption: text)
        }
        
        let saveFilterAction = UIAlertAction(title: "Save Filter without posting on Facebook", style: UIAlertActionStyle.default) { (UIAlertAction) -> Void in
            
            let text:String = {
                let textField = alert.textFields![0] as UITextField
                
                if let text = textField.text {
                    return text
                } else {
                    return ""
                }
            }()
            
            self.saveFilterToCoreData(indexPath: indexPath, caption: text)
        }
        
        let cancelAction = UIAlertAction(title: "Select another Filter", style: UIAlertActionStyle.cancel) { (UIAlertAction) -> Void in
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveFilterAction)
        alert.addAction(photoAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveFilterToCoreData (indexPath: IndexPath, caption: String) {
        
        let concurrentQueue = DispatchQueue(label: "filter queue", attributes: .concurrent)
        
        concurrentQueue.async(execute: { () -> Void in
            
            let filterImage = self.filteredImageFromImage(imageData: self.thisFeedItem.image!, filter: self.filters[indexPath.row])
            let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
            
            self.thisFeedItem.image = imageData! as NSData
            
            let thumbNailData = UIImageJPEGRepresentation(filterImage, 0.1)
            
            self.thisFeedItem.thumbNail = thumbNailData! as NSData
            self.thisFeedItem.caption = caption
            
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate.onSaveCompleted(feedItem: self.thisFeedItem)
            })
        })
        
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func shareToFacebook (indexPath: IndexPath) {
        let filterImage = self.filteredImageFromImage(imageData: self.thisFeedItem.image!, filter: self.filters[indexPath.row])
        
        let photos:NSArray = [filterImage] as NSArray
        let params = FBPhotoParams()
        params.photos = photos as! [Any]
        
        FBDialogs.presentShareDialog(with: params, clientState: nil) { (call, result, error) -> Void in
            
            if let result = result {
                print(result)
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    // MARK: - Caching
    
    func cacheImage(imageNumber: Int) {
        let fileName = "\(String(describing: thisFeedItem.uniqueID))\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(path: fileName)
        if !FileManager.default.fileExists(atPath: fileName) {
            let data = self.thisFeedItem.thumbNail
            let filter = self.filters[imageNumber]
            let image = filteredImageFromImage(imageData: data!, filter: filter)
            do {
             try UIImageJPEGRepresentation(image, 1.0)!.write(to: URL(fileURLWithPath: uniquePath), options: .atomic)
            } catch {
                print(error)
            }
        
        }
    }
    
    func getCachedImage (imageNumber: Int) -> UIImage {
        let fileName = "\(String(describing: thisFeedItem.uniqueID))\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(path: fileName)
        var image : UIImage
        
        if FileManager.default.fileExists(atPath: uniquePath) {
//            let returnedImage = UIImage(contentsOfFile: uniquePath)!
//            image = UIImage(cgImage: returnedImage.cgImage!, scale: 1.0, orientation: UIImageOrientation.right)
            image = UIImage(contentsOfFile: uniquePath)!
            
        } else {
            self.cacheImage(imageNumber: imageNumber)
//            let returnedImage = UIImage(contentsOfFile: uniquePath)!
//            image = UIImage(cgImage: returnedImage.cgImage!, scale: 1.0, orientation: UIImageOrientation.right)
            image = UIImage(contentsOfFile: uniquePath)!
        }
        return image
    }
}

extension String {
    func stringByAppendingPathComponent(path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
}





