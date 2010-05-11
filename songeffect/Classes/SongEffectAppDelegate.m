//
//  SongEffectAppDelegate.m
//  SongEffect
//
//  Created by liujuncong@gmail.com on 17/04/2010.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "SongEffectAppDelegate.h"
#import "SongEffectViewController.h"
#import "EAGLView.h"

@implementation SongEffectAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize glView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
// Override point for customization after app launch    
   [window addSubview:viewController.view];
   [window makeKeyAndVisible];
 

}

- (void)applicationWillResignActive:(UIApplication *)application {
 
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
 
}


- (void)dealloc {
    [viewController release];
 
    [window release];
    [super dealloc];
}

-(IBAction) changeSongSize {
 
}

@end
