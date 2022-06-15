//
//  CustoneCellTableViewCell.swift
//  SpeechRecognition
//
//  Created by Andrey KItenko on 25.05.2022.
//

import UIKit


protocol ReusableView: AnyObject {
    static var identifier: String { get }
}


class Cell: UICollectionViewCell {

    let lableCell: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 30)
        label.textColor = .white
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.layer.backgroundColor = UIColor(named: "ColorCell")?.cgColor
        label.padding = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        return  label
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
        setupLayouts()
    }

    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    func newText(new text: String) {
        lableCell.text = text
    }


    private func setupViews() {
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = Constants.contentViewCornerRadius
        contentView.backgroundColor = .white
        contentView.addSubview(lableCell)
    }

    private func setupLayouts() {
        lableCell.translatesAutoresizingMaskIntoConstraints = false
        var constrains = [NSLayoutConstraint]()
        // Add

        constrains.append(lableCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor))
        constrains.append(lableCell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor))
        constrains.append(lableCell.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
        constrains.append(lableCell.topAnchor.constraint(equalTo: contentView.topAnchor))

        //Activate
        NSLayoutConstraint.activate(constrains)
    }


    private enum Constants {
            // MARK: contentView layout constants
            static let contentViewCornerRadius: CGFloat = 20.0

            // MARK: profileImageView layout constants
            static let imageHeight: CGFloat = 180.0

            // MARK: Generic layout constants
            static let verticalSpacing: CGFloat = 8.0
            static let horizontalPadding: CGFloat = 16.0
            static let profileDescriptionVerticalPadding: CGFloat = 8.0
        }


}


extension Cell: ReusableView {
    static var identifier: String {
        return String(describing: self)
    }
}

extension UILabel {
    private struct AssociatedKeys {
        static var padding = UIEdgeInsets()
    }

    public var padding: UIEdgeInsets? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.padding) as? UIEdgeInsets
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.padding, newValue as UIEdgeInsets?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    override open func draw(_ rect: CGRect) {
        if let insets = padding {
            self.drawText(in: rect.inset(by: insets))
        } else {
            self.drawText(in: rect)
        }
    }

    override open var intrinsicContentSize: CGSize {
        guard let text = self.text else { return super.intrinsicContentSize }

        var contentSize = super.intrinsicContentSize
        var textWidth: CGFloat = frame.size.width
        var insetsHeight: CGFloat = 0.0
        var insetsWidth: CGFloat = 0.0

        if let insets = padding {
            insetsWidth += insets.left + insets.right
            insetsHeight += insets.top + insets.bottom
            textWidth -= insetsWidth
        }

        let newSize = text.boundingRect(with: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude),
                                        options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                        attributes: [NSAttributedString.Key.font: self.font], context: nil)

        contentSize.height = ceil(newSize.size.height) + insetsHeight
        contentSize.width = ceil(newSize.size.width) + insetsWidth

        return contentSize
    }
}
