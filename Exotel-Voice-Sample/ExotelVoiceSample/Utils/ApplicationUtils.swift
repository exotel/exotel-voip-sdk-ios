/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation
import UIKit
import Alamofire
import SVProgressHUD
import ExotelVoice

class Connectivity {
    class func isConnectedToInternet() -> Bool{
        return NetworkReachabilityManager()!.isReachable
    }
}

class ApplicationUtils {
    private static let TAG = "ApplicationUtils"
    private static var callContextListener: CallContextEvents?
    
    class func setCallContextListener(callContextListener: CallContextEvents) {
        self.callContextListener = callContextListener
    }
    
    class func showAlert(withMessage message: String? = nil, okayTitle: String = "Ok", cancelTitle: String? = nil,viewController:UIViewController, okCall: @escaping () -> () = { }, cancelCall: @escaping () -> () = { }) {
        let title = Constants.applicationName
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            if let cancelTitle = cancelTitle {
                let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { (_) in
                    cancelCall()
                }
                cancelAction.setValue(#colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1), forKey: "titleTextColor")
                alert.addAction(cancelAction)
            }
            let okayAction = UIAlertAction(title: okayTitle, style: .default) { (_) in
                okCall()
            }
            okayAction.setValue(#colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1), forKey: "titleTextColor")
            alert.addAction(okayAction)
            viewController.present(alert, animated: true)
        }
    }
    
    class func genricAlert(message: String){
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.natural
        let attributedMessageText = NSMutableAttributedString(
            string: message,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)
            ]
        )
        let alert = UIAlertController(title: Constants.applicationName, message: message, preferredStyle: .alert)
        alert.setValue(attributedMessageText, forKey: "attributedMessage")
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                VoiceAppLogger.error(TAG: TAG, message: "Failed to get the application delegate object.")
                return
            }
            guard let appWindow = appDelegate.window else {
                VoiceAppLogger.error(TAG: TAG, message: "Failed to get the application UI window object.")
                return
            }
            guard let rootVC = appWindow.rootViewController else {
                VoiceAppLogger.error(TAG: TAG, message: "Failed to get the application root view controller.")
                return
            }
            rootVC.present(alert, animated: true, completion: nil)
        }
    }
    
    
    class func alert(message : String, view:UIViewController){
        DispatchQueue.main.async {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.natural
            let attributedMessageText = NSMutableAttributedString(
                string: "\n\(message)",
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)
                ]
            )
            let alert = UIAlertController(title: Constants.applicationName, message: nil, preferredStyle: UIAlertController.Style.alert)
            alert.setValue(attributedMessageText, forKey: "attributedMessage")
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            alert.view.tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            view.present(alert, animated: true, completion: nil)
        }
    }
    
    class func alertDismiss(message : String, view:UIViewController){
        DispatchQueue.main.async {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.natural
            let attributedMessageText = NSMutableAttributedString(
                string: "\n\(message)",
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)
                ]
            )
            let alert = UIAlertController(title: Constants.applicationName, message: nil, preferredStyle: UIAlertController.Style.alert)
            alert.setValue(attributedMessageText, forKey: "attributedMessage")
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            alert.view.tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            view.present(alert, animated: true, completion: nil)
            
            // change to desired number of seconds (in this case 3 seconds)
            let when = DispatchTime.now() + 3
            DispatchQueue.main.asyncAfter(deadline: when){
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    class func svprogressHudShow(title:String,view:UIViewController) -> Void{
        SVProgressHUD.show(withStatus: title);
        SVProgressHUD.setDefaultAnimationType(SVProgressHUDAnimationType.native)
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.black)
        view.view.isUserInteractionEnabled = false
    }
    
    class func svprogressHudDismiss(view:UIViewController) -> Void{
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            view.view.isUserInteractionEnabled = true
        }
    }
    
    class func postData(_ strURL : String, params : String, success:@escaping ([String:Any]) -> Void, failure:@escaping (NSError) -> Void){
        
        if strURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true{
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Please Check Hostname."])
            return failure(error)
        } else {
            var request = URLRequest(url: URL(string: strURL)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let postString = params
            request.httpBody = postString.data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    if let err = error as? NSError {
                        failure(err)
                    }
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]
                    guard let request = jsonData else { return }
                    success(request)
                }  catch let error as NSError {
                    failure(error)
                    return
                }
            }
            task.resume()
        }
    }
    
    class func validateDialText(dialText: String) -> Bool {
        if dialText == "" {
            VoiceAppLogger.error(TAG: TAG, message: "No input entered in dial field.")
            return false
        }
        
        if dialText.starts(with: "+") {
            var input = dialText
            input.remove(at: input.startIndex)
            if input.range(of: "[^0-9]", options: .regularExpression) == nil {
                VoiceAppLogger.debug(TAG: TAG, message: "Valid input - \(dialText).")
                return true
            } else {
                VoiceAppLogger.error(TAG: TAG, message: "Invalid input - \(dialText).")
                return false
            }
        }
        
        if dialText.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil {
            VoiceAppLogger.debug(TAG: TAG, message: "Valid input - \(dialText).")
            return true
        }
        
        if dialText.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil {
            VoiceAppLogger.debug(TAG: TAG, message: "Valid input - \(dialText).")
            return true
        }
        
        VoiceAppLogger.error(TAG: TAG, message: "Invalid input - \(dialText).")
        return false
    }
    
    class func getUpdatedNumberToDial(destination: String) -> String {
        if destination.isEmpty {
            VoiceAppLogger.error(TAG: TAG, message: "getUpdatedNumberToDial: Dial number cannot be empty")
            return ""
        }
        if UserDefaults.standard.string(forKey: UserDefaults.Keys.enableDebugDialing.rawValue) == "true" {
            VoiceAppLogger.debug(TAG: TAG, message: "getUpdatedNumberToDial: Debug dialing is enabled. Dial number: \(destination)")
            return destination
        }
        let exophoneNumber = UserDefaults.standard.string(forKey: UserDefaults.Keys.exophoneNumber.rawValue) ?? ""
        VoiceAppLogger.debug(TAG: TAG, message: "getUpdatedNumberToDial: Debug dialing is disabled. Dial number: \(exophoneNumber)")
        return exophoneNumber
    }
    
    class func getUpdatedNumberToDialContact(destination: String, isSpecialNumber: Bool) -> String {
        if destination.isEmpty {
            VoiceAppLogger.error(TAG: TAG, message: "getUpdatedNumberToDialContact: Dial number cannot be empty")
            return ""
        }
        if !isSpecialNumber {
            let exophoneNumber = UserDefaults.standard.string(forKey: UserDefaults.Keys.exophoneNumber.rawValue) ?? ""
            VoiceAppLogger.debug(TAG: TAG, message: "getUpdatedNumberToDialContact: Dial regular number: \(exophoneNumber)")
            return exophoneNumber
        }
        
        VoiceAppLogger.debug(TAG: TAG, message: "getUpdatedNumberToDialContact: Dial special number: \(destination)")
        return destination
    }
    
    class func setCallContext(userId: String, destination: String, message: String) {
        var url = UserDefaults.standard.string(forKey: UserDefaults.Keys.bellatrixHostName.rawValue) ?? ""
        let accountSid = UserDefaults.standard.string(forKey: UserDefaults.Keys.accountSID.rawValue) ?? ""
        
        if url.isEmpty || accountSid.isEmpty || userId.isEmpty {
            VoiceAppLogger.error(TAG: TAG, message: "setCallContext: Host name, account id and user id cannot be empty")
            return
        }
        
        url = url + "/accounts/" + accountSid + "/subscribers/" + userId + "/context"
        let sipDestination = destination
        
        VoiceAppLogger.debug(TAG: TAG, message: "setCallContext: URL is: \(url)")
        VoiceAppLogger.debug(TAG: TAG, message: "setCallContext: Destination is: \(sipDestination)")
        VoiceAppLogger.debug(TAG: TAG, message: "setCallContext: userID is: \(userId)")
        VoiceAppLogger.debug(TAG: TAG, message: "setCallContext: message is: \(message)")
        
        let urlLink = NSURL(string: url)
        let parameters = ["dialToNumber": sipDestination,
                          "message": message]
        
        guard let bodyData = try? JSONSerialization.data(
            withJSONObject: parameters,
            options: []
        ) else {
            VoiceAppLogger.error(TAG: TAG, message: "setCallContext: json data serialization failed")
            return
        }
        
        let request = NSMutableURLRequest(url: urlLink! as URL)
        let accessToken = ExotelVoiceClientSDK.getToken()
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        
        let mData = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            guard let data = data, error == nil else {
                if error != nil {
                    VoiceAppLogger.error(TAG: TAG, message: "setCallContext: Failed to get response \(error!.localizedDescription)")
                }
                return
            }
            VoiceAppLogger.debug(TAG: TAG, message: "setCallContext: Got response: \(response.debugDescription) Data: \(data.debugDescription)")
        }
        mData.resume()
    }
    
    class func getCallContext(remoteId: String) {
        var url = UserDefaults.standard.string(forKey: UserDefaults.Keys.bellatrixHostName.rawValue) ?? ""
        let accountSid = UserDefaults.standard.string(forKey: UserDefaults.Keys.accountSID.rawValue) ?? ""
        
        if url.isEmpty || accountSid.isEmpty || remoteId.isEmpty {
            VoiceAppLogger.error(TAG: TAG, message: "getCallContext: Host name, account id and user id cannot be empty")
            return
        }
        
        url = url + "/accounts/" + accountSid + "/subscribers/" + remoteId + "/context"
        VoiceAppLogger.debug(TAG: TAG, message: "getCallContext: URL is: \(url)")
        
        let urlLink = NSURL(string: url)
        let request = NSMutableURLRequest(url: urlLink! as URL)
        let accessToken = ExotelVoiceClientSDK.getToken()
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        
        let mData = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            guard let data = data, error == nil else {
                if error != nil {
                    VoiceAppLogger.error(TAG: TAG, message: "getCallContext: Failed to get response \(error!.localizedDescription)")
                }
                return
            }
            do {
                let jsonDict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]
                guard let dict = jsonDict else {
                    VoiceAppLogger.debug(TAG: TAG, message: "getCallContext: Failed to read response received")
                    return
                }
                guard let status = dict["http_code"] as? Int else {
                    VoiceAppLogger.debug(TAG: TAG, message: "getCallContext: Failed to get valid HTTP response status code")
                    return
                }
                if status == 200 {
                    VoiceAppLogger.debug(TAG: TAG, message:"getCallContext: Response: \(dict) ")
                    let message = dict["message"] as? String ?? ""
                    if !message.isEmpty {
                        VoiceAppLogger.debug(TAG: TAG, message: "getCallContext: Status: \(status) Context message received: \(message)")
                        VoiceAppLogger.debug(TAG: TAG, message: "getCallContext: Setting shared preferences")
                        UserDefaults.standard.set(message, forKey: UserDefaults.Keys.contextMessage.rawValue)
                        if callContextListener != nil {
                            VoiceAppLogger.debug(TAG: TAG, message: "getCallContext: Sending callback")
                            callContextListener?.onGetContextSuccess()
                        }
                        return
                    } else {
                        VoiceAppLogger.debug(TAG: TAG, message: "getCallContext: Status: \(status) Context message received is empty")
                        return
                    }
                } else {
                    VoiceAppLogger.debug(TAG: TAG, message: "getCallContext: Status: \(status) Failed to get context message")
                    return
                }
            } catch let error {
                VoiceAppLogger.error(TAG: TAG, message: "getCallContext: Exception in reading response: \(error.localizedDescription)")
                return
            }
        }
        mData.resume()
    }
    
    class func removeCallContext(userId: String) {
        var url = UserDefaults.standard.string(forKey: UserDefaults.Keys.bellatrixHostName.rawValue) ?? ""
        let accountSid = UserDefaults.standard.string(forKey: UserDefaults.Keys.accountSID.rawValue) ?? ""
        
        if url.isEmpty || accountSid.isEmpty || userId.isEmpty {
            VoiceAppLogger.error(TAG: TAG, message: "removeCallContext: Host name, account id and user id cannot be empty")
            return
        }
        
        url = url + "/accounts/" + accountSid + "/subscribers/" + userId + "/context"
        VoiceAppLogger.debug(TAG: TAG, message: "removeCallContext: URL is: \(url)")
        
        let urlLink = NSURL(string: url)
        let request = NSMutableURLRequest(url: urlLink! as URL)
        let accessToken = ExotelVoiceClientSDK.getToken()
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        
        let mData = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            guard let data = data, error == nil else {
                if error != nil {
                    VoiceAppLogger.error(TAG: TAG, message: "removeCallContext: Failed to get response \(error!.localizedDescription)")
                }
                return
            }
            VoiceAppLogger.debug(TAG: TAG, message: "removeCallContext: \(response.debugDescription) Data: \(data.debugDescription)")
            VoiceAppLogger.debug(TAG: TAG, message: "removeCallContext: Removing shared preferences")
            UserDefaults.standard.set("", forKey: UserDefaults.Keys.contextMessage.rawValue)
        }
        mData.resume()
    }
    
    class func login(username: String, password: String, hostname: String, accountSid: String, displayName: String, viewController: UIViewController) {
        checkMicrophonePermission() { isEnabled in
            if isEnabled == false {
                DispatchQueue.main.async {
                    svprogressHudDismiss(view: viewController)
                    alert(message: missingMicrophonePermissionStr, view: viewController)
                    UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                }
                return
            } else {
                checkNotificationsPermission() { isEnabled in
                    if isEnabled == false {
                        DispatchQueue.main.async {
                            svprogressHudDismiss(view: viewController)
                            alert(message: missingNotificationPermissionStr, view: viewController)
                            UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                        }
                    } else {
                        loginUser(username: username, password: password, hostname: hostname, accountSid: accountSid, displayName: displayName, viewController: viewController)
                    }
                }
            }
        }
    }
    
    private static func loginUser(username: String, password: String, hostname: String, accountSid: String, displayName: String, viewController: UIViewController) {
        var api = APIList.init()
        api.BASE_URL = hostname
        let url = api.getUrlString(url: .REGISTRATION)
        let params = ["user_name": username.trimmingCharacters(in: .whitespacesAndNewlines), "password": password.trimmingCharacters(in: .whitespacesAndNewlines), "device_id": UIDevice.current.identifierForVendor?.uuidString, "account_sid": accountSid.trimmingCharacters(in: .whitespacesAndNewlines)]
        let requestData = jsonToString(json: params as [String : Any])
        VoiceAppLogger.debug(TAG: TAG, message: "Payload: \(requestData)" )
        
        UserDefaults.standard.resetMessages()
        UserDefaults.standard.set(hostname, forKey: UserDefaults.Keys.bellatrixHostName.rawValue)
        
        ApplicationUtils.postData(url, params: requestData, success: { response in
            DispatchQueue.main.async {
                VoiceAppLogger.debug(TAG: self.TAG, message: "Login response: \(response)")
                guard let status = response["http_code"] as? Int else { return }
                if status == 200 || status == 201 {
                    uploadFCMToken(username: username, hostname: hostname, accountSid: accountSid, viewController: viewController)
                    if let subscriber_token = response["subscriber_token"] as? [String:Any] {
                        UserDefaults.standard.set(response["exophone"] as? String ?? "", forKey: UserDefaults.Keys.exophoneNumber.rawValue)
                        UserDefaults.standard.set(response["subscriber_name"] as? String ?? "", forKey: UserDefaults.Keys.subscriberName.rawValue)
                        UserDefaults.standard.set(response["contact_display_name"] as? String ?? "", forKey: UserDefaults.Keys.contextDisplayName.rawValue)
                        UserDefaults.standard.set(response["host_name"] as? String ?? "", forKey: UserDefaults.Keys.milesHostName.rawValue)
                        UserDefaults.standard.set(response["account_sid"] as? String ?? "", forKey: UserDefaults.Keys.accountSID.rawValue)
                        UserDefaults.standard.set(password, forKey: UserDefaults.Keys.password.rawValue)
                        UserDefaults.standard.set(displayName.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UserDefaults.Keys.displayName.rawValue)
                        
                        VoiceAppService.shared.initialize(hostname: response["host_name"] as? String ?? "", subscriberName: response["subscriber_name"] as? String ?? "", accountSid: response["account_sid"] as? String ?? "", subscriberToken: jsonToString(json: subscriber_token), displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines))
                        
                        UserDefaults.standard.set("true", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                    }
                } else {
                    ApplicationUtils.svprogressHudDismiss(view: viewController)
                    ApplicationUtils.alert(message: "Failed to login.", view: viewController)
                    VoiceAppLogger.error(TAG: TAG, message: "Failed to login. Response: \(response)")
                    UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                }
            }
        }) { (error) in
            DispatchQueue.main.async {
                ApplicationUtils.svprogressHudDismiss(view: viewController)
                ApplicationUtils.alert(message: error.localizedDescription, view: viewController)
                
                if !error.localizedDescription.isEmpty {
                    UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
                }
            }
        }
    }
    
    class func uploadFCMToken(username: String, hostname: String, accountSid: String, viewController: UIViewController) {
        let url = hostname + "/accounts/" + accountSid + "/subscribers/" + username + "/devicetoken"
        VoiceAppLogger.debug(TAG: TAG, message: "firebaseURL: \(url)")
        
        let firebaseToken = UserDefaults.standard.string(forKey: UserDefaults.Keys.firebaseToken.rawValue)
        let params = ["deviceToken":  firebaseToken]
        let jsonParams = jsonToString(json: params as [String : Any])
        
        UserDefaults.standard.set(DeviceTokenState.stringFromEnum(deviceTokenState: .DEVICE_TOKEN_NOT_SENT), forKey: UserDefaults.Keys.deviceTokenState.rawValue)
        
        UserDefaults.standard.set(VoiceAppState.stringFromEnum(voiceAppState: .STATUS_INITIALIZATION_IN_PROGRESS), forKey: UserDefaults.Keys.voiceAppState.rawValue)
        
        ApplicationUtils.postData(url, params: jsonParams, success: { jsonDict in
            DispatchQueue.main.async {
                guard let status = jsonDict["http_code"] as? Int else { return }
                if status == 200 || status == 201 {
                    VoiceAppLogger.debug(TAG: self.TAG, message: "Sent device token successfully")
                    UserDefaults.standard.set(DeviceTokenState.stringFromEnum(deviceTokenState: .DEVICE_TOKEN_SEND_SUCCESS), forKey: UserDefaults.Keys.deviceTokenState.rawValue)
                    UserDefaults.standard.set(VoiceAppState.stringFromEnum(voiceAppState: .STATUS_READY), forKey: UserDefaults.Keys.voiceAppState.rawValue)
                } else {
                    ApplicationUtils.svprogressHudDismiss(view: viewController)
                    ApplicationUtils.alert(message: "Failed to upload device token.", view: viewController)
                    VoiceAppLogger.error(TAG: TAG, message: "Failed to upload device token. Response: \(jsonDict)")
                    UserDefaults.standard.set(DeviceTokenState.stringFromEnum(deviceTokenState: .DEVICE_TOKEN_SEND_FAILURE), forKey: UserDefaults.Keys.deviceTokenState.rawValue)
                    UserDefaults.standard.set(VoiceAppState.stringFromEnum(voiceAppState: .STATUS_INITIALIZATION_FAILURE), forKey: UserDefaults.Keys.voiceAppState.rawValue)
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: statusUpdate), object: nil, userInfo: nil)
            }
        }) { (error) in
            DispatchQueue.main.async {
                ApplicationUtils.svprogressHudDismiss(view: viewController)
                ApplicationUtils.alert(message: error.localizedDescription, view: viewController)
                UserDefaults.standard.set(DeviceTokenState.stringFromEnum(deviceTokenState: .DEVICE_TOKEN_NOT_SENT), forKey: UserDefaults.Keys.deviceTokenState.rawValue)
                UserDefaults.standard.set(VoiceAppState.stringFromEnum(voiceAppState: .STATUS_NOT_INITIALIZED), forKey: UserDefaults.Keys.voiceAppState.rawValue)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: statusUpdate), object: nil, userInfo: nil)
            }
        }
    }
    
    class func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if AVAudioSession.sharedInstance().recordPermission == .granted {
            VoiceAppLogger.debug(TAG: TAG, message: "Microphone permission granted")
            completion(true)
        } else {
            VoiceAppLogger.error(TAG: TAG, message: "Microphone permission denied")
            completion(false)
        }
    }
    
    class func checkNotificationsPermission(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { (settings) in
            if(settings.authorizationStatus == .authorized) {
                VoiceAppLogger.debug(TAG: self.TAG, message: "Push notification permission granted")
                completion(true)
            } else {
                VoiceAppLogger.error(TAG: self.TAG, message: "Push notification permission denied")
                completion(false)
            }
        }
    }
    
    class func logoutOnMissingPermission() {
        UserDefaults.standard.set("false", forKey: UserDefaults.Keys.isLoggedIn.rawValue)
        VoiceAppService.shared.reset()
        UserDefaults.standard.reset()
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                VoiceAppLogger.error(TAG: TAG, message: "Failed to get the application delegate object.")
                return
            }
            guard let appWindow = appDelegate.window else {
                VoiceAppLogger.error(TAG: TAG, message: "Failed to get the application UI window object.")
                return
            }
            guard let rootVC = appWindow.rootViewController else {
                VoiceAppLogger.error(TAG: TAG, message: "Failed to get the application root view controller.")
                return
            }
            if let navigationController = rootVC as? UINavigationController {
                navigationController.popToRootViewController(animated: true)
            }
        }
    }
    class func setIsReadyToReceiveCalls(flag:DarwinBoolean){
        VoiceAppService.shared.setIsReadyToReceiveCalls(flag: flag)
    }
    class func getIsReadyToReceiveCalls() -> DarwinBoolean{
        return VoiceAppService.shared.getIsReadyToReceiveCalls()
    }
    
 
    class func makeIPCall(number: String, destination: String) throws{
        UserDefaults.standard.set(destination, forKey: UserDefaults.Keys.lastDialedNumber.rawValue)
        try makeCall(phone: number, destination: "sip:"+destination)
        
    }
    
    class func makeWhatsappCall(destination: String) throws {
        UserDefaults.standard.set(destination, forKey: UserDefaults.Keys.lastDialedNumber.rawValue)
        let exophoneNumber = UserDefaults.standard.string(forKey: UserDefaults.Keys.exophoneNumber.rawValue) ?? ""
        if(exophoneNumber.isEmpty) {
            VoiceAppLogger.error(TAG: TAG, message: "Cannot find the expphone number to dial out")
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "exophone number is missing"])
            throw error
        }
        try makeCall(phone: exophoneNumber, destination: "wa:"+destination)
    }
    
    class func makeCall(phone: String, destination: String) throws {
        do {
            VoiceAppLogger.debug(TAG: TAG, message: "Initiating outgoing call")
            VoiceAppLogger.debug(TAG: TAG, message: "Dialing to phone: \(phone)")
            
            let call = try VoiceAppService.shared.dial(destination: phone, message: UserDefaults.standard.string(forKey: UserDefaults.Keys.contextDisplayName.rawValue) ?? "")
            if call != nil {
                ApplicationUtils.setCallContext(userId: UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue) ?? "", destination: destination, message: "")
                CallKitUtils.startCallOnCallkit(handle: phone)
            }

        } catch let voiceError as VoiceAppError {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to Dial from SDK: Module: \(voiceError.module) Error: \(voiceError.localizedDescription)")
            throw voiceError
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Dial: Failed to dial. \(error.localizedDescription)")
            throw error
        }
    }
    
}
