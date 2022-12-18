//
//  ViewController.swift
//  MapsWithCombineFW
//
//  Created by arturs on 17/08/2022.
//

import UIKit
import MapKit
import CoreLocation
import Combine

final class MapViewController: UIViewController {
    
    //MARK: - Properties
    @IBOutlet weak var mapView: MKMapView!
    
    private let mapViewModel: MapViewModel
    private var subscriptions = Set<AnyCancellable>()
    
    //MARK: - Init
    init?(coder: NSCoder, mapViewModel: MapViewModel) {
        self.mapViewModel = mapViewModel
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.register(AnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        subscribeForConnectionEstablishment()
        subscribeForUserLocationUpdates()

        mapViewModel.connect()
        mapViewModel.authorize(byEmail: "arturs.maksimovics@gmail.com")
    }
    
    //MARK: - Private Methods
    private func subscribeForConnectionEstablishment() {
        mapViewModel.connectionPublisher()
            .map { $0 }
            .sink { print("Connection status: \($0 ? "connected" : "not connected")") }
            .store(in: &subscriptions)
    }
    
    private func subscribeForUserLocationUpdates() {
        mapViewModel.usersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] userList in
                let noNilArray = userList.compactMap { $0 }
                guard !noNilArray.isEmpty else { return }
                
                if mapView.annotations.isEmpty {
                    noNilArray.forEach { user in
                        let pin = Annotation(title: nil,
                                             coordinate: CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude),
                                             name: user.fullName,
                                             address: user.address ?? "", image: user.image)
                        
                        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: noNilArray.last!.latitude,
                                                                                       longitude: noNilArray.last!.longitude),
                                                        span: MKCoordinateSpan(latitudeDelta: 0.02,
                                                                               longitudeDelta: 0.02))
                        
                        mapView.setRegion(region, animated: false)
                        
                        mapView.addAnnotation(pin)
                    }
                } else {
                    mapView.annotations.forEach { annotation in
                        if let annotation = annotation as? Annotation,
                           let updatedUser = noNilArray.first(where: { $0.fullName == annotation.name }) {
                            (mapView.view(for: annotation)?.detailCalloutAccessoryView as? CalloutView)?.updateSubtitle(withText: updatedUser.address ?? "")
                            
                            UIView.animate(withDuration: 0.5) {
                                annotation.coordinate = CLLocationCoordinate2D(latitude: updatedUser.latitude, longitude: updatedUser.longitude)
                            }
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }
}

//MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        annotationView?.image = UIImage(named: "pin")
        annotationView?.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        
        if let annotation = annotation as? Annotation {
            annotationView?.canShowCallout = true
            annotationView?.detailCalloutAccessoryView = CalloutView(annotation: annotation)
        }
        return annotationView
    }
}
