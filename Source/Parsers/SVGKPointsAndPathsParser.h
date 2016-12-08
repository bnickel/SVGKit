/*!
//  SVGKPointsAndPathsParser.h

 This class really needs to be "upgraded" by wrapping it in a class named
 
     SVGPathElement
 
 and naming methods in that new class so that they adhere to the method names used in the official SVG standard's SVGPathElement spec:
 
 http://www.w3.org/TR/SVG11/paths.html#InterfaceSVGPathElement
 
 ...
 
 */
#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <QuartzCore/QuartzCore.h>
#endif

/**
 * Partially spammy; not as spammy as DEBUG_PATH_CREATION
 */
#define VERBOSE_PARSE_SVG_COMMAND_STRINGS 0

/*! Very useful for debugging the parser - this will output one line of logging
 * for every CGPath command that's actually done; you can then compare these lines
 * to the input source file, and manually check what's being sent to the renderer
 * versus what was expected
 *
 * this is MORE SPAMMY than VERBOSE_PARSE_SVG_COMMAND_STRINGS
 */
#define DEBUG_PATH_CREATION 0


typedef struct SVGCurve
{
    CGPoint c1;
    CGPoint c2;
    CGPoint p;
    BOOL quadratic;
} SVGCurve;

SVGCurve SVGCurveMake(CGFloat cx1, CGFloat cy1, CGFloat cx2, CGFloat cy2, CGFloat px, CGFloat py, BOOL quadratic);
BOOL SVGCurveEqualToCurve(SVGCurve curve1, SVGCurve curve2);

#define SVGCurveZero SVGCurveMake(0.,0.,0.,0.,0.,0.,NO)

typedef struct SVGPathState {
    SVGCurve curve;
    CGPoint point;
    BOOL hasError;
} SVGPathState;

#define SVGPathStateMakeWithCurve(c) ({\
    SVGCurve curve = (c);\
    SVGPathState state = { curve, curve.p, NO };\
    state;\
})

#define SVGPathStateMakeWithPoint(p) ({\
    CGPoint point = (p);\
    SVGPathState state = { SVGCurveZero, point, NO };\
    state;\
})

#define SVGPathStateError ({\
    SVGPathState state = { SVGCurveZero, CGPointZero, YES };\
    state;\
})

#define SVGPathStateHasCurve(s) ({ ! SVGCurveEqualToCurve( (s).curve, SVGCurveZero ); })




@interface SVGKPointsAndPathsParser : NSObject

+ (SVGPathState) readMovetoDrawtoCommandGroups:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readMovetoDrawto:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readMoveto:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readMovetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;

+ (SVGPathState) readLinetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readLinetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readVerticalLinetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;
+ (SVGPathState) readVerticalLinetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;
+ (SVGPathState) readHorizontalLinetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;
+ (SVGPathState) readHorizontalLinetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;

+ (SVGPathState) readQuadraticCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readQuadraticCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readQuadraticCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;
+ (SVGPathState) readSmoothQuadraticCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState;
+ (SVGPathState) readSmoothQuadraticCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState;
+ (SVGPathState) readSmoothQuadraticCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState;

+ (SVGPathState) readCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;
+ (SVGPathState) readSmoothCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState isRelative:(BOOL) isRelative;
+ (SVGPathState) readSmoothCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState isRelative:(BOOL) isRelative;
+ (SVGPathState) readSmoothCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState;

+ (SVGPathState) readEllipticalArcCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readEllipticalArcArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL) isRelative;
+ (SVGPathState) readEllipticalArcArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;


+ (SVGPathState) readCloseCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;

@end
