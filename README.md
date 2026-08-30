# exotel-voip-sdk-ios
Contains SDK, integration guide, sample app code and API documentation.

Latest SDK Version : [1.0.19](https://github.com/exotel/exotel-voip-sdk-ios/releases/latest)
Documentation:https://docs.exotel.com/voice-apis/client-ios-sdk

## Exotel Voice SDK
Download the ExotelVoice.framework.zip sdk file and unzip it, follow the instructions provided in [Exotel Voice Client IOS SDK Integration Guide.pdf](https://github.com/exotel/exotel-voip-sdk-ios/blob/main/Exotel%20Voice%20Client%20IOS%20SDK%20Integration%20Guide.pdf).  
Latest SDK : (./SDK)




## Exotel Voice SDK Integration Guide  
File: [Exotel Voice Client IOS SDK Integration Guide.pdf](https://github.com/exotel/exotel-voip-sdk-ios/blob/main/Exotel%20Voice%20Client%20IOS%20SDK%20Integration%20Guide.pdf)




## Exotel Voice Sample Application Package
Download the test application and build it. After successful build install over an iOS device for demo. Contact us to get an account.  
File: [exotel-voice-sample.zip](https://github.com/exotel/exotel-voip-sdk-ios/blob/main/exotel-voice-sample.zip)




## Exotel Voice SDK API documentation
Download the zip file, extract, and open index.html file for list of APIs.  
File: [exotel-voice-sample-api-doc.zip](https://github.com/exotel/exotel-voip-sdk-ios/blob/main/exotel-voice-sample-api-doc.zip)

## Firebase setup (required to build the sample app)

The sample app requires a Firebase configuration file that is **not** shipped in this repo (per VST-2003).

1. Create your own Firebase project at https://console.firebase.google.com/
2. Add an iOS app with bundle ID matching `ExotelVoiceSample`.
3. Download `GoogleService-Info.plist` and place it at:
   `Exotel-Voice-Sample/ExotelVoiceSample/GoogleService-Info.plist`
4. In GCP Console, restrict the generated API key to your app's bundle ID.

A template with the required keys is at `GoogleService-Info.plist.sample`.
