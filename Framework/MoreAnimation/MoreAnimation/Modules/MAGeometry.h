//
//  MAGeometry.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-20.
//  Released into the public domain.
//

#import <QuartzCore/QuartzCore.h>

typedef struct {
	CGFloat x;
	CGFloat y;
	CGFloat z;
	CGFloat w;
} MAVector3D;

#define MAVector3DMake(X, Y, Z, W) \
	((MAVector3D){ .x = (X), .y = (Y), .z = (Z), .w = (W) })

/**
 * Transforms \a v using the given transformation matrix.
 */
MAVector3D MAVector3DApplyCATransform3D (MAVector3D v, CATransform3D t);

/**
 * Divides vector \a v by \a x.
 */
MAVector3D MAVector3DDivide (MAVector3D v, CGFloat x);

