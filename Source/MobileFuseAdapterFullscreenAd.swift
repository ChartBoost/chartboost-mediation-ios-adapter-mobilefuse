// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation

final class PARTNERNAMEAdapterFullscreenAd: PARTNERNAMEAdapterAd, PartnerAd {

    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? { nil }

    /// The PARTNERNAMESDK ad instance.
    var ad: PARTNERNAMEFullscreenAd?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)

        /// Construct a fullscreen ad object as well as the partner ad to be persisted for subsequent ad operations.
        let ad = PARTNERNAMEFullscreenAd(
            placement: request.partnerPlacement,
            adFormat: request.format == .interstitial ? .interstitial : .rewarded
        )
        ad.delegate = self

        // Keep the PARTNERNAME ad alive
        self.ad = ad

        // Load the PARTNERNAME fullscreen ad.
        ad.load(adm: request.adm)

        // For simplicity, the current implementation always assumes successes.
        log(.loadSucceeded)
        completion(.success([:]))
    }

    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.showStarted)

        guard let ad = ad else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(.failure(error))
            return
        }

        ad.show()
    }
}

extension PARTNERNAMEAdapterFullscreenAd: PARTNERNAMEFullscreenAdDelegate {

    func onAdShowSuccess() {
        log(.showSucceeded)
        showCompletion?(.success([:])) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func onAdShowFailed(_ PARTNERNAMEError: Error?) {
        let error = PARTNERNAMEError ?? self.error(.showFailureUnknown)
        log(.showFailed(error))
        showCompletion?(.failure(error)) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func onAdImpression() {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdClicked() {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdRewarded() {
        log(.didReward)
        delegate?.didReward(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdDismissed() {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }
}
