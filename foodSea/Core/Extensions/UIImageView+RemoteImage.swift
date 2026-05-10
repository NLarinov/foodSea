import UIKit
import ObjectiveC

private var remoteImageURLKey: UInt8 = 0
private var remoteImageTokenKey: UInt8 = 0

extension UIImageView {
    private var remoteImageURL: URL? {
        get { objc_getAssociatedObject(self, &remoteImageURLKey) as? URL }
        set { objc_setAssociatedObject(self, &remoteImageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var remoteImageToken: ImageLoader.RequestToken? {
        get { objc_getAssociatedObject(self, &remoteImageTokenKey) as? ImageLoader.RequestToken }
        set { objc_setAssociatedObject(self, &remoteImageTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func setRemoteImage(_ url: URL?, placeholderSymbol: String = "photo") {
        cancelRemoteImage()
        remoteImageURL = url

        guard let url else {
            image = UIImage(systemName: placeholderSymbol)
            return
        }
        if let cached = ImageLoader.shared.cachedImage(for: url) {
            image = cached
            return
        }
        image = UIImage(systemName: placeholderSymbol)
        remoteImageToken = ImageLoader.shared.load(url) { [weak self] downloaded in
            guard let self, self.remoteImageURL == url, let downloaded else { return }
            self.image = downloaded
        }
    }

    func cancelRemoteImage() {
        if let url = remoteImageURL, let token = remoteImageToken {
            ImageLoader.shared.cancel(token, for: url)
        }
        remoteImageToken = nil
        remoteImageURL = nil
    }
}
