//
//  NSView+MoreAnimationExtensions.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-18.
//  Released into the public domain.
//

#import "NSView+MoreAnimationExtensions.h"
#import "MALayer.h"
#import "EXTRuntimeExtensions.h"
#import "EXTSafeCategory.h"
#import "EXTScope.h"

// for associating an MALayer to an NSView
static char * const NSViewAssociatedMALayerKey = "NSViewAssociatedMALayer";

// variables for saving the old implementations
static
void (*originalDisplayRectInContextImpl)(NSView *, SEL, NSRect, NSGraphicsContext *) = NULL;

static
void (*originalDrawLayerInContextImpl)(NSView *, SEL, MALayer *, CGContextRef) = NULL;

// NSView method overrides
@interface NSViewMAMixin : NSView {}
@end

@implementation NSViewMAMixin

- (void)displayRectIgnoringOpacity:(NSRect)rect inContext:(NSGraphicsContext *)context {
	MALayer *layer = self.MALayer;
	if (!layer) {
		originalDisplayRectInContextImpl(self, _cmd, rect, context);
		return;
	}

	[self.MALayer display];
}

- (void)drawLayer:(MALayer *)layer inContext:(CGContextRef)context {
  	// 'layer' may be a CALayer, which means that NSView is meant to handle
	// CALayerDelegate methods
	if (![layer isKindOfClass:[MALayer class]]) {
		originalDrawLayerInContextImpl(self, _cmd, layer, context);
		return;
	}

	NSGraphicsContext *previousContext = [NSGraphicsContext currentContext];
	@onExit {
		[NSGraphicsContext setCurrentContext:previousContext];
	};

	NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
	[NSGraphicsContext setCurrentContext:graphicsContext];
	
  	[self lockFocus];
	[self drawRect:self.bounds];
	[self unlockFocus];
}

@end

// perform injection after all runtime setup
static
__attribute__((constructor))
void injectNSViewMAMixin (void) {
	ext_replaceMethodsFromClass([NSViewMAMixin class], [NSView class]);
}

// simple additions
@safecategory (NSView, MoreAnimationExtensions)

#pragma mark Properties

- (MALayer *)MALayer {
  	return objc_getAssociatedObject(self, NSViewAssociatedMALayerKey);
}

- (void)setMALayer:(MALayer *)layer {
  	objc_setAssociatedObject(self, NSViewAssociatedMALayerKey, layer, OBJC_ASSOCIATION_RETAIN);
}

@end
