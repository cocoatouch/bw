//
//  SongEffectAppDelegate.h
//  SongEffect
//
//  Created by liujuncong@gmail.com on 17/04/2010.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SongEffectViewController;
@class EAGLView;

@interface SongEffectAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SongEffectViewController *viewController;
	EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SongEffectViewController *viewController;
@property (nonatomic, retain) IBOutlet EAGLView *glView;
-(IBAction) changeSongSize;
@end

