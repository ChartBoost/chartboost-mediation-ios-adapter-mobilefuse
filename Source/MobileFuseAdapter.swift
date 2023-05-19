// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import MobileFuseSDK
import UIKit

// Must conform to NSObjectProtocol to be a IMFInitializationCallbackReceiver
final class MobileFuseAdapter: PartnerAdapter {
    // String meaning: spec v1, NO we haven't asked the user, NO they did not opt out
    private var CCPAString = "1NN-"
    private var initializationCompletion: ((Error?) -> Void)?
    private var isSubjectToCoppa: Bool?
    private var privacyPreferences: MobileFusePrivacyPreferences

    private func setPrivacyPreferences() {
        if let coppa = isSubjectToCoppa {
            privacyPreferences.setSubjectToCoppa(coppa)
        }
        // "US Privacy Strings" have the same format as CCPA strings
        // https://github.com/InteractiveAdvertisingBureau/USPrivacy/blob/master/CCPA/US%20Privacy%20String.md
        privacyPreferences.setUsPrivacyConsentString(CCPAString)
        MobileFuse.setPrivacyPreferences(privacyPreferences)
    }

    // MARK: PartnerAdapter

    /// The version of the partner SDK.
    let partnerSDKVersion = "1.4.5"

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    let adapterVersion = "4.1.4.5.0"

    /// The partner's unique identifier.
    let partnerIdentifier = "mobilefuse"

    /// The human-friendly partner name.
    let partnerDisplayName = "MobileFuse"

    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {
        privacyPreferences = MobileFusePrivacyPreferences()
    }

    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        MobileFuse.initializeCoreServices()
        // This init method doesn't trigger any callbacks, so we declare success right away
        log(.setUpSucceded)
    }

    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {
        log(.fetchBidderInfoStarted(request))
        let tokenRequest = MFBiddingTokenRequest()
        tokenRequest.privacyPreferences = privacyPreferences
        tokenRequest.isTestMode = MobileFuseAdapterConfiguration.testMode
        if let token = MFBiddingTokenProvider.getTokenWith(tokenRequest) {
            completion(["token": token])
            log(.fetchBidderInfoSucceeded(request))
        } else {
            completion(nil)
            let error = error(.prebidFailureUnknown)
            log(.fetchBidderInfoFailed(request, error: error))
        }
    }

    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's pMobileFuse.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        // GDPR consent setting is a NO-OP as Chartboost Mediation does not support an IAB-compatible privacy consent string
    }

    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        CCPAString = privacyString
        setPrivacyPreferences()
    }

    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool) {
        isSubjectToCoppa = isChildDirected
        setPrivacyPreferences()
        log(.privacyUpdated(setting: "subjectToCoppa", value: isChildDirected))
    }

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// `invalidate()` is called on ads before disposing of them in case partners need to perform any custom logic before the object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd {
        switch request.format {
        case .banner:
            return MobileFuseAdapterBannerAd(adapter: self, request: request, delegate: delegate)
        case .interstitial:
            return MobileFuseAdapterInterstitialAd(adapter: self, request: request, delegate: delegate)
        case .rewarded:
            return MobileFuseAdapterRewardedAd(adapter: self, request: request, delegate: delegate)
        default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }
}