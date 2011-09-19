//
//  MAOpenGLProgram.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-19.
//  Released into the public domain.
//

#import "MAOpenGLProgram.h"
#import "MAOpenGLShader.h"
#import "NSOpenGLContext+MoreAnimationExtensions.h"
#import "EXTScope.h"
#import <OpenGL/gl.h>

const NSInteger MAOpenGLProgramLinkingFailed = -1;

@interface MAOpenGLProgram ()
// publicly readonly
@property (nonatomic, assign, readwrite) GLuint programID;
@property (nonatomic, strong, readwrite) NSOpenGLContext *GLContext;
@end

@implementation MAOpenGLProgram

#pragma mark Properties

@synthesize programID = m_programID;
@synthesize GLContext = m_GLContext;

#pragma mark Lifecycle

+ (id)program; {
	return [[self alloc] init];
}

+ (id)programWithGLContext:(NSOpenGLContext *)context; {
	return [[self alloc] initWithGLContext:context];
}

+ (id)programWithShaders:(NSArray *)shaders; {
	return [[self alloc] initWithShaders:shaders];
}

- (id)init; {
  	return [self initWithGLContext:[NSOpenGLContext currentContext]];
}

- (id)initWithGLContext:(NSOpenGLContext *)context; {
  	if ((self = [super init])) {
		__block GLuint program = 0;
		[context executeWhileCurrentContext:^{
			program = glCreateProgram();
		}];

		if (!program) {
			return nil;
		}

		self.GLContext = context;
		self.programID = program;
	}

	return self;
}

- (id)initWithShaders:(NSArray *)shaders; {
  	NSParameterAssert([shaders count] > 0);

	MAOpenGLShader *firstShader = [shaders objectAtIndex:0];
  	if ((self = [self initWithGLContext:firstShader.GLContext])) {
		[self.GLContext executeWhileCurrentContext:^{
			for (MAOpenGLShader *shader in shaders) {
				[self attachShader:shader];
			}
		}];
	}

	return self;
}

- (void)dealloc {
  	[self.GLContext executeWhileCurrentContext:^{
		glDeleteProgram(self.programID);
	}];

	self.programID = 0;
}

#pragma mark Error handling

+ (NSString *)errorDomain; {
	return @"MAOpenGLProgramErrorDomain";
}

#pragma mark Shader attachments

- (void)attachShader:(MAOpenGLShader *)shader; {
  	NSAssert2(shader.GLContext == self.GLContext, @"shader %@ must be associated with the same OpenGL context as program %@", shader, self);
  	
  	[self.GLContext executeWhileCurrentContext:^{
		glAttachShader(self.programID, shader.shaderID);
	}];
}

- (void)detachShader:(MAOpenGLShader *)shader; {
  	NSAssert2(shader.GLContext == self.GLContext, @"shader %@ must be associated with the same OpenGL context as program %@", shader, self);
  	
  	[self.GLContext executeWhileCurrentContext:^{
		glDetachShader(self.programID, shader.shaderID);
	}];
}

#pragma mark Linking

- (BOOL)linkProgram:(NSError **)error; {
  	__block GLint linkStatus = 0;

  	[self.GLContext executeWhileCurrentContext:^{
		glLinkProgram(self.programID);

		glGetProgramiv(self.programID, GL_LINK_STATUS, &linkStatus);
		if (!linkStatus) {
			if (error) {
				int logLength = 0;
				glGetProgramiv(self.programID, GL_INFO_LOG_LENGTH, &logLength);

				char *log = malloc((size_t)logLength + 1);
				glGetProgramInfoLog(self.programID, logLength + 1, NULL, log);

				NSString *errorDescription = [[NSString alloc] initWithBytesNoCopy:log length:(NSUInteger)logLength + 1 encoding:NSUTF8StringEncoding freeWhenDone:YES];

				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey];

				*error = [NSError
					errorWithDomain:[[self class] errorDomain]
					code:MAOpenGLProgramLinkingFailed
					userInfo:userInfo
				];
			}
		}
	}];

	return (linkStatus != 0);
}

@end
