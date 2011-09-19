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

// workhorse functions
static
void recursivelyDisplayMALayerHostingViews (NSView *view) {
	MALayer *layer = view.MALayer;
	if (layer) {
		NSGraphicsContext *previousContext = [NSGraphicsContext currentContext];
		@onExit {
			[NSGraphicsContext setCurrentContext:previousContext];
		};

		NSGraphicsContext *context = [[view window] graphicsContext];
		[NSGraphicsContext setCurrentContext:context];

		[view lockFocus];
		[layer renderInContext:context.graphicsPort];
		[view unlockFocus];
	}

	NSArray *subviews = view.subviews;
	for (NSView *view in subviews) {
		recursivelyDisplayMALayerHostingViews(view);
	}
}

// NSView method overrides
@interface NSViewMAMixin : NSView {}
@end

@implementation NSViewMAMixin

- (void)display {
	displayImpl(self, _cmd);
  	recursivelyDisplayMALayerHostingViews(self);
}

- (void)displayIfNeeded {
	displayIfNeededImpl(self, _cmd);
  	recursivelyDisplayMALayerHostingViews(self);
}

- (void)displayIfNeededIgnoringOpacity {
	displayIfNeededIgnoringOpacityImpl(self, _cmd);
  	recursivelyDisplayMALayerHostingViews(self);
}

- (void)displayIfNeededInRectIgnoringOpacity:(NSRect)rect {
	displayIfNeededInRectIgnoringOpacityImpl(self, _cmd, rect);
  	recursivelyDisplayMALayerHostingViews(self);
}

- (void)displayRect:(NSRect)rect {
	displayRectImpl(self, _cmd, rect);
  	recursivelyDisplayMALayerHostingViews(self);
}

- (void)displayRectIgnoringOpacity:(NSRect)rect {
	displayRectIgnoringOpacityImpl(self, _cmd, rect);
  	recursivelyDisplayMALayerHostingViews(self);
}

- (void)displayRectIgnoringOpacity:(NSRect)rect inContext:(NSGraphicsContext *)context {
	displayRectIgnoringOpacityInContextImpl(self, _cmd, rect, context);
  	recursivelyDisplayMALayerHostingViews(self);
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
	[self drawRect:self.bounds];
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

	layer.delegate = (id<MALayerDelegate>)self;

  	objc_setAssociatedObject(self, NSViewAssociatedMALayerKey, layer, OBJC_ASSOCIATION_RETAIN);
	[self setNeedsDisplay:YES];
}

@end
