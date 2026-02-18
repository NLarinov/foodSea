import UIKit

extension UIView {
    func pinToSuperview(padding: CGFloat = 0) {
        guard let superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: padding),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: padding),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -padding),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -padding),
        ])
    }

    func pinToSuperviewSafeArea(padding: CGFloat = 0) {
        guard let superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: padding),
            leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
        ])
    }

    func centerInSuperview() {
        guard let superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor),
        ])
    }

    func setSize(width: CGFloat? = nil, height: CGFloat? = nil) {
        translatesAutoresizingMaskIntoConstraints = false
        if let width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
}
