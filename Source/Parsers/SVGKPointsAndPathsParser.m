#import "SVGKPointsAndPathsParser.h"


#import "NSCharacterSet+SVGKExtensions.h"

// TODO: support quadratic-bezier-curveto
// TODO: support smooth-quadratic-bezier-curveto
// TODO: support elliptical-arc

inline SVGCurve SVGCurveMake(CGFloat cx1, CGFloat cy1, CGFloat cx2, CGFloat cy2, CGFloat px, CGFloat py, BOOL quadratic)
{
    SVGCurve curve;
    curve.c1 = CGPointMake(cx1, cy1);
    curve.c2 = CGPointMake(cx2, cy2);
    curve.p = CGPointMake(px, py);
    curve.quadratic = quadratic;
    return curve;
}
inline BOOL SVGCurveEqualToCurve(SVGCurve curve1, SVGCurve curve2)
{
    return (
            CGPointEqualToPoint(curve1.c1, curve2.c1)
            &&
            CGPointEqualToPoint(curve1.c2, curve2.c2)
            &&
            CGPointEqualToPoint(curve1.p, curve2.p)
            &&
            curve1.quadratic == curve2.quadratic
            );
}

@implementation SVGKPointsAndPathsParser


/* references
 http://www.w3.org/TR/2011/REC-SVG11-20110816/paths.html#PathDataBNF
 http://www.w3.org/TR/2011/REC-SVG11-20110816/shapes.html#PointsBNF
 
 */

/*
 http://www.w3.org/TR/2011/REC-SVG11-20110816/paths.html#PathDataBNF
 svg-path:
 wsp* moveto-drawto-command-groups? wsp*
 moveto-drawto-command-groups:
 moveto-drawto-command-group
 | moveto-drawto-command-group wsp* moveto-drawto-command-groups
 moveto-drawto-command-group:
 moveto wsp* drawto-commands?
 drawto-commands:
 drawto-command
 | drawto-command wsp* drawto-commands
 drawto-command:
 closepath
 | lineto
 | horizontal-lineto
 | vertical-lineto
 | curveto
 | smooth-curveto
 | quadratic-bezier-curveto
 | smooth-quadratic-bezier-curveto
 | elliptical-arc
 moveto:
 ( "M" | "m" ) wsp* moveto-argument-sequence
 moveto-argument-sequence:
 coordinate-pair
 | coordinate-pair comma-wsp? lineto-argument-sequence
 closepath:
 ("Z" | "z")
 lineto:
 ( "L" | "l" ) wsp* lineto-argument-sequence
 lineto-argument-sequence:
 coordinate-pair
 | coordinate-pair comma-wsp? lineto-argument-sequence
 horizontal-lineto:
 ( "H" | "h" ) wsp* horizontal-lineto-argument-sequence
 horizontal-lineto-argument-sequence:
 coordinate
 | coordinate comma-wsp? horizontal-lineto-argument-sequence
 vertical-lineto:
 ( "V" | "v" ) wsp* vertical-lineto-argument-sequence
 vertical-lineto-argument-sequence:
 coordinate
 | coordinate comma-wsp? vertical-lineto-argument-sequence
 curveto:
 ( "C" | "c" ) wsp* curveto-argument-sequence
 curveto-argument-sequence:
 curveto-argument
 | curveto-argument comma-wsp? curveto-argument-sequence
 curveto-argument:
 coordinate-pair comma-wsp? coordinate-pair comma-wsp? coordinate-pair
 smooth-curveto:
 ( "S" | "s" ) wsp* smooth-curveto-argument-sequence
 smooth-curveto-argument-sequence:
 smooth-curveto-argument
 | smooth-curveto-argument comma-wsp? smooth-curveto-argument-sequence
 smooth-curveto-argument:
 coordinate-pair comma-wsp? coordinate-pair
 quadratic-bezier-curveto:
 ( "Q" | "q" ) wsp* quadratic-bezier-curveto-argument-sequence
 quadratic-bezier-curveto-argument-sequence:
 quadratic-bezier-curveto-argument
 | quadratic-bezier-curveto-argument comma-wsp? 
 quadratic-bezier-curveto-argument-sequence
 quadratic-bezier-curveto-argument:
 coordinate-pair comma-wsp? coordinate-pair
 smooth-quadratic-bezier-curveto:
 ( "T" | "t" ) wsp* smooth-quadratic-bezier-curveto-argument-sequence
 smooth-quadratic-bezier-curveto-argument-sequence:
 coordinate-pair
 | coordinate-pair comma-wsp? smooth-quadratic-bezier-curveto-argument-sequence
 elliptical-arc:
 ( "A" | "a" ) wsp* elliptical-arc-argument-sequence
 elliptical-arc-argument-sequence:
 elliptical-arc-argument
 | elliptical-arc-argument comma-wsp? elliptical-arc-argument-sequence
 elliptical-arc-argument:
 nonnegative-number comma-wsp? nonnegative-number comma-wsp? 
 number comma-wsp flag comma-wsp? flag comma-wsp? coordinate-pair
 coordinate-pair:
 coordinate comma-wsp? coordinate
 coordinate:
 number
 nonnegative-number:
 integer-constant
 | floating-point-constant
 number:
 sign? integer-constant
 | sign? floating-point-constant
 flag:
 "0" | "1"
 comma-wsp:
 (wsp+ comma? wsp*) | (comma wsp*)
 comma:
 ","
 integer-constant:
 digit-sequence
 floating-point-constant:
 fractional-constant exponent?
 | digit-sequence exponent
 fractional-constant:
 digit-sequence? "." digit-sequence
 | digit-sequence "."
 exponent:
 ( "e" | "E" ) sign? digit-sequence
 sign:
 "+" | "-"
 digit-sequence:
 digit
 | digit digit-sequence
 digit:
 "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
 */

/*
 http://www.w3.org/TR/2011/REC-SVG11-20110816/shapes.html#PointsBNF
 
 list-of-points:
 wsp* coordinate-pairs? wsp*
 coordinate-pairs:
 coordinate-pair
 | coordinate-pair comma-wsp coordinate-pairs
 coordinate-pair:
 coordinate comma-wsp coordinate
 | coordinate negative-coordinate
 coordinate:
 number
 number:
 sign? integer-constant
 | sign? floating-point-constant
 negative-coordinate:
 "-" integer-constant
 | "-" floating-point-constant
 comma-wsp:
 (wsp+ comma? wsp*) | (comma wsp*)
 comma:
 ","
 integer-constant:
 digit-sequence
 floating-point-constant:
 fractional-constant exponent?
 | digit-sequence exponent
 fractional-constant:
 digit-sequence? "." digit-sequence
 | digit-sequence "."
 exponent:
 ( "e" | "E" ) sign? digit-sequence
 sign:
 "+" | "-"
 digit-sequence:
 digit
 | digit digit-sequence
 digit:
 "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
 */

/**
 wsp:
 (#x20 | #x9 | #xD | #xA)
 */
+ (void)readWhitespace:(NSScanner *)scanner
{
	/** This log message can be called literally hundreds of thousands of times in a single parse, which defeats
	 even Cocoa Lumberjack.
	 
	 Even in "verbose" debugging, that's too much!
	 
	 Hence: commented-out
	SVGKitLogVerbose(@"Apple's implementation of scanCharactersFromSet seems to generate large amounts of temporary objects and can cause a crash here by taking literally megabytes of RAM in temporary internal variables. This is surprising, but I can't see anythign we're doing wrong. Adding this autoreleasepool drops memory usage (inside Apple's methods!) massively, so it seems to be the right thing to do");
	 */
	@autoreleasepool {
		[scanner scanCharactersFromSet:[NSCharacterSet SVGWhitespaceCharacterSet] intoString:NULL];
	}
}

+ (void)readCommaAndWhitespace:(NSScanner *)scanner
{
    [self readWhitespace:scanner];
    [scanner scanString:@"," intoString:NULL];
    [self readWhitespace:scanner];
}

+ (NSInteger)readFloats:(CGFloat[])values count:(NSInteger)count scanner:(NSScanner *)scanner
{
    NSInteger read = 0;
    while (read < count) {
        
        BOOL success;
        CGFloat value;
#if CGFLOAT_IS_DOUBLE
        success = [scanner scanDouble:&value];
#else
        success = [scanner scanFloat:&value];
#endif
        if (!success) {
            if (read != 0) {
                SVGKitLogWarn(@"Expected zero or %lld values but got %lld.  Remaining string: %@", (long long)count, (long long)read, [scanner.string substringFromIndex:scanner.scanLocation]);
            }
            break;
        }
        
        [self readCommaAndWhitespace:scanner];
        
        values[read++] = value;
    }
    
    return read;
}

+ (BOOL)readFloat:(CGFloat *)value scanner:(NSScanner *)scanner
{
    return [self readFloats:value count:1 scanner:scanner] == 1;
}

+ (BOOL)readPoint:(CGPoint *)value relativeToPoint:(CGPoint)origin scanner:(NSScanner *)scanner
{
    CGFloat floats[2];
    if ([self readFloats:floats count:2 scanner:scanner] == 2) {
        *value = CGPointMake(floats[0] + origin.x, floats[1] + origin.y);
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)readCommand:(NSString *)commandCharacters scanner:(NSScanner *)scanner
{
    NSCharacterSet *cmdFormat = [NSCharacterSet characterSetWithCharactersInString:commandCharacters];
    if ([scanner scanCharactersFromSet:cmdFormat intoString:NULL]) {
        [self readWhitespace:scanner];
        return YES;
    } else {
        SVGKitLogWarn(@"Did not find any of %@.  Remaining string: %@", commandCharacters, [scanner.string substringFromIndex:scanner.scanLocation]);
        return NO;
    }
}

/**
 moveto-drawto-command-groups:
 moveto-drawto-command-group
 | moveto-drawto-command-group wsp* moveto-drawto-command-groups
 */
+ (SVGPathState)readMovetoDrawtoCommandGroups:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
#if VERBOSE_PARSE_SVG_COMMAND_STRINGS
	SVGKitLogVerbose(@"Parsing command string: move-to, draw-to command");
#endif
    
    SVGPathState state = [self readMovetoDrawto:scanner path:path relativeTo:origin isRelative:isRelative];
    [self readWhitespace:scanner];
    
    while ( ! [scanner isAtEnd] && ! state.hasError ) {
        [self readWhitespace:scanner];
        state = [self readMovetoDrawto:scanner path:path relativeTo:origin isRelative:isRelative];
    }
    
    return state;
}

/** moveto-drawto-command-group:
 moveto wsp* drawto-commands?
 */
+ (SVGPathState)readMovetoDrawto:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
    SVGPathState state = [self readMoveto:scanner path:path relativeTo:origin isRelative:isRelative];
    [self readWhitespace:scanner];
    return state;
}

/**
 moveto:
 ( "M" | "m" ) wsp* moveto-argument-sequence
 */
+ (SVGPathState)readMoveto:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
    if (![self readCommand:@"Mm" scanner:scanner]) {
        return SVGPathStateError;
	}
    
    [SVGKPointsAndPathsParser readWhitespace:scanner];
    
    return [self readMovetoArgumentSequence:scanner path:path relativeTo:origin isRelative:isRelative];
}

/** moveto-argument-sequence:
 coordinate-pair
 | coordinate-pair comma-wsp? lineto-argument-sequence
 */
+ (SVGPathState)readMovetoArgumentSequence:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
    CGPoint coord;
    if ( ! [self readPoint:&coord relativeToPoint:origin scanner:scanner] ) {
        return SVGPathStateError;
    }
    
    CGPathMoveToPoint(path, NULL, coord.x, coord.y);
    
#if DEBUG_PATH_CREATION
	SVGKitLogWarn(@"[%@] PATH: MOVED to %2.2f, %2.2f", [SVGKPointsAndPathsParser class], coord.x, coord.y );
#endif
    
    while ( ! [scanner isAtEnd] ) {
        if (isRelative) {
            origin = coord;
        }
        
        if ( ! [self readPoint:&coord relativeToPoint:origin scanner:scanner] ) {
            return SVGPathStateError;
        }
        
        CGPathMoveToPoint(path, NULL, coord.x, coord.y);
        
#if DEBUG_PATH_CREATION
        SVGKitLogWarn(@"[%@] PATH: MOVED to %2.2f, %2.2f", [SVGKPointsAndPathsParser class], coord.x, coord.y );
#endif
    }
        
    return SVGPathStateMakeWithPoint(coord);
}

/** 
 lineto:
 ( "L" | "l" ) wsp* lineto-argument-sequence
 */
+ (SVGPathState)readLinetoCommand:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
#if VERBOSE_PARSE_SVG_COMMAND_STRINGS
	SVGKitLogVerbose(@"Parsing command string: line-to command");
#endif
	
    if (![self readCommand:@"Ll" scanner:scanner]) {
        return SVGPathStateError;
	}
    
    return [self readLinetoArgumentSequence:scanner path:path relativeTo:origin isRelative:isRelative];
}

/** 
 lineto-argument-sequence:
 coordinate-pair
 | coordinate-pair comma-wsp? lineto-argument-sequence
 */
+ (SVGPathState)readLinetoArgumentSequence:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
    CGPoint coord;
    if ( ! [self readPoint:&coord relativeToPoint:origin scanner:scanner] ) {
        return SVGPathStateError;
    }
    
    CGPathAddLineToPoint(path, NULL, coord.x, coord.y);
    
#if DEBUG_PATH_CREATION
	SVGKitLogWarn(@"[%@] PATH: LINE to %2.2f, %2.2f", [SVGKPointsAndPathsParser class], coord.x, coord.y );
#endif
	
	while ( ! [scanner isAtEnd] ) {
        if (isRelative) {
            origin = coord;
        }
        
        if ( ! [self readPoint:&coord relativeToPoint:origin scanner:scanner] ) {
            return SVGPathStateError;
        }
        
        CGPathAddLineToPoint(path, NULL, coord.x, coord.y);
        
#if DEBUG_PATH_CREATION
		SVGKitLogWarn(@"[%@] PATH: LINE to %2.2f, %2.2f", [SVGKPointsAndPathsParser class], coord.x, coord.y );
#endif
	}
    
    return SVGPathStateMakeWithPoint(coord);
}

/**
 quadratic-bezier-curveto:
 ( "Q" | "q" ) wsp* quadratic-bezier-curveto-argument-sequence
 */
+ (SVGPathState)readQuadraticCurvetoCommand:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
#if VERBOSE_PARSE_SVG_COMMAND_STRINGS
	SVGKitLogVerbose(@"Parsing command string: quadratic-bezier-curve-to command");
#endif
	
    if (![self readCommand:@"Qq" scanner:scanner]) {
        return SVGPathStateError;
	}
	
    return [self readQuadraticCurvetoArgumentSequence:scanner path:path relativeTo:origin isRelative:isRelative];
}
/**
 quadratic-bezier-curveto-argument-sequence:
 quadratic-bezier-curveto-argument
 | quadratic-bezier-curveto-argument comma-wsp? quadratic-bezier-curveto-argument-sequence
 */
+ (SVGPathState)readQuadraticCurvetoArgumentSequence:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
    SVGPathState state = [self readQuadraticCurvetoArgument:scanner path:path relativeTo:origin];
    
    while ( ! [scanner isAtEnd] && ! state.hasError ) {
        if (isRelative) { origin = state.point; }
        state = [self readQuadraticCurvetoArgument:scanner path:path relativeTo:origin];
    }
    
    return state;
}

/**
 quadratic-bezier-curveto-argument:
 coordinate-pair comma-wsp? coordinate-pair
 */
+ (SVGPathState)readQuadraticCurvetoArgument:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
	SVGCurve curveResult;
    curveResult.c2 = CGPointZero;
    curveResult.quadratic = YES;
    
    if ( ! [self readPoint:&(curveResult.c1) relativeToPoint:origin scanner:scanner] || ! [self readPoint:&(curveResult.p) relativeToPoint:origin scanner:scanner] ) {
        return SVGPathStateError;
    }
    
    CGPathAddQuadCurveToPoint(path, NULL, curveResult.c1.x, curveResult.c1.y, curveResult.p.x, curveResult.p.y);
#if DEBUG_PATH_CREATION
	SVGKitLogWarn(@"[%@] PATH: QUADRATIC CURVE to (%2.2f, %2.2f)..(%2.2f, %2.2f)", [SVGKPointsAndPathsParser class], curveResult.c1.x, curveResult.c1.y, curveResult.p.x, curveResult.p.y);
#endif
    
    return SVGPathStateMakeWithCurve(curveResult);
}

/**
 smooth-quadratic-bezier-curveto:
 ( "T" | "t" ) wsp* smooth-quadratic-bezier-curveto-argument-sequence
 */
+ (SVGPathState)readSmoothQuadraticCurvetoCommand:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState
{
#if VERBOSE_PARSE_SVG_COMMAND_STRINGS
	SVGKitLogVerbose(@"Parsing command string: smooth-quadratic-bezier-curve-to command");
#endif
    
    if (![self readCommand:@"Tt" scanner:scanner]) {
		NSAssert( FALSE, @"failed to scan smooth quadratic curve to command");
		return SVGPathStateError;
	}
    
    return [self readSmoothQuadraticCurvetoArgumentSequence:scanner path:path relativeTo:origin withPrevState:prevState];
}


/**
 smooth-quadratic-bezier-curveto-argument-sequence:
 smooth-quadratic-bezier-curveto-argument
 | smooth-quadratic-bezier-curveto-argument comma-wsp? smooth-quadratic-bezier-curveto-argument-sequence
 */
+ (SVGPathState)readSmoothQuadraticCurvetoArgumentSequence:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState
{
    SVGPathState state = [self readSmoothQuadraticCurvetoArgument:scanner path:path relativeTo:origin withPrevState:prevState];
    
    while ( ! [scanner isAtEnd] && ! state.hasError ) {
        state = [self readSmoothQuadraticCurvetoArgument:scanner path:path relativeTo:state.point withPrevState:state];
    }
    
    return state;
}

/**
 smooth-quadratic-bezier-curveto-argument:
 coordinate-pair
 */
+ (SVGPathState)readSmoothQuadraticCurvetoArgument:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState
{
    SVGCurve thisCurve;
    thisCurve.quadratic = YES;
    thisCurve.c2 = CGPointZero;
    if ( ! [self readPoint:&(thisCurve.p) relativeToPoint:origin scanner:scanner] ) {
        return SVGPathStateError;
    }
    
    if (SVGPathStateHasCurve(prevState) && prevState.curve.quadratic) {
        CGPoint currentPoint = prevState.curve.p;
        CGPoint controlPoint = prevState.curve.c1;
        thisCurve.c1 = CGPointMake(currentPoint.x+(currentPoint.x-controlPoint.x), currentPoint.y+(currentPoint.y-controlPoint.y));
    } else {
        thisCurve.c1 = prevState.point;
    }
    
    CGPathAddQuadCurveToPoint(path, NULL, thisCurve.c1.x, thisCurve.c1.y, thisCurve.p.x, thisCurve.p.y );
#if DEBUG_PATH_CREATION
	SVGKitLogWarn(@"[%@] PATH: SMOOTH QUADRATIC CURVE to (%2.2f, %2.2f)..(%2.2f, %2.2f)", [SVGKPointsAndPathsParser class], thisCurve.c1.x, thisCurve.c1.y, thisCurve.p.x, thisCurve.p.y );
#endif
	
    return SVGPathStateMakeWithCurve(thisCurve);
}

/**
 curveto:
 ( "C" | "c" ) wsp* curveto-argument-sequence
 */
+ (SVGPathState)readCurvetoCommand:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
#if VERBOSE_PARSE_SVG_COMMAND_STRINGS
	SVGKitLogVerbose(@"Parsing command string: curve-to command");
#endif
    
    if (![self readCommand:@"Cc" scanner:scanner]) {
		NSAssert( FALSE, @"failed to scan curve to command");
		return SVGPathStateError;
	}
    
    return [self readCurvetoArgumentSequence:scanner path:path relativeTo:origin isRelative:isRelative];
}

/**
 curveto-argument-sequence:
 curveto-argument
 | curveto-argument comma-wsp? curveto-argument-sequence
 */
+ (SVGPathState)readCurvetoArgumentSequence:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isRelative:(BOOL)isRelative
{
    SVGPathState state = [self readCurvetoArgument:scanner path:path relativeTo:origin];
    
    while ( ! [scanner isAtEnd] && ! state.hasError ) {
        if (isRelative) { origin = state.point; }
        state = [self readCurvetoArgument:scanner path:path relativeTo:origin];
    }
    
    return state;
}

/**
 curveto-argument:
 coordinate-pair comma-wsp? coordinate-pair comma-wsp? coordinate-pair
 */
+ (SVGPathState)readCurvetoArgument:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
	SVGCurve curveResult;
    curveResult.quadratic = NO;
    if ( ! [self readPoint:&(curveResult.c1) relativeToPoint:origin scanner:scanner] || ! [self readPoint:&(curveResult.c2) relativeToPoint:origin scanner:scanner] || ! [self readPoint:&(curveResult.p) relativeToPoint:origin scanner:scanner]) {
        return SVGPathStateError;
    }
    
    CGPathAddCurveToPoint(path, NULL, curveResult.c1.x, curveResult.c1.y, curveResult.c2.x, curveResult.c2.y, curveResult.p.x, curveResult.p.y);
#if DEBUG_PATH_CREATION
	SVGKitLogWarn(@"[%@] PATH: CURVE to (%2.2f, %2.2f)..(%2.2f, %2.2f)..(%2.2f, %2.2f)", [SVGKPointsAndPathsParser class], curveResult.c1.x, curveResult.c1.y, curveResult.c2.x, curveResult.c2.y, curveResult.p.x, curveResult.p.y);
#endif
    
    return SVGPathStateMakeWithCurve(curveResult);
}

/**
 smooth-curveto:
 ( "S" | "s" ) wsp* smooth-curveto-argument-sequence
 */
+ (SVGPathState)readSmoothCurvetoCommand:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState
{
    if (![self readCommand:@"Ss" scanner:scanner]) {
        return SVGPathStateError;
    }
    
    return [self readSmoothCurvetoArgumentSequence:scanner path:path relativeTo:origin withPrevState:prevState];
}

/**
 smooth-curveto-argument-sequence:
 smooth-curveto-argument
 | smooth-curveto-argument comma-wsp? smooth-curveto-argument-sequence
 */
+ (SVGPathState)readSmoothCurvetoArgumentSequence:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState
{
    SVGPathState state = [self readSmoothCurvetoArgument:scanner path:path relativeTo:origin withPrevState:prevState];
    
    while ( ! [scanner isAtEnd] && ! state.hasError ) {
        state = [self readSmoothCurvetoArgument:scanner path:path relativeTo:state.point withPrevState:state];
    }
    
    return state;
}

/**
 smooth-curveto-argument:
 coordinate-pair comma-wsp? coordinate-pair
 */
+ (SVGPathState)readSmoothCurvetoArgument:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevState:(SVGPathState)prevState
{
    CGPoint coord1, coord2;
    
    if ( ! [self readPoint:&coord1 relativeToPoint:origin scanner:scanner] || ! [self readPoint:&coord2 relativeToPoint:origin scanner:scanner] ) {
        return SVGPathStateError;
    }
	
    SVGCurve thisCurve;
    if (SVGPathStateHasCurve(prevState) && ! prevState.curve.quadratic) {
        // calculate the mirror of the previous control point
        CGPoint currentPoint = prevState.curve.p;
        CGPoint controlPoint = prevState.curve.c2;
        CGPoint mirrorCoord = CGPointMake(currentPoint.x+(currentPoint.x-controlPoint.x), currentPoint.y+(currentPoint.y-controlPoint.y));
        thisCurve = SVGCurveMake(mirrorCoord.x, mirrorCoord.y, coord1.x, coord1.y, coord2.x, coord2.y, NO);
    } else {
        CGPoint currentPoint = prevState.point;
        thisCurve = SVGCurveMake(currentPoint.x, currentPoint.y, coord1.x, coord1.y, coord2.x, coord2.y, NO);
    }
    
    CGPathAddCurveToPoint(path, NULL, thisCurve.c1.x, thisCurve.c1.y, thisCurve.c2.x, thisCurve.c2.y, thisCurve.p.x, thisCurve.p.y);
#if DEBUG_PATH_CREATION
	SVGKitLogWarn(@"[%@] PATH: SMOOTH CURVE to (%2.2f, %2.2f)..(%2.2f, %2.2f)..(%2.2f, %2.2f)", [SVGKPointsAndPathsParser class], thisCurve.c1.x, thisCurve.c1.y, thisCurve.c2.x, thisCurve.c2.y, thisCurve.p.x, thisCurve.p.y );
#endif
	
    return SVGPathStateMakeWithCurve(thisCurve);
}

/**
 vertical-lineto-argument-sequence:
 coordinate
 | coordinate comma-wsp? vertical-lineto-argument-sequence
 */
+ (SVGPathState)readVerticalLinetoArgumentSequence:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    CGFloat yValue;
    if ( ! [self readFloat:&yValue scanner:scanner]) {
        return SVGPathStateError;
    }
    
    do {
        origin = CGPointMake(CGPathGetCurrentPoint(path).x, origin.y + yValue);
        CGPathAddLineToPoint(path, NULL, origin.x, origin.y);
    } while ([self readFloat:&yValue scanner:scanner]);
    
#if DEBUG_PATH_CREATION
	SVGKitLogWarn(@"[%@] PATH: VERTICAL LINE to (%2.2f, %2.2f)", [SVGKPointsAndPathsParser class], coord.x, coord.y );
#endif
    
    return SVGPathStateMakeWithPoint(origin);
}

/**
 vertical-lineto:
 ( "V" | "v" ) wsp* vertical-lineto-argument-sequence
 */
+ (SVGPathState)readVerticalLinetoCommand:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
#if VERBOSE_PARSE_SVG_COMMAND_STRINGS
	SVGKitLogVerbose(@"Parsing command string: vertical-line-to command");
#endif
    
    if (![self readCommand:@"Vv" scanner:scanner]) {
        return SVGPathStateError;
    }
    
    return [SVGKPointsAndPathsParser readVerticalLinetoArgumentSequence:scanner path:path relativeTo:origin];
}

/**
 horizontal-lineto-argument-sequence:
 coordinate
 | coordinate comma-wsp? horizontal-lineto-argument-sequence
 */
+ (SVGPathState)readHorizontalLinetoArgumentSequence:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    CGFloat xValue;
    if ( ! [self readFloat:&xValue scanner:scanner]) {
        return SVGPathStateError;
    }
    
    do {
        origin = CGPointMake(origin.x + xValue, CGPathGetCurrentPoint(path).y);
        CGPathAddLineToPoint(path, NULL, origin.x, origin.y);
    } while ([self readFloat:&xValue scanner:scanner]);
    
#if DEBUG_PATH_CREATION
	SVGKitLogWarn(@"[%@] PATH: HORIZONTAL LINE to (%2.2f, %2.2f)", [SVGKPointsAndPathsParser class], coord.x, coord.y );
#endif
    
    return SVGPathStateMakeWithPoint(origin);
}

/**
 horizontal-lineto:
 ( "H" | "h" ) wsp* horizontal-lineto-argument-sequence
 */
+ (SVGPathState)readHorizontalLinetoCommand:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
#if VERBOSE_PARSE_SVG_COMMAND_STRINGS
	SVGKitLogVerbose(@"Parsing command string: horizontal-line-to command");
#endif
    
    if (![self readCommand:@"Hh" scanner:scanner]) {
        return SVGPathStateError;
    }
	
    return [SVGKPointsAndPathsParser readHorizontalLinetoArgumentSequence:scanner path:path relativeTo:origin];
}

+ (SVGPathState)readCloseCommand:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
#if VERBOSE_PARSE_SVG_COMMAND_STRINGS
	SVGKitLogVerbose(@"Parsing command string: close command");
#endif
    
    if (![self readCommand:@"Zz" scanner:scanner]) {
        return SVGPathStateError;
    }
	
    CGPathCloseSubpath(path);
#if DEBUG_PATH_CREATION
	SVGKitLogWarn(@"[%@] PATH: finished path", [SVGKPointsAndPathsParser class] );
#endif
    
    return SVGPathStateMakeWithPoint(CGPathGetCurrentPoint(path));
}

+ (SVGPathState)readEllipticalArcArguments:(NSScanner *)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{

    if (![self readCommand:@"Aa" scanner:scanner]) {
        return SVGPathStateError;
    }
    
    SVGCurve curve = SVGCurveZero;
    CGFloat parameters[7];
    NSInteger readParameters = [self readFloats:parameters count:7 scanner:scanner];
    
    if (readParameters != 7) {
        SVGKitLogWarn(@"Expected 7 parameters in first pass, got %lld.", (long long)readParameters);
        return SVGPathStateError;
    }
    
    do {
        // need to find the center point of the ellipse from the two points and an angle
        // see http://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes for these calculations
        
        CGPoint currentPt = CGPathGetCurrentPoint(path);
        
        CGFloat x1 = currentPt.x;
        CGFloat y1 = currentPt.y;
        
        CGFloat rx = fabs(parameters[0]);
        CGFloat ry = fabs(parameters[1]);
        CGFloat phi = fmod(parameters[2] * M_PI / 180., 2 * M_PI);
        BOOL largeArcFlag = parameters[3] != 0.;
        BOOL sweepFlag = parameters[4] != 0.;
        CGFloat x2 = parameters[5] + origin.x;
        CGFloat y2 = parameters[6] + origin.y;
        
        curve.p = CGPointMake(x2, y2);
        
        if (rx == 0 || ry == 0)
        {
            CGPathAddLineToPoint(path, NULL, curve.p.x, curve.p.y);
            return SVGPathStateMakeWithPoint(origin); // TODO: This is short circuting and wrong.
        }
        CGFloat cosPhi = cos(phi);
        CGFloat sinPhi = sin(phi);
        
        CGFloat	x1p = cosPhi * (x1-x2)/2. + sinPhi * (y1-y2)/2.;
        CGFloat	y1p = -sinPhi * (x1-x2)/2. + cosPhi * (y1-y2)/2.;
        
        CGFloat lhs;
        {
            CGFloat rx_2 = rx * rx;
            CGFloat ry_2 = ry * ry;
            CGFloat xp_2 = x1p * x1p;
            CGFloat yp_2 = y1p * y1p;
            
            CGFloat delta = xp_2/rx_2 + yp_2/ry_2;
            
            if (delta > 1.0)
            {
                rx *= sqrt(delta);
                ry *= sqrt(delta);
                rx_2 = rx * rx;
                ry_2 = ry * ry;
            }
            CGFloat sign = (largeArcFlag == sweepFlag) ? -1 : 1;
            CGFloat numerator = rx_2 * ry_2 - rx_2 * yp_2 - ry_2 * xp_2;
            CGFloat denom = rx_2 * yp_2 + ry_2 * xp_2;
            
            numerator = MAX(0, numerator);
            
            lhs = sign * sqrt(numerator/denom);
        }
        
        CGFloat cxp = lhs * (rx*y1p)/ry;
        CGFloat cyp = lhs * -((ry * x1p)/rx);
        
        CGFloat cx = cosPhi * cxp + -sinPhi * cyp + (x1+x2)/2.;
        CGFloat cy = cxp * sinPhi + cyp * cosPhi + (y1+y2)/2.;
        
        // transform our ellipse into the unit circle
        
        CGAffineTransform tr = CGAffineTransformMakeScale(1./rx, 1./ry);
        
        tr = CGAffineTransformRotate(tr, -phi);
        tr = CGAffineTransformTranslate(tr, -cx, -cy);
        
        CGPoint arcPt1 = CGPointApplyAffineTransform(CGPointMake(x1, y1), tr);
        CGPoint arcPt2 = CGPointApplyAffineTransform(CGPointMake(x2, y2), tr);
        
        CGFloat startAngle = atan2(arcPt1.y, arcPt1.x);
        CGFloat endAngle = atan2(arcPt2.y, arcPt2.x);
        
        CGFloat angleDelta = endAngle - startAngle;;
        
        if (sweepFlag)
        {
            if (angleDelta < 0)
                angleDelta += 2. * M_PI;
        }
        else
        {
            if (angleDelta > 0)
                angleDelta = angleDelta - 2 * M_PI;
        }
        // construct the inverse transform
        CGAffineTransform trInv = CGAffineTransformMakeTranslation( cx, cy);
        
        trInv = CGAffineTransformRotate(trInv, phi);
        trInv = CGAffineTransformScale(trInv, rx, ry);
        
        // add a inversely transformed circular arc to the current path
        CGPathAddRelativeArc( path, &trInv, 0, 0, 1., startAngle, angleDelta);
        
        origin = CGPathGetCurrentPoint(path);
    } while ((readParameters = [self readFloats:&parameters count:7 scanner:scanner]) == 7);
    
    if (readParameters != 0) {
        SVGKitLogWarn(@"Expected 7 parameters in first pass, got %lld.", (long long)readParameters);
        return SVGPathStateError;
    }

    return SVGPathStateMakeWithPoint(origin);
}

@end
