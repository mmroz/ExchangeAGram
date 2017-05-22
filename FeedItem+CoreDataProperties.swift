//
//  FeedItem+CoreDataProperties.swift
//  ExchangeAGram
//
//  Created by Mark Mroz on 2017-05-22.
//  Copyright © 2017 MarkMroz. All rights reserved.
//

import Foundation
import CoreData


extension FeedItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FeedItem> {
        return NSFetchRequest<FeedItem>(entityName: "FeedItem")
    }

    @NSManaged public var caption: String?
    @NSManaged public var image: NSData?
    @NSManaged public var thumbNail: NSData?

}
