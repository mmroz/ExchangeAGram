//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by Mark Mroz on 2017-05-21.
//  Copyright © 2017 MarkMroz. All rights reserved.
//

import UIKit

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
        
            if thisFeedItem.thumbNail != nil {
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
        let filterImage = self.filteredImageFromImage(imageData: self.thisFeedItem.image!, filter: self.filters[indexPath.row])
        let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
        self.thisFeedItem.image = imageData as NSData!
        let thumbNailData = UIImageJPEGRepresentation(filterImage, 0.1)
        self.thisFeedItem.thumbNail = thumbNailData! as NSData
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        self.navigationController?.popViewController(animated: true)
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
        
//        let colorClamp = CIFilter(name: "CIColorClamp") ?? CIFilter()
//        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
//        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")
        
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
    
    // MARK: - Caching functions
    
    func cacheImage(imageNumber: Int) {
        let fileName = "\(imageNumber)"
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
        let fileName = "\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(path: fileName)
        var image : UIImage
        
        if FileManager.default.fileExists(atPath: uniquePath) {
            image = UIImage(contentsOfFile: uniquePath)!
        } else {
            self.cacheImage(imageNumber: imageNumber)
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





