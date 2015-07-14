//
//  ViewController.swift
//  Fellow
//
//  Created by Mac-Triplei-Au on 7/6/2558 BE.
//  Copyright (c) 2558 Mac-Triplei-Au. All rights reserved.
//

import UIKit

class ViewController: UIViewController , PFLogInViewControllerDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
   @IBOutlet weak var tableView: UITableView!
    
    var permissions = [ "public_profile", "email", "user_friends","user_likes"]
    var dict : NSDictionary!
    var logInController = PFLogInViewController()
    var locationManager:CLLocationManager!
    var checkItemList : [String] = ["G","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"]
    var channelList : [String] = []
    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
        logInController.delegate = self
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        var currentUser = PFUser.currentUser()
        if currentUser != nil {
            //Insert UserInfo into Parse
            updateUserLocation()
            saveUserInfo(currentUser!)
            
            if let channels = PFInstallation.currentInstallation().channels {
                channelList = channels as! [String]
                tableView.reloadData()
            }
            
        } else {
            // Show the signup or login screen
            showPFLoginViewController()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checkItemList.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        if let findItemIndex = find(channelList,checkItemList[indexPath.row]) {
            cell.accessoryType = .Checkmark
        }else{
            cell.accessoryType = .None
        }
        
        cell.textLabel?.text = self.checkItemList[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if cell.accessoryType == .Checkmark {
                cell.accessoryType = .None
                let findItemIndex = find(channelList,checkItemList[indexPath.row])
                channelList.removeAtIndex(findItemIndex!)
                
            } else {
                cell.accessoryType = .Checkmark
                channelList.append(checkItemList[indexPath.row]);
            }
            self.updateUserChannels()
            tableView.reloadData()
        }
    }
    
    func locationManager(manager: CLLocationManager!,   didUpdateLocations locations: [AnyObject]!) {
//        var locValue:CLLocationCoordinate2D = manager.location.coordinate
//        println("locations = \(locValue.latitude) \(locValue.longitude)")
        
    }
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showPFLoginViewController(){
        // Show the signup or login screen
//        var logInController = PFLogInViewController()
        logInController.fields = (PFLogInFields.Facebook)
        logInController.facebookPermissions = permissions
        self.presentViewController(logInController, animated:true, completion:nil)
    }
    
    func saveUserInfo(currentUser: PFUser){
        // Do stuff with the user
        if((FBSDKAccessToken.currentAccessToken()) != nil){
            //deleteUserLikeList(currentUser)
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, last_name, email"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! NSDictionary
                    var userInfoObject = PFObject(className: "UserInfo")
                    userInfoObject["UserLoginID"] = currentUser.objectId
                    userInfoObject["FacebookID"] = self.dict.valueForKey("id")
                    userInfoObject["first_name"] = self.dict.valueForKey("first_name")
                    userInfoObject["last_name"] = self.dict.valueForKey("last_name")
                    userInfoObject["email"] = self.dict.valueForKey("email")
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                        
                        let FacebookID: AnyObject? = userInfoObject["FacebookID"]
                        
                        var query  = PFQuery(className: "UserInfo")
                        query.whereKey("FacebookID", equalTo: FacebookID!)
                        
                        var findObject: AnyObject? = query.findObjects()
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            //Has findOject been recorded in ClassUserInfo?
                            if let findObj: AnyObject = findObject{
                                if findObj.count <= 0 {
                                    userInfoObject.save()
                                }else{
                                    //User has been recorded in class UserInfo
//                                    println("findObject = \(findObject!.count) meaning UserInfo has been recorded")
                                    
                                }
                                self.updateUserLocation()
//                                self.updateUserChannels()
                                //self.saveFBLikeList()
                                
                            }
                        }
                    }
                }
            })
            
        }else{
            //User not has currentAccessToken
        }
        
    }
    
    func updateUserChannels() {
        let currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.removeObjectForKey("channels")
        currentInstallation.addUniqueObjectsFromArray(channelList, forKey: "channels")
        currentInstallation.saveInBackground()
    }
    
    //inner func saveFBLikeList
    func saveFBLikeList(){
        if((FBSDKAccessToken.currentAccessToken()) != nil){
            
            FBSDKGraphRequest(graphPath: "me/likes?pretty=0&limit=999", parameters: nil).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! NSDictionary
                    var dataList: NSArray? = self.dict.valueForKey("data") as? NSArray
                    
                    var likeListName:[NSString] = []
                    
                    for item in dataList!{
                        likeListName.append( (item["name"] as! NSString).lowercaseString )
                    }
                    
                    likeListName = self.uniq(likeListName)
                    
                    for dataItem in likeListName {
                        var likeObject = PFObject(className: "Like")
                        likeObject["name"] = dataItem
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                            
                            var query  = PFQuery(className: "Like")
                            query.whereKey("name", equalTo: dataItem )
                            var findObject: AnyObject? = query.findObjects()
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                //Has findOject been recorded in ClassUserInfo?
                                if let findObj: AnyObject = findObject{
                                    if findObj.count <= 0 {
                                        
                                        likeObject.save()

                                    }else{
                                        //User has been recorded in class UserInfo
//                                        println("findObject = \(findObject!.count) meaning UserInfo has been recorded")
                                    }
                                }
                            }
                        }
                    }
                    
                    if PFUser.currentUser() != nil {
                        self.saveUserLikeList(PFUser.currentUser()!)
                    }
                    
                }
            })
            
        }else{
            //User not has currentAccessToken
        }
    }
    
    func saveManualLikeList() {
        
    }
    
    func saveUserLikeList(currentUser: PFUser) {
        
        if((FBSDKAccessToken.currentAccessToken()) != nil){
            
            FBSDKGraphRequest(graphPath: "me/likes?pretty=0&limit=999", parameters: nil).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! NSDictionary
                    var dataList: NSArray? = self.dict.valueForKey("data") as? NSArray
                    
                    var likeListName:[NSString] = []
                    
                    for item in dataList!{
                        likeListName.append( (item["name"] as! NSString).lowercaseString )
                    }
                    
                    likeListName = self.uniq(likeListName)
                    
                    for dataItem in likeListName {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                            var query  = PFQuery(className: "Like")
                            query.whereKey("name", equalTo: dataItem )
                            var findObjects = query.findObjects() as! [PFObject]
                            for findItem in findObjects {
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    //Has findOject been recorded in ClassUserInfo?
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                                        var query  = PFQuery(className: "UserLike")
                                        query.whereKey("LikeID", equalTo: findItem.objectId! )
                                        var findObjects = query.findObjects() as! [PFObject]
                                        if findObjects.count == 0 {
                                            dispatch_async(dispatch_get_main_queue()) {
                                                var UserLikeObject = PFObject(className: "UserLike")
                                                UserLikeObject["UserID"] = currentUser.objectId
                                                UserLikeObject["LikeID"] = findItem.objectId
                                            
                                                UserLikeObject.save()
                                            }
                                        }
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            })
            
        }else{
            //User not has currentAccessToken
        }
    }
    
    func updateUserLocation() {
        var query = PFQuery(className:"UserLocation")
        
        query.whereKey("UserID", equalTo: PFUser.currentUser()!.objectId!)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){

            if var findObjects = query.findObjects() as? [PFObject]{
                dispatch_async(dispatch_get_main_queue(),{
                    if findObjects.count <= 0 {
                        self.saveUserLocation(PFObject(className: "UserLocation"))
                    }else{
                        query.getObjectInBackgroundWithId(findObjects[0].objectId!) {
                            (PFobj: PFObject?, error: NSError?) -> Void in
                            if error != nil {
                                println(error)
                            } else {
                                self.saveUserLocation(PFobj)
                            }
                        }
                    }
                })
            }
        }
    }
    
    func saveUserLocation(PFobj: PFObject?) {
        let getLatitude : CLLocationDegrees? = self.locationManager.location.coordinate.latitude
        let getLongitude : CLLocationDegrees? = self.locationManager.location.coordinate.longitude
        if let obj = PFobj {
            if let lat = getLatitude , let lon = getLongitude {
                if PFUser.currentUser() != nil {
                    obj["UserID"] = PFUser.currentUser()!.objectId!
                    obj["GeoPoint"] = PFGeoPoint(latitude: lat,longitude: lon)
                    obj.saveInBackground()
                }
            }
        }
    }
    
    func deleteUserLikeList(currentUser: PFUser) {
        var query = PFQuery(className: "UserLike")
        query.whereKey("UserID", equalTo: currentUser.objectId!)
        var findObjects = query.findObjects() as! [PFObject]
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            for findItem in findObjects {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    findItem.delete()
                    
                })
            }
        }
    }
    
    // func เพื่อใช้ในการหาค่า Array ซ้ำ
    func uniq<S : SequenceType, T : Hashable where S.Generator.Element == T>(source: S) -> [T] {
        var buffer = [T]()
        var added = Set<T>()
        for elem in source {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didTapFacebookConnect(sender: AnyObject) {

        PFUser.logOutInBackgroundWithBlock { ( error:NSError?) -> Void in
            
            if error == nil {
                self.showPFLoginViewController()
            }else{
                println(error)
            }
        }
    }
}

