// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlatformAppleMap {
  FakePlatformAppleMap(int id, Map<dynamic, dynamic> params) {
    cameraPosition = CameraPosition.fromMap(params['initialCameraPosition']);
    channel = MethodChannel('apple_maps_plugin.luisthein.de/apple_maps_$id',
        const StandardMethodCodec());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, onMethodCall);
    updateOptions(params['options']);
    updatePolylines(params);
    updateAnnotations(params);
    updatePolygons(params);
    updateCircles(params);
  }

  late MethodChannel channel;

  CameraPosition? cameraPosition;

  bool? compassEnabled;

  MapType? mapType;

  MinMaxZoomPreference? minMaxZoomPreference;

  bool? rotateGesturesEnabled;

  bool? scrollGesturesEnabled;

  bool? pitchGesturesEnabled;

  bool? zoomGesturesEnabled;

  bool? myLocationEnabled;

  bool? myLocationButtonEnabled;

  Set<AnnotationId>? annotationIdsToRemove;

  Set<Annotation>? annotationsToAdd;

  Set<Annotation>? annotationsToChange;

  Set<PolylineId>? polylineIdsToRemove;

  Set<Polyline>? polylinesToAdd;

  Set<Polyline>? polylinesToChange;

  Set<PolygonId>? polygonIdsToRemove;

  Set<Polygon>? polygonsToAdd;

  Set<Polygon>? polygonsToChange;

  Set<CircleId>? circleIdsToRemove;

  Set<Circle>? circlesToAdd;

  Set<Circle>? circlesToChange;

  Future<dynamic> onMethodCall(MethodCall call) {
    switch (call.method) {
      case 'map#update':
        updateOptions(call.arguments['options']);
        return Future<void>.sync(() {});
      case 'annotations#update':
        updateAnnotations(call.arguments);
        return Future<void>.sync(() {});
      case 'polylines#update':
        updatePolylines(call.arguments);
        return Future<void>.sync(() {});
      case 'polygons#update':
        updatePolygons(call.arguments);
        return Future<void>.sync(() {});
      case 'circles#update':
        updateCircles(call.arguments);
        return Future<void>.sync(() {});
      default:
        return Future<void>.sync(() {});
    }
  }

  void updateAnnotations(Map<dynamic, dynamic>? annotationUpdates) {
    if (annotationUpdates == null) {
      return;
    }
    annotationsToAdd =
        _deserializeAnnotations(annotationUpdates['annotationsToAdd']);
    annotationIdsToRemove =
        _deserializeAnnotationIds(annotationUpdates['annotationIdsToRemove']);
    annotationsToChange =
        _deserializeAnnotations(annotationUpdates['annotationsToChange']);
  }

  Set<AnnotationId> _deserializeAnnotationIds(List<dynamic>? annotationIds) {
    if (annotationIds == null) {
      return Set<AnnotationId>();
    }
    return annotationIds
        .map((dynamic annotationId) => AnnotationId(annotationId))
        .toSet();
  }

  Set<Annotation> _deserializeAnnotations(dynamic annotations) {
    if (annotations == null) {
      return Set<Annotation>();
    }
    final List<dynamic> annotationsData = annotations;
    final Set<Annotation> result = Set<Annotation>();
    for (Map<dynamic, dynamic> annotationData in annotationsData) {
      final String annotationId = annotationData['annotationId'];
      final bool draggable = annotationData['draggable'];
      final bool visible = annotationData['visible'];
      final double alpha = annotationData['alpha'];

      final dynamic infoWindowData = annotationData['infoWindow'];
      InfoWindow infoWindow = InfoWindow.noText;
      if (infoWindowData != null) {
        final Map<dynamic, dynamic> infoWindowMap = infoWindowData;
        infoWindow = InfoWindow(
          title: infoWindowMap['title'],
          snippet: infoWindowMap['snippet'],
        );
      }

      result.add(
        Annotation(
            annotationId: AnnotationId(annotationId),
            draggable: draggable,
            visible: visible,
            infoWindow: infoWindow,
            alpha: alpha),
      );
    }

    return result;
  }

  void updatePolylines(Map<dynamic, dynamic>? polylineUpdates) {
    if (polylineUpdates == null) {
      return;
    }
    polylinesToAdd = _deserializePolylines(polylineUpdates['polylinesToAdd']);
    polylineIdsToRemove =
        _deserializePolylineIds(polylineUpdates['polylineIdsToRemove']);
    polylinesToChange =
        _deserializePolylines(polylineUpdates['polylinesToChange']);
  }

  Set<PolylineId> _deserializePolylineIds(List<dynamic>? polylineIds) {
    if (polylineIds == null) {
      return Set<PolylineId>();
    }
    return polylineIds
        .map((dynamic polylineId) => PolylineId(polylineId))
        .toSet();
  }

  Set<Polyline> _deserializePolylines(dynamic polylines) {
    if (polylines == null) {
      return Set<Polyline>();
    }
    final List<dynamic> polylinesData = polylines;
    final Set<Polyline> result = Set<Polyline>();
    for (Map<dynamic, dynamic> polylineData in polylinesData) {
      final String polylineId = polylineData['polylineId'];
      final bool visible = polylineData['visible'];
      // final bool geodesic = polylineData['geodesic'];

      result.add(Polyline(
        polylineId: PolylineId(polylineId),
        visible: visible,
        // geodesic: geodesic,
      ));
    }

    return result;
  }

  void updatePolygons(Map<dynamic, dynamic>? polygonUpdates) {
    if (polygonUpdates == null) {
      return;
    }
    polygonsToAdd = _deserializePolygons(polygonUpdates['polygonsToAdd']);
    polygonIdsToRemove =
        _deserializePolygonIds(polygonUpdates['polygonIdsToRemove']);
    polygonsToChange = _deserializePolygons(polygonUpdates['polygonsToChange']);
  }

  Set<PolygonId> _deserializePolygonIds(List<dynamic>? polygonIds) {
    if (polygonIds == null) {
      return Set<PolygonId>();
    }
    return polygonIds.map((dynamic polygonId) => PolygonId(polygonId)).toSet();
  }

  Set<Polygon> _deserializePolygons(dynamic polygons) {
    if (polygons == null) {
      return Set<Polygon>();
    }
    final List<dynamic> polygonsData = polygons;
    final Set<Polygon> result = Set<Polygon>();
    for (Map<dynamic, dynamic> polygonData in polygonsData) {
      final String polygonId = polygonData['polygonId'];
      final bool visible = polygonData['visible'];
      final bool consumeTapEvent = polygonData['consumeTapEvents'];
      final List<LatLng> points = _deserializePoints(polygonData['points']);

      result.add(
        Polygon(
          polygonId: PolygonId(polygonId),
          visible: visible,
          points: points,
          consumeTapEvents: consumeTapEvent,
        ),
      );
    }

    return result;
  }

  List<LatLng> _deserializePoints(List<dynamic> points) {
    return points.map<LatLng>((dynamic list) {
      return LatLng(list[0], list[1]);
    }).toList();
  }

  void updateCircles(Map<dynamic, dynamic>? circleUpdates) {
    if (circleUpdates == null) {
      return;
    }
    circlesToAdd = _deserializeCircles(circleUpdates['circlesToAdd']);
    circleIdsToRemove =
        _deserializeCircleIds(circleUpdates['circleIdsToRemove']);
    circlesToChange = _deserializeCircles(circleUpdates['circlesToChange']);
  }

  Set<CircleId>? _deserializeCircleIds(List<dynamic>? circleIds) {
    if (circleIds == null) {
      return Set<CircleId>();
    }
    return circleIds.map((dynamic circleId) => CircleId(circleId)).toSet();
  }

  Set<Circle> _deserializeCircles(dynamic circles) {
    if (circles == null) {
      return Set<Circle>();
    }
    final List<dynamic> circlesData = circles;
    final Set<Circle> result = Set<Circle>();
    for (Map<dynamic, dynamic> circleData in circlesData) {
      final String circleId = circleData['circleId'];
      final bool visible = circleData['visible'];
      final double radius = circleData['radius'];

      result.add(Circle(
        circleId: CircleId(circleId),
        visible: visible,
        radius: radius,
      ));
    }

    return result;
  }

  void updateOptions(Map<dynamic, dynamic> options) {
    if (options.containsKey('compassEnabled')) {
      compassEnabled = options['compassEnabled'];
    }
    if (options.containsKey('mapType')) {
      mapType = MapType.values[options['mapType']];
    }
    if (options.containsKey('minMaxZoomPreference')) {
      final List<dynamic> minMaxZoomList = options['minMaxZoomPreference'];
      minMaxZoomPreference =
          MinMaxZoomPreference(minMaxZoomList[0], minMaxZoomList[1]);
    }
    if (options.containsKey('rotateGesturesEnabled')) {
      rotateGesturesEnabled = options['rotateGesturesEnabled'];
    }
    if (options.containsKey('scrollGesturesEnabled')) {
      scrollGesturesEnabled = options['scrollGesturesEnabled'];
    }
    if (options.containsKey('pitchGesturesEnabled')) {
      pitchGesturesEnabled = options['pitchGesturesEnabled'];
    }
    if (options.containsKey('zoomGesturesEnabled')) {
      zoomGesturesEnabled = options['zoomGesturesEnabled'];
    }
    if (options.containsKey('myLocationEnabled')) {
      myLocationEnabled = options['myLocationEnabled'];
    }
    if (options.containsKey('myLocationButtonEnabled')) {
      myLocationButtonEnabled = options['myLocationButtonEnabled'];
    }
  }
}

class FakePlatformViewsController {
  FakePlatformAppleMap? lastCreatedView;

  Future<dynamic> fakePlatformViewsMethodHandler(MethodCall call) {
    switch (call.method) {
      case 'create':
        final Map<dynamic, dynamic> args = call.arguments;
        final Map<dynamic, dynamic> params = _decodeParams(args['params']);
        lastCreatedView = FakePlatformAppleMap(
          args['id'],
          params,
        );
        return Future<int>.sync(() => 1);
      default:
        return Future<void>.sync(() {});
    }
  }

  void reset() {
    lastCreatedView = null;
  }
}

Map<dynamic, dynamic> _decodeParams(Uint8List paramsMessage) {
  final ByteBuffer buffer = paramsMessage.buffer;
  final ByteData messageBytes = buffer.asByteData(
    paramsMessage.offsetInBytes,
    paramsMessage.lengthInBytes,
  );
  return const StandardMessageCodec().decodeMessage(messageBytes);
}
