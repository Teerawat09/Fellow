//
//  ViewController.swift
//  Fellow
//
//  Created by Mac-Triplei-Au on 7/6/2558 BE.
//  Copyright (c) 2558 Mac-Triplei-Au. All rights reserved.
//

import UIKit

class ViewController: UIViewController , PFLogInViewControllerDelegate, ATLConversationListViewControllerDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    var permissions = [ "public_profile", "email", "user_friends","user_likes"]
    var dict : NSDictionary!
    var logInController = PFLogInViewController()
    var locationManager:CLLocationManager!
    var checkItemList : [String] = ["G","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"]
    
    var channelList : [String] = []
    
    let myAppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var layerClient: LYRClient!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layerClient = myAppDelegate.layerClient
        // Do any additional setup after loading the view, typically from a nib.
        self.locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
        logInController.delegate = self
        
        let chatList = UIBarButtonItem(title: "Chat List", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("ChatListButtonTapped:"))
        self.navigationItem.setLeftBarButtonItem(chatList, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if PFUser.currentUser() != nil{
            //Insert UserInfo into Parse
            updateUserLocation()
            saveUserInfo(PFUser.currentUser()!)
                        
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
        self.updateUserLocation()
    }
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.layerRequestAuthentication(self.layerClient)
        })
    }
    
    func logout(){
        PFUser.logOutInBackgroundWithBlock { ( error:NSError?) -> Void in
            if error == nil {
                self.layerRequestDeAuthentication(self.layerClient)
                self.showPFLoginViewController()
            }else{
                println(error)
            }
        }
    }
    
    func showPFLoginViewController(){
        // Show the signup or login screen
        logInController.fields = (PFLogInFields.Facebook)
        logInController.facebookPermissions = permissions
        
        self.presentViewController(logInController, animated:true, completion:nil)
    }
    
    func saveUserInfo(currentUser: PFUser){
        // Do stuff with the user
        if((FBSDKAccessToken.currentAccessToken()) != nil){
            //deleteUserLikeList(currentUser)
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! NSDictionary
                    if let userInfoObject = PFUser.currentUser(){
                        userInfoObject["username"] = self.dict.valueForKey("name") as! String
                        userInfoObject["first_name"] = self.dict.valueForKey("first_name") as! String
                        userInfoObject["last_name"] = self.dict.valueForKey("last_name") as! String
                        userInfoObject["email"] = self.dict.valueForKey("email") as! String
                        
                        userInfoObject.saveInBackground()
                        let installation = PFInstallation.currentInstallation()
                        installation["user"] = PFUser.currentUser()
                        installation.saveInBackground()
                        self.updateUserLocation()
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
        currentInstallation.saveInBackground()
        
        currentInstallation.addUniqueObjectsFromArray(channelList, forKey: "channels")
        currentInstallation.saveInBackground()
        
        if let user =  PFUser.currentUser(){
            user["likes"] = currentInstallation.channels as [AnyObject]!
            user.saveInBackground()
        }
    }
    
    func updateUserLocation() {
        if self.locationManager.location != nil{
            let getLatitude : CLLocationDegrees? = self.locationManager.location.coordinate.latitude
            let getLongitude : CLLocationDegrees? = self.locationManager.location.coordinate.longitude
            if let lat = getLatitude , let lon = getLongitude {
                if let user =  PFUser.currentUser(){
                    user["location"] = PFGeoPoint(latitude: lat,longitude: lon) as PFGeoPoint
                    user.saveInBackground()
                }
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
    
    // MARK: LayerClient function
    
    func layerRequestAuthentication(layerClient : LYRClient){
        SVProgressHUD.show()
        // Request an authentication nonce from Layer
        layerClient.requestAuthenticationNonceWithCompletion { (nonce : String!, error : NSError!) -> Void in
            // Upon reciept of nonce, post to your backend and acquire a Layer identityToken
            if (nonce != nil) {
                let user = PFUser.currentUser()
                let userID = user!.objectId! as String

                PFCloud.callFunctionInBackground("generateToken", withParameters: ["nonce": nonce, "userID": userID]) { (object:AnyObject?, error: NSError?) -> Void in
                    if error == nil {
                        let identityToken = object as! String
                        layerClient.authenticateWithIdentityToken(identityToken) { authenticatedUserID, error in
                            if (error == nil) {
                                SVProgressHUD.dismiss()
                                println("Parse User authenticated with Layer Identity Token")
                                
                            }else{
                                SVProgressHUD.showErrorWithStatus("\(error)")
                                println("Parse User failed to authenticate with token with error: \(error)")
                            }
                        }
                    } else {
                        println("Parse Cloud function failed to be called to generate token with error: \(error)")
                    }
                }
            }
        }
    }
    
    func layerRequestDeAuthentication(layerClient : LYRClient){
        layerClient.deauthenticateWithCompletion { (success, error) -> Void in
            if(!success){
                println("Failed to deauthenticate user: \(error)")
            }else{
                println("User was deauthenticated")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendNotification(){
        // Find users near a given location
        let myCompanyLocation = PFGeoPoint(latitude: 13.904837646718576, longitude: 100.52979811952365)
        
        // Find users near a given location
        let userQuery = PFUser.query()
        userQuery!.whereKey("location", nearGeoPoint: myCompanyLocation, withinMiles: 1)
        
        // Find devices associated with these users
        let pushQuery = PFInstallation.query()
        pushQuery!.whereKey("user", matchesQuery: userQuery!)
        
        // Send push notification to query
        let push = PFPush()
        push.setQuery(pushQuery) // Set our Installation query
        push.setMessage("You are near at my Company")
        push.sendPushInBackground()
    }
    
    func sendNotify(#geoPoint : PFGeoPoint , channels : [AnyObject]){
        // Find users near a given location
        let userQuery = PFUser.query()
        userQuery!.whereKey("location", nearGeoPoint: geoPoint, withinMiles: 1)
        userQuery!.whereKey("likes", containedIn:channels)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            var userfindObjects = userQuery?.findObjects() as! [PFUser]
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                var userParticipant:[String] = {
                    var tempUserPlayers = [String]()
                    for userItem in userfindObjects {
                        tempUserPlayers.append(userItem.username!)
                    }
                    return tempUserPlayers
                }()
                                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    
                    // Find devices associated with these users
                    let pushQuery = PFInstallation.query()
                    pushQuery!.whereKey("user", matchesQuery: userQuery!)
                    
                    var data = [
                        "alert" : "มี \(userQuery!.countObjects() - 1) คน ชื่นชอบ\(channels.last as! String)เหมือนกับคุณ",
                        "badge" : "addParticipant",
                        "type"  : "addParticipant",
                        "userParticipant": userParticipant,
                        "sound" : "cheering.caf"
                    ]
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let push = PFPush()
                        push.setQuery(pushQuery) // Set our Installation query
                        push.setData(data as [NSObject : AnyObject])
                        push.sendPushInBackground()
                    })
                })
                
            })
        })

    }

    @IBAction func didTapLogout(sender: AnyObject) {
//        logout()
        if let location = locationManager.location?.coordinate {
            let myGeoPoint : PFGeoPoint = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)
            
            let randomIndex = Int(arc4random_uniform(UInt32(PFInstallation.currentInstallation().channels!.count)))
            let channelSelectedItem: NSArray? = [PFInstallation.currentInstallation().channels![randomIndex]]
            sendNotify(geoPoint: myGeoPoint, channels:channelSelectedItem as! [AnyObject])
        }
    }
//    MARK: ATLConversationListViewControllerDelegate
    func conversationListViewController(conversationListViewController: ATLConversationListViewController!, didSelectConversation conversation: LYRConversation!) {
//        code
    }
    
    func ChatListButtonTapped(sender: AnyObject) {
        
        let controller: ConversationListViewController = ConversationListViewController(layerClient: self.layerClient)
        controller.delegate = self
//        self.navigationController!.pushViewController(controller, animated: true)
        let navigationController = UINavigationController(rootViewController: controller)
        self.navigationController!.presentViewController(navigationController, animated: true, completion: nil)
        
    }
}

