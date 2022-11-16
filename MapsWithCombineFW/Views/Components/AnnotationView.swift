//
//  AnnotationView.swift
//  MapsWithCombineFW
//
//  Created by arturs on 18/08/2022.
//

import UIKit
import MapKit

final class AnnotationView: MKPinAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let value = newValue as? Annotation else { return }
            canShowCallout = true
            detailCalloutAccessoryView = CalloutView(annotation: value)
        }
    }
}

final class Annotation: NSObject, MKAnnotation {
    dynamic var coordinate : CLLocationCoordinate2D
    
    var title: String?
    let name: String
    var address: String
    let image: UIImage?
    
    init(title: String?,
         coordinate: CLLocationCoordinate2D,
         name: String,
         address: String,
         image: UIImage?) {
        self.title = title
        self.coordinate = coordinate
        self.name = name
        self.address = address
        self.image = image
    }
}
