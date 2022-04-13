#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,IPDFCameraViewType)
{
    IPDFCameraViewTypeBlackAndWhite,
    IPDFCameraViewTypeNormal
};

typedef NS_ENUM(NSInteger, IPDFRectangeType)
{
    IPDFRectangeTypeGood,
    IPDFRectangeTypeBadAngle,
    IPDFRectangeTypeTooFar
};

@protocol IPDFCameraViewControllerDelegate <NSObject>

- (void) didDetectRectangle: (CIRectangleFeature*) rectangle withType: (IPDFRectangeType) type;

@end

@interface IPDFCameraViewController : UIView

- (void)setupCameraView;

- (void)start;
- (void)stop;

@property (nonatomic,assign,getter=isBorderDetectionEnabled) BOOL enableBorderDetection;
@property (nonatomic,assign,getter=isTorchEnabled) BOOL enableTorch;
@property (nonatomic,assign,getter=isFrontCam) BOOL useFrontCam;

@property (weak, nonatomic) id<IPDFCameraViewControllerDelegate> delegate;

@property (nonatomic,assign) IPDFCameraViewType cameraViewType;

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)())completionHandler;

- (void)captureImageWithCompletionHander:(void(^)(UIImage *data, UIImage *initialData, CIRectangleFeature *rectangleFeature))completionHandler;

@property (nonatomic, strong) UIColor* overlayColor;
@property (nonatomic, assign) float saturation;// 饱和度
@property (nonatomic, assign) float contrast;// 对比度
@property (nonatomic, assign) float brightness;// 亮度
@property (nonatomic, assign) NSInteger detectionRefreshRateInMS;


@end
