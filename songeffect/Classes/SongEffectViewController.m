//
//  SongEffectViewController.m
//  SongEffect
//
//  Created by liujuncong@gmail.com on 17/04/2010.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "SongEffectViewController.h"
#import "EAGLView.h"
#import "EAGLReflectView.h"
#import "QuartzCore/QuartzCore.h" // for CALayer
 
@implementation SongEffectViewController
@synthesize glView;
@synthesize glReflectView;
@synthesize reflectionView;
 

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


 
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	glView.songController = self;
	glView.isLargeView = NO;
	glView.animationInterval = 0.1;
	
	glReflectView.songController = self;
	glReflectView.isLargeView = NO;
	glReflectView.animationInterval = 0.1;
 	
	
  	//[glView startAnimation];	
	
//	[self addreflecteffect:glView];
}
 


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[glView release];
	[glReflectView release];
    [super dealloc];
}



-(IBAction) changeSongSize {
	glView.isLargeView = !glView.isLargeView;
	if (glView.drawtype == 0) {
		glView.drawtype = 1;
	}
	else if (glView.drawtype == 1){
		glView.drawtype = 0; 
	}

	glView.animationInterval = 0.1;	
}

-(IBAction) stopSong {
	glView.isStop = !glView.isStop;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft
		|| toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) // 底座向左边
	{
		glView.frame = CGRectMake(20, 15, 440, 240);
		
		glView.drawtype = 2;
		
  	}
 	else if(toInterfaceOrientation == UIInterfaceOrientationPortrait
			|| toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
	{
		glView.frame = CGRectMake(10, 0, 298, 308);
 		glView.drawtype = 1;
 
	}	
	
	[glView setupView];
	glView.animationInterval = 0.1;	
	
}



#pragma mark -
#pragma mark reflect effect



static const CGFloat kDefaultReflectionFraction = 0.15;
static const CGFloat kDefaultReflectionOpacity = 0.40;
static const NSInteger kSliderTag = 1337;

-(void)addreflecteffect:(UIView *)view1{
	CGRect reflectionRect = view1.frame;
	
	// the reflection is a fraction of the size of the view being reflected
	reflectionRect.size.height = reflectionRect.size.height * kDefaultReflectionFraction;
	
	// and is offset to be at the bottom of the view being reflected
	reflectionRect = CGRectOffset(reflectionRect, 0, view1.frame.size.height);
	
	reflectionView = [[UIImageView alloc] initWithFrame:reflectionRect];
	
	// determine the size of the reflection to create
	NSUInteger reflectionHeight = view1.bounds.size.height * kDefaultReflectionFraction;
	
	// create the reflection image, assign it to the UIImageView and add the image view to the containerView
	reflectionView.image = [self reflectedImage:view1 withHeight:reflectionHeight];
	reflectionView.alpha = kDefaultReflectionOpacity;
	[self.view addSubview:reflectionView];
	
}


CGImageRef CreateGradientImage(int pixelsWide, int pixelsHigh)
{
	CGImageRef theCGImage = NULL;
	
	// gradient is always black-white and the mask must be in the gray colorspace
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	// create the bitmap context
	CGContextRef gradientBitmapContext = CGBitmapContextCreate(nil, pixelsWide, pixelsHigh,
															   8, 0, colorSpace, kCGImageAlphaNone);
	
	// define the start and end grayscale values (with the alpha, even though
	// our bitmap context doesn't support alpha the gradient requires it)
	CGFloat colors[] = {0.0, 1.0, 1.0, 1.0};
	
	// create the CGGradient and then release the gray color space
	CGGradientRef grayScaleGradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
	CGColorSpaceRelease(colorSpace);
	
	// create the start and end points for the gradient vector (straight down)
	CGPoint gradientStartPoint = CGPointZero;
	CGPoint gradientEndPoint = CGPointMake(0, pixelsHigh);
	
	// draw the gradient into the gray bitmap context
	CGContextDrawLinearGradient(gradientBitmapContext, grayScaleGradient, gradientStartPoint,
								gradientEndPoint, kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(grayScaleGradient);
	
	// convert the context into a CGImageRef and release the context
	theCGImage = CGBitmapContextCreateImage(gradientBitmapContext);
	CGContextRelease(gradientBitmapContext);
	
	// return the imageref containing the gradient
    return theCGImage;
}

CGContextRef MyCreateBitmapContext(int pixelsWide, int pixelsHigh)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	// create the bitmap context
	CGContextRef bitmapContext = CGBitmapContextCreate (nil, pixelsWide, pixelsHigh, 8,
														0, colorSpace,
														// this will give us an optimal BGRA format for the device:
														(kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
	CGColorSpaceRelease(colorSpace);
	
    return bitmapContext;
}

- (UIImage *)reflectedImage:(UIView *)fromImage withHeight:(NSUInteger)height
{
    if (!height) return nil;
    
	// create a bitmap graphics context the size of the image
	CGContextRef mainViewContentContext = MyCreateBitmapContext(fromImage.bounds.size.width, height);
	
	// offset the context -
	// This is necessary because, by default, the layer created by a view for caching its content is flipped.
	// But when you actually access the layer content and have it rendered it is inverted.  Since we're only creating
	// a context the size of our reflection view (a fraction of the size of the main view) we have to translate the
	// context the delta in size, and render it.
	//
	CGFloat translateVertical = fromImage.bounds.size.height - height;
	CGContextTranslateCTM(mainViewContentContext, 0, -translateVertical);

	// render the layer into the bitmap context
	CALayer *layer = fromImage.layer;               //------
	[layer renderInContext:mainViewContentContext]; //------
	
	// create CGImageRef of the main view bitmap content, and then release that bitmap context
	CGImageRef mainViewContentBitmapContext = CGBitmapContextCreateImage(mainViewContentContext);
	CGContextRelease(mainViewContentContext);
	
	// create a 2 bit CGImage containing a gradient that will be used for masking the 
	// main view content to create the 'fade' of the reflection.  The CGImageCreateWithMask
	// function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
	CGImageRef gradientMaskImage = CreateGradientImage(1, height);
	
	// create an image by masking the bitmap of the mainView content with the gradient view
	// then release the  pre-masked content bitmap and the gradient bitmap
	CGImageRef reflectionImage = CGImageCreateWithMask(mainViewContentBitmapContext, gradientMaskImage);
	
 
	CGImageRelease(mainViewContentBitmapContext);
	CGImageRelease(gradientMaskImage);
	
	// convert the finished reflection image to a UIImage 
	UIImage *theImage = [UIImage imageWithCGImage:reflectionImage];
	
	// image is retained by the property setting above, so we can release the original
	CGImageRelease(reflectionImage);
	
	return theImage;
}

-(IBAction)BeginReflect {
	//[self addreflecteffect:glView];
	glView.alpha = 0.3;
	
	//CGAffineTransform landscapeTransform = CGAffineTransformMakeRotation(M_PI);
	//[glView setTransform:landscapeTransform];	
}
@end
