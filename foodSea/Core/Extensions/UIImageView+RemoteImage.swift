import UIKit
import ObjectiveC

private var remoteImageURLKey: UInt8 = 0
private var remoteImageTaskKey: UInt8 = 0

extension UIImageView {
    private static let remoteImageCache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = Constants.Cache.imageCacheMaxSize
        return cache
    }()

    private var remoteImageURL: URL? {
        get { objc_getAssociatedObject(self, &remoteImageURLKey) as? URL }
        set { objc_setAssociatedObject(self, &remoteImageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var remoteImageTask: URLSessionDataTask? {
        get { objc_getAssociatedObject(self, &remoteImageTaskKey) as? URLSessionDataTask }
        set { objc_setAssociatedObject(self, &remoteImageTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func setRemoteImage(_ url: URL?, placeholderSymbol: String = "photo") {
        remoteImageTask?.cancel()
        remoteImageTask = nil
        remoteImageURL = url

        guard let url else {
            image = UIImage(systemName: placeholderSymbol)
            return
        }
        if let cached = Self.remoteImageCache.object(forKey: url as NSURL) {
            image = cached
            return
        }
        image = UIImage(systemName: placeholderSymbol)
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let downloaded = UIImage(data: data) else { return }
            let cost = data.count
            Self.remoteImageCache.setObject(downloaded, forKey: url as NSURL, cost: cost)
            DispatchQueue.main.async {
                guard self.remoteImageURL == url else { return }
                self.image = downloaded
            }
        }
        remoteImageTask = task
        task.resume()
    }

    func cancelRemoteImage() {
        remoteImageTask?.cancel()
        remoteImageTask = nil
        remoteImageURL = nil
    }
}
