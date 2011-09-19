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
#import <objc/runtime.h>

// for associating an MALayer to an NSView
static char * const NSViewAssociatedMALayerKey = "NSViewAssociatedMALayer";

// variables for saving the old implementations
static
void (*displayImpl)(NSView *, SEL) = NULL;

static
void (*displayIfNeededImpl)(NSView *, SEL) = NULL;

static
void (*displayIfNeededIgnoringOpacityImpl)(NSView *, SEL) = NULL;

static
void (*displayIfNeededInRectImpl)(NSView *, SEL, NSRect) = NULL;

static
void (*displayIfNeededInRectIgnoringOpacityImpl)(NSView *, SEL, NSRect) = NULL;

static
void (*displayRectImpl)(NSView *, SEL, NSRect) = NULL;

static
void (*displayRectIgnoringOpacityImpl)(NSView *, SEL, NSRect) = NULL;

static
void (*displayRectIgnoringOpacityInContextImpl)(NSView *, SEL, NSRect, NSGraphicsContext *) = NULL;

static
void (*drawLayerInContextImpl)(NSView *, SEL, MALayer *, CGContextRef) = NULL;

// NSView method overrides
@interface NSViewMAMixin : NSView {}
@end

@implementation NSViewMAMixin

- (void)display {
	MALayer *layer = self.MALayer;
	if (!layer) {
		displayImpl(self, _cmd);
		return;
	}

	[self displayRectIgnoringOpacity:self.bounds inContext:[NSGraphicsContext currentContext]];
}

- (void)displayIfNeeded {
	MALayer *layer = self.MALayer;
	if (!layer) {
		displayIfNeededImpl(self, _cmd);
		return;
	}

  	if (![self needsDisplay])
		return;

	[self displayRectIgnoringOpacity:self.bounds inContext:[NSGraphicsContext currentContext]];
}

- (void)displayIfNeededIgnoringOpacity {
	MALayer *layer = self.MALayer;
	if (!layer) {
		displayIfNeededIgnoringOpacityImpl(self, _cmd);
		return;
	}

  	if (![self needsDisplay])
		return;

	[self displayRectIgnoringOpacity:self.bounds inContext:[NSGraphicsContext currentContext]];
}

- (void)displayIfNeededInRectIgnoringOpacity:(NSRect)rect {
	MALayer *layer = self.MALayer;
	if (!layer) {
		displayIfNeededInRectIgnoringOpacityImpl(self, _cmd, rect);
		return;
	}

  	if (![self needsDisplay])
		return;

	[self displayRectIgnoringOpacity:rect inContext:[NSGraphicsContext currentContext]];
}

- (void)displayRect:(NSRect)rect {
	MALayer *layer = self.MALayer;
	if (!layer) {
		displayRectImpl(self, _cmd, rect);
		return;
	}

	[self displayRectIgnoringOpacity:rect inContext:[NSGraphicsContext currentContext]];
}

- (void)displayRectIgnoringOpacity:(NSRect)rect {
	MALayer *layer = self.MALayer;
	if (!layer) {
		displayRectIgnoringOpacityImpl(self, _cmd, rect);
		return;
	}

	[self displayRectIgnoringOpacity:rect inContext:[NSGraphicsContext currentContext]];
}

- (void)displayRectIgnoringOpacity:(NSRect)rect inContext:(NSGraphicsContext *)context {
	MALayer *layer = self.MALayer;
	if (!layer) {
		displayRectIgnoringOpacityInContextImpl(self, _cmd, rect, context);
		return;
	}

	[layer renderInContext:context.graphicsPort];
	[self setNeedsDisplay:NO];
}

- (void)drawLayer:(MALayer *)layer inContext:(CGContextRef)context {
  	// 'layer' may be a CALayer, which means that NSView is meant to handle
	// CALayerDelegate methods
	if (![layer isKindOfClass:[MALayer class]]) {
		drawLayerInContextImpl(self, _cmd, layer, context);
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
	IMP *savedImpls[] = {
		(IMP *)&displayImpl,
		(IMP *)&displayIfNeededImpl,
		(IMP *)&displayIfNeededIgnoringOpacityImpl,
		(IMP *)&displayIfNeededInRectImpl,
		(IMP *)&displayIfNeededInRectIgnoringOpacityImpl,
		(IMP *)&displayRectImpl,
		(IMP *)&displayRectIgnoringOpacityImpl,
		(IMP *)&displayRectIgnoringOpacityInContextImpl,
		(IMP *)&drawLayerInContextImpl
	};

	SEL selectors[] = {
		@selector(display),
		@selector(displayIfNeeded),
		@selector(displayIfNeededIgnoringOpacity),
		@selector(displayIfNeededInRect:),
		@selector(displayIfNeededInRectIgnoringOpacity:),
		@selector(displayRect:),
		@selector(displayRectIgnoringOpacity:),
		@selector(displayRectIgnoringOpacity:inContext:),
		@selector(drawLayer:inContext:)
	};

	size_t count = sizeof(savedImpls) / sizeof(*savedImpls);
	Class dstClass = [NSView class];

	for (size_t i = 0;i < count;++i) {
		IMP *implPtr = savedImpls[i];
		SEL selector = selectors[i];

		Method method = class_getInstanceMethod(dstClass, selector);
		if (method) {
			*implPtr = method_getImplementation(method);
		}
	}

	ext_replaceMethodsFromClass([NSViewMAMixin class], dstClass);
}

// simple additions
@safecategory (NSView, MoreAnimationExtensions)

#pragma mark Properties

- (MALayer *)MALayer {
  	return objc_getAssociatedObject(self, NSViewAssociatedMALayerKey);
}

- (void)setMALayer:(MALayer *)layer {
	__weak id weakSelf = self;
	__unsafe_unretained MALayer *weakLayer = layer;

	layer.needsRenderBlock = ^(MALayer *layerNeedingRender){
		if (layerNeedingRender == weakLayer) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[weakSelf setNeedsDisplay:YES];
			});
		}
	};

  	objc_setAssociatedObject(self, NSViewAssociatedMALayerKey, layer, OBJC_ASSOCIATION_RETAIN);
}

@end
