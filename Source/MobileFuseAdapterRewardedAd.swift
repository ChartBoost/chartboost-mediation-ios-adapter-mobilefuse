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
                self.ad = rewardedAd
                self.loadCompletion = completion
                // Set test mode to either true or false
                rewardedAd.testMode = MobileFuseAdapterConfiguration.testMode
                // Set self as the callback receiver
                rewardedAd.register(self)
                rewardedAd.load(withBiddingResponseToken: self.request.adm)
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

        viewController.view.addSubview(ad)
        ad.show()
    }

    func invalidate() throws {
        log(.invalidateStarted)
        DispatchQueue.main.async {
            if let ad = self.ad {
                ad.destroy()
                self.log(.invalidateSucceeded)
            } else {
                self.log(.invalidateFailed(self.error(.invalidateFailureAdNotFound)))
            }
        }
    }
}

extension MobileFuseAdapterRewardedAd: IMFAdCallbackReceiver {
    func onAdLoaded(_ ad: MFAd!) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func onAdNotFilled(_ ad: MFAd!) {
        let error = error(.loadFailureNoFill)
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func onAdClosed(_ ad: MFAd!) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }

    func onAdRendered(_ ad: MFAd!) {
        log(.showSucceeded)
        showCompletion?(.success([:])) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func onAdClicked(_ ad: MFAd!) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdExpired(_ ad: MFAd!) {
        log(.didExpire)
        delegate?.didExpire(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdError(_ ad: MFAd!, withError error: MFAdError!) {
        let errorMessage = error.localizedDescription
        log(.custom(errorMessage))
    }

    func onUserEarnedReward(_ ad: MFAd!) {
        log(.didReward)
        delegate?.didReward(self, details: [:]) ?? log(.delegateUnavailable)
    }
}
