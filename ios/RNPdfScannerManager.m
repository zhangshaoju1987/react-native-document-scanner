
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

static CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180.0;
};


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

RCT_EXPORT_METHOD(stop) {

    NSLog(@"停止相机扫描");
    [_scannerView stopCamera];
}

RCT_EXPORT_METHOD(thumbnail:(NSString *)imageUri scale:(float)scale quality:(float)quality callback:(RCTResponseSenderBlock)callback)
{
    NSString *parsedImageUri = [imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    UIImage *image = [UIImage imageWithContentsOfFile:parsedImageUri];
    
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scale, image.size.height * scale));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imageData = UIImageJPEGRepresentation(scaledImage, quality);
    
    NSString *dir = NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory , NSUserDomainMask , YES ).firstObject;
    NSUUID *uuid = [NSUUID UUID];
    NSString *time = [uuid UUIDString];

    NSString *filePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"thumbnail_image_%@.jpeg",time]];
    [imageData writeToFile:filePath atomically:YES];
    NSString *uri = [NSString stringWithFormat:@"%@%@",@"file://",filePath];
    callback(@[@{@"image": uri}]);
}


RCT_EXPORT_METHOD(scaleImage:(NSString *)imageUri scale:(float)scale callback:(RCTResponseSenderBlock)callback)
{
    NSString *parsedImageUri = [imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    UIImage *image = [UIImage imageWithContentsOfFile:parsedImageUri];
    
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scale, image.size.height * scale));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imageToEncode = UIImageJPEGRepresentation(scaledImage, 1.0);
    
    NSString *dir = NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory , NSUserDomainMask , YES ).firstObject;
    NSUUID *uuid = [NSUUID UUID];
    NSString *time = [uuid UUIDString];
    NSString *filePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"scaled_image_%@.jpeg",time]];
    [imageToEncode writeToFile:filePath atomically:YES];
    NSString *uri = [NSString stringWithFormat:@"%@%@",@"file://",filePath];
    callback(@[@{@"image": uri}]);
}

RCT_EXPORT_METHOD(rotateImage:(NSString *)base64Img callback:(RCTResponseSenderBlock)callback)
{
    UIImage *image = nil;
    // 同时支持base64图片和磁盘图片
    if ([base64Img hasPrefix:@"file://"]){
        NSString *parsedImageUri = [base64Img stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        NSLog(@"rotateImage url is %@",parsedImageUri);
        image = [UIImage imageWithContentsOfFile:parsedImageUri];
    }else{
        NSData *data = [[NSData alloc]initWithBase64EncodedString:base64Img options:NSDataBase64DecodingIgnoreUnknownCharacters];
        image = [UIImage imageWithData:data];
    }
    
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(90));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
      
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
      
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);
      
    // Rotate the image context
    CGContextRotateCTM(bitmap, DegreesToRadians(90));
      
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
      
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *imageToEncode = UIImageJPEGRepresentation(rotatedImage, 1.0);
    
    NSString *dir = NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory , NSUserDomainMask , YES ).firstObject;
    NSUUID *uuid = [NSUUID UUID];
    NSString *time = [uuid UUIDString];
    NSString *filePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"rotate_%@.jpeg",time]];
    [imageToEncode writeToFile:filePath atomically:YES];
    NSString *uri = [NSString stringWithFormat:@"%@%@",@"file://",filePath];
    callback(@[@{@"image": uri}]);
}

RCT_EXPORT_METHOD(detectDocument:(NSString *)imageUri callback:(RCTResponseSenderBlock)callback)
{
    NSString *parsedImageUri = [imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSLog(@"url is %@",imageUri);
    NSURL *fileURL = [NSURL fileURLWithPath:parsedImageUri];
    CIImage *ciImage = [CIImage imageWithContentsOfURL:fileURL];
    UIImage *uiImage = [UIImage imageWithContentsOfFile:parsedImageUri];

    NSDictionary *p = ciImage.properties;
    NSLog(@"UIImage width=%.20f,height=%.20f",uiImage.size.width,uiImage.size.height);
    float pixelWidth = [p[@"PixelWidth"] floatValue];
    
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorReturnSubFeatures: @(YES) }];
    // 获取矩形区域数组
    NSArray <CIFeature *>*rectangles = [detector featuresInImage:ciImage];
    CIRectangleFeature *rectangleFeature = nil;
    if (rectangles.count > 0) {
        
        // 最大矩形区域
        rectangleFeature = (CIRectangleFeature *)rectangles.firstObject;
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
    NSDictionary *rectangleCoordinates = nil;
    if(pixelWidth == uiImage.size.width){
        CGRect rect = CGRectMake(0, 0, uiImage.size.width, uiImage.size.height);
        CGAffineTransform transform = CGAffineTransformMakeTranslation(0.f, CGRectGetHeight(rect));
        transform = CGAffineTransformScale(transform, 1, -1);
        NSLog(@"仿射变换之前topLeft.x=%f,topLeft.y=%f",rectangleFeature.topLeft.x,rectangleFeature.topLeft.y);
        CGPoint topLeft = CGPointApplyAffineTransform(rectangleFeature.topLeft, transform);
        CGPoint topRight = CGPointApplyAffineTransform(rectangleFeature.topRight, transform);
        CGPoint bottomRight = CGPointApplyAffineTransform(rectangleFeature.bottomRight, transform);
        CGPoint bottomLeft = CGPointApplyAffineTransform(rectangleFeature.bottomLeft, transform);
        NSLog(@"仿射变换之后topLeft.x=%f,topLeft.y=%f",topLeft.x,topLeft.y);

        rectangleCoordinates = rectangleFeature ? @{
                                 @"topLeft": @{ @"y": @(topLeft.y), @"x": @(topLeft.x)},
                                 @"topRight": @{ @"y": @(topRight.y), @"x": @(topRight.x)},
                                 @"bottomLeft": @{ @"y": @(bottomLeft.y), @"x": @(bottomLeft.x)},
                                 @"bottomRight": @{ @"y": @(bottomRight.y), @"x": @(bottomRight.x)},
                                 } : [NSDictionary dictionary];
    }else{
        rectangleCoordinates = rectangleFeature ? @{
                                     @"topLeft": @{ @"y": @(rectangleFeature.bottomLeft.x), @"x": @(rectangleFeature.bottomLeft.y)},
                                     @"topRight": @{ @"y": @(rectangleFeature.topLeft.x), @"x": @(rectangleFeature.topLeft.y)},
                                     @"bottomLeft": @{ @"y": @(rectangleFeature.bottomRight.x), @"x": @(rectangleFeature.bottomRight.y)},
                                     @"bottomRight": @{ @"y": @(rectangleFeature.topRight.x), @"x": @(rectangleFeature.topRight.y)},
                                     } : [NSDictionary dictionary];
    }
    callback(@[@{@"success":@YES,@"rectangleCoordinates":rectangleCoordinates,@"size":@{@"width":@(uiImage.size.width),@"height":@(uiImage.size.height)}}]);
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
    NSData *imageToEncode = UIImageJPEGRepresentation(image, 1.0);
    
    CGImageRelease(cgimage);

    NSString *dir = NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory , NSUserDomainMask , YES ).firstObject;
    int time = (int)[NSDate date].timeIntervalSince1970;
    NSString *filePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"document0_%i.jpeg",time]];
    [imageToEncode writeToFile:filePath atomically:YES];
    NSString *uri = [NSString stringWithFormat:@"%@%@",@"file://",filePath];
    callback(@[@{@"image": uri}]);
    
}

RCT_EXPORT_METHOD(cropImage:(NSDictionary *)points imageUri:(NSString *)imageUri callback:(RCTResponseSenderBlock)callback)
{
    NSString *parsedImageUri = [imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSURL *fileURL = [NSURL fileURLWithPath:parsedImageUri];
    CIImage *ciImage = [CIImage imageWithContentsOfURL:fileURL];
    UIImage *uiImage = [UIImage imageWithContentsOfFile:parsedImageUri];
    NSDictionary *p = ciImage.properties;
    NSLog(@"UIImage width=%.20f,height=%.20f",uiImage.size.width,uiImage.size.height);
    float pixelWidth = [p[@"PixelWidth"] floatValue];
    
    CGPoint newLeft = CGPointMake([points[@"topLeft"][@"y"] floatValue], [points[@"topLeft"][@"x"] floatValue]);
    CGPoint newRight = CGPointMake([points[@"topRight"][@"y"] floatValue], [points[@"topRight"][@"x"] floatValue]);
    CGPoint newBottomRight = CGPointMake([points[@"bottomRight"][@"y"] floatValue], [points[@"bottomRight"][@"x"] floatValue]);
    CGPoint newBottomLeft = CGPointMake([points[@"bottomLeft"][@"y"] floatValue], [points[@"bottomLeft"][@"x"] floatValue]);
    
    if(pixelWidth == uiImage.size.width){
        
        newLeft = CGPointMake([points[@"topLeft"][@"x"] floatValue], [points[@"topLeft"][@"y"] floatValue]);
        newRight = CGPointMake([points[@"topRight"][@"x"] floatValue], [points[@"topRight"][@"y"] floatValue]);
        newBottomRight = CGPointMake([points[@"bottomRight"][@"x"] floatValue], [points[@"bottomRight"][@"y"] floatValue]);
        newBottomLeft = CGPointMake([points[@"bottomLeft"][@"x"] floatValue], [points[@"bottomLeft"][@"y"] floatValue]);
        NSLog(@"裁剪收到的参数,topLeft.x=%f,topLeft.y=%f",newLeft.x,newLeft.y);
        CGRect rect = CGRectMake(0, 0, uiImage.size.width, uiImage.size.height);
        CGAffineTransform transform = CGAffineTransformMakeTranslation(0.f, CGRectGetHeight(rect));
        transform = CGAffineTransformScale(transform, 1, -1);
        newLeft = CGPointApplyAffineTransform(newLeft, transform);
        newRight = CGPointApplyAffineTransform(newRight, transform);
        newBottomRight = CGPointApplyAffineTransform(newBottomRight, transform);
        newBottomLeft = CGPointApplyAffineTransform(newBottomLeft, transform);
        NSLog(@"裁剪变换后的参数,topLeft.x=%f,topLeft.y=%f",newLeft.x,newLeft.y);

    }
    
    NSMutableDictionary *rectangleCoordinates = [[NSMutableDictionary alloc] init];
    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:newLeft];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:newRight];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:newBottomLeft];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:newBottomRight];
    
    ciImage = [ciImage imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgimage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *image = [UIImage imageWithCGImage:cgimage];

    NSData *imageToEncode = UIImageJPEGRepresentation(image, 1.0);
    CGImageRelease(cgimage);

    NSString *dir = NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory , NSUserDomainMask , YES ).firstObject;
    int time = (int)[NSDate date].timeIntervalSince1970;
    NSString *filePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"document0_%i.jpeg",time]];
    [imageToEncode writeToFile:filePath atomically:YES];
    NSString *uri = [NSString stringWithFormat:@"%@%@",@"file://",filePath];
    callback(@[@{@"image": uri}]);
}

- (CGPoint)cartesianForPoint:(CGPoint)point height:(float)height {
    return CGPointMake(point.x, height - point.y);
}

- (UIView*) view {
    _scannerView = [[DocumentScannerView alloc] init];
    return _scannerView;
}

@end
