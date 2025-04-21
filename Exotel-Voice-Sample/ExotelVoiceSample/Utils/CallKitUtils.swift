////
////  CallKitUtils.swift
////  ExotelVoiceSample
////
////  Created by ashishrastogi on 31/10/23.
////
//
//import Foundation
//import CallKit
//import UIKit
//
//class CallKitUtils {
//    private static let TAG = "CallKitUtils"
//    private static var callController : CXCallController?
//    private static var provideDelagete : ProviderDelegate?
//    private static var provider : CXProvider?
//    private static var activeUUID: UUID?
//    
//    @available(iOS 14.0, *)
//    class func inializeCallKit() {
//        VoiceAppLogger.debug(TAG: TAG, message: "inializing Call Kit")
//        let providerConfiguration = CXProviderConfiguration(localizedName: "Exotel Sample App")
//        // Prevents multiple calls from being grouped.
//        providerConfiguration.maximumCallsPerCallGroup = 1
//        providerConfiguration.supportsVideo = false
//        providerConfiguration.supportedHandleTypes = [.phoneNumber]
//        providerConfiguration.ringtoneSound = "Ringtone.aif"
//        if let iconImage = UIImage(named: "AppIcon") {
//            providerConfiguration.iconTemplateImageData = iconImage.pngData()
//            }
//        
//        provider = CXProvider(configuration: providerConfiguration)
//        callController = CXCallController()
//        provideDelagete = ProviderDelegate(provider: provider!)
//        provider!.setDelegate(provideDelagete, queue: nil)
//    }
//    
//    
//    class func reportConnectedOutgoingCall() {
//        VoiceAppLogger.info(TAG: TAG, message: "reportOutgoingCall")
//        provider?.reportOutgoingCall(with: activeUUID!, connectedAt: nil)
//    }
//    
//    class func reportConnectingOutgoingCall() {
//        VoiceAppLogger.info(TAG: TAG, message: "reportOutgoingCall")
//        provider?.reportOutgoingCall(with: activeUUID!, startedConnectingAt: nil)
//    }
//    
//    class func startCallOnCallkit(handle: String, video: Bool = false) {
//        let handle = CXHandle(type: .phoneNumber, value: handle)
//        activeUUID = UUID()
//        let startCallAction = CXStartCallAction(call: activeUUID!, handle: handle)
//        startCallAction.isVideo = video
//
//        let transaction = CXTransaction()
//        transaction.addAction(startCallAction)
//
//        requestTransaction(transaction)
//    }
//
//    /// Ends the specified call.
//    /// - Parameter call: The call to end.
//    class func endCallonCallkit() {
//        let endCallAction = CXEndCallAction(call: activeUUID!)
//        let transaction = CXTransaction()
//        transaction.addAction(endCallAction)
//        requestTransaction(transaction)
//    }
//
//    /// Sets the specified call's on hold status.
//    /// - Parameters:
//    ///   - call: The call to update on hold status for.
//    ///   - onHold: Specifies whether the call should be placed on hold.
//    class func setOnHoldStatus(for call: UUID, to onHold: Bool) {
//        let setHeldCallAction = CXSetHeldCallAction(call: call, onHold: onHold)
//        let transaction = CXTransaction()
//        transaction.addAction(setHeldCallAction)
//
//        requestTransaction(transaction)
//    }
//
//    /// Requests that the actions in the specified transaction be asynchronously performed by the telephony provider.
//    /// - Parameter transaction: A transaction that contains actions to be performed.
//    class func requestTransaction(_ transaction: CXTransaction) {
//        callController?.request(transaction) { error in
//            if let error = error {
//                VoiceAppLogger.error(TAG: TAG, message: "Error requesting transaction: \(error)")
//            } else {
//                VoiceAppLogger.info(TAG: TAG, message: "Requested transaction successfully:")
//            }
//        }
//    }
//
//    
//    class func setActiveUUID(uuid: UUID) {
//        VoiceAppLogger.info(TAG: TAG, message: "setActiveUUID")
//        activeUUID = uuid
//    }
//    
//    class func displayIncomingCall(handle: String) {
//        activeUUID = UUID()
//        reportIncomingCall(uuid: activeUUID!, handle: handle, hasVideo: false)
//    }
//    
//    class func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((Error?) -> Void)? = nil) {
//        // Construct a CXCallUpdate describing the incoming call, including the caller.
//        let update = CXCallUpdate()
//        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
//        update.hasVideo = hasVideo
//
//        // Report the incoming call to the system
//        provider!.reportNewIncomingCall(with: uuid, update: update) { error in
//            /*
//             Only add an incoming call to an app's list of calls if it's allowed, i.e., there is no error.
//             Calls may be denied for various legitimate reasons. See CXErrorCodeIncomingCallError.
//             */
//            if let error = error {
//                VoiceAppLogger.error(TAG: CallKitUtils.TAG, message: "Error requesting transaction: \(error)")
//            } else {
//                VoiceAppLogger.info(TAG: CallKitUtils.TAG, message: "Requested transaction successfully:")
//            }
//        }
//    }
//}
