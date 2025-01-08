//
//  ProviderDelegate.swift
//  ExotelVoiceSample
//
//  Created by ashishrastogi on 24/10/23.
//

import Foundation
import UIKit
import AVFoundation
import CallKit

final class ProviderDelegate: NSObject,CXProviderDelegate {
    let TAG = "CallKitProviderDelegate"
    
    internal init( provider: CXProvider) {
        self.provider = provider
    }
    private let provider: CXProvider

    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")

        do {
            try VoiceAppService.shared.hangup()
        } catch let error {
            VoiceAppLogger.debug(TAG: TAG, message: "Error: \(error.localizedDescription)")
        }

        // Remove all calls from the app's list of calls.
//        callManager.removeAllCalls()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        CallKitUtils.setActiveUUID(uuid: action.callUUID)
        action.fulfill()
        
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        VoiceAppLogger.info(TAG: TAG, message: "CXAnswerCallAction")
        let payLoad = VoiceAppService.shared.pushNotificationData
        guard let userId = payLoad?["subscriberName"] as? String else {
            VoiceAppLogger.error(TAG: TAG, message: "callerId not found in payload")
            return
        }
        
        guard let payLoadVersion = payLoad?["payloadVersion"] as? String else {
            VoiceAppLogger.error(TAG: TAG, message: "payloadVersion not found in payload")
            return
        }
        
        guard let payLoadData = payLoad?["payload"] as? String else {
            VoiceAppLogger.error(TAG: TAG, message: "payload not found in payload")
            return
        }
        
        VoiceAppLogger.error(TAG: TAG, message: "payload Handling the notificaito on answer button tap")
        
        self.startAudioSessionIfNeeded()
       DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
           
            VoiceAppService.shared.sendPushNotificationData(
                payload: payLoadData,
                payloadVersion: payLoadVersion,
                userId: userId)
        }
        //        VoiceAppService.shared.answer()
        // Signal to the system that the action was successfully performed.
        action.fulfill()
    }
    
    
    func startAudioSessionIfNeeded() {
        do {
            // Ensure the audio session is set up correctly for voice calls
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.duckOthers, .allowBluetooth, .defaultToSpeaker])
            try session.setActive(true)
        } catch {
            VoiceAppLogger.error(TAG: TAG, message: "Error starting audio session: \(error)")
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        VoiceAppLogger.info(TAG: TAG, message: "CXEndCallAction")

        do {
            try VoiceAppService.shared.hangup()
        } catch let error {
            VoiceAppLogger.debug(TAG: TAG, message: "Error: \(error.localizedDescription)")
        }
        // Signal to the system that the action was successfully performed.
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        VoiceAppLogger.info(TAG: TAG, message: "CXSetHeldCallAction")

        // Signal to the system that the action has been successfully performed.
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        VoiceAppLogger.info(TAG: TAG, message: "CXSetMutedCallAction")
        if action.isMuted {
            VoiceAppService.shared.mute()
        } else {
            VoiceAppService.shared.unmute()
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        VoiceAppLogger.info(TAG: TAG, message: "timedOutPerforming")
//        print("Timed out", #function)
        VoiceAppLogger.error(TAG: TAG, message: "timedOutPerforming : React to the action timeout if necessary, such as showing an error UI")

        // React to the action timeout if necessary, such as showing an error UI.
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        VoiceAppLogger.info(TAG: TAG, message: "didActivate")
        VoiceAppLogger.error(TAG: TAG, message: "audioSession : Start call audio media, now that the audio session is activated")
      
        /*
         Start call audio media, now that the audio session is activated,
         after having its priority elevated.
         */
//        startAudio()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        VoiceAppLogger.info(TAG: TAG, message: "didDeactivate")

        VoiceAppLogger.error(TAG: TAG, message: "audioSession :  Restart any non-call related audio now that the app's audio session is deactivated")
        
        /*
         Restart any non-call related audio now that the app's audio session is deactivated,
         after having its priority restored to normal.
         */
    }
}
