//
//  AppDelegate.swift
//  Fellow
//
//  Created by Mac-Triplei-Au on 7/6/2558 BE.
//  Copyright (c) 2558 Mac-Triplei-Au. All rights reserved.
//



import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ATLConversationListViewControllerDelegate, ATLConversationViewControllerDelegate {

    var window: UIWindow?
    
    var lastViewController: AnyObject?
    
    var getUserInfo: [NSObject : AnyObject] = [:]
    
    let ParseAppIDString: String = "QvrS99pSLUBnS3UiYlPDCL2BeP0riwYz1OncSCp7"
    let ParseClientKeyString: String = "BsWsJoRXsIFPRXi5E2UQ2aa1BaXDKFZJjfRFhjm8"
    
    var layerClient : LYRClient!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //setupParse
        setupParse()
        
        //Initializes a LYRClient object
        var urlLayerAppID = NSURL(string: "layer:///apps/staging/b6217282-23a6-11e5-8729-77a47d007ada")
        layerClient = LYRClient(appID: urlLayerAppID)
        layerClient.autodownloadMaximumContentSize = 1024 * 100
        layerClient.autodownloadMIMETypes = NSSet(objects: "image/jpeg") as Set<NSObject>
        
        if(layerClient.isConnected){
            println("Client is already connected!!")
        }else{
            // Tells LYRClient to establish a connection with the Layer service
            layerClient.connectWithCompletion { (success, error) -> Void in
                if (success){
                    println("Client is connected!")
                }else{
                    println("Layer error \(error)")
                }
            }
        }
        
        
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        let userNotificationTypes = (UIUserNotificationType.Alert |  UIUserNotificationType.Badge |  UIUserNotificationType.Sound);
        
        let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        // Extract the notification data
        if let notificationPayload = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
            NotificationOpenLayerView()
        }
        
        

        return true
    }
    
    func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject?) -> Bool {
            return FBSDKApplicationDelegate.sharedInstance().application(
                application,
                openURL: url,
                sourceApplication: sourceApplication,
                annotation: annotation)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current Installation and save it to Parse
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        self.getUserInfo = userInfo
        completionHandler(UIBackgroundFetchResult.NewData)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        // Extract the notification data
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        
        if self.getUserInfo.count != 0{
            NotificationOpenLayerView()
        }
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func setupParse() {
        // Enable Parse local data store for user persistence
        Parse.enableLocalDatastore()
        Parse.setApplicationId(ParseAppIDString, clientKey: ParseClientKeyString)
        
        // Set default ACLs
        let defaultACL: PFACL = PFACL()
        defaultACL.setPublicReadAccess(true)
        PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
    }
    
    
    
//    MARK: ATLConversationListViewControllerDelegate
    func conversationListViewController(conversationListViewController: ATLConversationListViewController!, didSelectConversation conversation: LYRConversation!) {
//        code
    }
    
//    MARK: ATLParticipantTableViewControllerDelegate
    func participantTableViewController(participantTableViewController: ATLParticipantTableViewController!, didSelectParticipant participant: ATLParticipant!) {
//        code
    }
    
    /**
    @abstract Informs the delegate that a search has been made with the following search string.
    @param participantTableViewController The participant table view controller in which the search was made.
    @param searchString The search string that was just used for search.
    @param completion The completion block that should be called when the results are fetched from the search.
    */
    func participantTableViewController(participantTableViewController: ATLParticipantTableViewController!, didSearchWithString searchText: String!, completion: ((Set<NSObject>!) -> Void)!) {
//        code
    }
    
    func NotificationOpenLayerView(){
        var token : dispatch_once_t = 0
        dispatch_once(&token) { () -> Void in
            
            let childViews = self.window?.rootViewController?.childViewControllers
            let rootViewController = self.window?.rootViewController as! UINavigationController
            
            println("getUserInfo:\(self.getUserInfo)")
            if(self.getUserInfo["type"] != nil){
                if(self.getUserInfo["type"]!.isEqualToString("addParticipant")){
                    let userQuery = PFQuery(className: "User")
                    let userParicipant: AnyObject? = self.getUserInfo["userParticipant"]
                    let userString = userParicipant as! [String]
                    println("user\(userString)")
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        
                        userQuery.whereKey("username", containedIn: userParicipant as! [AnyObject])
                        let users = userQuery.findObjects()
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let participants = NSSet(array: users as! [PFUser]) as Set<NSObject>
                            
                            self.layerClient.newConversationWithParticipants(participants, options: nil, error: nil)
                            
                            if !(childViews!.last!.isKindOfClass(ConversationListViewController)) {
                                let controller: ConversationListViewController = ConversationListViewController(layerClient: self.layerClient)
                                controller.delegate = self
                                let navigationController = UINavigationController(rootViewController: controller)
                                rootViewController.presentViewController(navigationController, animated: true, completion: nil)
                            }
                        })
                    })
                }
                else if (self.getUserInfo["type"]!.isEqualToString("getMessage")){
                    if !(childViews!.last!.isKindOfClass(ConversationListViewController)) {
                        let controller: ConversationListViewController = ConversationListViewController(layerClient: self.layerClient)
                        controller.delegate = self
                        let navigationController = UINavigationController(rootViewController: controller)
                        rootViewController.presentViewController(navigationController, animated: true, completion: nil)
                    }
                    

// Search แล้ว bug 
                    if !(childViews!.last!.isKindOfClass(ConversationViewController)) {
                        let controller = ConversationViewController(layerClient: self.layerClient)
                        controller.displaysAddressBar = true
                        controller.delegate = self
                        rootViewController.pushViewController(controller, animated: false)
                    }
//Search แล้วติด bug
//                    let controller: ConversationViewController = ConversationViewController(layerClient: self.layerClient)
                    
                    
//                    var myparticipants = Set<NSObject>()
//                    myparticipants.insert("xuYN5xAnIs")
//                    myparticipants.insert("JzIaq0OOFM")
//                    var myConversation : LYRConversation = LYRConversation()
//                    myConversation.addParticipants(myparticipants, error: nil)
//                    controller.conversation = myConversation
//                    controller.displaysAddressBar = true;
//                    
//                    let navigationController = UINavigationController(rootViewController: controller)
//                    self.window?.rootViewController?.navigationController?.pushViewController(navigationController, animated: true)
                }
            }
            else{
                
                let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                var VC = mainStoryboard.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
                
                let navController = UINavigationController(rootViewController: VC) as UINavigationController
                
                if !(childViews!.last!.isKindOfClass(ConversationListViewController)) {
                    
                    let controller: ConversationListViewController = ConversationListViewController(layerClient: self.layerClient)
                    controller.delegate = self
                    let navigationController = UINavigationController(rootViewController: controller)
                    rootViewController.presentViewController(navigationController, animated: true, completion: nil)
                }
            }

            self.getUserInfo = [:]
        }
    }

}

