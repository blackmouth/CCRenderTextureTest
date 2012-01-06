//
//  HelloWorldLayer.h
//  CCRenderTextureTest
//
//  Created by Edgar on 1/5/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
  CCSprite * _background;
#if defined (__COCOS2D_GLES2__)  
  GLuint m_shaderProgram; 
	GLuint m_a_positionHandle;
	GLuint m_a_colorHandle;
	GLuint m_u_mvpHandle;	
#endif

}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
