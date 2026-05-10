import UIKit

final class ProductCell: UICollectionViewCell {
    static let reuseIdentifier = "ProductCell"

    var addToCartAction: (() -> Void)? {
        get { cardView.addToCartAction }
        set { cardView.addToCartAction = newValue }
    }

    var onQuantityChanged: ((Int) -> Void)? {
        get { cardView.onQuantityChanged }
        set { cardView.onQuantityChanged = newValue }
    }

    private let cardView = ProductCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardView)
        cardView.pinToSuperview()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.prepareForReuse()
    }

    func configure(with product: Product, quantity: Int = 0) {
        cardView.configure(with: product, quantity: quantity)
    }
}
