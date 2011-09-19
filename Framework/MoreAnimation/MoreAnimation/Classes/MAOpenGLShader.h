//
//  MAOpenGLShader.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-19.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>

/**
 * An OpenGL shader object.
 */
@interface MAOpenGLShader : NSObject
/**
 * The OpenGL shader object ID associated with the receiver.
 *
 * @warning When the receiver is deallocated, this shader will be deleted.
 */
@property (nonatomic, assign, readonly) GLuint shaderID;

/**
 * The type of shader object stored in #shaderID, as specified at the time of
 * initialization.
 */
@property (nonatomic, assign, readonly) GLenum type;

/**
 * The OpenGL context associated with the receiver. You should not attempt to
 * use the receiver's #shaderID in any other OpenGL context without first
 * copying the object into that context.
 */
@property (nonatomic, strong, readonly) NSOpenGLContext *GLContext;

/**
 * Returns an autoreleased shader initialized with #initWithType:.
 */
+ (id)shaderWithType:(GLenum)type;

/**
 * Returns an autoreleased shader initialized with #initWithType:GLContext:.
 */
+ (id)shaderWithType:(GLenum)type GLContext:(NSOpenGLContext *)cxt;

/**
 * Returns an autoreleased shader initialized with
 * #initWithContentsOfURL:type:GLContext:.
 */
+ (id)shaderWithContentsOfURL:(NSURL *)url type:(GLenum)type GLContext:(NSOpenGLContext *)cxt;

/**
 * Returns an autoreleased shader initialized with #initWithString:type:GLContext:.
 */
+ (id)shaderWithString:(NSString *)code type:(GLenum)type GLContext:(NSOpenGLContext *)cxt;

/**
 * Invokes #initWithType:GLContext: with the current \c NSOpenGLContext for the
 * current thread.
 */
- (id)initWithType:(GLenum)type;

/**
 * Initializes a shader of the given type for the specified OpenGL context.
 * A #shaderID will be automatically created without any associated source code.
 * 
 * This is the designated initializer for this class.
 */
- (id)initWithType:(GLenum)type GLContext:(NSOpenGLContext *)cxt;

/**
 * Initializes a shader of the given type for the specified OpenGL context.
 * A #shaderID will be automatically created, with source code loaded and
 * compiled from \a url.
 */
- (id)initWithContentsOfURL:(NSURL *)url type:(GLenum)type GLContext:(NSOpenGLContext *)cxt;

/**
 * Initializes a shader of the given type for the specified OpenGL context.
 * A #shaderID will be automatically created, with the given source code loaded
 * and compiled.
 */
- (id)initWithString:(NSString *)code type:(GLenum)type GLContext:(NSOpenGLContext *)cxt;
@end
