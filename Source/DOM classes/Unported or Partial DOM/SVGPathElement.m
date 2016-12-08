//
//  SVGPathElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGPathElement.h"

#import "SVGUtils.h"
#import "SVGKPointsAndPathsParser.h"

#import "SVGElement_ForParser.h" // to resolve Xcode circular dependencies; in long term, parsing SHOULD NOT HAPPEN inside any class whose name starts "SVG" (because those are reserved classes for the SVG Spec)

@interface SVGPathElement ()

- (void) parseData:(NSString *)data;

@end

@implementation SVGPathElement

- (void)postProcessAttributesAddingErrorsTo:(SVGKParseResult *)parseResult
{
	[super postProcessAttributesAddingErrorsTo:parseResult];
	
	[self parseData:[self getAttribute:@"d"]];
}

- (void)parseData:(NSString *)data
{
	CGMutablePathRef path = CGPathCreateMutable();
    NSScanner* dataScanner = [NSScanner scannerWithString:data];
    SVGPathState lastState = SVGPathStateMakeWithPoint(CGPointZero);
    BOOL foundCmd;
    
    NSCharacterSet *knownCommands = [NSCharacterSet characterSetWithCharactersInString:@"MmLlCcVvHhAaSsQqTtZz"];
    NSString* command;
    
    do {
        
        command = nil;
        foundCmd = [dataScanner scanCharactersFromSet:knownCommands intoString:&command];
        
        if (command.length > 1) {
            // Take only one char (it can happen that multiple commands are consecutive, as "ZM" - so we only want to get the "Z")
            const NSUInteger tooManyChars = command.length-1;
            command = [command substringToIndex:1];
            [dataScanner setScanLocation:([dataScanner scanLocation] - tooManyChars)];
        }
        
        if (foundCmd) {
            if ([@"z" isEqualToString:command] || [@"Z" isEqualToString:command]) {
                lastState = [SVGKPointsAndPathsParser readCloseCommand:[NSScanner scannerWithString:command]
                                                                  path:path
                                                            relativeTo:lastState.point];
            } else {
                NSString *cmdArgs = nil;
                BOOL foundParameters = [dataScanner scanUpToCharactersFromSet:knownCommands
                                                                   intoString:&cmdArgs];
                
                if (foundParameters) {
                    NSString* commandWithParameters = [command stringByAppendingString:cmdArgs];
                    NSScanner* commandScanner = [NSScanner scannerWithString:commandWithParameters];
                    
                    if ([@"m" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readMovetoDrawtoCommandGroups:commandScanner
                                                                        path:path
                                                                  relativeTo:lastState.point
										  isRelative:TRUE];
                    } else if ([@"M" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readMovetoDrawtoCommandGroups:commandScanner
                                                                        path:path
                                                                  relativeTo:CGPointZero
										  isRelative:FALSE];
                    } else if ([@"l" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readLinetoCommand:commandScanner
                                                            path:path
                                                      relativeTo:lastState.point
										  isRelative:TRUE];
                    } else if ([@"L" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readLinetoCommand:commandScanner
                                                            path:path
                                                      relativeTo:CGPointZero
										  isRelative:FALSE];
                    } else if ([@"v" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readVerticalLinetoCommand:commandScanner
                                                                    path:path
                                                              relativeTo:lastState.point];
                    } else if ([@"V" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readVerticalLinetoCommand:commandScanner
                                                                    path:path
                                                      relativeTo:CGPointZero];
                    } else if ([@"h" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readHorizontalLinetoCommand:commandScanner
                                                                      path:path
                                                                relativeTo:lastState.point];
                    } else if ([@"H" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readHorizontalLinetoCommand:commandScanner
                                                                      path:path
                                                                relativeTo:CGPointZero];
                    } else if ([@"c" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readCurvetoCommand:commandScanner
                                                        path:path
                                                  relativeTo:lastState.point
												  isRelative:TRUE];
                    } else if ([@"C" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readCurvetoCommand:commandScanner
                                                        path:path
                                                  relativeTo:CGPointZero
									 isRelative:FALSE];
                    } else if ([@"s" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readSmoothCurvetoCommand:commandScanner
                                                              path:path
                                                        relativeTo:lastState.point
                                                     withPrevState:lastState];
                    } else if ([@"S" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readSmoothCurvetoCommand:commandScanner
                                                              path:path
                                                                            relativeTo:CGPointZero
                                                                         withPrevState:lastState];
                    } else if ([@"q" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readQuadraticCurvetoCommand:commandScanner
                                                                            path:path
                                                                      relativeTo:lastState.point
                                                                      isRelative:YES];
                    } else if ([@"Q" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readQuadraticCurvetoCommand:commandScanner
                                                                            path:path
                                                                      relativeTo:CGPointZero
                                                                      isRelative:NO];
					} else if ([@"t" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readSmoothQuadraticCurvetoCommand:commandScanner
                                                                                           path:path
                                                                                     relativeTo:lastState.point
                                                                                  withPrevState:lastState];
                    } else if ([@"T" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readSmoothQuadraticCurvetoCommand:commandScanner
																				  path:path
                                                                                     relativeTo:CGPointZero
                                                                                  withPrevState:lastState];
					} else if ([@"a" isEqualToString:command]) {
                        lastState = [SVGKPointsAndPathsParser readEllipticalArcArguments:commandScanner
                                                                                    path:path
                                                                              relativeTo:lastState.point];
					}  else if ([@"A" isEqualToString:command]) {
						lastState = [SVGKPointsAndPathsParser readEllipticalArcArguments:commandScanner
                                                                                         path:path
                                                                                   relativeTo:CGPointZero];
					} else  {
                        SVGKitLogWarn(@"unsupported command %@", command);
                        lastState = SVGPathStateError;
                    }
                }
            }
        }
        
    } while (foundCmd && ! lastState.hasError);
	
    
	self.pathForShapeInRelativeCoords = path;
	CGPathRelease(path);
}

@end
