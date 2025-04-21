/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import UIKit
import ExotelVoice
import NotificationCenter
//import CallKit

class CallViewController: UIViewController, CallContextEvents {
    @IBOutlet weak var muteBtn: UIButton!
    @IBOutlet weak var speakerBtn: UIButton!
    @IBOutlet weak var mobileNumberLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var callStatusLbl: UILabel!
    @IBOutlet weak var callOptionsView: UIView!
    let TAG = "CallViewController"
    
    var destinationStr = ""
    var counter = 0
    var timer = Timer()
    var speakerToggle = false
    var muteToggle = true
    var ringingConnected = ""
    var payload_data:[String:String] = [:]
    var call: Call? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mobileNumberLbl.text = destinationStr
        speakerBtn.isHidden = true
        muteBtn.isHidden  = true
        if call != nil {
            let callDetails = call?.getCallDetails()
            if callDetails?.getCallDirection() == .INCOMING {
                callStatusLbl.text = "Answering.."
            } else if callDetails?.getCallDirection() == .OUTGOING {
                callStatusLbl.text = "Connecting.."
            }
        } else {
            VoiceAppLogger.debug(TAG: TAG, message: "No call")
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: false)
                UserDefaults.standard.set("Call Failed", forKey: UserDefaults.Keys.toastMessage.rawValue)
            }
        }
        timer.invalidate()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCallRinging), name: Notification.Name(rawValue: ringingCallKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCallEstablished), name: Notification.Name(rawValue: establishedCallKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCallDisruped), name: Notification.Name(rawValue: disruptedCallKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCallRenewed), name: Notification.Name(rawValue: renewedCallKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCallEnded), name: Notification.Name(rawValue: endedCallKey), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ringingCallKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: establishedCallKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: disruptedCallKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: renewedCallKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: endedCallKey), object: nil)
    }
    
    @objc func timerAction() {
        counter += 1
        timeLbl.text = timeString(time: TimeInterval(counter))
    }
    
    @objc func onCallRinging(notification: NSNotification) {
        VoiceAppLogger.debug(TAG: TAG, message: "Call Ringing")
        DispatchQueue.main.async {
            self.callStatusLbl.text = "Ringing.."
//            if #available(iOS 14.0, *) {
//                    CallKitUtils.reportConnectingOutgoingCall()
//            }
        }
    }
    
    @objc func onCallEstablished(notification: NSNotification) {
        VoiceAppLogger.debug(TAG: TAG, message: "Call Established")
        
        let enableMultiCall = UserDefaults.standard.string(forKey: UserDefaults.Keys.enableMultiCall.rawValue)
        if enableMultiCall == "true" {
            var count = 0
            let timeout = 40 //seconds
            DispatchQueue.main.async {
                let timerObject = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    count = count + 1
                    
                    //End timer when muli-call is disabled
                    if UserDefaults.standard.string(forKey: UserDefaults.Keys.enableMultiCall.rawValue) == "false" {
                        timer.invalidate()
                    } else if count == timeout {
                        do {
                            VoiceAppLogger.debug(TAG: self.TAG, message: "Multi-Call: End the call")
                            try VoiceAppService.shared.hangup()
                        } catch let error {
                            VoiceAppLogger.error(TAG: self.TAG, message: "Multi-Call: Failed to end call. \(error.localizedDescription)")
                        }
                        timer.invalidate()
                    }
                }
                timerObject.fire()
            }
        }
        
        DispatchQueue.main.async {
            self.timer.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
            VoiceAppService.shared.displayCallStatistics()
            self.callStatusLbl.text = "Connected"
            self.speakerBtn.isHidden = false
            self.muteBtn.isHidden  = false
            VoiceAppLogger.debug(TAG: self.TAG, message: "CUSTOM :: 1 ")
//            if #available(iOS 14.0, *) {
//                    CallKitUtils.reportConnectedOutgoingCall()
//            }
        }
    }
    
    @objc func onCallDisruped(notification: NSNotification) {
        VoiceAppLogger.debug(TAG: TAG, message: "Call Disruped")
        DispatchQueue.main.async {
            self.callStatusLbl.text = "Reconnecting"
        }
    }
    
    @objc func onCallRenewed(notification: NSNotification) {
        VoiceAppLogger.debug(TAG: TAG, message: "Call Connected")
        DispatchQueue.main.async {
            self.callStatusLbl.text = "Connected"
        }
    }
    
    @objc func onCallEnded(notification: NSNotification) {
        VoiceAppLogger.debug(TAG: TAG, message: "Call Ended")
        
        let enableMultiCall = UserDefaults.standard.string(forKey: UserDefaults.Keys.enableMultiCall.rawValue)
        if enableMultiCall == "true" {
            var count = 0
            let timeout = 20 //seconds
            DispatchQueue.main.async {
                let timerObject = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    count = count + 1
                    
                    //End timer when muli-call is disabled
                    if UserDefaults.standard.string(forKey: UserDefaults.Keys.enableMultiCall.rawValue) == "false" {
                        timer.invalidate()
                    } else if count == timeout {
                        do {
                            VoiceAppLogger.debug(TAG: self.TAG, message: "Multi-Call: Make next call")
                            let destination = UserDefaults.standard.string(forKey: UserDefaults.Keys.lastDialedNumber.rawValue) ?? ""
                            if destination.isEmpty {
                                VoiceAppLogger.error(TAG: self.TAG, message: "Multi-Call: Failed to get last dialed call data")
                            } else {
                                VoiceAppLogger.debug(TAG: self.TAG, message: "Multi-Call: Last dialed number from recent calls list: \(destination)")
                                let number = ApplicationUtils.getUpdatedNumberToDial(destination: destination)
                                if number.isEmpty {
                                    VoiceAppLogger.error(TAG: self.TAG, message: "Multi-Call: Cannot find the number to dial out")
                                } else {
                                    VoiceAppLogger.debug(TAG: self.TAG, message: "Dialing to: \(number)")
                                    let call = try VoiceAppService.shared.dial(destination: number, message: UserDefaults.standard.string(forKey: UserDefaults.Keys.contextDisplayName.rawValue) ?? "")
                                    if call != nil {
                                        ApplicationUtils.setCallContext(userId: UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue) ?? "", destination: destination, message: "")
                                    }
                                }
                            }
                        } catch let error {
                            VoiceAppLogger.error(TAG: self.TAG, message: "Multi-Call: Failed to make call. \(error.localizedDescription)")
                        }
                        timer.invalidate()
                    }
                }
                timerObject.fire()
            }
        }
        
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
            self.timer.invalidate()
            self.timeLbl.isHidden = true
            self.callStatusLbl.text = "call ended"
//            CallKitUtils.endCallonCallkit()
            self.navigationController?.popToViewController(of: HomeViewController.self, animated: true)
            UserDefaults.standard.set(callEndedMessage, forKey: UserDefaults.Keys.toastMessage.rawValue)
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format:"%02i:%02i", minutes, seconds)
        }
    }
    
    @IBAction func speakerBtnAction(_ sender: UIButton) {
//        if speakerToggle == true {
//            disableSpeaker()
//        } else {
//            enableSpeaker()
//        }
        presentAudioOutput(self,sender)
    }
    
    func enableSpeaker() {
        VoiceAppService.shared.enableSpeaker()
        speakerBtn.setImage(UIImage(named: "Btn_SpeakerOff"), for: .normal)
        speakerToggle = true
    }
        
    func disableSpeaker() {
        VoiceAppService.shared.disableSpeaker()
        speakerBtn.setImage(UIImage(named: "Btn_SpeakerOn"), for: .normal)
        speakerToggle = false
    }
    
    @IBAction func muteBtnAction(_ sender: UIButton) {
        if muteToggle == true {
            VoiceAppService.shared.mute()
            muteToggle = false
            muteBtn.setImage(UIImage(named: "Btn_Unmute"), for: .normal)
        } else {
            VoiceAppService.shared.unmute()
            muteToggle = true
            muteBtn.setImage(UIImage(named: "Btn_Mute"), for: .normal)
        }
    }
    
    @IBAction func endCallBtnAction(_ sender: UIButton) {
        VoiceAppLogger.debug(TAG: TAG, message: "Hangup Call")
        DispatchQueue.main.async {
            do {
                try VoiceAppService.shared.hangup()
//                CallKitUtils.endCallonCallkit()
            } catch let error {
                VoiceAppLogger.debug(TAG: self.TAG, message: "Error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func showKeypadBtnAction(_ sender: UIButton) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let customKeyPadVC = storyBoard.instantiateViewController(withIdentifier: "CustomKeyPadVC") as! CustomKeyPadVC
        navigationController?.pushViewController(customKeyPadVC, animated: false)
    }
    
    
    func enableBluetooth() {
        VoiceAppService.shared.enableBluetooth()
    }
    
    func disableBluetooth() {
        VoiceAppService.shared.disableBluetooth()
    }
    
    
    func onGetContextSuccess() {
        VoiceAppLogger.debug(TAG: TAG, message: "onGetContextSuccess: Successfully got context")
    }
    
    func presentAudioOutput(_ presenterViewController : UIViewController, _ sourceView: UIView) {
            let speakerTitle = "Speaker"
            let headphoneTitle = "Headphones"
            let deviceTitle = (UIDevice.current.userInterfaceIdiom == .pad) ? "iPad" : "iPhone"
            let cancelTitle = "Cancel"
            
            var deviceAction = UIAlertAction()
            var headphonesExist = false
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            guard let availableInputs = AVAudioSession.sharedInstance().availableInputs else {
                print("No inputs available ")
                return
            }
            
            for audioPort in availableInputs {
                switch audioPort.portType {
                case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE :
                    let bluetoothAction = UIAlertAction(title: audioPort.portName, style: .default) { _ in
                        VoiceAppService.shared.enableBluetooth()
                    }
                    
                    if isCurrentOutput(portType: audioPort.portType) {
                        bluetoothAction.setValue(true, forKey: "checked")
                    }
                    
                    optionMenu.addAction(bluetoothAction)
                    
                case .builtInMic, .builtInReceiver:
                    
                    deviceAction = UIAlertAction(title: deviceTitle, style: .default, handler: { _ in
                        VoiceAppService.shared.disableSpeaker()
                    })
                    if (isCurrentOutput(portType: .builtInReceiver) ||
                        isCurrentOutput(portType: .builtInMic)) {
                        deviceAction.setValue(true, forKey: "checked")
                    }
                    
                case .headphones, .headsetMic:
                    headphonesExist = true
                    
                    let headphoneAction = UIAlertAction(title: headphoneTitle, style: .default) { _ in
                        
                    }
                    
                    if isCurrentOutput(portType: .headphones) || isCurrentOutput(portType: .headsetMic) {
                        headphoneAction.setValue(true, forKey: "checked")
                    }
                    
                    optionMenu.addAction(headphoneAction)
                
                default:
                    break
                }
            }
            
            // device actions only required if no headphone available
            if !headphonesExist {
                optionMenu.addAction(deviceAction)
            }
            
            let speakerAction = UIAlertAction(title: speakerTitle, style: .default) { _ in
                VoiceAppService.shared.enableSpeaker()
            }
            optionMenu.addAction(speakerAction)
            if isCurrentOutput(portType: .builtInSpeaker) {
                speakerAction.setValue(true, forKey: "checked")
            }
            // configure cancel action
            let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
            optionMenu.addAction(cancelAction)
            
            optionMenu.modalPresentationStyle = .popover
            if let presenter = optionMenu.popoverPresentationController {
                presenter.sourceView = sourceView
                presenter.sourceRect = sourceView.bounds
            }
            
            presenterViewController.present(optionMenu, animated: true, completion: nil)
            
            // auto dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                optionMenu.dismiss(animated: true, completion: nil)
            }
        }
        func isCurrentOutput(portType: AVAudioSession.Port) -> Bool {
            return AVAudioSession.sharedInstance().currentRoute.outputs.contains(where: { $0.portType == portType })
        }
}
