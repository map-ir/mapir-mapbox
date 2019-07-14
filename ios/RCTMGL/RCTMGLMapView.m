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
#import <React/UIView+React.h>

@implementation RCTMGLMapView
{
    BOOL _pendingInitialLayout;
}

static double const DEG2RAD = M_PI / 180;
static double const LAT_MAX = 85.051128779806604;
static double const TILE_SIZE = 256;
static double const EARTH_RADIUS_M = 6378137;
static double const M2PI = M_PI * 2;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _pendingInitialLayout = YES;
        _cameraUpdateQueue = [[CameraUpdateQueue alloc] init];
        _sources = [[NSMutableArray alloc] init];
        _pointAnnotations = [[NSMutableArray alloc] init];
        _reactSubviews = [[NSMutableArray alloc] init];
        _layerWaiters = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (_pendingInitialLayout) {
        _pendingInitialLayout = NO;

        [   _reactCamera initialLayout];
    }
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

- (void)layerAdded:(MGLStyleLayer*) layer
{
    NSString* layerID = layer.identifier;
    NSMutableArray* waiters = [_layerWaiters valueForKey:layerID];
    if (waiters) {
        for (FoundLayerBlock foundLayerBlock in waiters) {
            foundLayerBlock(layer);
        }
        [_layerWaiters removeObjectForKey:layerID];
    }
}

- (void)waitForLayerWithID:(nonnull NSString*)layerID then:(void (^)(MGLStyleLayer* layer))foundLayer {
    if (self.style) {
        MGLStyleLayer* layer = [self.style layerWithIdentifier:layerID];
        if (layer) {
            foundLayer(layer);
        } else {
            NSMutableArray* existingWaiters = [_layerWaiters valueForKey:layerID];
            
            NSMutableArray* waiters = existingWaiters;
            if (waiters == nil) {
                waiters = [[NSMutableArray alloc] init];
            }
            [waiters addObject:foundLayer];
            if (! existingWaiters) {
                [_layerWaiters setObject:waiters forKey:layerID];
            }
        }
    } else {
        // TODO
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
    } else if ([subview isKindOfClass:[RCTMGLCamera class]]) {
        RCTMGLCamera *camera = (RCTMGLCamera *)subview;
        camera.map = self;
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
    } else if ([subview isKindOfClass:[RCTMGLCamera class]]) {
        RCTMGLCamera *camera = (RCTMGLCamera *)subview;
        camera.map = nil;
    } else {
        NSArray<id<RCTComponent>> *childSubViews = [subview reactSubviews];
        
        for (int i = 0; i < childSubViews.count; i++) {
            [self removeFromMap:childSubViews[i]];
        }
    }
    if ([_layerWaiters count] > 0) {
        RCTLogWarn(@"The following layers were waited on but never added to the map: %@", [_layerWaiters allKeys]);
        [_layerWaiters removeAllObjects];
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
    // FMTODO
    //_reactShowUserLocation = reactShowUserLocation;
    self.showsUserLocation = reactShowUserLocation; //_reactShowUserLocation;
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
    _reactStyleURL = @"https://map.ir/vector/styles/main/main_mobile_style.json";
    [self _removeAllSourcesFromMap];
    self.styleURL = [self _getStyleURLFromKey:_reactStyleURL];
    
    NSString *base64Logo = @"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";
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Logo options: NSDataBase64DecodingIgnoreUnknownCharacters];
    self.logoView.image = [UIImage imageWithData:data];
    self.logoView.contentMode = UIViewContentModeScaleAspectFit;
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
    return [self altitudeFromZoom:zoomLevel atLatitude:self.camera.centerCoordinate.latitude];
}

- (CLLocationDistance)altitudeFromZoom:(double)zoomLevel atLatitude:(CLLocationDegrees)latitude
{
    return [self altitudeFromZoom:zoomLevel atLatitude:latitude atPitch:self.camera.pitch];
}

- (CLLocationDistance)altitudeFromZoom:(double)zoomLevel atLatitude:(CLLocationDegrees)latitude atPitch:(CGFloat)pitch
{
    return MGLAltitudeForZoomLevel(zoomLevel, pitch, latitude, self.frame.size);
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

- (NSArray<RCTMGLShapeSource *> *)getAllShapeSources
{
    NSMutableArray<RCTMGLSource *> *shapeSources = [[NSMutableArray alloc] init];
    
    for (RCTMGLSource *source in _sources) {
        if ([source isKindOfClass:[RCTMGLShapeSource class]]) {
            [shapeSources addObject:source];
        }
    }
    
    return shapeSources;
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

- (void)_removeAllSourcesFromMap
{
    if (self.style == nil || _sources.count == 0) {
        return;
    }
    for (RCTMGLSource *source in _sources) {
        source.map = nil;
    }
}

- (void)didChangeUserTrackingMode:(MGLUserTrackingMode)mode animated:(BOOL)animated {
    [_reactCamera didChangeUserTrackingMode:mode animated:animated];
}

@end
