
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"
#import "EAGLReflectView.h"
#import "SongEffectViewController.h"

#define USE_DEPTH_BUFFER 1
#define DEGREES_TO_RADIANS(__ANGLE) ((__ANGLE) / 180.0 * M_PI)

 

@implementation UIColor(Random)
+(UIColor *)randomColor
{
    static BOOL seeded = NO;
    if (!seeded) {
        seeded = YES;
        srandom(time(NULL));
    }
    CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}
@end

// A class extension to declare private methods
@interface EAGLView ()

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) NSTimer *animationTimer;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation EAGLView

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;
@synthesize isLargeView;
@synthesize drawtype;
@synthesize isStop;
@synthesize reflectionView;
@synthesize songController;

- (void)setupView
{ 
	glEnable(GL_DEPTH_TEST);
	CGRect rect = self.bounds;
	glViewport(0, 0, rect.size.width, rect.size.height);
	//glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, self.frame.size.width, 0, self.frame.size.height, -100, 100);
	//glOrthof(0, self.frame.size.width, self.frame.size.height, 0, -100, 100);
	
	//glMatrixMode(GL_MODELVIEW);
}

// You must implement this method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}


- (BOOL)initContext {
	// Get the layer
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];  
	/*
	CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
	
	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
	*/
	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	
	if (!context || ![EAGLContext setCurrentContext:context]) {
		[self release];
		return NO;
	}
	
	rota = 0.0;
	
	[self setupView];
	//[self loadTexture];
	
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];	
	
	return YES;
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
	
	drawtype = 0;
	isStop = NO;
    
    if ((self = [super initWithCoder:coder])) {
 
		if (![self initContext]) {
			return nil;
		}
    }
	
	[self setBackgroundColor:[UIColor clearColor]];
	
    return self;
}
 




- (void)layoutSubviews {
 //	[self setBackgroundColor:[UIColor clearColor]];	
    [EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
 	[self createFramebuffer];
 	
/*
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    if (USE_DEPTH_BUFFER) {
        glGenRenderbuffersOES(1, &depthRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    }
 */
}


- (BOOL)createFramebuffer {
    
    glGenFramebuffersOES(1, &viewFramebuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
   
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
	
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    if (USE_DEPTH_BUFFER) {
        glGenRenderbuffersOES(1, &depthRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    }
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}
 



- (void)destroyFramebuffer {
    
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


// 第一种风格的，每个格子偏向于矩形
- (void)drawLargeView_1 {
	if (isStop) {
		return;
	}
	
	GLfloat lines[140];
	int j = 0;
	for (int i=0; i<140; i+=14) {
		UIColor *color1 = [UIColor randomColor];
		
		lines[i] = 12.0+32*j;lines[i+1]=2.0;lines[i+2]=-6.0;
		lines[i+3]=1.0;//(CGFloat)random()/(CGFloat)RAND_MAX;
		lines[i+4]=1.0;//(CGFloat)random()/(CGFloat)RAND_MAX;
		lines[i+5]=1.0;//(CGFloat)random()/(CGFloat)RAND_MAX;
		lines[i+6]=1.0;
		
		color1 = [UIColor randomColor];
		
		lines[i+7] = 12.0+32*j;lines[i+8]=(CGFloat)random()/(CGFloat)RAND_MAX*300;lines[i+9]=-6.0;
		
		lines[i+10]= 0.8;
		lines[i+11]= 0.1;
		lines[i+12]= 0.0;
		lines[i+13]=1.0;		
		
		j++;
	}
	
	
	
	GLfloat horizontalLines[560];
	
	j = 0;
	for (int i=0; i<560; i+=14) {
 		horizontalLines[i] = 0;horizontalLines[i+1]=10+j*10;horizontalLines[i+2]=-6.0;
		horizontalLines[i+3]=0;
		horizontalLines[i+4]=0;
		horizontalLines[i+5]=0;
		horizontalLines[i+6]=1.0;
		
 		horizontalLines[i+7] = 320;horizontalLines[i+8]=10+j*10;horizontalLines[i+9]=-6.0;
		horizontalLines[i+10]=0;
		horizontalLines[i+11]=0;
		horizontalLines[i+12]=0;
		horizontalLines[i+13]=1.0;	
		
		j++;
	}
	
	
	const GLfloat squareVertices[] = {
		0, 100.0, -6.0,            // Top left
        0.0, 0.0, -6.0,           // Bottom left
        100.0, 0.0, -6.0,            // Bottom right
        100.0, 100.0, -6.0              // Top right
	};
	
	
    [EAGLContext setCurrentContext:context];   
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glMatrixMode(GL_MODELVIEW);
	
	
	// Setup and render the lines
	
	
	glEnable(GL_BLEND);
    glBlendFunc(GL_ZERO, GL_ZERO);
	glLineWidth(3.0);
	glVertexPointer(3, GL_FLOAT, 28, horizontalLines);
	glColorPointer(4, GL_FLOAT, 28, &horizontalLines[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 80);	
	glDisable(GL_BLEND);    
	
	
	glLineWidth(25.0);
	glEnableClientState(GL_COLOR_ARRAY);
	glVertexPointer(3, GL_FLOAT, 28, lines);
	glColorPointer(4, GL_FLOAT, 28, &lines[3]);
	glDrawArrays(GL_LINES, 0, 20);
	
	
	
	glColor4f(0.0, 1.0, 0.0, 1.0);
	glVertexPointer(3, GL_FLOAT, 0, squareVertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0 , 4);
	
	
	
	
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
}

// 每个格子是正方形，portrait
- (void)drawLargeView_2_p{
	 
	if (isStop) {
		return;
	}
	
	const GLfloat squareVertices1[] = {
		0, 300.0, -6.0, 1.0,1.0,0.0,1.0,            
        0.0, 0.0, -6.0, 1.0,1.0,0.0,1.0,           
        75.0, 0.0, -6.0, 0.0,1.0,0.0,1.0,             
        75.0, 300.0, -6.0, 0.0,1.0,0.0,1.0              
	};
	const GLfloat squareVertices2[] = {
		75, 300.0, -6.0, 0.0,1.0,0.0,1.0,             
        75.0, 0.0, -6.0, 0.0,1.0,0.0,1.0,           
        150.0, 0.0, -6.0, 0.0,0.0,1.0,1.0,            
        150.0, 300.0, -6.0, 0.0,0.0,1.0,1.0              
	};	
	const GLfloat squareVertices3[] = {
		150, 300.0, -6.0, 0.0,0.0,1.0,1.0,            
        150.0, 0.0, -6.0, 0.0,0.0,1.0,1.0,          
        225.0, 0.0, -6.0, 0.0,1.0,1.0,1.0,           
        225.0, 300.0, -6.0, 0.0,1.0,1.0,1.0              
	};	
	const GLfloat squareVertices4[] = {
		225.0, 300.0, -6.0, 0.0,1.0,1.0,1.0,            
        225.0, 0.0, -6.0, 0.0,1.0,1.0,1.0,           
        296.0, 0.0, -6.0, 1.0,0.0,0.0,1.0,            
        296.0, 300.0, -6.0, 1.0,0.0,0.0,1.0              
	};	
	
 	
	GLfloat horizontalLines[560];
	
	int j = 0;
	for (int i=0; i<560; i+=14) {
 		horizontalLines[i] = 0;horizontalLines[i+1]=9+j*9;horizontalLines[i+2]=-6.0;
		horizontalLines[i+3]=0;
		horizontalLines[i+4]=0;
		horizontalLines[i+5]=0;
		horizontalLines[i+6]=1.0;
		
 		horizontalLines[i+7] = 320;horizontalLines[i+8]=9+j*9;horizontalLines[i+9]=-6.0;
		horizontalLines[i+10]=0;
		horizontalLines[i+11]=0;
		horizontalLines[i+12]=0;
		horizontalLines[i+13]=1.0;	
		
		j++;
	}
	
	GLfloat portraitLines[560];
	
	j = 1;
	for (int i=0; i<560; i+=14) {
 		portraitLines[i]=j*9;portraitLines[i+1] = 0;portraitLines[i+2]=-6.0;
		portraitLines[i+3]=0;
		portraitLines[i+4]=0;
		portraitLines[i+5]=0;
		portraitLines[i+6]=1.0;
		
 		portraitLines[i+7]=j*9;portraitLines[i+8] = 320;portraitLines[i+9]=-6.0;
		portraitLines[i+10]=0;
		portraitLines[i+11]=0;
		portraitLines[i+12]=0;
		portraitLines[i+13]=1.0;	
		
		j++;
	}	
	
	GLfloat blackLines[560];
	
	GLfloat randomBlackLine;
	
	j = 0;
	for (int i=0; i<560; i+=14) {
 		blackLines[i]=4.3+j*9;blackLines[i+1]=480;blackLines[i+2]=-6.0;
		blackLines[i+3]=0;
		blackLines[i+4]=0;
		blackLines[i+5]=0;
		blackLines[i+6]=1.0;
		
		randomBlackLine = (CGFloat)random()/(CGFloat)RAND_MAX*300;
		
 		blackLines[i+7]=4.3+j*9;blackLines[i+8] = randomBlackLine;blackLines[i+9]=-6.0;
		blackLines[i+10]=0;
		blackLines[i+11]=0;
		blackLines[i+12]=0;
		blackLines[i+13]=1.0;	
		
		j++;
	}		
	
	
    [EAGLContext setCurrentContext:context];   
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glMatrixMode(GL_MODELVIEW);
	
 
	
	/*
 	glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
	glDisableClientState(GL_COLOR_ARRAY);
	glColor4f(1.0, 0, 0, 0.50);
	glLineWidth(9.0);
	glVertexPointer(3, GL_FLOAT, 0, lineVertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 4);	
	glDisable(GL_BLEND);  	
	*/
	
 	glEnable(GL_BLEND);
    glBlendFunc(GL_ZERO, GL_ZERO);
	glLineWidth(9.0);
	glVertexPointer(3, GL_FLOAT, 28, blackLines);
	glColorPointer(4, GL_FLOAT, 28, &blackLines[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 80);	
	glDisable(GL_BLEND);  
	
	
 	glEnable(GL_BLEND);
    glBlendFunc(GL_ZERO, GL_ZERO);
	glLineWidth(1.0);
	glVertexPointer(3, GL_FLOAT, 28, horizontalLines);
	glColorPointer(4, GL_FLOAT, 28, &horizontalLines[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 80);	
	glDisable(GL_BLEND);   
	
 	glEnable(GL_BLEND);
    glBlendFunc(GL_ZERO, GL_ZERO);
	glLineWidth(1.0);
	glVertexPointer(3, GL_FLOAT, 28, portraitLines);
	glColorPointer(4, GL_FLOAT, 28, &portraitLines[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 80);	
	glDisable(GL_BLEND);  	
	
	////////////// draw rect>>>>
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
 	glVertexPointer(3, GL_FLOAT, 28, squareVertices1);
	glColorPointer(4, GL_FLOAT, 28, &squareVertices1[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0 , 4);
	glDisable(GL_BLEND);
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
 	glVertexPointer(3, GL_FLOAT, 28, squareVertices2);
	glColorPointer(4, GL_FLOAT, 28, &squareVertices2[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0 , 4);
	glDisable(GL_BLEND);	
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
 	glVertexPointer(3, GL_FLOAT, 28, squareVertices3);
	glColorPointer(4, GL_FLOAT, 28, &squareVertices3[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0 , 4);
	glDisable(GL_BLEND);	
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
 	glVertexPointer(3, GL_FLOAT, 28, squareVertices4);
	glColorPointer(4, GL_FLOAT, 28, &squareVertices4[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0 , 4);
	glDisable(GL_BLEND);
	/////// <<<<<< draw rect
	
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	[songController.glReflectView drawLargeView_2_p:blackLines];
	
}


// 每个格子是正方形，portrait
- (void)drawLargeView_2_l{
	if (isStop) {
		return;
	}
#define LARGE_VIEW_LANDSCAPE_H 220
	const GLfloat squareVertices1[] = {
		0, LARGE_VIEW_LANDSCAPE_H, -6.0, 1.0,1.0,0.0,1.0,            
        0.0, 0.0, -6.0, 1.0,1.0,0.0,1.0,           
        110.0, 0.0, -6.0, 0.0,1.0,0.0,1.0,             
        110.0, LARGE_VIEW_LANDSCAPE_H, -6.0, 0.0,1.0,0.0,1.0              
	};
	const GLfloat squareVertices2[] = {
		110, LARGE_VIEW_LANDSCAPE_H, -6.0, 0.0,1.0,0.0,1.0,             
        110.0, 0.0, -6.0, 0.0,1.0,0.0,1.0,           
        220.0, 0.0, -6.0, 0.0,0.0,1.0,1.0,            
        220.0, LARGE_VIEW_LANDSCAPE_H, -6.0, 0.0,0.0,1.0,1.0              
	};	
	const GLfloat squareVertices3[] = {
		220, LARGE_VIEW_LANDSCAPE_H, -6.0, 0.0,0.0,1.0,1.0,            
        220.0, 0.0, -6.0, 0.0,0.0,1.0,1.0,          
        330.0, 0.0, -6.0, 0.0,1.0,1.0,1.0,           
        330.0, LARGE_VIEW_LANDSCAPE_H, -6.0, 0.0,1.0,1.0,1.0              
	};	
	const GLfloat squareVertices4[] = {
		330.0, LARGE_VIEW_LANDSCAPE_H, -6.0, 0.0,1.0,1.0,1.0,            
        330.0, 0.0, -6.0, 0.0,1.0,1.0,1.0,           
        440.0, 0.0, -6.0, 1.0,0.0,0.0,1.0,            
        440.0, LARGE_VIEW_LANDSCAPE_H, -6.0, 1.0,0.0,0.0,1.0              
	};	
	
 	// 一条线占用14个元素，350 ／ 14 ＝ 25条线
	GLfloat horizontalLines[350]; 
	
	int j = 0;
	for (int i=0; i<350; i+=14) {
 		horizontalLines[i] = 0;horizontalLines[i+1]=9+j*9;horizontalLines[i+2]=-6.0;
		horizontalLines[i+3]=0;
		horizontalLines[i+4]=0;
		horizontalLines[i+5]=0;
		horizontalLines[i+6]=1.0;
		
 		horizontalLines[i+7] = 480;horizontalLines[i+8]=9+j*9;horizontalLines[i+9]=-6.0;
		horizontalLines[i+10]=0;
		horizontalLines[i+11]=0;
		horizontalLines[i+12]=0;
		horizontalLines[i+13]=1.0;	
		
		j++;
	}
	
	GLfloat portraitLines[700]; // 每条线间隔9
	
	j = 1;
	for (int i=0; i<700; i+=14) {
 		portraitLines[i]=j*9;portraitLines[i+1] = 0;portraitLines[i+2]=-6.0;
		portraitLines[i+3]=0;
		portraitLines[i+4]=0;
		portraitLines[i+5]=0;
		portraitLines[i+6]=1.0;
		
 		portraitLines[i+7]=j*9;portraitLines[i+8] = 320;portraitLines[i+9]=-6.0;
		portraitLines[i+10]=0;
		portraitLines[i+11]=0;
		portraitLines[i+12]=0;
		portraitLines[i+13]=1.0;	
		
		j++;
	}	
	
	GLfloat blackLines[700];
	
	j = 0;
	for (int i=0; i<700; i+=14) {
 		blackLines[i]=4.3+j*9;blackLines[i+1]=480;blackLines[i+2]=-6.0;
		blackLines[i+3]=0;
		blackLines[i+4]=0;
		blackLines[i+5]=0;
		blackLines[i+6]=1.0;
		
 		blackLines[i+7]=4.3+j*9;blackLines[i+8] = (CGFloat)random()/(CGFloat)RAND_MAX*300;;blackLines[i+9]=-6.0;
		blackLines[i+10]=0;
		blackLines[i+11]=0;
		blackLines[i+12]=0;
		blackLines[i+13]=1.0;	
		
		j++;
	}		
	
	
    [EAGLContext setCurrentContext:context];   
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glMatrixMode(GL_MODELVIEW);
	 
	 
 	glEnable(GL_BLEND);
    glBlendFunc(GL_ZERO, GL_ZERO);
	glLineWidth(9.0);
	glVertexPointer(3, GL_FLOAT, 28, blackLines);
	glColorPointer(4, GL_FLOAT, 28, &blackLines[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 100);	
	glDisable(GL_BLEND);  
  
	// 水平分割线
 	glEnable(GL_BLEND);
    glBlendFunc(GL_ZERO, GL_ZERO);
	glLineWidth(1.0);
	glVertexPointer(3, GL_FLOAT, 28, horizontalLines);
	glColorPointer(4, GL_FLOAT, 28, &horizontalLines[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 50);	
	glDisable(GL_BLEND);   
	  
	// 垂直分割线
 	glEnable(GL_BLEND);
    glBlendFunc(GL_ZERO, GL_ZERO);
	glLineWidth(1.0);
	glVertexPointer(3, GL_FLOAT, 28, portraitLines);
	glColorPointer(4, GL_FLOAT, 28, &portraitLines[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 100);	// 1条线2个个点
	glDisable(GL_BLEND);  	
 
	////////////// draw rect>>>>
 
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
 	glVertexPointer(3, GL_FLOAT, 28, squareVertices1);
	glColorPointer(4, GL_FLOAT, 28, &squareVertices1[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0 , 4);
	glDisable(GL_BLEND);
 
	 
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
 	glVertexPointer(3, GL_FLOAT, 28, squareVertices2);
	glColorPointer(4, GL_FLOAT, 28, &squareVertices2[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0 , 4);
	glDisable(GL_BLEND);	
	 

	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
 	glVertexPointer(3, GL_FLOAT, 28, squareVertices3);
	glColorPointer(4, GL_FLOAT, 28, &squareVertices3[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0 , 4);
	glDisable(GL_BLEND);	
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
 	glVertexPointer(3, GL_FLOAT, 28, squareVertices4);
	glColorPointer(4, GL_FLOAT, 28, &squareVertices4[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0 , 4);
	glDisable(GL_BLEND);
 
	/////// <<<<<< draw rect
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}



- (void)drawViewSmall {
	 
	if (isStop) {
		return;
	}
	
	GLfloat lines[56];
	int j = 0;
	GLfloat randomBlackLine1;
	for (int i=0; i<56; i+=14) {
 		
		lines[i] = 12.0+13*j;lines[i+1]=2.0;lines[i+2]=-6.0;
		lines[i+3]=0.0; 
		lines[i+4]=1.0; 
		lines[i+5]=0.0; 
		lines[i+6]=1.0;
		
 		randomBlackLine1 = (CGFloat)random()/(CGFloat)RAND_MAX*30;
		lines[i+7] = 12.0+13*j;lines[i+8]=randomBlackLine1;lines[i+9]=-6.0;
		//0.8 0.0 0.0
		lines[i+10]= 1.0;
		lines[i+11]= 0.0;
		lines[i+12]= 0.0;
		lines[i+13]=1.0;		
		
		j++;
	}
	
	
	
	GLfloat horizontalLines[140];
	
	j = 0;
	for (int i=0; i<140; i+=14) {
 		horizontalLines[i] = 0;horizontalLines[i+1]=6+j*6;horizontalLines[i+2]=-6.0;
		horizontalLines[i+3]=0;
		horizontalLines[i+4]=0;
		horizontalLines[i+5]=0;
		horizontalLines[i+6]=1.0;
		
 		horizontalLines[i+7] = 80;horizontalLines[i+8]=6+j*6;horizontalLines[i+9]=-6.0;
		horizontalLines[i+10]=0;
		horizontalLines[i+11]=0;
		horizontalLines[i+12]=0;
		horizontalLines[i+13]=1.0;	
		
		j++;
	}
	
	
    [EAGLContext setCurrentContext:context];   
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	//glMatrixMode(GL_MODELVIEW);
	
	
	// Setup and render the lines

	glEnable(GL_BLEND);
    glBlendFunc(GL_ZERO, GL_ZERO);
	glLineWidth(1.5);
	glVertexPointer(3, GL_FLOAT, 28, horizontalLines);
	glColorPointer(4, GL_FLOAT, 28, &horizontalLines[3]);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 20);	
	glDisable(GL_BLEND);    
	
	glLineWidth(10.0);
	glEnableClientState(GL_COLOR_ARRAY);
	glVertexPointer(3, GL_FLOAT, 28, lines);
	glColorPointer(4, GL_FLOAT, 28, &lines[3]);
	glDrawArrays(GL_LINES, 0, 8);
	
	
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	[songController.glReflectView drawViewSmall:lines horizontalLines1:horizontalLines];
		
//	[songController addreflecteffect:songController.glView];
	
}



- (void)startAnimation {
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawViewSmall) userInfo:nil repeats:YES];
}

- (void)startAnimationLarge {
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawLargeView_2_p) userInfo:nil repeats:YES];
}

- (void)stopAnimation {
	if ([self.animationTimer isValid]) {
		[self.animationTimer invalidate];
	}
 	
    self.animationTimer = nil;
}


- (void)setAnimationTimer:(NSTimer *)newTimer {
	if ([animationTimer isValid]) {
		[animationTimer invalidate];
	}
 
    animationTimer = newTimer;
}


- (void)setAnimationInterval:(NSTimeInterval)interval {
    animationInterval = interval;
    if (animationTimer) {
        [self stopAnimation];
	}
	
	switch (drawtype) {
		case 0:
			[self startAnimation];
			break;
		case 1:
			[self startAnimationLarge];
			break;
		case 2:
			self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawLargeView_2_l) userInfo:nil repeats:YES];
			break;
		default:
			break;
	}
	
}


- (void)checkGLError:(BOOL)visibleCheck {
	
    GLenum error = glGetError();
	
    switch (error) {			
        case GL_INVALID_ENUM:			
            NSLog(@"GL Error: Enum argument is out of range");			
            break;			
        case GL_INVALID_VALUE:			
            NSLog(@"GL Error: Numeric value is out of range");			
            break;			
        case GL_INVALID_OPERATION:			
            NSLog(@"GL Error: Operation illegal in current state");			
            break;			
        case GL_STACK_OVERFLOW:			
            NSLog(@"GL Error: Command would cause a stack overflow");			
            break;			
        case GL_STACK_UNDERFLOW:
            NSLog(@"GL Error: Command would cause a stack underflow");
            break;
        case GL_OUT_OF_MEMORY:
            NSLog(@"GL Error: Not enough memory to execute command");			
            break;			
        case GL_NO_ERROR:			
            if (visibleCheck) {				
                NSLog(@"No GL Error");				
            }
            break;
			
        default:
            NSLog(@"Unknown GL Error");			
            break;
    }
}

/**
 * Basically what we’re doing is pointing CoreGraphics at our texture data 
 * and telling it the format and size of our texture.
 */

- (void)loadTexture {
    CGImageRef textureImage = [UIImage imageNamed:@"checkerplate.png"].CGImage;
    if (textureImage == nil) {
        NSLog(@"Failed to load texture image");
		return;
    }
	
    NSInteger texWidth = CGImageGetWidth(textureImage);
    NSInteger texHeight = CGImageGetHeight(textureImage);
	
	GLubyte *textureData = (GLubyte *)malloc(texWidth * texHeight * 4);
	
    CGContextRef textureContext = CGBitmapContextCreate(textureData,
														texWidth, texHeight,
														8, texWidth * 4,
														CGImageGetColorSpace(textureImage),
														kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (float)texWidth, (float)texHeight), textureImage);
	CGContextRelease(textureContext);
	
	glGenTextures(1, &textures[0]);
	glBindTexture(GL_TEXTURE_2D, textures[0]);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
	
	free(textureData);
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glEnable(GL_TEXTURE_2D);
}


- (void)dealloc {
    
    [self stopAnimation];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];  
	
    [self destroyFramebuffer];
	
	[reflectionView release];
	[super dealloc];
}
  
@end
