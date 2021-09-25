//
//  OAGPXLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAGPXLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OATargetPoint.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"
#import "OAGpxWptItem.h"
#import "OASelectedGPXHelper.h"
#import "OASavingTrackHelper.h"
#import "OAWaypointsMapLayerProvider.h"
#import "OAFavoritesLayer.h"
#import "OARouteColorizationHelper.h"
#import "OAColoringType.h"

#include <OsmAndCore/Ref.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@implementation OAGPXLayer
{
    std::shared_ptr<OAWaypointsMapLayerProvider> _waypointsMapProvider;
    BOOL _showCaptionsCache;
    OsmAnd::PointI _hiddenPointPos31;
}

- (NSString *) layerId
{
    return kGpxLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _hiddenPointPos31 = OsmAnd::PointI();
    _showCaptionsCache = self.showCaptions;

    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    
    [self.mapView addKeyedSymbolsProvider:_linesCollection];
}

- (void) resetLayer
{
    [super resetLayer];

    [self.mapView removeTiledSymbolsProvider:_waypointsMapProvider];
    [self.mapView removeKeyedSymbolsProvider:_linesCollection];

    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    
    _gpxDocs.clear();
}

- (BOOL) updateLayer
{
    [super updateLayer];
    
    if (self.showCaptions != _showCaptionsCache)
    {
        _showCaptionsCache = self.showCaptions;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshGpxWaypoints];
        });
    }
    
    return YES;
}

- (void) refreshGpxTracks:(QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> >)gpxDocs
{
    [self resetLayer];

    _gpxDocs = gpxDocs;
    
    [self refreshGpxTracks];
}

- (OAGPX *)getGpxItem:(const QString &)filename
{
    NSString *filenameNS = filename.toNSString();
    filenameNS = [OAUtilities getGpxShortPath:filenameNS];
    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:filenameNS];
    return gpx;
}

- (OsmAnd::ColorARGB) getTrackColor:(QString)filename
{
    OAGPX * gpx = [self getGpxItem:filename];
    int colorValue = kDefaultTrackColor;
    if (gpx && gpx.color != 0)
        colorValue = (int) gpx.color;
    
    OsmAnd::ColorARGB color(colorValue);
    
//    if (extraData)
//    {
//        const auto& values = extraData->getValues();
//        const auto& it = values.find(QStringLiteral("color"));
//        if (it != values.end())
//        {
//            //bool ok;
//            //color = OsmAnd::Utilities::parseColor(it.value().toString(), OsmAnd::ColorARGB(kDefaultTrackColor), &ok);
//            NSString *colorStr = it.value().toString().toNSString();
//            UIColor *c = [OAUtilities colorFromString:colorStr];
//            if (c)
//            {
//                CGFloat r, g, b, a;
//                [c getRed:&r green:&g blue:&b alpha:&a];
//                color = OsmAnd::ColorARGB(255 * a, 255 * r, 255 * g, 255 * b);
//            }
//        }
//    }
    return color;
}

- (UIColor *) getWptColor:(OsmAnd::Ref<OsmAnd::GeoInfoDocument::ExtraData>)extraData
{
    if (extraData)
    {
        const auto& values = extraData->getValues();
        const auto& it = values.find(QStringLiteral("color"));
        if (it != values.end())
            return [OAUtilities colorFromString:it.value().toString().toNSString()];
    }
    return nil;
}

- (void) refreshGpxTracks
{
    if (!_gpxDocs.empty())
    {
        int baseOrder = self.baseOrder;
        int lineId = 1;
        for (auto it = _gpxDocs.begin(); it != _gpxDocs.end(); ++it)
        {
            if (it.key().isNull() && !it.value())
                continue;
            
            BOOL routePoints = NO;
            
            OAGPX *gpx = [self getGpxItem:it.key()];

            if (it.value()->hasTrkPt())
            {
                for (const auto& track : it.value()->tracks)
                {
                    for (const auto& seg : track->segments)
                    {
                        QVector<OsmAnd::PointI> points;
                        
                        for (const auto& pt : seg->points)
                        {
                            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                        }
                        [self drawLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++];
                    }
                }
            }
            else if (it.value()->hasRtePt())
            {
                routePoints = YES;
                for (const auto& route : it.value()->routes)
                {
                    QVector<OsmAnd::PointI> points;
                    for (const auto& pt : route->points)
                    {
                        points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                    }
                    [self drawLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++];
                }
            }
        }
        [self.mapView addKeyedSymbolsProvider:_linesCollection];
    }
    [self setVectorLineProvider:_linesCollection];
    [self refreshGpxWaypoints];
}

- (void) drawLine:(QVector<OsmAnd::PointI> &)points gpx:(OAGPX *)gpx baseOrder:(int)baseOrder lineId:(int)lineId
{
    if (points.size() > 1)
    {
        QList<OsmAnd::FColorARGB> colors;
        if (gpx.coloringType.length > 0)
        {
            NSString *path = [self.app.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
            QString qPath = QString::fromNSString(path);
            auto geoDoc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_gpxDocs[qPath]);
            OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxDocument:std::dynamic_pointer_cast<OsmAnd::GpxDocument>(geoDoc)];
            doc.path = path;
            OAColoringType *type = [OAColoringType getNonNullTrackColoringTypeByName:gpx.coloringType];
            OARouteColorizationHelper *routeColorization = [[OARouteColorizationHelper alloc] initWithGpxFile:doc analysis:[doc getAnalysis:0] type:type.toGradientScaleType.toColorizationType maxProfileSpeed:0];
            
            colors = routeColorization ? [routeColorization getResult] : QList<OsmAnd::FColorARGB>();
            // Add outline for colorized lines
            if (!colors.isEmpty())
            {
                const auto outlineColor = OsmAnd::ColorARGB(150, 0, 0, 0);
                
                OsmAnd::VectorLineBuilder outlineBuilder;
                outlineBuilder.setBaseOrder(baseOrder--)
                .setIsHidden(points.size() == 0)
                .setLineId(lineId + 1000)
                .setLineWidth(30)
                .setPoints(points)
                .setFillColor(outlineColor);
                
                outlineBuilder.buildAndAddToCollection(_linesCollection);
            }
        }
        
        const auto colorARGB = OsmAnd::ColorARGB((int) gpx.color);
        OsmAnd::VectorLineBuilder builder;
        builder.setBaseOrder(baseOrder)
        .setIsHidden(points.size() == 0)
        .setLineId(lineId)
        .setLineWidth(20)
        .setPoints(points)
        .setFillColor(colorARGB);
        
        if (!colors.empty())
            builder.setColorizationMapping(colors);
        
        if (gpx.showArrows)
        {
            // Use black arrows for gradient colorization
            UIColor *color = gpx.coloringType.length == 0 ? UIColor.whiteColor : UIColorFromARGB(gpx.color);
            builder.setPathIcon([self bitmapForColor:color fileName:@"map_direction_arrow"])
            .setSpecialPathIcon([self specialBitmapWithColor:colorARGB])
            .setShouldShowArrows(true)
            .setScreenScale(UIScreen.mainScreen.scale);
        }
        
        builder.buildAndAddToCollection(_linesCollection);
    }
}

- (void) refreshGpxWaypoints
{
    if (_waypointsMapProvider)
    {
        [self.mapView removeTiledSymbolsProvider:_waypointsMapProvider];
        _waypointsMapProvider = nullptr;
    }

    if (!_gpxDocs.empty())
    {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>> locationMarks;
        QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> >::iterator it;
        for (it = _gpxDocs.begin(); it != _gpxDocs.end(); ++it)
        {
            if (!it.value())
                continue;
            
            if (!it.value()->locationMarks.empty())
                locationMarks.append(it.value()->locationMarks);
        }
        
        const auto rasterTileSize = self.mapViewController.referenceTileSizeRasterOrigInPixels;
        QList<OsmAnd::PointI> hiddenPoints;
        if (_hiddenPointPos31 != OsmAnd::PointI())
            hiddenPoints.append(_hiddenPointPos31);
        
        _waypointsMapProvider.reset(new OAWaypointsMapLayerProvider(locationMarks, self.baseOrder - locationMarks.count() - 1, hiddenPoints,
                                                                    self.showCaptions, self.captionStyle, self.captionTopSpace, rasterTileSize));
        [self.mapView addTiledSymbolsProvider:_waypointsMapProvider];
    }
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OAGpxWptItem class]])
    {
        OAGpxWptItem *item = (OAGpxWptItem *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetWpt;
        targetPoint.location = item.point.position;
        targetPoint.targetObj = item;

        targetPoint.icon = item.getCompositeIcon;
        targetPoint.title = item.point.name;
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    OAMapViewController *mapViewController = self.mapViewController;
    if (const auto markerGroup = dynamic_cast<OsmAnd::MapMarker::SymbolsGroup*>(symbolInfo->mapSymbol->groupPtr))
    {
        if ([mapViewController findWpt:point])
        {
            OAGpxWpt *wpt = mapViewController.foundWpt;
            NSArray *foundWptGroups = mapViewController.foundWptGroups;
            NSString *foundWptDocPath = mapViewController.foundWptDocPath;

            OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
            item.point = wpt;
            item.groups = foundWptGroups;
            item.docPath = foundWptDocPath;

            OATargetPoint *targetPoint = [self getTargetPoint:item];
            if (![found containsObject:targetPoint])
                [found addObject:targetPoint];
        }
    }
}

#pragma mark - OAMoveObjectProvider

- (BOOL) isObjectMovable:(id)object
{
    return [object isKindOfClass:OAGpxWptItem.class];
}

- (void) applyNewObjectPosition:(id)object position:(CLLocationCoordinate2D)position
{
    if (object && [self isObjectMovable:object])
    {
        OAGpxWptItem *item = (OAGpxWptItem *)object;
        
        if (item.docPath)
        {
            item.point.position = position;
            item.point.wpt->position = OsmAnd::LatLon(position.latitude, position.longitude);
            const auto activeGpx = [OASelectedGPXHelper instance].activeGpx;
            const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(activeGpx[QString::fromNSString(item.docPath)]);
            if (doc != nullptr)
            {
                doc->saveTo(QString::fromNSString(item.docPath));
                QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> > docs;
                docs[QString::fromNSString(item.docPath)] = doc;
                [self refreshGpxTracks:docs];
            }
        }
        else
        {
            OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
            [helper updatePointCoordinates:item.point newLocation:position];
            item.point.wpt->position = OsmAnd::LatLon(position.latitude, position.longitude);
            [self.app.trackRecordingObservable notifyEventWithKey:@(YES)];
        }
    }
}

- (UIImage *) getPointIcon:(id)object
{
    if (object && [self isObjectMovable:object])
    {
        OAGpxWptItem *point = (OAGpxWptItem *)object;
        return [OAFavoritesLayer getImageWithColor:point.color background:point.point.getBackgroundIcon icon:[@"mx_" stringByAppendingString:point.point.getIcon]];
    }
    OAFavoriteColor *def = [OADefaultFavorite nearestFavColor:OADefaultFavorite.builtinColors.firstObject];
    return [OAFavoritesLayer getImageWithColor:def.color background:@"circle" icon:[@"mx_" stringByAppendingString:@"special_star"]];
}

- (void) setPointVisibility:(id)object hidden:(BOOL)hidden
{
    if (object && [self isObjectMovable:object])
    {
        OAGpxWptItem *point = (OAGpxWptItem *)object;
        const auto& pos = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.point.getLatitude, point.point.getLongitude));
        _hiddenPointPos31 = hidden ? pos : OsmAnd::PointI();
        [self refreshGpxWaypoints];
    }
}

- (EOAPinVerticalAlignment) getPointIconVerticalAlignment
{
    return EOAPinAlignmentCenterVertical;
}


- (EOAPinHorizontalAlignment) getPointIconHorizontalAlignment
{
    return EOAPinAlignmentCenterHorizontal;
}

@end
