//
//  CalloutView.swift
//  MapsWithCombineFW
//
//  Created by arturs on 18/08/2022.
//

import UIKit
import MapKit

final class CalloutView: UIView {
    
    private let titleLabel = UILabel(frame: .zero)
    private let subtitleLabel = UILabel(frame: .zero)
    private let imageView = UIImageView(frame: .zero)
    private let annotation: Annotation
    
    init(annotation: Annotation) {
        self.annotation = annotation
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        setupImageView()
        setupTitle()
        setupSubtitle()
    }
    
    private func setupTitle() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.text = annotation.name
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    private func setupSubtitle() {
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .gray
        subtitleLabel.text = annotation.address
        addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    private func setupImageView() {
        imageView.image = annotation.image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    public func updateSubtitle(withText: String) {
        subtitleLabel.text = withText
    }
}
