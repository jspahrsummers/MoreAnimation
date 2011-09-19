//
//  MAOpenGLProgram.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-19.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>

@class MAOpenGLShader;

/**
 * An error code indicating that linking failed.
 */
extern const NSInteger MAOpenGLProgramLinkingFailed;

/**
 * An OpenGL program object.
 */
@interface MAOpenGLProgram : NSObject
/**
 * The domain for errors originating from this class.
 */
+ (NSString *)errorDomain;

/**
 * The OpenGL program object ID associated with the receiver.
 *
 * @warning When the receiver is deallocated, this program object will be
 * deleted.
 */
@property (nonatomic, assign, readonly) GLuint programID;

/**
 * The OpenGL context associated with the receiver. You should not attempt to
 * use the receiver's #programID in any other OpenGL context without first
 * copying the object into that context.
 */
@property (nonatomic, strong, readonly) NSOpenGLContext *GLContext;

/**
 * Returns an autoreleased program initialized with #init.
 */
+ (id)program;

/**
 * Returns an autoreleased program initialized with #initWithGLContext:.
 */
+ (id)programWithGLContext:(NSOpenGLContext *)context;

/**
 * Returns an autoreleased program initialized with #initWithShaders:.
 */
+ (id)programWithShaders:(NSArray *)shaders;

/**
 * Invokes #initWithGLContext: with the current \c NSOpenGLContext for the
 * current thread.
 */
- (id)init;

/**
 * Initializes a program for the specified OpenGL context. A #programID will be
 * automatically created without any attached shaders.
 * 
 * This is the designated initializer for this class.
 */
- (id)initWithGLContext:(NSOpenGLContext *)context;

/**
 * Initializes a program, attaching the given shaders. The OpenGL context is
 * inferred from the objects in the \a shaders array, which must all be
 * associated with the same OpenGL context.
 *
 * The program is not linked after this method finishes. You must still bind
 * attributes and invoke #linkProgram: yourself.
 *
 * @note \a shaders must not be empty.
 */
- (id)initWithShaders:(NSArray *)shaders;

/**
 * Attaches \a shader to the receiver's program object. \a shader must be
 * associated with the same OpenGL context as the receiver.
 *
 * @note \a shader can be safely destroyed after attachment. The shader will
 * persist for the lifetime of the program.
 */
- (void)attachShader:(MAOpenGLShader *)shader;

/**
 * Detaches \a shader from the receiver's program object. \a shader must be
 * associated with the same OpenGL context as the receiver.
 */
- (void)detachShader:(MAOpenGLShader *)shader;

/**
 * Attempts to link together all the shaders attached to the receiver. If an
 * error occurs, \c NO is returned and \a error (if provided) is filled in with
 * a description of the error.
 */
- (BOOL)linkProgram:(NSError **)error;
@end
