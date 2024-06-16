# PushExpressLib

**PushExpressLib** is a library designed to simplify the integration and handling of push notifications in iOS applications using the PushExpress service and Firebase Cloud Messaging (FCM).

## Requirements

- **Programming Language:** Swift 5.10 or higher
- **Platforms:** iOS

## Get Started

This guide will walk you through integrating PushExpressLib into your application and handling push notifications in both foreground and background states.

### Step 1: Project Setup

Before getting started, make sure your application is configured to receive remote notifications:

1. **Create an APNs certificate** and upload it to your FCM project.
2. **Enable the following capabilities in your target:**
   - Background Modes: check `Remote notifications`.
   - Push Notifications.

### Step 2: Import and Initialize Firebase

1. Install `FirebaseMessaging` using CocoaPods or Swift Package Manager (SPM).
2. Add the `GoogleService-Info.plist` file to your project.

3. Open `AppDelegate` and import the necessary modules:

   ```swift
   import Foundation
   import UIKit
   import Firebase
   import UserNotifications
   import FirebaseMessaging
Configure Firebase and register for remote notifications in AppDelegate:


    @main
    class AppDelegate: UIResponder, UIApplicationDelegate,          MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()  // Initialize Firebase
        application.registerForRemoteNotifications() // Register for remote notifications
        return true
    }
}
### Step 3: Register and Handle FCM Tokens
Conform to the MessagingDelegate protocol and implement the methods to handle tokens:


    @main
    class AppDelegate: UIResponder, UIApplicationDelegate,  MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()  // Initialize Firebase
        application.registerForRemoteNotifications() // Register for remote notifications
        Messaging.messaging().delegate = self // Set AppDelegate as the delegate for FCM
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken // Pass the APNs token to FCM
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}
### Step 4: Integrate PushExpressLib
Add PushExpressLib to your project and initialize it:


    import Foundation
    import UIKit
    import Firebase
    import UserNotifications
    import FirebaseMessaging
    import PushExpressLib

    @main
    class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()  // Initialize Firebase
        application.registerForRemoteNotifications() // Register for remote notifications
        Messaging.messaging().delegate = self // Set AppDelegate as the delegate for FCM
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken // Pass the APNs token to FCM
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        PushExpressManager.shared.setNotificationToken(token: fcmToken) // Set notification token
        PushExpressManager.shared.initialize(
            appId: "20908-1212", // PushExpress App ID
            transportType: .fcm, // Notification transport type (FCM)
            foreground: true, // Enable foreground notification handling
            extId: nil
        )
    }

Verify the integration:

Run your application.
Send a test notification from the PushExpress website. If everything is set up correctly, you should see the notification on your device.
### Step 5: Handle Notifications in Background
Add a new target Notification Service Extension:

Lower the OS version if needed (by default, the latest version is set).
Add PushExpressLib to Frameworks and Libraries of the extension.
Edit the NotificationService file:


    import UserNotifications
    import PushExpressLib

    class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    let notificationServiceManager = NotificationManager()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        notificationServiceManager.handleNotification(request: request, contentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
Verify background handling:

Close your application.
Send a test notification from the PushExpress website. If everything is set up correctly, you should see the notification on your device.
### Important Note
Handling notification clicks does not work if the application is in a Terminated state. 

### Conclusion
You have successfully configured push notification handling using PushExpressLib and Firebase Cloud Messaging in your iOS application! Follow these instructions to integrate notifications and handle them in both foreground and background modes.

If you have any questions or issues, please refer to the PushExpressLib documentation or contact support.
