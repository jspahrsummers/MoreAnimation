//
//  MAOpenGLProgramManager.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-19.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>

@class MAOpenGLProgram;

/**
 * Private class that manages OpenGL programs needed by the framework. Programs
 * are loaded and stored on a per-context basis.
 */
@interface MAOpenGLProgramManager : NSObject
/**
 * The singleton instance of this manager.
 */
+ (id)defaultManager;

/**
 * Returns a program for rendering a textured triangle.
 */
- (MAOpenGLProgram *)texturedTriangleProgramForContext:(NSOpenGLContext *)context;
@end
