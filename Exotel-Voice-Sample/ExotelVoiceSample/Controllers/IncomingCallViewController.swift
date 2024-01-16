/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import UIKit
import ExotelVoice

class IncomingCallViewController: UIViewController {
    
    @IBOutlet weak var contextMessage: UILabel!
    @IBOutlet weak var callerID: UILabel!
    @IBOutlet weak var callDirection: UILabel!
    
    var caller_id:String? = ""
    var context: AnyObject? = nil
    let TAG = "IncomingCallController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.callerID.text = caller_id ?? ""
        callDirection.text = "Incoming"
        if let contextData = context as? [String:AnyObject]{
            if let message = contextData["message"] as? String{
                self.contextMessage.text = message
            }
        } else if let contextData = context as? String {
            self.contextMessage.text = contextData
        }
        VoiceAppLogger.debug(TAG: TAG, message: "context message: \(self.contextMessage.text ?? "")")
        VoiceAppLogger.debug(TAG: TAG, message: "Incoming Call Ringing")
        let enableMultiCall = UserDefaults.standard.string(forKey: UserDefaults.Keys.enableMultiCall.rawValue)
        if enableMultiCall == "true" {
            VoiceAppLogger.debug(TAG: self.TAG, message: "Multi-Call: Accept the call")
            VoiceAppService.shared.answer()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusBarColorChangeIncomingCall()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCallEnded), name: Notification.Name(rawValue: endedCallKey), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: endedCallKey), object: nil)
    }
    
    @objc func onCallEnded(notification: NSNotification) {
        VoiceAppLogger.debug(TAG: TAG, message: "Incoming Call Ended")
        
        let enableMultiCall = UserDefaults.standard.string(forKey: UserDefaults.Keys.enableMultiCall.rawValue)
        if enableMultiCall == "true" {
            UserDefaults.standard.set("", forKey: UserDefaults.Keys.lastDialedNumber.rawValue)
        }
        let userId = UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue) ?? ""
        ApplicationUtils.removeCallContext(userId: userId)
        
        let call = notification.object as? Call ?? nil
        var callEndedMessage = ""
        if call != nil {
            let endReason = call?.getCallDetails().getCallEndReason()
            if endReason != nil {
                if endReason == .NONE {
                    callEndedMessage = "Call Ended"
                } else {
                    callEndedMessage = "Call Ended - " + CallEndReason.stringFromEnum(callEndReason: endReason!)
                }
            } else {
                callEndedMessage = "Call Ended"
            }
        } else {
            callEndedMessage = "Call Ended"
        }
        VoiceAppLogger.debug(TAG: TAG, message: callEndedMessage)
        DispatchQueue.main.async {
            UserDefaults.standard.set(callEndedMessage, forKey: UserDefaults.Keys.toastMessage.rawValue)
            self.navigationController?.popToViewController(of: HomeViewController.self, animated: true)
        }
    }
    
    @IBAction func rejectCall(_ sender: UIButton) {
        VoiceAppLogger.debug(TAG: TAG, message: "Rejecting call")
        do {
            try VoiceAppService.shared.hangup()
        } catch let hangupError as ExotelVoiceError {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to hangup call. \(hangupError.getErrorMessage())")
        } catch let otherError {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to hangup call. \(otherError.localizedDescription)")
        }
    }
    
    @IBAction func acceptCall(_ sender: UIButton) {
        VoiceAppService.shared.answer()
        navigationController?.popViewController(animated: true)
    }
}
