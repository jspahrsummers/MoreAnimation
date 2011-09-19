//
//  MAOpenGLProgramManager.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-19.
//  Released into the public domain.
//

#import "MAOpenGLProgramManager.h"
#import "MAOpenGLProgram.h"
#import "MAOpenGLShader.h"
#import <OpenGL/gl.h>

/**
 * A block for creating an OpenGL program for the specified context.
 */
typedef MAOpenGLProgram *(^MAOpenGLProgramCreateBlock)(NSOpenGLContext *context);

@interface MAOpenGLProgramManager () {
	/**
	 * Synchronizes access to arrays of programs.
	 */
	dispatch_queue_t m_programsQueue;

	/**
	 * Stores a textured quad program for every active OpenGL context.
	 */
	NSMutableArray *m_texturedQuadPrograms;
}

/**
 * If any program in \a programs is associated with \a context, returns that
 * program. Otherwise, executes \a createBlock (if provided), saves it into the
 * specified array, and returns the result.
 */
- (MAOpenGLProgram *)programForContext:(NSOpenGLContext *)context inArray:(NSMutableArray *)programs createBlock:(MAOpenGLProgramCreateBlock)createBlock;
@end

@implementation MAOpenGLProgramManager

#pragma mark Lifecycle

+ (id)defaultManager; {
	static id singleton = nil;
	static dispatch_once_t pred;

	dispatch_once(&pred, ^{
		singleton = [[self alloc] init];
	});

	return singleton;
}

- (id)init {
  	if ((self = [super init])) {
		m_programsQueue = dispatch_queue_create("org.MoreAnimation.MAOpenGLProgramManager.programsQueue", DISPATCH_QUEUE_SERIAL);
		m_texturedQuadPrograms = [NSMutableArray array];
	}

	return self;
}

- (void)dealloc {
	dispatch_release(m_programsQueue);
	m_programsQueue = NULL;
}

#pragma mark Program management

- (MAOpenGLProgram *)programForContext:(NSOpenGLContext *)context inArray:(NSMutableArray *)programs createBlock:(MAOpenGLProgramCreateBlock)createBlock; {
  	__block MAOpenGLProgram *programForContext = nil;

  	dispatch_sync(m_programsQueue, ^{
		NSUInteger index = [programs indexOfObjectPassingTest:^(MAOpenGLProgram *program, NSUInteger index, BOOL *stop){
			return (BOOL)(program.GLContext == context);
		}];

		if (index != NSNotFound) {
			programForContext = [programs objectAtIndex:index];
		}
	});

	if (!programForContext && createBlock) {
		if ((programForContext = createBlock(context))) {
			dispatch_async(m_programsQueue, ^{
				// only add it to the array if it's still not present
				if ([programs indexOfObjectIdenticalTo:programForContext] == NSNotFound)
					[programs addObject:programForContext];
			});
		}
	}

	return programForContext;
}

#pragma mark Built-in programs

- (MAOpenGLProgram *)texturedTriangleProgramForContext:(NSOpenGLContext *)context; {
	MAOpenGLProgramCreateBlock createBlock = ^(NSOpenGLContext *context){
		NSString *vertSource = @"\
#version 150\n\
in vec3 in_Position;\n\
in vec4 in_Color;\n\
out vec4 ex_Color;\n\
void main(void) {\n\
    gl_Position = vec4(in_Position.x, in_Position.y, in_Position.z, 1.0);\n\
    ex_Color = in_Color;\n\
}\n\
";
		
		NSString *fragSource = @"\
#version 150\n\
precision highp float;\n\
in vec4 ex_Color;\n\
out vec4 gl_FragColor;\n\
void main(void) {\n\
    gl_FragColor = ex_Color;\n\
}\n\
";

		MAOpenGLShader *vertexShader = [MAOpenGLShader shaderWithType:GL_VERTEX_SHADER GLContext:context];
		MAOpenGLShader *fragmentShader = [MAOpenGLShader shaderWithType:GL_FRAGMENT_SHADER GLContext:context];
		MAOpenGLProgram *program = [MAOpenGLProgram programWithShaders:[NSArray arrayWithObjects:vertexShader, fragmentShader, nil]];

		glBindAttribLocation(program.programID, 0, "in_Position");
	 	glBindAttribLocation(program.programID, 1, "in_Color");

		NSError *error = nil;
		if ([program linkProgram:&error]) {
			return program;
		} else {
			NSLog(@"Could not link textured triangle program %@: %@", program, error);
			return nil;
		}
	};

  	return [self programForContext:context inArray:m_texturedQuadPrograms createBlock:createBlock];
}

@end
