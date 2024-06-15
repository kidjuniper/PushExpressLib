//
//  UNUserNotificationCenterDelegate.swift
//
//
//  Created by Nikita Stepanov on 15.06.2024.
//

import UserNotifications

extension PushExpressManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let data = notification.request.content.userInfo
        if let msgId = data["px.msg_id"] as? String {
            if let title = data["px.title"] as? String, let body = data["px.body"] as? String {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                if let imageUrlString = data["px.image"] as? String, let imageUrl = URL(string: imageUrlString) {
                    URLSession.downloadImage(atURL: imageUrl) { attachment, error in
                        if let error = error {
                            print("[PushExpress] Failed to download image: \(error.localizedDescription)")
                        } else if let attachment = attachment {
                            content.attachments = [attachment]
                        }
                        
                        let request = UNNotificationRequest(identifier: msgId, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                    }
                } else {
                    let request = UNNotificationRequest(identifier: msgId, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
                PushExpressManager.shared.sendNotificationEvent(msgId: msgId, event: .delivered)
            }
        }
        
        completionHandler([.alert, .sound, .badge])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        if let data = userInfo as? [String: Any], let msgId = data["px.msg_id"] as? String {
            let a = msgId
            PushExpressManager.shared.sendNotificationEvent(msgId: a, event: .clicked)
        }
    }
}
