// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import MobileFuseSDK

final class MobileFuseAdapterBannerAd: MobileFuseAdapterAd, PartnerAd {

    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? {
        mfBannerAd
    }

    var mfBannerAd: MFBannerAd? = nil

    // tmp
    // TODO: actually I think this needs to be permanent
    var vc: UIViewController?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {

        vc = viewController

        log(.loadStarted)
        let adSize = getMobileFuseBannerAdSize(size: request.size)
        if let bannerAd = MFBannerAd.init(placementId: request.partnerPlacement, with: adSize) {
            mfBannerAd = bannerAd
            loadCompletion = completion
            bannerAd.register(self)
//            viewController?.view.addSubview(bannerAd)
            // BEGIN KLUDGE
            if let signaldata = self.request.partnerSettings["signaldata"] as? String {
                bannerAd.load(withBiddingResponseToken: signaldata)
            } else {
                let error = self.error(.loadFailureUnknown)
                self.log(.loadFailed(error))
                completion(.failure(error))
            }
            // END KLUDGE
//            ad.load(withBiddingResponseToken: request.adm)
        } else {
            let error = error(.loadFailureUnknown)
            log(.loadFailed(error))
            completion(.failure(error))
        }
    }

    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }

    /// Map Chartboost Mediation's banner sizes to the MobileFuse SDK's supported sizes.
    /// - Parameter size: The Chartboost Mediation's banner size.
    /// - Returns: The corresponding MobileFuse banner size.
    func getMobileFuseBannerAdSize(size: CGSize?) -> MFBannerAdSize {
        let height = size?.height ?? 50

        switch height {
        case 50..<89:
            return MFBannerAdSize.MOBILEFUSE_BANNER_SIZE_320x50
        case 90..<249:
            return MFBannerAdSize.MOBILEFUSE_BANNER_SIZE_728x90
        case 250...:
            return MFBannerAdSize.MOBILEFUSE_BANNER_SIZE_300x250
        default:
            return MFBannerAdSize.MOBILEFUSE_BANNER_SIZE_320x50
        }
    }

    func invalidate() throws {
        // Don't bother dispatching the task if self.ad isn't there
        if let ad = mfBannerAd { // TODO: retest with "if self.ad != nil {"
            // Must be called from main thread
            DispatchQueue.main.async {
                ad.destroy()
            }
        }
    }
}

extension MobileFuseAdapterBannerAd: IMFAdCallbackReceiver {
    func onAdLoaded(_ ad: MFAd!) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil

        guard let ready = self.mfBannerAd?.isAdReady, ready  else {
            loadCompletion?(.failure(error(.showFailureAdNotReady))) ?? log(.showResultIgnored)
            loadCompletion = nil
            return
        }

//        ad.show()
//        mfBannerAd?.isHidden = false
//        self.mfBannerAd?.show(with: vc)
        self.mfBannerAd?.show()

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
}
