//
//  MAOpenGLShader.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-19.
//  Released into the public domain.
//

#import "MAOpenGLShader.h"
#import "NSOpenGLContext+MoreAnimationExtensions.h"
#import "EXTScope.h"
#import <OpenGL/gl.h>

const NSInteger MAOpenGLShaderCompilationFailed = -1;

@interface MAOpenGLShader ()
// publicly readonly
@property (nonatomic, assign, readwrite) GLuint shaderID;
@property (nonatomic, assign, readwrite) GLenum type;
@property (nonatomic, strong, readwrite) NSOpenGLContext *GLContext;
@end

@implementation MAOpenGLShader

#pragma mark Properties

@synthesize shaderID = m_shaderID;
@synthesize type = m_type;
@synthesize GLContext = m_GLContext;

#pragma mark Lifecycle

+ (id)shaderWithType:(GLenum)type; {
	return [[self alloc] initWithType:type];
}

+ (id)shaderWithType:(GLenum)type GLContext:(NSOpenGLContext *)cxt; {
	return [[self alloc] initWithType:type GLContext:cxt];
}

+ (id)shaderWithContentsOfURL:(NSURL *)url type:(GLenum)type GLContext:(NSOpenGLContext *)cxt; {
	return [[self alloc] initWithContentsOfURL:url type:type GLContext:cxt];
}

+ (id)shaderWithString:(NSString *)code type:(GLenum)type GLContext:(NSOpenGLContext *)cxt; {
	return [[self alloc] initWithString:code type:type GLContext:cxt];
}

- (id)initWithType:(GLenum)type; {
  	return [self initWithType:type GLContext:[NSOpenGLContext currentContext]];
}

- (id)initWithType:(GLenum)type GLContext:(NSOpenGLContext *)cxt; {
  	if ((self = [super init])) {
		__block GLuint shader = 0;
		[cxt executeWhileCurrentContext:^{
			shader = glCreateShader(type);
		}];

		if (!shader) {
			return nil;
		}

		self.GLContext = cxt;
		self.shaderID = shader;
		self.type = type;
	}
	
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)url type:(GLenum)type GLContext:(NSOpenGLContext *)cxt; {
  	NSStringEncoding encoding = 0;
	NSString *code = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:NULL];

	if (code) {
		return [self initWithString:code type:type GLContext:cxt];
	} else {
		return nil;
	}
}

- (id)initWithString:(NSString *)code type:(GLenum)type GLContext:(NSOpenGLContext *)cxt; {
  	if ((self = [self initWithType:type GLContext:cxt])) {
		__block BOOL compiled = NO;

		[self.GLContext executeWhileCurrentContext:^{
			const char *UTF8Source = [code UTF8String];
			int length = (int)[code length];

			glShaderSource(self.shaderID, 1, &UTF8Source, &length);

			NSError *error = nil;
			if (!(compiled = [self compileShader:&error])) {
				NSLog(@"Could not compile shader %@: %@", self, error);
			}
		}];

		if (!compiled)
			return nil;
	}

	return self;
}

- (void)dealloc {
  	[self.GLContext executeWhileCurrentContext:^{
		glDeleteShader(self.shaderID);
	}];

	self.shaderID = 0;
}

#pragma mark Error handling

+ (NSString *)errorDomain {
	return @"MAOpenGLShaderErrorDomain";
}

#pragma mark Compilation

- (BOOL)compileShader:(NSError **)error; {
  	__block GLint compileStatus = 0;

  	[self.GLContext executeWhileCurrentContext:^{
		glCompileShader(self.shaderID);

		glGetShaderiv(self.shaderID, GL_COMPILE_STATUS, &compileStatus);
		if (!compileStatus) {
			if (error) {
				int logLength = 0;
				glGetShaderiv(self.shaderID, GL_INFO_LOG_LENGTH, &logLength);

				char *log = malloc((size_t)logLength + 1);
				glGetShaderInfoLog(self.shaderID, logLength + 1, NULL, log);

				NSString *errorDescription = [[NSString alloc] initWithBytesNoCopy:log length:(NSUInteger)logLength + 1 encoding:NSUTF8StringEncoding freeWhenDone:YES];

				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey];

				*error = [NSError
					errorWithDomain:[[self class] errorDomain]
					code:MAOpenGLShaderCompilationFailed
					userInfo:userInfo
				];
			}
		}
	}];

	return (compileStatus != 0);
}

@end
