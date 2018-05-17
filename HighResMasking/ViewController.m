//
//  ViewController.m
//  Full res masking
//
//  Created by Reza on 2/6/18.
//  Copyright © 2018 maName. All rights reserved.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()
@property  (nonatomic,assign) BOOL highresMode;
@property  (nonatomic,assign) BOOL firstPreview;
@property  (nonatomic) CGRect  targetBound;
@property  (nonatomic) CGRect  imageRect;
@property  (nonatomic) CGRect  bigTargetBound;
@property  (nonatomic) CGRect  bigImageRect;
@property  (nonatomic) CGFloat screenHeight;
@property  (nonatomic) CGFloat screenWidth;
@property  (nonatomic) CGFloat scale;
@property  (nonatomic,strong) UIBezierPath * examplePath;
@property  (nonatomic,strong) UIView * mainView;
@property  (nonatomic,strong) UIImage * bezierPreviewImage;
@property  (nonatomic,strong) UIImage * highResolutionImage;
@property  (nonatomic,strong) UIImage * maskImage;
@property  (nonatomic,strong) UIImage * finalRenderedMaskedImage;
@property  (nonatomic,strong) UIImageView * highResMaskedImageView;
@property  (nonatomic,strong) UIImageView * pathPreviewImageView;

@end
@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    _highresMode  =NO;
    _firstPreview =YES;
    _examplePath  = [self gimmeARandomPath];
    _highResolutionImage = [UIImage imageNamed:@"2"];
    _scale = [[UIScreen mainScreen] scale];
    _screenHeight = [UIScreen mainScreen].bounds.size.height;
    _screenWidth  = [UIScreen mainScreen].bounds.size.width;
    
    [self showStuffOnScreen];
    
}

-(void)showStuffOnScreen{
    
    if (!_firstPreview) {
        //        NSLog(@"not the First time to show images");
       
        [self.mainView removeFromSuperview];
        [self.mainView setFrame:_targetBound];
         self.mainView.backgroundColor = [UIColor blueColor];
        [self.view insertSubview:self.mainView belowSubview:_highResBtnOutlet];
        
         self.highResMaskedImageView.image=nil;
        [self.highResMaskedImageView removeFromSuperview];
         self.highResMaskedImageView = [[UIImageView alloc]initWithImage:self.finalRenderedMaskedImage];

        [self.mainView insertSubview:self.highResMaskedImageView belowSubview:self.highResBtnOutlet];
        [self.highResMaskedImageView  setFrame:AVMakeRectWithAspectRatioInsideRect(_finalRenderedMaskedImage.size,_targetBound)];
    }else{
        //        NSLog(@"First time to show images");
        
         self.mainView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, _screenWidth,_screenHeight)];
         self.mainView.backgroundColor = [UIColor blueColor];
        [self.view insertSubview:self.mainView belowSubview:_highResBtnOutlet];

        _targetBound = self.mainView.bounds;
        _imageRect=AVMakeRectWithAspectRatioInsideRect(_highResolutionImage.size,_targetBound);
        _bezierPreviewImage = [self previewOfThePathAsImage];
        
         self.highResMaskedImageView = [[UIImageView alloc]initWithImage:_highResolutionImage];
        [self.highResMaskedImageView setFrame:AVMakeRectWithAspectRatioInsideRect(self.highResolutionImage.size, _targetBound)];
        
         self.pathPreviewImageView   = [[UIImageView alloc]initWithImage:_bezierPreviewImage];
        [self.pathPreviewImageView
             setFrame:AVMakeRectWithAspectRatioInsideRect(_bezierPreviewImage.size, _targetBound)];

        [self.mainView insertSubview:self.highResMaskedImageView belowSubview:self.highResBtnOutlet];
        [self.mainView insertSubview:self.pathPreviewImageView   belowSubview:self.highResBtnOutlet];
    }
    _firstPreview=NO;
}

-(UIImage*)previewOfThePathAsImage{
//    NSLog(@"previewOfThePathAsImage");
    
    UIGraphicsBeginImageContextWithOptions(_targetBound.size,NO, 1.0);
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextAddPath (c, self.examplePath.CGPath);
    CGContextSetFillColorWithColor (c, [UIColor redColor].CGColor);
    CGContextSetStrokeColorWithColor (c, [UIColor redColor].CGColor);
    CGContextDrawPath (c, kCGPathFillStroke);
    UIImage* pathImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return pathImage;
    
}

-(UIImage*)normalResolutionMasking{
    
    NSLog(@"///Normal (screen resolution) masking///////////////////////////////////////////////////");
    //1.Rendering the path into an image with the size of _targetBound (which is the size of a device screen sized view in which the path is drawn.)
    UIGraphicsBeginImageContextWithOptions(_targetBound.size, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath (context, _examplePath.CGPath);
    CGContextSetFillColorWithColor (context, [UIColor redColor].CGColor);
    CGContextSetStrokeColorWithColor (context, [UIColor redColor].CGColor);
    CGContextDrawPath (context, kCGPathFillStroke);
    UIImage * pathImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //2. Cropping the rendered image to its visible pixels.
    _maskImage = [self cropThisImage:pathImage toRect:_imageRect];
    NSLog(@"Normal res _TargetBound: %@",NSStringFromCGRect(_targetBound));
    NSLog(@"Normal res _ImageRect: %@",NSStringFromCGRect(_imageRect));
    NSLog(@"Normal res pathImage.size: %@",NSStringFromCGSize(pathImage.size));
 
    //3. Masking the high resolution image with the rendered image from path.
    CGColorSpaceRef colorSpace= CGColorSpaceCreateDeviceRGB();
    CGContextRef mainViewContentContext = CGBitmapContextCreate (NULL, _imageRect.size.width, _imageRect.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    CGContextClipToMask(mainViewContentContext,
                        CGRectMake(0,
                                   0,
                                   _imageRect.size.width,
                                   _imageRect.size.height),
                                   _maskImage.CGImage);
    NSLog(@"Normal res CGContextClipToMask rect: %@",NSStringFromCGRect(
                        CGRectMake(0,
                                   0,
                                   _imageRect.size.width,
                                   _imageRect.size.height)));
    
    
    CGContextDrawImage(mainViewContentContext,
                       CGRectMake(0,
                                  0,
                                  _imageRect.size.width,
                                  _imageRect.size.height),
                                  _highResolutionImage.CGImage);
    NSLog(@"Normal res CGContextDrawImage rect: %@",NSStringFromCGRect(
                      CGRectMake(0,0,
                                 _imageRect.size.width,
                                 _imageRect.size.height)));
    
    CGImageRef mainViewContentBitmapContext = CGBitmapContextCreateImage(mainViewContentContext);
    CGContextRelease(mainViewContentContext);
    UIImage*image = [UIImage imageWithCGImage:mainViewContentBitmapContext];
    CGImageRelease(mainViewContentBitmapContext);
    NSLog(@"Normal res Final mask size: %@",NSStringFromCGSize(image.size));
    return image;
 }

-(UIImage*)highResolutionMasking{
    NSLog(@"///High quality (Image resolution) masking///////////////////////////////////////////////////");

    //1.Rendering the path into an image with the size of _targetBound (which is the size of a device screen sized view in which the path is drawn.)
    CGFloat aspectRatioOfImageBasedOnHeight = _highResolutionImage.size.height/ _highResolutionImage.size.width;
    CGFloat aspectRatioOfTargetBoundBasedOnHeight = _targetBound.size.height/ _targetBound.size.width;

    CGFloat pathScalingFactor = 0;
    if ((_highResolutionImage.size.height >= _targetBound.size.height)||
        (_highResolutionImage.size.width  >= _targetBound.size.width)) {
            //Then image is bigger than targetBound
        
            if ((_highResolutionImage.size.height<=_highResolutionImage.size.width)) {
            //The image is Horizontal

                CGFloat newWidthForTargetBound =_highResolutionImage.size.width;
                CGFloat ratioOfHighresImgWidthToTargetBoundWidth = (_highResolutionImage.size.width/_targetBound.size.width);
                CGFloat newHeightForTargetBound = _targetBound.size.height* ratioOfHighresImgWidthToTargetBoundWidth;

                _bigTargetBound = CGRectMake(0, 0, newWidthForTargetBound, newHeightForTargetBound);
                pathScalingFactor = _highResolutionImage.size.width/_targetBound.size.width;
                
            }else if((_highResolutionImage.size.height > _highResolutionImage.size.width)&&
                     (aspectRatioOfImageBasedOnHeight  <= aspectRatioOfTargetBoundBasedOnHeight)){
                //The image is Vertical but has smaller aspect ratio (based on height) than targetBound

                CGFloat newWidthForTargetBound =_highResolutionImage.size.width;
                CGFloat ratioOfHighresImgWidthToTargetBoundWidth = (_highResolutionImage.size.width/_targetBound.size.width);
                CGFloat newHeightForTargetBound = _targetBound.size.height* ratioOfHighresImgWidthToTargetBoundWidth;
                
                _bigTargetBound = CGRectMake(0, 0, newWidthForTargetBound, newHeightForTargetBound);
                pathScalingFactor = _highResolutionImage.size.width/_targetBound.size.width;
                
            }else if((_highResolutionImage.size.height > _highResolutionImage.size.width)&&
                     (aspectRatioOfImageBasedOnHeight  > aspectRatioOfTargetBoundBasedOnHeight)){

                CGFloat newHeightForTargetBound =_highResolutionImage.size.height;
                CGFloat ratioOfHighresImgHeightToTargetBoundHeight = (_highResolutionImage.size.height/_targetBound.size.height);
                CGFloat newWidthForTargetBound = _targetBound.size.width* ratioOfHighresImgHeightToTargetBoundHeight;
                
                _bigTargetBound = CGRectMake(0, 0, newWidthForTargetBound, newHeightForTargetBound);
                pathScalingFactor = _highResolutionImage.size.height/_targetBound.size.height;
            }else{
                //Do nothing
            }
    }else{
            //Then image is smaller than targetBound
            _bigTargetBound = _imageRect;
            pathScalingFactor =1;
    }
    
    CGSize correctedSize = CGSizeMake(_highResolutionImage.size.width  *_scale,
                                      _highResolutionImage.size.height *_scale);
    
    _bigImageRect= AVMakeRectWithAspectRatioInsideRect(correctedSize,_bigTargetBound);
    
    //Scaling path
    CGAffineTransform scaleTransform = CGAffineTransformIdentity;
    scaleTransform = CGAffineTransformScale(scaleTransform, pathScalingFactor, pathScalingFactor);
    
    CGPathRef scaledCGPath = CGPathCreateCopyByTransformingPath(_examplePath.CGPath,&scaleTransform);
    
    //Render scaled path into image
    UIGraphicsBeginImageContextWithOptions(_bigTargetBound.size, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath (context, scaledCGPath);
    CGContextSetFillColorWithColor (context, [UIColor redColor].CGColor);
    CGContextSetStrokeColorWithColor (context, [UIColor redColor].CGColor);
    CGContextDrawPath (context, kCGPathFillStroke);
    UIImage * pathImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSLog(@"High res pathImage.size: %@",NSStringFromCGSize(pathImage.size));
    
    //Cropping it from targetBound into imageRect
    _maskImage = [self cropThisImage:pathImage toRect:_bigImageRect];
    NSLog(@"High res _croppedRenderedPathImage.size: %@",NSStringFromCGSize(_maskImage.size));
  
    //Masking the high res image with my mask image which both have the same size.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef maskImageRef = [_maskImage CGImage];
    CGContextRef myContext = CGBitmapContextCreate (NULL, _highResolutionImage.size.width, _highResolutionImage.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    if (myContext==NULL)
        return NULL;
    
    CGFloat ratio = 0;
    ratio = _maskImage.size.width/ _highResolutionImage.size.width;
    if(ratio * _highResolutionImage.size.height < _maskImage.size.height) {
        ratio = _maskImage.size.height/ _highResolutionImage.size.height;
    }
    
    CGRect rectForMask  = {{0, 0}, {_maskImage.size.width, _maskImage.size.height}};
    CGRect rectForImageDrawing  = {{-((_highResolutionImage.size.width*ratio)-_maskImage.size.width)/2 , -((_highResolutionImage.size.height*ratio)-_maskImage.size.height)/2},
        {_highResolutionImage.size.width*ratio, _highResolutionImage.size.height*ratio}};
    
    CGContextClipToMask(myContext, rectForMask, maskImageRef);
    CGContextDrawImage(myContext, rectForImageDrawing, _highResolutionImage.CGImage);
    CGImageRef newImage = CGBitmapContextCreateImage(myContext);
    CGContextRelease(myContext);
    UIImage *theImage = [UIImage imageWithCGImage:newImage];
    CGImageRelease(newImage);
    return theImage;
}

-(UIImage *)cropThisImage:(UIImage*)image toRect:(CGRect)rect{
    CGImageRef subImage = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *croppedImage = [UIImage imageWithCGImage:subImage];
    CGImageRelease(subImage);
    return croppedImage;
}

-(void)saveToGallery{
    CGRect rect= CGRectZero;
    if(_highresMode)
        rect = CGRectMake(0, 0, _bigImageRect.size.width,  _bigImageRect.size.height);
    else
        rect = CGRectMake(0, 0, _imageRect.size.width,  _imageRect.size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0);
    [_finalRenderedMaskedImage drawInRect:rect];
    UIImage* imageToBeSaved =   UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    NSData* imgdata =  UIImagePNGRepresentation (imageToBeSaved);
    UIImage* img = [UIImage imageWithData:imgdata];
    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
}

-(UIBezierPath*)gimmeARandomPath{
    //Creating a random path
    UIBezierPath* starPath = [UIBezierPath bezierPath];
    [starPath moveToPoint:    CGPointMake(45.25*1.4+230, 0+230)];
    [starPath addLineToPoint: CGPointMake(61.13*1.4+230, 23*1.4+230)];
    [starPath addLineToPoint: CGPointMake(88.29*1.4+230, 30.75*1.4+230)];
    [starPath addLineToPoint: CGPointMake(70.95*1.4+230, 52.71*1.4+230)];
    [starPath addLineToPoint: CGPointMake(71.85*1.4+230, 80.5*1.4+230)];
    [starPath addLineToPoint: CGPointMake(45.25*1.4+230, 71.07*1.4+230)];
    [starPath addLineToPoint: CGPointMake(18.65*1.4+230, 80.5*1.4+230)];
    [starPath addLineToPoint: CGPointMake(19.55*1.4+230, 52.71*1.4+230)];
    [starPath addLineToPoint: CGPointMake(2.21*1.4+230, 30.75*1.4+230)];
    [starPath addLineToPoint: CGPointMake(29.37*1.4+230, 23*1.4+230)];
    [starPath closePath];
    [UIColor.redColor setStroke];
    [UIColor.redColor setFill];
    starPath.lineWidth = 5;
    [starPath stroke];
    [starPath fill];
    return starPath;
}

- (IBAction)highResButtonAction:(id)sender {
    _highresMode=YES;
    self.finalRenderedMaskedImage= [self highResolutionMasking];
    [self showStuffOnScreen];
}
- (IBAction)normalResButtonAction:(id)sender {
    _highresMode=NO;
    self.finalRenderedMaskedImage=[self normalResolutionMasking];
    [self showStuffOnScreen];
}
- (IBAction)resetButtonAction:(id)sender {
    _firstPreview=YES;
    
    self.finalRenderedMaskedImage= nil;
    self.highResMaskedImageView.image= nil;
    
    [self.highResMaskedImageView removeFromSuperview];
    [self.mainView removeFromSuperview];
    
    [self showStuffOnScreen];
}
- (IBAction)anotherVerticalImage:(id)sender {
    _highResolutionImage = [UIImage imageNamed:@"3"];
    _firstPreview=YES;
    
    self.finalRenderedMaskedImage= nil;
    self.highResMaskedImageView.image= nil;
    
    [self.highResMaskedImageView removeFromSuperview];
    [self.mainView removeFromSuperview];
    
    [self showStuffOnScreen];
}
- (IBAction)horizontalImgBtn:(id)sender {
    _highResolutionImage = [UIImage imageNamed:@"1"];
    _firstPreview=YES;
    
    self.finalRenderedMaskedImage= nil;
    self.highResMaskedImageView.image= nil;
    
    [self.highResMaskedImageView removeFromSuperview];
    [self.mainView removeFromSuperview];
    
    [self showStuffOnScreen];
}
- (IBAction)verticalImgAction:(id)sender {
    _highResolutionImage = [UIImage imageNamed:@"2"];
    _firstPreview=YES;
    self.finalRenderedMaskedImage= nil;
    self.highResMaskedImageView.image= nil;
    [self.highResMaskedImageView removeFromSuperview];
    [self.mainView removeFromSuperview];
    
    [self showStuffOnScreen];
}
- (IBAction)saveBtnAction:(id)sender {
    [self saveToGallery];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
