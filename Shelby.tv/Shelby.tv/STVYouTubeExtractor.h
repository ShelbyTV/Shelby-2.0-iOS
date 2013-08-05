//
//  STVYouTubeExtractor.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  Use the get_video_info API call directly to obtain video maps.
//  This works fairly well; we are using it as a fallback when scraping the video
//  page directly fails.  But this doesn't seem to work for embed-restricted videos,
//  like Vevo.
//
//  I don't think "extractor" is the right name for this, but it matches the other one
//  we're mimicking, so it's fine for now.

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, STVYouTubeVideoQuality){
    STVYouTubeVideoQualitySmall,
    STVYouTubeVideoQualityMedium,
    STVYouTubeVideoQualityLarge,
    STVYouTubeVideoQualityHD720,
    STVYouTubeVideoQualityHD1080
};

@protocol STVYouTubeExtractorDelegate;

@interface STVYouTubeExtractor : NSObject

@property (nonatomic, readonly) NSString *videoID;
@property (nonatomic, readonly) STVYouTubeVideoQuality quality;
@property (nonatomic, strong, readonly) NSURL *extractedURL;
@property (nonatomic, weak) id <STVYouTubeExtractorDelegate> delegate;

-(id)initWithID:(NSString*)videoID quality:(STVYouTubeVideoQuality)quality;

-(void)startExtracting;
-(void)stopExtracting;

@end

@protocol STVYouTubeExtractorDelegate <NSObject>

-(void)stvYouTubeExtractor:(STVYouTubeExtractor *)extractor didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL;
-(void)stvYouTubeExtractor:(STVYouTubeExtractor *)extractor failedExtractingYouTubeURLWithError:(NSError *)error;

@end