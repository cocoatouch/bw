//
//  SongEffectViewController.h
//  SongEffect
//
//  Created by liujuncong@gmail.com on 17/04/2010.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;
@class EAGLReflectView;
@interface SongEffectViewController : UIViewController {
	EAGLView *glView;
	EAGLReflectView *glReflectView;
	
	UIImageView *reflectionView;	
}
@property (nonatomic, retain) IBOutlet EAGLView *glView;
@property (nonatomic, retain) IBOutlet EAGLReflectView *glReflectView;

-(IBAction) changeSongSize;
-(IBAction) stopSong;

@property (nonatomic,retain) UIImageView *reflectionView;

- (UIImage *)reflectedImage:(UIView *)fromImage withHeight:(NSUInteger)height;
-(void)addreflecteffect:(UIView *)view1;
-(IBAction)BeginReflect;
@end

