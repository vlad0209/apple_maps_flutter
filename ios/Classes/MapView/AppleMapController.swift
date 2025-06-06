//
//  AppleMapController.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 03.09.19.
//

import Foundation
import MapKit

public class AppleMapController: NSObject, FlutterPlatformView {
    var contentView: UIView
    var mapView: FlutterMapView
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var initialCameraPosition: [String: Any]
    var options: [String: Any]
    var currentlySelectedAnnotation: String?
    var snapShotOptions: MKMapSnapshotter.Options = MKMapSnapshotter.Options()
    var snapShot: MKMapSnapshotter?
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withargs args: Dictionary<String, Any> ,withId id: Int64) {
        self.options = args["options"] as! [String: Any]
        self.channel = FlutterMethodChannel(name: "apple_maps_plugin.luisthein.de/apple_maps_\(id)", binaryMessenger: registrar.messenger())
        
        self.mapView = FlutterMapView(channel: channel, options: options)
        self.registrar = registrar
        
        // To stop the odd movement of the Apple logo.
        self.contentView = UIScrollView()
        self.contentView.addSubview(mapView)
        mapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.initialCameraPosition = args["initialCameraPosition"]! as! Dictionary<String, Any>
        
        super.init()
        
        self.mapView.delegate = self
        
        self.setMethodCallHandlers()
        
        if let annotationsToAdd: NSArray = args["annotationsToAdd"] as? NSArray {
            self.annotationsToAdd(annotations: annotationsToAdd)
        }
        if let polylinesToAdd: NSArray = args["polylinesToAdd"] as? NSArray {
            self.addPolylines(polylineData: polylinesToAdd)
        }
        if let polygonsToAdd: NSArray = args["polygonsToAdd"] as? NSArray {
            self.addPolygons(polygonData: polygonsToAdd)
        }
        if let circlesToAdd: NSArray = args["circlesToAdd"] as? NSArray {
            self.addCircles(circleData: circlesToAdd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mapView.setCenterCoordinate(self.initialCameraPosition, animated: false)
        }
    }
    
    public func view() -> UIView {
        return contentView
    }
    
    private func setMethodCallHandlers() {
        channel.setMethodCallHandler({ [unowned self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if let args: Dictionary<String, Any> = call.arguments as? Dictionary<String,Any> {
                switch(call.method) {
                case "annotations#update":
                    self.annotationUpdate(args: args)
                    result(nil)
                    break
                case "annotations#showInfoWindow":
                    self.selectAnnotation(with: args["annotationId"] as! String)
                    break
                case "annotations#hideInfoWindow":
                    self.hideAnnotation(with: args["annotationId"] as! String)
                    break
                case "annotations#isInfoWindowShown":
                    result(self.isAnnotationSelected(with: args["annotationId"] as! String))
                    break
                case "polylines#update":
                    self.polylineUpdate(args: args)
                    result(nil)
                    break
                case "polygons#update":
                    self.polygonUpdate(args: args)
                    result(nil)
                    break
                case "circles#update":
                    self.circleUpdate(args: args)
                    result(nil)
                    break
                case "map#update":
                    self.mapView.interpretOptions(options: args["options"] as! Dictionary<String, Any>)
                    break
                case "camera#animate":
                    self.animateCamera(args: args)
                    result(nil)
                    break
                case "camera#move":
                    self.moveCamera(args: args)
                    result(nil)
                    break
                case "camera#convert":
                    self.cameraConvert(args: args, result: result)
                    break
                case "map#takeSnapshot":
                    self.takeSnapshot(options: SnapshotOptions.init(options: args), onCompletion: { (snapshot: FlutterStandardTypedData?, error: Error?) -> Void in
                        result(snapshot ?? error)
                    })
                    break
                case "map#lookAround":
                    var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: args["latitude"] as! CLLocationDegrees, longitude: args["longitude"] as! CLLocationDegrees)
                    if #available(iOS 16.0, *) {
                        var categoryNames: Array<String> = args["poi_filter"] as? Array<String> ?? []
                                            
                                            var categories: [MKPointOfInterestCategory] = categoryNames.map { name in
                                                var category: MKPointOfInterestCategory;
                                                switch(name) {
                                                case "airport":
                                                    category = .airport
                                                    break
                                                case "amusementPark":
                                                    category = .amusementPark
                                                    break
                                                case "aquarium":
                                                    category = .aquarium
                                                    break
                                                case "atm":
                                                    category = .atm
                                                    break
                                                case "bakery":
                                                    category = .bakery
                                                    break
                                                case "bank":
                                                    category = .bank
                                                    break
                                                case "beach":
                                                    category = .beach
                                                    break
                                                case "brewery":
                                                    category = .brewery
                                                    break
                                                case "cafe":
                                                    category = .cafe
                                                    break
                                                case "campground":
                                                    category = .campground
                                                    break
                                                case "carRental":
                                                    category = .carRental
                                                    break
                                                case "evCharger":
                                                    category = .evCharger
                                                    break
                                                case "fireStation":
                                                    category = .fireStation
                                                    break
                                                case "fitnessCenter":
                                                    category = .fitnessCenter
                                                    break
                                                case "foodMarket":
                                                    category = .foodMarket
                                                    break
                                                case "gasStation":
                                                    category = .gasStation
                                                    break
                                                case "hospital":
                                                    category = .hospital
                                                    break
                                                case "hotel":
                                                    category = .hotel
                                                    break
                                                case "laundry":
                                                    category = .laundry
                                                    break
                                                case "library":
                                                    category = .library
                                                    break
                                                case "marina":
                                                    category = .marina
                                                    break
                                                case "movieTheater":
                                                    category = .movieTheater
                                                    break
                                                case "museum":
                                                    category = .museum
                                                    break
                                                case "nationalPark":
                                                    category = .nationalPark
                                                    break
                                                case "nightlife":
                                                    category = .nightlife
                                                    break
                                                case "park":
                                                    category = .park
                                                    break
                                                case "parking":
                                                    category = .parking
                                                    break
                                                case "pharmacy":
                                                    category = .pharmacy
                                                    break
                                                case "police":
                                                    category = .police
                                                    break
                                                case "postOffice":
                                                    category = .postOffice
                                                    break
                                                case "publicTransport":
                                                    category = .publicTransport
                                                    break
                                                case "restaurant":
                                                    category = .restaurant
                                                    break
                                                case "restroom":
                                                    category = .restroom
                                                    break
                                                case "school":
                                                    category = .school
                                                    break
                                                case "stadium":
                                                    category = .stadium
                                                    break
                                                case "store":
                                                    category = .store
                                                    break
                                                case "theater":
                                                    category = .theater
                                                    break
                                                case "university":
                                                    category = .university
                                                    break
                                                case "winery":
                                                    category = .winery
                                                    break
                                                case "zoo":
                                                    category = .zoo
                                                    break
                                                default:
                                                    category = MKPointOfInterestCategory(rawValue: name)
                                                }
                                                return category
                                            }
                                            
                                            lookAround(selectedCoordinate: selectedCoordinate, categories: categories)
                    }
                    break
                case "map#isLookAroundAvailable":
                    var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: args["latitude"] as! CLLocationDegrees, longitude: args["longitude"] as! CLLocationDegrees)
                    if #available(iOS 16.0, *) {
                        self.isLookAroundAvailable(selectedCoordinate: selectedCoordinate) { available in
                            result(available)
                        }
                    } else {
                        result(false)
                    }
                    break
                default:
                    result(FlutterMethodNotImplemented)
                    break
                }
            } else {
                switch call.method {
                case "map#getVisibleRegion":
                    result(self.mapView.getVisibleRegion())
                    break
                case "map#isCompassEnabled":
                    if #available(iOS 9.0, *) {
                        result(self.mapView.showsCompass)
                    } else {
                        result(false)
                    }
                    break
                case "map#isPitchGesturesEnabled":
                    result(self.mapView.isPitchEnabled)
                    break
                case "map#isScrollGesturesEnabled":
                    result(self.mapView.isScrollEnabled)
                    break
                case "map#isZoomGesturesEnabled":
                    result(self.mapView.isZoomEnabled)
                    break
                case "map#isRotateGesturesEnabled":
                    result(self.mapView.isRotateEnabled)
                    break
                case "map#isMyLocationButtonEnabled":
                    result(self.mapView.isMyLocationButtonShowing ?? false)
                    break
                case "map#getMinMaxZoomLevels":
                    result([self.mapView.minZoomLevel, self.mapView.maxZoomLevel])
                    break
                case "camera#getZoomLevel":
                    result(self.mapView.calculatedZoomLevel)
                    break
                default:
                    result(FlutterMethodNotImplemented)
                    break
                }
            }
        })
    }
    
    @available(iOS 16.0, *)
    func lookAround(selectedCoordinate: CLLocationCoordinate2D, categories: [MKPointOfInterestCategory]) {
        // Create a look around scene request
        let sceneRequest = MKLookAroundSceneRequest(coordinate: selectedCoordinate)
        
        // Fetch the look around scene
        sceneRequest.getSceneWithCompletionHandler { [weak self] (scene: MKLookAroundScene?, error: Error?) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching look around scene: \(error)")
                return
            }
            
            guard let scene = scene else {
                print("No look around scene available at this location")
                return
            }
            
            // Store the fetched scene
            let lookAroundScene = scene
            
            // Create and present a look around view controller
            let lookAroundVC = MKLookAroundViewController(scene: scene)
            if(categories.isEmpty == false) {
                lookAroundVC.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
            }
            
            // Make sure to present the look around view controller on the main thread
            DispatchQueue.main.async {
                if let topVC = self.getTopViewController() {
                    topVC.present(lookAroundVC, animated: true, completion: nil)
                }
            }
        }
    }
        
    @available(iOS 16.0, *)
    func isLookAroundAvailable(selectedCoordinate: CLLocationCoordinate2D, completion: @escaping (Bool) -> Void) {
       let sceneRequest = MKLookAroundSceneRequest(coordinate: selectedCoordinate)
       sceneRequest.getSceneWithCompletionHandler { (scene: MKLookAroundScene?, error: Error?) in
                    if let _ = scene {
                        completion(true)
                    } else {
                        completion(false)
                    }
        }
    }


    private func getTopViewController() -> UIViewController? {
            var topViewController: UIViewController? = nil
            if #available(iOS 13.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    topViewController = windowScene.windows.first { $0.isKeyWindow }?.rootViewController
                    while let presentedVC = topViewController?.presentedViewController {
                        topViewController = presentedVC
                    }
                }
            }
            return topViewController
    }
    
    private func annotationUpdate(args: Dictionary<String, Any>) -> Void {
        if let annotationsToAdd = args["annotationsToAdd"] as? NSArray {
            if annotationsToAdd.count > 0 {
                self.annotationsToAdd(annotations: annotationsToAdd)
            }
        }
        if let annotationsToChange = args["annotationsToChange"] as? NSArray {
            if annotationsToChange.count > 0 {
                self.annotationsToChange(annotations: annotationsToChange)
            }
        }
        if let annotationsToDelete = args["annotationIdsToRemove"] as? NSArray {
            if annotationsToDelete.count > 0 {
                self.annotationsIdsToRemove(annotationIds: annotationsToDelete)
            }
        }
    }
    
    private func polygonUpdate(args: Dictionary<String, Any>) -> Void {
        if let polyligonsToAdd: NSArray = args["polygonsToAdd"] as? NSArray {
            self.addPolygons(polygonData: polyligonsToAdd)
        }
        if let polygonsToChange: NSArray = args["polygonsToChange"] as? NSArray {
            self.changePolygons(polygonData: polygonsToChange)
        }
        if let polygonsToRemove: NSArray = args["polygonIdsToRemove"] as? NSArray {
            self.removePolygons(polygonIds: polygonsToRemove)
        }
    }
    
    private func polylineUpdate(args: Dictionary<String, Any>) -> Void {
        if let polylinesToAdd: NSArray = args["polylinesToAdd"] as? NSArray {
            self.addPolylines(polylineData: polylinesToAdd)
        }
        if let polylinesToChange: NSArray = args["polylinesToChange"] as? NSArray {
            self.changePolylines(polylineData: polylinesToChange)
        }
        if let polylinesToRemove: NSArray = args["polylineIdsToRemove"] as? NSArray {
            self.removePolylines(polylineIds: polylinesToRemove)
        }
    }
    
    private func circleUpdate(args: Dictionary<String, Any>) -> Void {
        if let circlesToAdd: NSArray = args["circlesToAdd"] as? NSArray {
            self.addCircles(circleData: circlesToAdd)
        }
        if let circlesToChange: NSArray = args["circlesToChange"] as? NSArray {
            self.changeCircles(circleData: circlesToChange)
        }
        if let circlesToRemove: NSArray = args["circleIdsToRemove"] as? NSArray {
            self.removeCircles(circleIds: circlesToRemove)
        }
    }
    
    private func moveCamera(args: Dictionary<String, Any>) -> Void {
        let positionData: Dictionary<String, Any> = self.toPositionData(data: args["cameraUpdate"] as! Array<Any>, animated: true)
        if !positionData.isEmpty {
            guard let _ = positionData["moveToBounds"] else {
                self.mapView.setCenterCoordinate(positionData, animated: false)
                return
            }
            self.mapView.setBounds(positionData, animated: false)
        }
    }
    
    private func animateCamera(args: Dictionary<String, Any>) -> Void {
        let positionData: Dictionary<String, Any> = self.toPositionData(data: args["cameraUpdate"] as! Array<Any>, animated: true)
        if !positionData.isEmpty {
            guard let _ = positionData["moveToBounds"] else {
                self.mapView.setCenterCoordinate(positionData, animated: true)
                return
            }
            self.mapView.setBounds(positionData, animated: true)
        }
    }
    
    private func cameraConvert(args: Dictionary<String, Any>, result: FlutterResult) -> Void {
        guard let annotation = args["annotation"] as? Array<Double> else {
            result(nil)
            return
        }
        let point = self.mapView.convert(CLLocationCoordinate2D(latitude: annotation[0] , longitude: annotation[1]), toPointTo: self.view())
        result(["point": [point.x, point.y]])
    }
    
    private func toPositionData(data: Array<Any>, animated: Bool) -> Dictionary<String, Any> {
        var positionData: Dictionary<String, Any> = [:]
        if let update: String = data[0] as? String {
            switch(update) {
            case "newCameraPosition":
                if let _positionData : Dictionary<String, Any> = data[1] as? Dictionary<String, Any> {
                    positionData = _positionData
                }
            case "newLatLng":
                if let _positionData : Array<Any> = data[1] as? Array<Any> {
                    positionData = ["target": _positionData]
                }
            case "newLatLngZoom":
                if let _positionData: Array<Any> = data[1] as? Array<Any> {
                    let zoom: Double = data[2] as? Double ?? 0
                    positionData = ["target": _positionData, "zoom": zoom]
                }
            case "newLatLngBounds":
                if let _positionData: Array<Any> = data[1] as? Array<Any> {
                    let padding: Double = data[2] as? Double ?? 0
                    positionData = ["target": _positionData, "padding": padding, "moveToBounds": true]
                }
            case "zoomBy":
                if let zoomBy: Double = data[1] as? Double {
                    mapView.zoomBy(zoomBy: zoomBy, animated: animated)
                }
            case "zoomTo":
                if let zoomTo: Double = data[1] as? Double {
                    mapView.zoomTo(newZoomLevel: zoomTo, animated: animated)
                }
            case "zoomIn":
                mapView.zoomIn(animated: animated)
            case "zoomOut":
                mapView.zoomOut(animated: animated)
            default:
                positionData = [:]
            }
            return positionData
        }
        return [:]
    }
}


extension AppleMapController: MKMapViewDelegate {
    // onIdle
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if ((self.mapView.mapContainerView) != nil) {
            let locationOnMap = self.mapView.region.center
            self.channel.invokeMethod("camera#onMove", arguments: ["position": ["heading": self.mapView.actualHeading, "target":  [locationOnMap.latitude, locationOnMap.longitude], "pitch": self.mapView.camera.pitch, "zoom": self.mapView.calculatedZoomLevel]])
        }
        self.channel.invokeMethod("camera#onIdle", arguments: "")
    }
    
    // onMoveStarted
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.channel.invokeMethod("camera#onMoveStarted", arguments: "")
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is FlutterPolyline {
            return self.polylineRenderer(overlay: overlay)
        } else if overlay is FlutterPolygon {
            return self.polygonRenderer(overlay: overlay)
        } else if overlay is FlutterCircle {
            return self.circleRenderer(overlay: overlay)
        }
        return MKOverlayRenderer()
    }
}

extension AppleMapController {
    private func takeSnapshot(options: SnapshotOptions, onCompletion: @escaping (FlutterStandardTypedData?, Error?) -> Void) {
        // MKMapSnapShotOptions setting.
        snapShotOptions.region = self.mapView.region
        snapShotOptions.size = self.mapView.frame.size
        snapShotOptions.scale = UIScreen.main.scale
        snapShotOptions.showsBuildings = options.showBuildings
        snapShotOptions.showsPointsOfInterest = options.showPointsOfInterest
        
        // Set MKMapSnapShotOptions to MKMapSnapShotter.
        snapShot = MKMapSnapshotter(options: snapShotOptions)
        
        snapShot?.cancel()
        
        if #available(iOS 10.0, *) {
            snapShot?.start { [weak self] snapshot, error in
                guard let self = self else {
                    return
                }
                
                guard let snapshot = snapshot, error == nil else {
                    onCompletion(nil, error)
                    return
                }
                
                let image = UIGraphicsImageRenderer(size: self.snapShotOptions.size).image { [weak self] context in
                    guard let self = self else {
                        return
                    }
                    snapshot.image.draw(at: .zero)
                    let rect = self.snapShotOptions.mapRect
                    if options.showAnnotations {
                        for annotation in self.mapView.getMapViewAnnotations() {
                            self.drawAnnotations(annotation: annotation, point: snapshot.point(for: annotation!.coordinate))
                        }
                    }
                    if options.showOverlays {
                        for overlay in self.mapView.overlays {
                            if ((overlay.intersects?(rect)) != nil) {
                                self.drawOverlays(overlay: overlay, snapshot: snapshot, context: context)
                            }
                        }
                    }
                }

                if let imageData = image.pngData() {
                    onCompletion(FlutterStandardTypedData.init(bytes: imageData), nil)
                }
            }
        }
    }
    
    private func drawAnnotations(annotation: FlutterAnnotation?, point: CGPoint) {
        guard annotation != nil else {
            return
        }
        let annotationView = self.getAnnotationView(annotation: annotation!)
        
        var offsetPoint = point
        
        offsetPoint.x -= annotationView.bounds.width / 2
        offsetPoint.y -= annotationView.bounds.height / 2
        
        
        if #available(iOS 11.0, *), annotationView is MKMarkerAnnotationView {
            annotationView.drawHierarchy(in: CGRect(x: offsetPoint.x, y: offsetPoint.y, width: annotationView.bounds.width, height: annotationView.bounds.height), afterScreenUpdates: true)
        } else {
            offsetPoint.x += annotationView.centerOffset.x
            offsetPoint.y += annotationView.centerOffset.y
            let annotationImage = annotationView.image
            annotationImage?.draw(at: offsetPoint)
        }
    }
    
    @available(iOS 10.0, *)
    private func drawOverlays(overlay: MKOverlay?, snapshot: MKMapSnapshotter.Snapshot, context: UIGraphicsRendererContext) {
        guard overlay != nil else {
            return
        }
        
        if let flutterOverlay: FlutterOverlay = overlay as? FlutterOverlay {
            flutterOverlay.getCAShapeLayer(snapshot: snapshot).render(in: context.cgContext)
        }
        
    }
}
