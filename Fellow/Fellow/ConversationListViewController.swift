import UIKit

class ConversationListViewController: ATLConversationListViewController, ATLConversationListViewControllerDelegate, ATLConversationListViewControllerDataSource , UINavigationBarDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        self.navigationController!.navigationBar.backIndicatorImage = UIImage(named: "backicon")
//        self.navigationController!.navigationBar.tintColor = ATLBlueColor()
        
        let logoutItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Reply, target: self, action: Selector("closeButtonTapped:"))
        
        self.navigationItem.setLeftBarButtonItem(logoutItem, animated: true)

        let composeItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Compose, target: self, action: Selector("composeButtonTapped:"))
        self.navigationItem.setRightBarButtonItem(composeItem, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK - ATLConversationListViewControllerDelegate Methods

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, didSelectConversation conversation:LYRConversation) {
        let controller = ConversationViewController(layerClient: self.layerClient)
        controller.conversation = conversation
        controller.displaysAddressBar = true
        self.navigationController!.pushViewController(controller, animated: true)
    }

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, didDeleteConversation conversation: LYRConversation, deletionMode: LYRDeletionMode) {
        println("Conversation deleted")
    }

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, didFailDeletingConversation conversation: LYRConversation, deletionMode: LYRDeletionMode, error: NSError?) {
        println("Failed to delete conversation with error: \(error)")
    }

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, didSearchForText searchText: String, completion: ((Set<NSObject>!) -> Void)?) {
        UserManager.sharedManager.queryForUserWithName(searchText) { (participants: NSArray?, error: NSError?) in
            if error == nil {
                if let callback = completion {
                    callback(NSSet(array: participants as! [AnyObject]) as Set<NSObject>)
                }
            } else {
                if let callback = completion {
                    callback(nil)
                }
                println("Error searching for Users by name: \(error)")
            }
        }
    }

    // MARK - ATLConversationListViewControllerDataSource Methods

    func conversationListViewController(conversationListViewController: ATLConversationListViewController, titleForConversation conversation: LYRConversation) -> String {
        if conversation.metadata["title"] != nil {
            return conversation.metadata["title"] as! String
        } else {
            let listOfParticipant = Array(conversation.participants)
            let unresolvedParticipants: NSArray = UserManager.sharedManager.unCachedUserIDsFromParticipants(listOfParticipant)
            let resolvedNames: NSArray = UserManager.sharedManager.resolvedNamesFromParticipants(listOfParticipant)
            
            if (unresolvedParticipants.count > 0) {
                UserManager.sharedManager.queryAndCacheUsersWithIDs(unresolvedParticipants as! [String]) { (participants: NSArray?, error: NSError?) in
                    if (error == nil) {
                        if (participants?.count > 0) {
                            self.reloadCellForConversation(conversation)
                        }
                    } else {
                        println("Error querying for Users: \(error)")
                    }
                }
            }
            
            if (resolvedNames.count > 0 && unresolvedParticipants.count > 0) {
                let resolved = resolvedNames.componentsJoinedByString(", ")
                return "\(resolved) and \(unresolvedParticipants.count) others"
            } else if (resolvedNames.count > 0 && unresolvedParticipants.count == 0) {
                return resolvedNames.componentsJoinedByString(", ")
            } else {
                return "Conversation with \(conversation.participants.count) users..."
            }
        }
    }

    // MARK - Actions

    func composeButtonTapped(sender: AnyObject) {
        let controller = ConversationViewController(layerClient: self.layerClient)
        controller.displaysAddressBar = true
        self.navigationController!.pushViewController(controller, animated: true)
    }

    func closeButtonTapped(sender: AnyObject) {
//        let controller = navigationController?.presentedViewController(layerClient: self.layerClient)
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
}
