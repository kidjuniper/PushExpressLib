// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import UserNotifications

public final class PushExpressManager: NSObject {
    public static let shared = PushExpressManager()
    private var appId: String?
    private var icId: String?
    private var updateInterval: TimeInterval = 120

    public override init() {
        self.icId = UserDefaults.standard.string(forKey: "px_ic_id")
    }

    public func initialize(appId: String,
                    transportType: TransportType,
                           foreground: Bool,
                    extId: String?) {
        self.appId = appId

        if icId == nil {
            createAppInstance(transportType: transportType,
                              extId: extId)
        } else {
            updateAppInstance(transportType: transportType,
                              extId: extId)
            schedulePeriodicUpdate(transportType: transportType,
                                   extId: extId)
        }
        
        if foreground {
            UNUserNotificationCenter.current().delegate = PushExpressManager.shared
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            }
        }
    }
    
    public func setNotificationToken(token: String?) {
        UserDefaults.standard.setValue(token, forKey: "idOfNotificationToken")
    }

    private func createAppInstance(transportType: TransportType,
                                   extId: String?) {
        guard let url = URL(string: "https://core.push.express/api/r/v2/apps/\(appId ?? "")/instances") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let id = UUID().uuidString.lowercased()
        let params: [String: Any] = ["ic_token": id]

        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if error != nil {
                self.retryCreateAppInstance(transportType: transportType,
                                            extId: extId)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []),
                  let jsonDict = json as? [String: Any],
                  let id = jsonDict["id"] as? String else {
                self.retryCreateAppInstance(transportType: transportType,
                                            extId: extId)
                return
            }

            self.icId = id
            UserDefaults.standard.setValue(id, forKey: "px_ic_id")
            self.updateAppInstance(transportType: transportType,
                                   extId: extId)
            self.schedulePeriodicUpdate(transportType: transportType,
                                        extId: extId)
        }

        task.resume()
    }

    private func retryCreateAppInstance(transportType: TransportType,
                                        extId: String?) {
        let initialDelay = Double.random(in: 1...5)
        let maxDelay = 120.0
        var delay = initialDelay

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.createAppInstance(transportType: transportType,
                                    extId: extId)
            delay = min(delay * 2, maxDelay)
        }
    }
    
    private func getTimeZoneOffsetInSeconds() -> Int {
        let timeZone = TimeZone.current
        let secondsFromGMT = timeZone.secondsFromGMT()
        return secondsFromGMT
    }
    
    private func getSettedLanguage() -> String {
        if #available(iOS 16, *) {
            let locale = Locale.current.language.languageCode
            return "\(locale ?? "")"
        }
        else {
            return ""
        }
    }
    
    private func getCountry() -> String {
        let countryCode = Locale.current.regionCode
        return countryCode ?? ""
    }

    func updateAppInstance(transportType: TransportType,
                           extId: String?) {
        guard let icId = icId, let url = URL(string: "https://core.push.express/api/r/v2/apps/\(appId ?? "")/instances/\(icId)/info") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let params: [String: Any] = [
            "transport_type": transportType.rawValue,
            "transport_token": UserDefaults.standard.string(forKey: "idOfNotificationToken") ?? "",
            "platform_type": "ios",
            "platform_name": "ios",
            "ext_id": extId ?? "",
            "lang": getSettedLanguage(),
            "county": getCountry(),
            "tz_sec": getTimeZoneOffsetInSeconds()
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if error != nil {
                self.retryUpdateAppInstance(transportType: transportType,
                                            extId: extId)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []),
                  let jsonDict = json as? [String: Any],
                  let updateInterval = jsonDict["update_interval_sec"] as? TimeInterval else {
                self.retryUpdateAppInstance(transportType: transportType,
                                            extId: extId)
                return
            }
            
            self.updateInterval = updateInterval
        }

        task.resume()
    }

    private func retryUpdateAppInstance(transportType: TransportType,
                                        extId: String?) {
        let initialDelay = Double.random(in: 1...5)
        let maxDelay = 120.0
        var delay = initialDelay

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.updateAppInstance(transportType: transportType,
                                    extId: extId)
            delay = min(delay * 2, maxDelay)
        }
    }

    private func schedulePeriodicUpdate(transportType: TransportType,
                                        extId: String?) {
        DispatchQueue.global().asyncAfter(deadline: .now() + updateInterval) { [weak self] in
            self?.updateAppInstance(transportType: transportType,
                                    extId: extId)
            self?.schedulePeriodicUpdate(transportType: transportType,
                                         extId: extId)
        }
    }

    public func sendNotificationEvent(msgId: String, event: Events) {
        
        guard let icId = icId, let appId = appId, let url = URL(string: "https://core.push.express/api/r/v2/apps/\(appId)/instances/\(icId)/events/notification") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let params: [String: Any] = [
            "msg_id": msgId,
            "event": event.rawValue
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send notification event: \(error)")
            }
        }

        task.resume()
    }

    public func sendLifecycleEvent(event: Events) {
        guard let icId = icId, let url = URL(string: "https://core.push.express/api/r/v2/apps/\(appId ?? "")/instances/\(icId)/events/lifecycle") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let params: [String: Any] = [
            "event": event
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[PushExpress] Failed to send lifecycle event: \(error)")
            }
        }

        task.resume()
    }
}

