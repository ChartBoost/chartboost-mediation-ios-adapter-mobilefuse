// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation

final class PARTNERNAMEAdapterBannerAd: PARTNERNAMEAdapterAd, PartnerAd {

    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        // TODO: Load the ad here.
        // completion(.success([:]))
    }

    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }

    /// Map Chartboost Mediation's banner sizes to the PARTNERNAME SDK's supported sizes.
    /// - Parameter size: The Chartboost Mediation's banner size.
    /// - Returns: The corresponding PARTNERNAME banner size.
    func getPARTNERNAMEBannerAdSize(size: CGSize?) -> PARTNERNAMEBannerAd.Size {
        let height = size?.height ?? 50

        switch height {
        case 50..<89:
            return PARTNERNAMEBannerAd.Size.banner
        case 90..<249:
            return PARTNERNAMEBannerAd.Size.leaderboard
        case 250...:
            return PARTNERNAMEBannerAd.Size.mediumRectangle
        default:
            return PARTNERNAMEBannerAd.Size.banner
        }
    }
}

extension PARTNERNAMEAdapterBannerAd: PARTNERNAMEBannerAdDelegate {

// TODO: In the 'ad did load' delegate, do the following...
// log(.loadSucceeded)
// loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
// loadCompletion = nil

// TODO: In the 'ad failed' delegate, do the following...
// log(.loadFailed(error))
// loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
// loadCompletion = nil

// TODO: log other delegate methods as appropriate, using .delegateCallIgnored when no good match

}
