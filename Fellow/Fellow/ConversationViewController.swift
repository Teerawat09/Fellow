import UIKit

class ConversationViewController: ATLConversationViewController, ATLConversationViewControllerDataSource, ATLConversationViewControllerDelegate, ATLParticipantTableViewControllerDelegate {
    var dateFormatter: NSDateFormatter = NSDateFormatter()
    var usersArray: NSArray!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        self.addressBarController.delegate = self
        
        // Setup the dateformatter used by the dataSource.
        self.dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle

        self.configureUI()
        
    }

    // MARK - UI Configuration methods

    func configureUI() {
        ATLOutgoingMessageCollectionViewCell.appearance().messageTextColor = UIColor.whiteColor()
    }

    // MARK - ATLConversationViewControllerDelegate methods

    func conversationViewController(viewController: ATLConversationViewController, didSendMessage message: LYRMessage) {
        println("Message sent! \(message.conversation)")
        
        var participantsId : [AnyObject] = []
        for participantItem in message.conversation.participants {
            participantsId.append(participantItem)
        }
        
        // Find users near a given location
        let userQuery = PFUser.query()
        userQuery!.whereKey("objectId", containedIn: participantsId)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            var userfindObjects = userQuery?.findObjects() as! [PFUser]
            
            // Find devices associated with these users
            let pushQuery = PFInstallation.query()
            pushQuery!.whereKey("user", matchesQuery: userQuery!)
                    
            var data = [
                "alert" : "คุณ \(PFUser.currentUser()!.username!) ได้ส่งข้อความสนทนาถึงคุณ",
                "badge" : "getMessage",
                "type"  : "getMessage",
                "sound" : "cheering.caf"
            ]
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let push = PFPush()
                push.setQuery(pushQuery) // Set our Installation query
                push.setData(data as [NSObject : AnyObject])
                push.sendPushInBackground()
            })
        })
    }

    func conversationViewController(viewController: ATLConversationViewController, didFailSendingMessage message: LYRMessage, error: NSError?) {
        println("Message failed to sent with error: \(error)")
    }

    func conversationViewController(viewController: ATLConversationViewController, didSelectMessage message: LYRMessage) {
        println("Message selected \(message)")
//        
//        
//        let msg : LYRMessagePart = message.parts[0] as! LYRMessagePart
//        if (msg.data != nil){
//            let msgtext : String = NSString(data:msg.data!, encoding:NSUTF8StringEncoding) as! String
//            let notifyMsg : LYRMessage = layerClient.newMessageWithParts(message.parts, options: [LYRMessageOptionsPushNotificationAlertKey: msgtext,LYRMessageOptionsPushNotificationSoundNameKey: "layerbell.caf"], error: nil)
//        }
    }

    // MARK - ATLConversationViewControllerDataSource methods

    func conversationViewController(conversationViewController: ATLConversationViewController, participantForIdentifier participantIdentifier: String) -> ATLParticipant? {
        if (participantIdentifier == PFUser.currentUser()!.objectId!) {
            return PFUser.currentUser()!
        }
        let user: PFUser? = UserManager.sharedManager.cachedUserForUserID(participantIdentifier)
        if (user == nil) {
            UserManager.sharedManager.queryAndCacheUsersWithIDs([participantIdentifier]) { (participants: NSArray?, error: NSError?) -> Void in
                if (participants?.count > 0 && error == nil) {
                    self.addressBarController.reloadView()
                    // TODO: Need a good way to refresh all the messages for the refreshed participants...
                    self.reloadCellsForMessagesSentByParticipantWithIdentifier(participantIdentifier)
                } else {
                    println("Error querying for users: \(error)")
                }
            }
        }
        return user
    }

    func conversationViewController(conversationViewController: ATLConversationViewController, attributedStringForDisplayOfDate date: NSDate) -> NSAttributedString? {
        let attributes: NSDictionary = [ NSFontAttributeName : UIFont.systemFontOfSize(14), NSForegroundColorAttributeName : UIColor.grayColor() ]
        return NSAttributedString(string: self.dateFormatter.stringFromDate(date), attributes: attributes as [NSObject : AnyObject])
    }

    func conversationViewController(conversationViewController: ATLConversationViewController, attributedStringForDisplayOfRecipientStatus recipientStatus: [NSObject:AnyObject]) -> NSAttributedString? {
        if (recipientStatus.count == 0) {
            return nil
        }
        let mergedStatuses: NSMutableAttributedString = NSMutableAttributedString()

        let recipientStatusDict = recipientStatus as NSDictionary
        let allKeys = recipientStatusDict.allKeys as NSArray
        allKeys.enumerateObjectsUsingBlock { participant, _, _ in
            let participantAsString = participant as! String
            if (participantAsString == self.layerClient.authenticatedUserID) {
                return
            }

            let checkmark: String = "✔︎"
            var textColor: UIColor = UIColor.lightGrayColor()
            let status: LYRRecipientStatus! = LYRRecipientStatus(rawValue: recipientStatusDict[participantAsString]!.unsignedIntegerValue)
            switch status! {
            case .Sent:
                textColor = UIColor.lightGrayColor()
            case .Delivered:
                textColor = UIColor.orangeColor()
            case .Read:
                textColor = UIColor.greenColor()
            default:
                textColor = UIColor.lightGrayColor()
            }
            let statusString: NSAttributedString = NSAttributedString(string: checkmark, attributes: [NSForegroundColorAttributeName: textColor])
            mergedStatuses.appendAttributedString(statusString)
        }
        return mergedStatuses;
    }

    // MARK - ATLAddressBarViewController Delegate methods methods

    override func addressBarViewController(addressBarViewController: ATLAddressBarViewController, didTapAddContactsButton addContactsButton: UIButton) {
        UserManager.sharedManager.queryForAllUsersWithCompletion { (users: NSArray?, error: NSError?) in
            if error == nil {
                let participants = NSSet(array: users as! [PFUser]) as Set<NSObject>
                let controller = ParticipantTableViewController(participants: participants, sortType: ATLParticipantPickerSortType.FirstName)
                controller.delegate = self
                
                let navigationController = UINavigationController(rootViewController: controller)
                self.navigationController!.presentViewController(navigationController, animated: true, completion: nil)
            } else {
                println("Error querying for All Users: \(error)")
            }
        }
    }

    override func addressBarViewController(addressBarViewController: ATLAddressBarViewController, searchForParticipantsMatchingText searchText: String, completion: (([AnyObject]) -> Void)?) {
        UserManager.sharedManager.queryForUserWithName(searchText) { (participants: NSArray?, error: NSError?) in
            if (error == nil) {
                if let callback = completion {
                    callback(participants! as [AnyObject])
                }
            } else {
                println("Error search for participants: \(error)")
            }
        }
    }

    // MARK - ATLParticipantTableViewController Delegate Methods

    func participantTableViewController(participantTableViewController: ATLParticipantTableViewController, didSelectParticipant participant: ATLParticipant) {
        println("participant: \(participant)")
        self.addressBarController.selectParticipant(participant)
        println("selectedParticipants: \(self.addressBarController.selectedParticipants)")
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func participantTableViewController(participantTableViewController: ATLParticipantTableViewController, didSearchWithString searchText: String, completion: ((Set<NSObject>!) -> Void)?) {
        UserManager.sharedManager.queryForUserWithName(searchText) { (participants, error) in
            if (error == nil) {
                if let callback = completion {
                    callback(NSSet(array: participants as! [AnyObject]) as Set<NSObject>)
                }
            } else {
                println("Error search for participants: \(error)")
            }
        }
    }

}
