//
//  ImageDB.swift
//  MARA Publisher
//
//  Created by Shree Raj Shrestha on 8/5/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import Foundation
import CoreData

class ImageDB: NSManagedObject {

    @NSManaged var date: String
    @NSManaged var descriptor: String
    @NSManaged var fileName: String
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var name: String
    @NSManaged var tags: String
    @NSManaged var url: String

}
