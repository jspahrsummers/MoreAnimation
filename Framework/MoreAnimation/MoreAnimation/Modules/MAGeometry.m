//
//  MAGeometry.c
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-20.
//  Released into the public domain.
//

#import "MAGeometry.h"

MAVector3D MAVector3DApplyCATransform3D (MAVector3D v, CATransform3D t) {
    MAVector3D dst;
    dst.x = v.x * t.m11 + v.y * t.m21 + v.z * t.m31 + v.w * t.m41;
    dst.y = v.x * t.m12 + v.y * t.m22 + v.z * t.m32 + v.w * t.m42;
    dst.z = v.x * t.m13 + v.y * t.m23 + v.z * t.m33 + v.w * t.m43;
    dst.w = v.x * t.m14 + v.y * t.m24 + v.z * t.m34 + v.w * t.m44;
    return dst;
}

MAVector3D MAVector3DDivide (MAVector3D v, CGFloat x) {
	CGFloat z = 1 / x;
	return MAVector3DMake(v.x * z, v.y * z, v.z * z, v.w * z);
}

