//
//  VideoTableViewController.swift
//  MARA for iPhone
//
//  Created by Shree Raj Shrestha on 7/27/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import UIKit
import CoreData

class VideoTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    private let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    private var searchResults = [VideoDB]()
    private var searchController = UISearchController()
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "VideoDB")
        let primarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [primarySortDescriptor]
        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.managedObjectContext!,
            sectionNameKeyPath: nil,
            cacheName: nil)
        frc.delegate = self
        return frc
        }()
    
    override func viewDidLoad() {
        self.searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.scopeButtonTitles = ["name","tags"]
            controller.searchBar.delegate = self
            self.tableView.tableHeaderView = controller.searchBar
            self.definesPresentationContext = true;
            return controller
        })()
        
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("fetchedResultsController performFetch error: \(error?.localizedDescription)")
        }
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func helpButtonClicked(sender: UIButton) {
        let supportNC = self.storyboard?.instantiateViewControllerWithIdentifier("supportNC") as! UINavigationController
        supportNC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.presentViewController(supportNC, animated: true, completion: nil)
    }
    
    @IBAction func settingsButtonClicked(sender: UIBarButtonItem) {
        let settingsNC = self.storyboard?.instantiateViewControllerWithIdentifier("settingsNC") as! UINavigationController
        settingsNC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.presentViewController(settingsNC, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.searchController.active) {
            return self.searchResults.count
        }
        else if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as! NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell
        
        var media: VideoDB?
        if (self.searchController.active) {
            media = searchResults[indexPath.row]
        }
        else {
            media = fetchedResultsController.objectAtIndexPath(indexPath) as? VideoDB
        }
        let nameLabel = cell.viewWithTag(1) as! UILabel
        let tagsLabel = cell.viewWithTag(2) as! UILabel
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        let preview = cell.viewWithTag(3) as! UIImageView
        
        let pathComponents = NSArray(objects: documentsDirectory, "/Videos/", media!.fileName)
        let imagePath = NSURL.fileURLWithPathComponents(pathComponents as [AnyObject])!.path
        let asset = AVURLAsset(URL: NSURL(fileURLWithPath: imagePath!), options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        
        var error: NSError? = nil
        let cgImage = imgGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil, error: &error)
        if let err = error {
            println("AVURLAsset copyCGImageAtTime error: \(err.localizedDescription)")
        }
        var previewImage = UIImage(CGImage: cgImage)
        
        nameLabel.text = media!.name
        tagsLabel.text = media!.tags
        preview.image = previewImage
        
        return cell
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var media: NSManagedObject?
        if let cell = sender as? UITableViewCell {
            
            let indexPath = self.tableView.indexPathForSelectedRow()
            if (self.searchController.active) {
                media = searchResults[indexPath!.row]
            }
            else {
                media = fetchedResultsController.objectAtIndexPath(indexPath!) as? NSManagedObject
            }
        }
        
        switch segue.identifier! {
        case "toDetailView":
            let destinationVC = segue.destinationViewController.topViewController as! DetailViewController
            destinationVC.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            destinationVC.mediaType = "video"
            destinationVC.mediaObject = media
            self.searchController.active = false
        default:
            let destinationVC = segue.destinationViewController.topViewController as! AddMediaViewController
            destinationVC.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            destinationVC.mediaType = "video"
        }
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        var scope = NSString()
        switch self.searchController.searchBar.selectedScopeButtonIndex {
        case 0:
            scope = "name"
        default:
            scope = "tags"
        }
        let fetchRequest = NSFetchRequest(entityName: "VideoDB")
        let sortDescriptor = NSSortDescriptor(key: scope as String, ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let predicate = NSPredicate(format: "%K contains[cd] %@", scope, self.searchController.searchBar.text)
        fetchRequest.predicate = predicate
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [VideoDB] {
            searchResults = fetchResults
        }
        self.tableView.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.updateSearchResultsForSearchController(self.searchController)
    }
    
}
