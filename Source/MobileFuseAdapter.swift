// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import UIKit

final class PARTNERNAMEAdapter: PartnerAdapter {
    /// The version of the partner SDK.
    // TODO: partnerSDKVersion
    let partnerSDKVersion = ""

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    // TODO: adapterVersion
    let adapterVersion = "0.0.0.0.0"

    /// The partner's unique identifier.
    // TODO: partnerIdentifier
    let partnerIdentifier = ""

    /// The human-friendly partner name.
    // TODO: partnerDisplayName
    let partnerDisplayName = ""

    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {
        // Perform any initialization tasks that are needed prior to setUp() here.
        // You may keep a reference to `storage` and use it later to gather some information from previously created ads.
    }

    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)

        // TODO: Init partner SDK
    }

    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {
        log(.fetchBidderInfoStarted(request))
        // TODO: IF this is a bidding partner, get bid token from partner SDK and return in completion.
        // log(.fetchBidderInfoSucceeded(request))
    }

    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's pPARTNERNAME.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        // TODO: Set GDPR consent status
        // log(.privacyUpdated(setting: "consentsToTracking", value: consentString))
    }

    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        // TODO: Set CCPA consent status
        // log(.privacyUpdated(setting: "ccpaConsent", value: consent))
    }

    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool) {
        // TODO: Set COPPA consent status
        // log(.privacyUpdated(setting: "coppaExempt", value: !isChildDirected))
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
            // TODO: create and return banner ad object
        case .interstitial:
            // TODO: Create and return interstitial ad object
        case .rewarded:
            // TODO: Create and return rewarded ad object
        default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }
}
