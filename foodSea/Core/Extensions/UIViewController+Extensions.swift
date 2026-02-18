import UIKit

extension UIViewController {
    func showAlert(title: String?, message: String?, actions: [UIAlertAction] = []) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if actions.isEmpty {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        } else {
            actions.forEach { alert.addAction($0) }
        }
        present(alert, animated: true)
    }

    func showError(_ error: Error) {
        showAlert(title: "Ошибка", message: error.localizedDescription)
    }

    func showConfirmation(
        title: String,
        message: String?,
        confirmTitle: String,
        confirmStyle: UIAlertAction.Style = .destructive,
        onConfirm: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Constants.Strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: confirmStyle) { _ in
            onConfirm()
        })
        present(alert, animated: true)
    }

    func showToast(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.font = .preferredFont(forTextStyle: .footnote)
        label.layer.cornerRadius = Constants.UI.smallCornerRadius
        label.clipsToBounds = true
        label.alpha = 0

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -Constants.UI.largePadding
            ),
            label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -Constants.UI.largePadding * 2),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minimumTapSize),
        ])

        let horizontalPadding = Constants.UI.standardPadding
        label.layoutMargins = UIEdgeInsets(
            top: Constants.UI.smallPadding,
            left: horizontalPadding,
            bottom: Constants.UI.smallPadding,
            right: horizontalPadding
        )

        UIView.animate(withDuration: Constants.Animation.defaultDuration) {
            label.alpha = 1
        }
        UIView.animate(
            withDuration: Constants.Animation.defaultDuration,
            delay: 2.0,
            options: []
        ) {
            label.alpha = 0
        } completion: { _ in
            label.removeFromSuperview()
        }
    }
}
