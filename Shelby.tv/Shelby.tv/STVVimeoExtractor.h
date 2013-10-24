//
//  STVVimeoExtractor.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 10/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, STVVimeoVideoQuality){
    STVVimeoVideoQualitySD,
    STVVimeoVideoQualityMobile,
    STVVimeoVideoQualityHD,
    STVVimeoVideoQualityHLS
};

@protocol STVVimeoExtractorDelegate;

@interface STVVimeoExtractor : NSObject

@property (nonatomic, readonly) NSString *videoID;
@property (nonatomic, readonly) STVVimeoVideoQuality quality;
@property (nonatomic, strong, readonly) NSURL *extractedURL;
@property (nonatomic, weak) id <STVVimeoExtractorDelegate> delegate;

-(id)initWithID:(NSString*)videoID quality:(STVVimeoVideoQuality)quality;

-(void)startExtracting;
-(void)stopExtracting;

@end

@protocol STVVimeoExtractorDelegate <NSObject>

-(void)stvVimeoExtractor:(STVVimeoExtractor *)extractor didSuccessfullyExtractVimeoURL:(NSURL *)videoURL;
-(void)stvVimeoExtractor:(STVVimeoExtractor *)extractor failedExtractingVimeoURLWithError:(NSError *)error;

@end
