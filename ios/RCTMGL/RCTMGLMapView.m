//
//  RCTMGLMapView.m
//  RCTMGL
//
//  Created by Nick Italiano on 8/23/17.
//  Copyright © 2017 Mapbox Inc. All rights reserved.
//

#import "RCTMGLMapView.h"
#import "CameraUpdateQueue.h"
#import "RCTMGLUtils.h"
#import "RNMBImageUtils.h"
#import "UIView+React.h"

@interface RCTMGLMapView()

@property (nonatomic, strong) UIImage *mapirLogo;

@end

@implementation RCTMGLMapView

static double const DEG2RAD = M_PI / 180;
static double const LAT_MAX = 85.051128779806604;
static double const TILE_SIZE = 256;
static double const EARTH_RADIUS_M = 6378137;
static double const M2PI = M_PI * 2;

@synthesize mapirLogo = _mapirLogo;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _cameraUpdateQueue = [[CameraUpdateQueue alloc] init];
        _sources = [[NSMutableArray alloc] init];
        _pointAnnotations = [[NSMutableArray alloc] init];
        _reactSubviews = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)invalidate
{
    if (_reactSubviews.count == 0) {
        return;
    }
    for (int i = 0; i < _reactSubviews.count; i++) {
        [self removeFromMap:_reactSubviews[i]];
    }
}

- (void) addToMap:(id<RCTComponent>)subview
{
    if ([subview isKindOfClass:[RCTMGLSource class]]) {
        RCTMGLSource *source = (RCTMGLSource*)subview;
        source.map = self;
        [_sources addObject:(RCTMGLSource*)subview];
    } else if ([subview isKindOfClass:[RCTMGLLight class]]) {
        RCTMGLLight *light = (RCTMGLLight*)subview;
        _light = light;
        _light.map = self;
    } else if ([subview isKindOfClass:[RCTMGLPointAnnotation class]]) {
        RCTMGLPointAnnotation *pointAnnotation = (RCTMGLPointAnnotation *)subview;
        pointAnnotation.map = self;
        [_pointAnnotations addObject:pointAnnotation];
    } else {
        NSArray<id<RCTComponent>> *childSubviews = [subview reactSubviews];

        for (int i = 0; i < childSubviews.count; i++) {
            [self addToMap:childSubviews[i]];
        }
    }
}

- (void) removeFromMap:(id<RCTComponent>)subview
{
    if ([subview isKindOfClass:[RCTMGLSource class]]) {
        RCTMGLSource *source = (RCTMGLSource*)subview;
        source.map = nil;
        [_sources removeObject:source];
    } else if ([subview isKindOfClass:[RCTMGLPointAnnotation class]]) {
        RCTMGLPointAnnotation *pointAnnotation = (RCTMGLPointAnnotation *)subview;
        pointAnnotation.map = nil;
        [_pointAnnotations removeObject:pointAnnotation];
    } else {
        NSArray<id<RCTComponent>> *childSubViews = [subview reactSubviews];
        
        for (int i = 0; i < childSubViews.count; i++) {
            [self removeFromMap:childSubViews[i]];
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)insertReactSubview:(id<RCTComponent>)subview atIndex:(NSInteger)atIndex {
    [self addToMap:subview];
    [_reactSubviews insertObject:(UIView *)subview atIndex:(NSUInteger) atIndex];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)removeReactSubview:(id<RCTComponent>)subview {
    // similarly, when the children are being removed we have to do the appropriate
    // underlying mapview action here.
    [self removeFromMap:subview];
    [_reactSubviews removeObject:(UIView *)subview];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (NSArray<id<RCTComponent>> *)reactSubviews {
    return _reactSubviews;
}
#pragma clang diagnostic pop

- (UIImage *)mapirLogo {
    if (!_mapirLogo) {
        NSString *base64Logo = @"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";
        
        NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Logo options: NSDataBase64DecodingIgnoreUnknownCharacters];
        _mapirLogo = [UIImage imageWithData:data];
    }
    return _mapirLogo;
}

- (void)setReactZoomEnabled:(BOOL)reactZoomEnabled
{
    _reactZoomEnabled = reactZoomEnabled;
    self.zoomEnabled = _reactZoomEnabled;
}

- (void)setReactScrollEnabled:(BOOL)reactScrollEnabled
{
    _reactScrollEnabled = reactScrollEnabled;
    self.scrollEnabled = _reactScrollEnabled;
}

- (void)setReactPitchEnabled:(BOOL)reactPitchEnabled
{
    _reactPitchEnabled = reactPitchEnabled;
    self.pitchEnabled = _reactPitchEnabled;
}

- (void)setReactRotateEnabled:(BOOL)reactRotateEnabled
{
    _reactRotateEnabled = reactRotateEnabled;
    self.rotateEnabled = _reactRotateEnabled;
}

- (void)setReactAttributionEnabled:(BOOL)reactAttributionEnabled
{
    _reactAttributionEnabled = reactAttributionEnabled;
    self.attributionButton.hidden = !_reactAttributionEnabled;
    
}

- (void)setReactLogoEnabled:(BOOL)reactLogoEnabled
{
    _reactLogoEnabled = reactLogoEnabled;
    self.logoView.hidden = !_reactLogoEnabled;
}

- (void)setReactCompassEnabled:(BOOL)reactCompassEnabled
{
    _reactCompassEnabled = reactCompassEnabled;
    self.compassView.hidden = !_reactCompassEnabled;
}

- (void)setReactShowUserLocation:(BOOL)reactShowUserLocation
{
    _reactShowUserLocation = reactShowUserLocation;
    self.showsUserLocation = _reactShowUserLocation;
}

- (void)setReactCenterCoordinate:(NSString *)reactCenterCoordinate
{
    _reactCenterCoordinate = reactCenterCoordinate;
    [self _updateCameraIfNeeded:YES];
}

- (void)setReactContentInset:(NSArray<NSNumber *> *)reactContentInset
{
    CGFloat top = 0.0f, right = 0.0f, left = 0.0f, bottom = 0.0f;
    
    if (reactContentInset.count == 4) {
        top = [reactContentInset[0] floatValue];
        right = [reactContentInset[1] floatValue];
        bottom = [reactContentInset[2] floatValue];
        left = [reactContentInset[3] floatValue];
    } else if (reactContentInset.count == 2) {
        top = [reactContentInset[0] floatValue];
        right = [reactContentInset[1] floatValue];
        bottom = [reactContentInset[0] floatValue];
        left = [reactContentInset[1] floatValue];
    } else if (reactContentInset.count == 1) {
        top = [reactContentInset[0] floatValue];
        right = [reactContentInset[0] floatValue];
        bottom = [reactContentInset[0] floatValue];
        left = [reactContentInset[0] floatValue];
    }
    
    self.contentInset = UIEdgeInsetsMake(top, left, bottom, right);
}

- (void)setReactStyleURL:(NSString *)reactStyleURL
{
    _reactStyleURL = reactStyleURL;
    [self _removeAllSourcesFromMap];
    self.styleURL = [self _getStyleURLFromKey:_reactStyleURL];
    self.attributionButton.alpha = 0;
    self.logoView.image = self.mapirLogo;
    
    [self.logoView setTranslatesAutoresizingMaskIntoConstraints: NO];
    [[self.logoView.widthAnchor constraintEqualToConstant:80.0] setActive:YES];
    [[self.logoView.heightAnchor constraintEqualToConstant:21.0] setActive:YES];
}

- (void)setHeading:(double)heading
{
    _heading = heading;
    [self _updateCameraIfNeeded:NO];
}

- (void)setPitch:(double)pitch
{
    _pitch = pitch;
    [self _updateCameraIfNeeded:NO];
}

- (void)setReactZoomLevel:(double)reactZoomLevel
{
    _reactZoomLevel = reactZoomLevel;
    self.zoomLevel = _reactZoomLevel;
}

- (void)setReactMinZoomLevel:(double)reactMinZoomLevel
{
    _reactMinZoomLevel = reactMinZoomLevel;
    self.minimumZoomLevel = _reactMinZoomLevel;
}

- (void)setReactMaxZoomLevel:(double)reactMaxZoomLevel
{
    _reactMaxZoomLevel = reactMaxZoomLevel;
    self.maximumZoomLevel = reactMaxZoomLevel;
}

- (void)setReactUserTrackingMode:(int)reactUserTrackingMode
{
    _reactUserTrackingMode = reactUserTrackingMode;
    [self setUserTrackingMode:_reactUserTrackingMode animated:NO];
    self.showsUserHeadingIndicator = (NSUInteger)_reactUserTrackingMode == MGLUserTrackingModeFollowWithHeading;
}

- (void)setReactUserLocationVerticalAlignment:(int)reactUserLocationVerticalAlignment
{
    _reactUserLocationVerticalAlignment = reactUserLocationVerticalAlignment;
    self.userLocationVerticalAlignment = reactUserLocationVerticalAlignment;
}

#pragma mark - methods

- (NSString *)takeSnap:(BOOL)writeToDisk
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return writeToDisk ? [RNMBImageUtils createTempFile:snapshot] : [RNMBImageUtils createBase64:snapshot];
}

- (CLLocationDistance)getMetersPerPixelAtLatitude:(double)latitude withZoom:(double)zoomLevel
{
    double constrainedZoom = [[RCTMGLUtils clamp:[NSNumber numberWithDouble:zoomLevel]
                                             min:[NSNumber numberWithDouble:self.minimumZoomLevel]
                                             max:[NSNumber numberWithDouble:self.maximumZoomLevel]] doubleValue];
    
    double constrainedLatitude = [[RCTMGLUtils clamp:[NSNumber numberWithDouble:latitude]
                                                 min:[NSNumber numberWithDouble:-LAT_MAX]
                                                 max:[NSNumber numberWithDouble:LAT_MAX]] doubleValue];
    
    double constrainedScale = pow(2.0, constrainedZoom);
    return cos(constrainedLatitude * DEG2RAD) * M2PI * EARTH_RADIUS_M / (constrainedScale * TILE_SIZE);
}

- (CLLocationDistance)altitudeFromZoom:(double)zoomLevel
{
    CLLocationDistance metersPerPixel = [self getMetersPerPixelAtLatitude:self.camera.centerCoordinate.latitude withZoom:zoomLevel];
    CLLocationDistance metersTall = metersPerPixel * self.frame.size.height;
    CLLocationDistance altitude = metersTall / 2 / tan(MGLRadiansFromDegrees(30) / 2.0);
    return altitude * sin(M_PI_2 - MGLRadiansFromDegrees(self.camera.pitch)) / sin(M_PI_2);
}

- (RCTMGLPointAnnotation*)getRCTPointAnnotation:(MGLPointAnnotation *)mglAnnotation
{
    for (int i = 0; i < _pointAnnotations.count; i++) {
        RCTMGLPointAnnotation *rctAnnotation = _pointAnnotations[i];
        if (rctAnnotation.annotation == mglAnnotation) {
            return rctAnnotation;
        }
    }
    return nil;
}

- (NSArray<RCTMGLSource *> *)getAllTouchableSources
{
    NSMutableArray<RCTMGLSource *> *touchableSources = [[NSMutableArray alloc] init];
    
    for (RCTMGLSource *source in _sources) {
        if (source.hasPressListener) {
            [touchableSources addObject:source];
        }
    }
    
    return touchableSources;
}

- (RCTMGLSource *)getTouchableSourceWithHighestZIndex:(NSArray<RCTMGLSource *> *)touchableSources
{
    if (touchableSources == nil || touchableSources.count == 0) {
        return nil;
    }
    
    if (touchableSources.count == 1) {
        return touchableSources[0];
    }
    
    NSMutableDictionary<NSString *, RCTMGLSource *> *layerToSoureDict = [[NSMutableDictionary alloc] init];
    for (RCTMGLSource *touchableSource in touchableSources) {
        NSArray<NSString *> *layerIDs = [touchableSource getLayerIDs];
        
        for (NSString *layerID in layerIDs) {
            layerToSoureDict[layerID] = touchableSource;
        }
    }
    
    NSArray<MGLStyleLayer *> *layers = self.style.layers;
    for (int i = (int)layers.count - 1; i >= 0; i--) {
        MGLStyleLayer *layer = layers[i];
        
        RCTMGLSource *source = layerToSoureDict[layer.identifier];
        if (source != nil) {
            return source;
        }
    }
    
    return nil;
}

- (NSURL*)_getStyleURLFromKey:(NSString *)styleURL
{
    return [NSURL URLWithString:styleURL];
}

- (void)_updateCameraIfNeeded:(BOOL)shouldUpdateCenterCoord
{
    if (shouldUpdateCenterCoord) {
        [self setCenterCoordinate:[RCTMGLUtils fromFeature:_reactCenterCoordinate] animated:_animated];
    } else {
        MGLMapCamera *camera = [self.camera copy];
        camera.pitch = _pitch;
        camera.heading = _heading;
        [self setCamera:camera animated:_animated];
    }
}

- (void)_removeAllSourcesFromMap
{
    if (self.style == nil || _sources.count == 0) {
        return;
    }
    for (RCTMGLSource *source in _sources) {
        source.map = nil;
    }
}

@end
