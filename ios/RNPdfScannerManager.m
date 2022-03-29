
#import "RNPdfScannerManager.h"
#import "DocumentScannerView.h"

@interface RNPdfScannerManager()
@property (strong, nonatomic) DocumentScannerView *scannerView;
@end

@implementation RNPdfScannerManager

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_VIEW_PROPERTY(onPictureTaken, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRectangleDetect, RCTBubblingEventBlock)


RCT_EXPORT_VIEW_PROPERTY(overlayColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(enableTorch, BOOL)
RCT_EXPORT_VIEW_PROPERTY(useFrontCam, BOOL)
RCT_EXPORT_VIEW_PROPERTY(useBase64, BOOL)
RCT_EXPORT_VIEW_PROPERTY(saveInAppDocument, BOOL)
RCT_EXPORT_VIEW_PROPERTY(captureMultiple, BOOL)
RCT_EXPORT_VIEW_PROPERTY(detectionCountBeforeCapture, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(detectionRefreshRateInMS, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(saturation, float)
RCT_EXPORT_VIEW_PROPERTY(quality, float)
RCT_EXPORT_VIEW_PROPERTY(brightness, float)
RCT_EXPORT_VIEW_PROPERTY(contrast, float)

RCT_EXPORT_METHOD(capture) {

    [_scannerView capture];
}

RCT_EXPORT_METHOD(detectDocument:(NSString *)imageUri callback:(RCTResponseSenderBlock)callback)
{
    NSString *parsedImageUri = [imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSURL *fileURL = [NSURL fileURLWithPath:parsedImageUri];
    CIImage *ciImage = [CIImage imageWithContentsOfURL:fileURL];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
    // 获取矩形区域数组
    NSArray <CIFeature *>*rectangles = [detector featuresInImage:[CIImage imageWithCGImage:ciImage.CGImage]];
    CIRectangleFeature *rectangleFeature = nil;
    if (rectangles.count > 0) {
        
        // 最大矩形区域
        CIRectangleFeature *rectangleFeature = (CIRectangleFeature *)rectangles.firstObject;
        
        CGFloat rectangleRect = 0;
        
        for (CIRectangleFeature *rect in rectangles) {
            
            CGPoint p1 = rect.topLeft;
            CGPoint p2 = rect.topRight;
            CGFloat width = hypotf(p1.x - p2.x, p1.y - p2.y);
            
            CGPoint p3 = rect.topLeft;
            CGPoint p4 = rect.bottomLeft;
            CGFloat height = hypotf(p3.x - p4.x, p3.y - p4.y);
            
            CGFloat currentRectangleRect = height + width;
            
            // 获取最大矩形rect
            if (rectangleRect < currentRectangleRect) {
                
                rectangleRect = currentRectangleRect;
                rectangleFeature = rect;
            }
        }
    }
    NSDictionary *rectangleCoordinates = rectangleFeature ? @{
                             @"topLeft": @{ @"y": @(rectangleFeature.bottomLeft.x + 30), @"x": @(rectangleFeature.bottomLeft.y)},
                             @"topRight": @{ @"y": @(rectangleFeature.topLeft.x + 30), @"x": @(rectangleFeature.topLeft.y)},
                             @"bottomLeft": @{ @"y": @(rectangleFeature.bottomRight.x), @"x": @(rectangleFeature.bottomRight.y)},
                             @"bottomRight": @{ @"y": @(rectangleFeature.topRight.x), @"x": @(rectangleFeature.topRight.y)},
                             } : [NSDictionary dictionary];
    
    NSDictionary * p = ciImage.properties;
    callback(@[@{@"rectangleCoordinates":rectangleCoordinates,@"size":@{@"width":p[@"PixelWidth"],@"height":p[@"PixelHeight"]}}]);
}

RCT_EXPORT_METHOD(crop:(NSDictionary *)points imageUri:(NSString *)imageUri callback:(RCTResponseSenderBlock)callback)
{
    NSString *parsedImageUri = [imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSURL *fileURL = [NSURL fileURLWithPath:parsedImageUri];
    CIImage *ciImage = [CIImage imageWithContentsOfURL:fileURL];
    
    CGPoint newLeft = CGPointMake([points[@"topLeft"][@"x"] floatValue], [points[@"topLeft"][@"y"] floatValue]);
    CGPoint newRight = CGPointMake([points[@"topRight"][@"x"] floatValue], [points[@"topRight"][@"y"] floatValue]);
    CGPoint newBottomLeft = CGPointMake([points[@"bottomLeft"][@"x"] floatValue], [points[@"bottomLeft"][@"y"] floatValue]);
    CGPoint newBottomRight = CGPointMake([points[@"bottomRight"][@"x"] floatValue], [points[@"bottomRight"][@"y"] floatValue]);
    
    newLeft = [self cartesianForPoint:newLeft height:[points[@"height"] floatValue] ];
    newRight = [self cartesianForPoint:newRight height:[points[@"height"] floatValue] ];
    newBottomLeft = [self cartesianForPoint:newBottomLeft height:[points[@"height"] floatValue] ];
    newBottomRight = [self cartesianForPoint:newBottomRight height:[points[@"height"] floatValue] ];
    
    
    
    NSMutableDictionary *rectangleCoordinates = [[NSMutableDictionary alloc] init];
    
    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:newLeft];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:newRight];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:newBottomLeft];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:newBottomRight];
    
    ciImage = [ciImage imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgimage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *image = [UIImage imageWithCGImage:cgimage];
    
    NSData *imageToEncode = UIImageJPEGRepresentation(image, 0.8);
    callback(@[[NSNull null], @{@"image": [imageToEncode base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]}]);
}

- (CGPoint)cartesianForPoint:(CGPoint)point height:(float)height {
    return CGPointMake(point.x, height - point.y);
}


- (UIView*) view {
    _scannerView = [[DocumentScannerView alloc] init];
    return _scannerView;
}

@end
