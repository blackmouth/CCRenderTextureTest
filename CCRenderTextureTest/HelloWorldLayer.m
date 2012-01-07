//
//  HelloWorldLayer.m
//  CCRenderTextureTest
//
//  Created by Edgar on 1/5/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (ccColor4F)randomBrightColor {
  
  while (true) {
    float requiredBrightness = 192;
    ccColor4B randomColor = 
    ccc4(arc4random() % 255,
         arc4random() % 255, 
         arc4random() % 255, 
         255);
    if (randomColor.r > requiredBrightness || 
        randomColor.g > requiredBrightness ||
        randomColor.b > requiredBrightness) {
      return ccc4FFromccc4B(randomColor);
    }        
  }
  
}

#if defined (__COCOS2D_GLES2__)

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
  
  // 1
  NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
  NSError* error;
  NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
  if (!shaderString) {
    NSLog(@"Error loading shader: %@", error.localizedDescription);
    exit(1);
  }
  
  // 2
  GLuint shaderHandle = glCreateShader(shaderType);    
  
  // 3
  const char * shaderStringUTF8 = [shaderString UTF8String];    
  int shaderStringLength = [shaderString length];
  glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
  
  // 4
  glCompileShader(shaderHandle);
  
  // 5
  GLint compileSuccess;
  glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
  if (compileSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"%@", messageString);
    exit(1);
  }
  
  return shaderHandle;
  
}

- (void)compileShaders {
  
  GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
  GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
  
  m_shaderProgram = glCreateProgram();
  glAttachShader(m_shaderProgram, vertexShader);
  glAttachShader(m_shaderProgram, fragmentShader);
  glLinkProgram(m_shaderProgram);
  
  GLint linkSuccess;
  glGetProgramiv(m_shaderProgram, GL_LINK_STATUS, &linkSuccess);
  if (linkSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetProgramInfoLog(m_shaderProgram, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"%@", messageString);
    exit(1);
  }else{
    NSLog(@"Success linking shaders");
  }
  
  m_a_positionHandle = glGetAttribLocation(m_shaderProgram, "a_position");
	m_a_colorHandle = glGetAttribLocation(m_shaderProgram, "a_color");
	m_u_mvpHandle = glGetUniformLocation(m_shaderProgram, "u_mvpMatrix");
  
}

-(CCSprite *)stripedSpriteWithColor1:(ccColor4F)c1 color2:(ccColor4F)c2 textureSize:(float)textureSize  stripes:(int)nStripes {
  
  // 1: Create new CCRenderTexture
  CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
  
  // 2: Call CCRenderTexture:begin
  [rt beginWithClear:c1.r g:c1.g b:c1.b a:c1.a];
  
  // 3: Draw into the texture      
  // Layer 1: Stripes
  glDisable(GL_TEXTURE_2D);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);
    
  CGPoint vertices[nStripes*6];
  int nVertices = 0;
  float x1 = -textureSize;
  float x2;
  float y1 = textureSize;
  float y2 = 0;
  float dx = textureSize / nStripes * 2;
  float stripeWidth = dx/2;
  
  for (int i=0; i<nStripes; i++) {
    x2 = x1 + textureSize;    
    vertices[nVertices++] = CGPointMake(x1, y1);
    vertices[nVertices++] = CGPointMake(x1+stripeWidth, y1);
    vertices[nVertices++] = CGPointMake(x2, y2);
    vertices[nVertices++] = vertices[nVertices-3];
    vertices[nVertices++] = vertices[nVertices-3];
    vertices[nVertices++] = CGPointMake(x2+stripeWidth, y2);
    x1 += dx;
    
  }
//  What works in openGL es 1.1
//  glColor4f(c2.r, c2.g, c2.b, c2.a);
//  glVertexPointer(2, GL_FLOAT, 0, vertices);
//  glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);

//////// openGL es 2.0 ///////////////////////////
  glColor4f(c2.r, c2.g, c2.b, c2.a);
  ccGLUseProgram( self.shaderProgram->program_ );
  ccGLUniformModelViewProjectionMatrix( self.shaderProgram);
  ccGLEnableVertexAttribs(kCCVertexAttrib_Color | kCCVertexAttribFlag_Position );
  glUniform4f( kCCVertexAttrib_Color, c2.r, c2.g, c2.b, c2.a );
  glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);  
	glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(vertices),vertices);
  glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);
//////////////////////////////////////////////////  
  CHECK_GL_ERROR();
  glEnableClientState(GL_COLOR_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glEnable(GL_TEXTURE_2D);
  
  // Layer 2: Noise    
  CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
  [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
  noise.position = ccp(textureSize/2, textureSize/2);
  [noise visit];
  
  // 4: Call CCRenderTexture:end
  [rt end];
  
  // 5: Create a new Sprite from the texture
  return [CCSprite spriteWithTexture:rt.sprite.texture];
}

#else

-(CCSprite *)stripedSpriteWithColor1:(ccColor4F)c1 color2:(ccColor4F)c2 textureSize:(float)textureSize  stripes:(int)nStripes {
  
  // 1: Create new CCRenderTexture
  CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
  
  // 2: Call CCRenderTexture:begin
  [rt beginWithClear:c1.r g:c1.g b:c1.b a:c1.a];
  
  // 3: Draw into the texture      
  // Layer 1: Stripes
  glDisable(GL_TEXTURE_2D);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);
  
  CGPoint vertices[nStripes*6];
  int nVertices = 0;
  float x1 = -textureSize;
  float x2;
  float y1 = textureSize;
  float y2 = 0;
  float dx = textureSize / nStripes * 2;
  float stripeWidth = dx/2;
  
  for (int i=0; i<nStripes; i++) {
    x2 = x1 + textureSize;    
    vertices[nVertices++] = CGPointMake(x1, y1);
    vertices[nVertices++] = CGPointMake(x1+stripeWidth, y1);
    vertices[nVertices++] = CGPointMake(x2, y2);
    vertices[nVertices++] = vertices[nVertices-3];
    vertices[nVertices++] = vertices[nVertices-3];
    vertices[nVertices++] = CGPointMake(x2+stripeWidth, y2);
    x1 += dx;
    
  }
  
  glColor4f(c2.r, c2.g, c2.b, c2.a);
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);
  
  glEnableClientState(GL_COLOR_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glEnable(GL_TEXTURE_2D);
  
  // Layer 2: Noise    
  CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
  [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
  noise.position = ccp(textureSize/2, textureSize/2);
  [noise visit];
  
  // 4: Call CCRenderTexture:end
  [rt end];
  
  // 5: Create a new Sprite from the texture
  return [CCSprite spriteWithTexture:rt.sprite.texture];
}

#endif

- (void)genBackground {
  
  [_background removeFromParentAndCleanup:YES];
  
  ccColor4F bgColor = [self randomBrightColor];
  ccColor4F color2  = [self randomBrightColor];
  //_background = [self spriteWithColor:bgColor textureSize:512];
  //int nStripes = ((arc4random() % 4) + 1) * 2;
  _background = [self stripedSpriteWithColor1:bgColor color2:color2 textureSize:512 stripes:4];
  
  CGSize winSize = [CCDirector sharedDirector].winSize;
  _background.position = ccp(winSize.width/2, winSize.height/2);        
  ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
  [_background.texture setTexParameters:&tp];
  
  [self addChild:_background];
  
  [self schedule:@selector(updateTexture:)];
  
}


- (void)updateTexture:(ccTime)dt {
  
  float PIXELS_PER_SECOND = 100;
  static float offset = 0;
  offset += PIXELS_PER_SECOND * dt;
  
  if(offset > 1024) offset = 0;
  
  CGSize textureSize = _background.textureRect.size;
  [_background setTextureRect:CGRectMake(0, offset, textureSize.width, textureSize.height)];
  
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// create and initialize a Label
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Hello World" fontName:@"Marker Felt" fontSize:64];

		// ask director the the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
	
		// position the label on the center of the screen
		label.position =  ccp( size.width /2 , size.height/2 );
		
		// add the label as a child to this Layer
		//[self addChild: label];
#if defined (__COCOS2D_GLES2__)
    [self compileShaders];
    self.shaderProgram = 
    [[[GLProgram alloc] 
      initWithVertexShaderFilename:@"PositionTextureColor.vsh"
      fragmentShaderFilename:@"PositionTextureColor.fsh"] autorelease];
    CHECK_GL_ERROR_DEBUG();
    [self.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
		[self.shaderProgram addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];
		CHECK_GL_ERROR_DEBUG();
		[shaderProgram_ link];    
		CHECK_GL_ERROR_DEBUG();
		[shaderProgram_ updateUniforms];    
		CHECK_GL_ERROR_DEBUG();                
//    m_a_positionHandle = glGetUniformLocation( self.shaderProgram->program_, "u_texture");
    CHECK_GL_ERROR_DEBUG();
#endif
    [self genBackground];
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
