// Copyright 2023-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import MobileFuseSDK
import UIKit

final class MobileFuseAdapter: PartnerAdapter {
    private var privacyPreferences: MobileFusePrivacyPreferences = MobileFusePrivacyPreferences()
    private var initializationDelegate: MobileFuseAdapterInitializationDelegate?

    // MARK: PartnerAdapter

    /// The version of the partner SDK.
    let partnerSDKVersion = MobileFuse.version() ?? ""

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    let adapterVersion = "4.1.7.0.0"

    /// The partner's unique identifier.
    let partnerID = "mobilefuse"

    /// The human-friendly partner name.
    let partnerDisplayName = "MobileFuse"

    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {
        // no-op
    }

    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.setUpStarted)

        // Apply initial consents
        setConsents(configuration.consents, modifiedKeys: Set(configuration.consents.keys))
        setIsUserUnderage(configuration.isUserUnderage)

        initializationDelegate = MobileFuseAdapterInitializationDelegate(parentAdapter: self, completionHandler: completion)
        // MobileFuse's initialization needs to be done on the main thread
        // This isn't stated in their documentation but a warning in Xcode says we're accessing [UIApplication applicationState] here
        DispatchQueue.main.async {
            MobileFuse.initWithDelegate(self.initializationDelegate)
        }
    }

    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String : String], Error>) -> Void) {
        log(.fetchBidderInfoStarted(request))
        let tokenRequest = MFBiddingTokenRequest()
        tokenRequest.privacyPreferences = privacyPreferences
        tokenRequest.isTestMode = MobileFuseAdapterConfiguration.testMode
        MFBiddingTokenProvider.getTokenWith(tokenRequest) { token in
            self.log(.fetchBidderInfoSucceeded(request))
            completion(.success(["signal": token]))
        }
    }

    /// Indicates that the user consent has changed.
    /// - parameter consents: The new consents value, including both modified and unmodified consents.
    /// - parameter modifiedKeys: A set containing all the keys that changed.
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>) {
        guard modifiedKeys.contains(ConsentKeys.tcf)
                || modifiedKeys.contains(ConsentKeys.usp)
                || modifiedKeys.contains(ConsentKeys.gpp)
        else {
            return
        }
        if let tcfString = consents[ConsentKeys.tcf] {
            privacyPreferences.setIabConsentString(tcfString)
            log(.privacyUpdated(setting: "setIabConsentString", value: tcfString))
        }
        if let uspString = consents[ConsentKeys.usp] {
            privacyPreferences.setUsPrivacyConsentString(uspString)
            log(.privacyUpdated(setting: "setUsPrivacyConsentString", value: uspString))
        }
        if let gppString = consents[ConsentKeys.gpp] {
            privacyPreferences.setGppConsentString(gppString)
            log(.privacyUpdated(setting: "setGppConsentString", value: gppString))
        }
        MobileFuse.setPrivacyPreferences(privacyPreferences)
    }

    /// Indicates that the user is underage signal has changed.
    /// - parameter isUserUnderage: `true` if the user is underage as determined by the publisher, `false` otherwise.
    func setIsUserUnderage(_ isUserUnderage: Bool) {
        privacyPreferences.setSubjectToCoppa(isUserUnderage)
        MobileFuse.setPrivacyPreferences(privacyPreferences)
        log(.privacyUpdated(setting: "subjectToCoppa", value: isUserUnderage))
    }

    /// Creates a new banner ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd {
        // This partner supports multiple loads for the same partner placement.
        MobileFuseAdapterBannerAd(adapter: self, request: request, delegate: delegate)
    }

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd {
        // This partner supports multiple loads for the same partner placement.
        switch request.format {
        case PartnerAdFormats.interstitial:
            return MobileFuseAdapterInterstitialAd(adapter: self, request: request, delegate: delegate)
        case PartnerAdFormats.rewarded, PartnerAdFormats.rewardedInterstitial:
            return MobileFuseAdapterRewardedAd(adapter: self, request: request, delegate: delegate)
        default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }
}

final class MobileFuseAdapterInitializationDelegate: NSObject, IMFInitializationCallbackReceiver {
    weak var parentAdapter: MobileFuseAdapter?
    let completionBlock: (Result<PartnerDetails, Error>) -> Void

    init(parentAdapter: MobileFuseAdapter, completionHandler: @escaping (Result<PartnerDetails, Error>) -> Void) {
        self.parentAdapter = parentAdapter
        self.completionBlock = completionHandler
    }

    func onInitSuccess(_ appId: String, withPublisherId publisherId: String) {
        parentAdapter?.log(.setUpSucceded)
        completionBlock(.success([:]))
    }

    func onInitError(_ appId: String, withPublisherId publisherId: String, withError error: MFAdError) {
        parentAdapter?.log(.setUpFailed(error))
        completionBlock(.failure(error))
    }
}
