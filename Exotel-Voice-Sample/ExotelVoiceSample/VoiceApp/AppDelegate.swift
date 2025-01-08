/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import UIKit
import IQKeyboardManagerSwift
import AVFoundation
import Firebase
import ExotelVoice
import UserNotifications
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder,UIApplicationDelegate {
    var user_callerId = ""
    var user_sessionid = ""
    var window: UIWindow?
    let TAG = "AppDelegate"
    var repeatingTimer : RepeatingTimer!
    var pushRegistry: PKPushRegistry?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
 
        VoiceAppLogger.setFilesDir()
        
        // Initialize PushKit for VoIP notifications
          pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
          pushRegistry?.delegate = self
          pushRegistry?.desiredPushTypes = [.voIP]
        // Override point for customization after application launch.
        FirebaseApp.configure()
        application.registerForRemoteNotifications()
//        Messaging.messaging().delegate = self
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            VoiceAppLogger.debug(TAG: TAG, message: "Microphone permission granted")
        case AVAudioSession.RecordPermission.denied:
            VoiceAppLogger.debug(TAG: TAG, message: "Microphone pemission denied")
            UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
            ApplicationUtils.genricAlert(message: missingMicrophonePermissionStr)
        case AVAudioSession.RecordPermission.undetermined:
            VoiceAppLogger.debug(TAG: TAG, message: "Request Microphone permission here")
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    VoiceAppLogger.debug(TAG: self.TAG, message: "The user granted access. Present recording interface.")
                } else {
                    VoiceAppLogger.debug(TAG: self.TAG, message: "Microphone pemission denied")
                    UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                    ApplicationUtils.genricAlert(message: missingMicrophonePermissionStr)
                }
            }
        @unknown default:
            VoiceAppLogger.debug(TAG: TAG, message: "Microphone permission coming to default ")
        }
        
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
//            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { (isEnabled, error) in
                    if error == nil {
                        if isEnabled {
                            VoiceAppLogger.debug(TAG: self.TAG, message: "Notifications pemission granted")
                        } else {
                            VoiceAppLogger.debug(TAG: self.TAG, message: "Notifications pemission denied")
                            UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                            ApplicationUtils.genricAlert(message: missingNotificationPermissionStr)
                        }
                    } else {
                        VoiceAppLogger.error(TAG: self.TAG, message: error?.localizedDescription ?? "")
                        UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                        ApplicationUtils.genricAlert(message: missingNotificationPermissionStr)
                    }
                }
            )
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        
        if #available(iOS 14.0, *) {
            CallKitUtils.inializeCallKit()
        }
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        VoiceAppLogger.debug(TAG: TAG, message: "Application is being moved to foreground")
        
        ApplicationUtils.checkMicrophonePermission() { isEnabled in
            if isEnabled == false {
                UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                ApplicationUtils.genricAlert(message: missingMicrophonePermissionStr)
                ApplicationUtils.logoutOnMissingPermission()
                return
            }
        }
        
        ApplicationUtils.checkNotificationsPermission() { isEnabled in
            if isEnabled == false {
                UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                ApplicationUtils.genricAlert(message: missingNotificationPermissionStr)
                ApplicationUtils.logoutOnMissingPermission()
                return
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        VoiceAppLogger.debug(TAG: TAG, message: "Application is terminating")
        
        if UserDefaults.standard.string(forKey: UserDefaults.Keys.isLoggedIn.rawValue) == "false" {
            VoiceAppLogger.debug(TAG: TAG, message: "Logged out. Clear all data stored.")
            let isLoggedOut = VoiceAppService.shared.deinitialize()
            if isLoggedOut {
                VoiceAppLogger.debug(TAG: TAG, message: "Cleared all data and SDK deinitialized")
            } else {
                VoiceAppLogger.error(TAG: TAG, message: "Failed to logout")
            }
        } else {
            VoiceAppLogger.debug(TAG: TAG, message: "Close application without logging out")
            UserDefaults.standard.disableFeatures()
            UserDefaults.standard.resetMessages()
            VoiceAppService.shared.reset()
            VoiceAppLogger.debug(TAG: TAG, message: "Disabled all the features")
            VoiceAppLogger.debug(TAG: TAG, message: "SDK reset completed")
        }
    }
}

extension AppDelegate: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }
        
        
        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        
        if(token.isEmpty) {
            VoiceAppLogger.debug(TAG: TAG, message: "FCM Token is not generated yet!!")
            return
        }
        VoiceAppLogger.debug(TAG: TAG, message: "PushKit token: \(token)")
//        showToast(message:token)
        VoiceAppLogger.debug(TAG: TAG, message:"Firebase registration token: \(String(describing: token))")
        UserDefaults.standard.set((String(describing: token)), forKey: UserDefaults.Keys.firebaseToken.rawValue)
        let dataDict: [String: String] = ["token": token ]
            NotificationCenter.default.post(
                name: Notification.Name("FCMToken"),
                object: nil,
                userInfo: dataDict)
        // Send token to your server for VoIP notifications
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
           
            VoiceAppLogger.debug(TAG: TAG, message: "VoIP push received ")

          ApplicationUtils.checkMicrophonePermission() { isEnabled in
              if isEnabled == false {
                  UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                 completion()
                  return
              }
          }
          
        
        
          ApplicationUtils.checkNotificationsPermission() { isEnabled in
              if isEnabled == false {
                  UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                  completion()
                  return
              }
          }
            guard let payloadDict = payload.dictionaryPayload as? [String: Any] else {
                 VoiceAppLogger.error(TAG: TAG, message: "Invalid payload format")
                completion()
                return
               
            }
          
            // Extract notification data
                  
             guard let callerId = payloadDict["subscriberName"] as? String else {
                 VoiceAppLogger.error(TAG: TAG, message: "callerId not found in payload")
                 completion()
                 return
             }
            
        
            VoiceAppService.shared.pushNotificationData = payloadDict
            let validateLogin = UserDefaults.standard.string(forKey: UserDefaults.Keys.isLoggedIn.rawValue) ?? "false"
            if validateLogin == "false" {
                VoiceAppLogger.error(TAG: TAG, message: "User is not logged into App")
                 completion()
                return
            }
            
        
            let state = UIApplication.shared.applicationState
            if state == .background || state == .inactive {
                VoiceAppLogger.debug(TAG: TAG, message: "App receiving notification in background mode\(state)")
//                NotificationPublisher.shared.pushNotificationData = userInfo
//                NotificationPublisher.shared.sendNotification(callerName: callerId)
                repeatingTimer = RepeatingTimer(timeInterval: 25.0)
                repeatingTimer.eventHandler = { [self] in
                    DispatchQueue.global(qos: .background).async {
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["CALL_ARRIVED"])
                        VoiceAppLogger.debug(TAG: self.TAG, message: "Notification cleared")
                        self.repeatingTimer = nil
                    }
                }
                repeatingTimer.resume()
                
        
                
            } else if state == .active {
                VoiceAppLogger.debug(TAG: TAG, message: "App receiving notification in foreground mode")
    //            VoiceAppService.shared.onReceivePushNotification()
            }
    //        completionHandler(UIBackgroundFetchResult.newData)
            
            
        

//        let _: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        CallKitUtils.displayIncomingCall(handle: callerId)
//        let incomingVC = storyBoard.instantiateViewController(withIdentifier: "IncomingCallViewController") as! IncomingCallViewController
     completion()
            
        }
}





//This is to extract payload data
extension AppDelegate {
    func decode(jwtToken jwt: String) -> [String: Any] {
        let segments = jwt.components(separatedBy: ".")
        return decodeJWTPart(segments[1]) ?? [:]
    }
    
    func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    func decodeJWTPart(_ value: String) -> [String: Any]? {
        guard let bodyData = base64UrlDecode(value),
              let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
            return nil
        }
        return payload
    }
    
    
    
    
    func showToast(message: String) {
        // Create a label and calculate its size based on the message text
        let toast = UILabel()
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.textColor = .white
        toast.textAlignment = .center
        toast.text = message
        toast.numberOfLines = 0 // Allow multiple lines
        toast.font = UIFont.systemFont(ofSize: 16)
        toast.layer.cornerRadius = 10
        toast.clipsToBounds = true
        
        // Calculate size based on the message
        let maxSize = CGSize(width: UIScreen.main.bounds.width - 40, height: UIScreen.main.bounds.height)
        let expectedSize = toast.sizeThatFits(maxSize)
        let width = expectedSize.width + 20
        let height = expectedSize.height + 20
        toast.frame = CGRect(x: 20, y: UIScreen.main.bounds.height - height - 50, width: width, height: height)
        
        // Add to window and show
        self.window?.addSubview(toast)
        
        // Animate fade-out and remove
        UIView.animate(withDuration: 10.0, delay: 2.0, options: .curveEaseOut, animations: {
            toast.alpha = 0.0
        }) { _ in
            toast.removeFromSuperview()
        }
    }

    
    
    
}
