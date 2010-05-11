

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
 

/*
This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
The view content is basically an EAGL surface you render your OpenGL scene into.
Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/

@interface UIColor(Random)
+(UIColor *)randomColor;
@end

@class SongEffectViewController;

@interface EAGLView : UIView {
    SongEffectViewController *songController;
	
@private
    /* The pixel dimensions of the backbuffer */
    GLint backingWidth;
    GLint backingHeight;
    
	// an array of 1 GLuint
	GLuint textures[10];
	
    EAGLContext *context;
    
	GLfloat rota;
	
    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint viewRenderbuffer, viewFramebuffer;
    
    /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
    GLuint depthRenderbuffer;
    
    NSTimer *animationTimer;
    NSTimeInterval animationInterval;
	
	BOOL isLargeView; // 判断动画是否在大的模式
	
	int drawtype; // 描绘类型，0-最小；1－portrait; 2-landsccpe
	
	BOOL isStop; // 是否停止播放
	
	UIImageView *reflectionView;
}

@property (nonatomic,retain) UIImageView *reflectionView;

@property NSTimeInterval animationInterval;
@property BOOL isLargeView;
@property int drawtype;
@property BOOL isStop;
@property (nonatomic,retain) SongEffectViewController *songController;
- (void)setupView;
- (void)startAnimation;
- (void)stopAnimation;
- (void)drawViewSmall;
- (void)drawLargeView_1;
- (void)drawLargeView_2_p;
- (void)drawLargeView_2_l;
- (void)checkGLError:(BOOL)visibleCheck;
// put the code to actually load the texture
- (void)loadTexture;
- (BOOL)initContext;
 
@end
