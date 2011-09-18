//
//  NSView+MoreAnimationExtensions.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-18.
//  Released into the public domain.
//

#import "NSView+MoreAnimationExtensions.h"
#import "MALayer.h"
#import "EXTScope.h"

// for associating an MALayer to an NSView
static char * const NSViewAssociatedMALayerKey = "NSViewAssociatedMALayer";

@implementation NSView (MoreAnimationExtensions)

#pragma mark NSView swizzles

- (void)displayRectIgnoringOpacity:(NSRect)rect inContext:(NSGraphicsContext *)context; {
	[self.MALayer display];
}

#pragma mark MALayerDelegate

- (void)drawLayer:(MALayer *)layer inContext:(CGContextRef)context {
	NSGraphicsContext *previousContext = [NSGraphicsContext currentContext];
	@onExit {
		[NSGraphicsContext setCurrentContext:previousContext];
	};

	NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithPort:context flipped:NO];
	[NSGraphicsContext setCurrentContext:graphicsContext];
	
  	[self lockFocus];
	[self drawRect:self.bounds];
	[self unlockFocus];
}

#pragma mark Properties

- (MALayer *)MALayer {
  	return objc_getAssociatedObject(self, NSViewAssociatedMALayerKey);
}

- (void)setMALayer:(MALayer *)layer {
  	objc_setAssociatedObject(self, NSViewAssociatedMALayerKey, layer, OBJC_ASSOCIATION_RETAIN);
}

@end
