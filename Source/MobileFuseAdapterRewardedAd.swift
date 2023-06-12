// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import MobileFuseSDK

final class MobileFuseAdapterRewardedAd: MobileFuseAdapterAd, PartnerAd {

    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? { nil }

    /// The MobileFuseSDK ad instance.
    var ad: MFRewardedAd?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)

        DispatchQueue.main.async {
            if let rewardedAd = MFRewardedAd(placementId: self.request.partnerPlacement) {
                self.loadCompletion = completion
                self.ad = rewardedAd
                rewardedAd.register(self)
                // BEGIN KLUDGE
                if let signaldata = self.request.partnerSettings["signaldata"] as? String {
                    rewardedAd.load(withBiddingResponseToken: signaldata)
                } else {
                    let error = self.error(.loadFailureUnknown)
                    self.log(.loadFailed(error))
                    completion(.failure(error))
                }
                // END KLUDGE
                //            rewardedAd.load(withBiddingResponseToken: request.adm)
            } else {
                let error = self.error(.loadFailureUnknown)
                self.log(.loadFailed(error))
                completion(.failure(error))
            }
        }
    }

    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.showStarted)

        guard let ad = ad, ad.isLoaded() else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(.failure(error))
            return
        }
        showCompletion = completion
        // TODO: match additions to interstitial ad
        ad.show()
    }
}

extension MobileFuseAdapterRewardedAd: IMFAdCallbackReceiver {
    func onAdLoaded() {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func onAdNotFilled() {
        let error = error(.loadFailureNoFill)
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func onAdClosed() {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }

    func onAdRendered() {
        log(.showSucceeded)
        showCompletion?(.success([:])) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func onAdClicked() {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdExpired() {
        log(.didExpire)
        delegate?.didExpire(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdError(_ message: String!) {
        let errorMessage = message ?? "An unidentified error occoured"
        log(.custom(errorMessage))
    }

    func onUserEarnedReward() {
        log(.didReward)
        delegate?.didReward(self, details: [:]) ?? log(.delegateUnavailable)
    }
}
