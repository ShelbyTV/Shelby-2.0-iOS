//
//  STVYouTubeExtractor.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "STVYouTubeExtractor.h"
#import <AVFoundation/AVFoundation.h>
#import "AFNetworking.h"
#import "ShelbyAnalyticsClient.h"

static NSString * const kYouTubeRequestURL = @"https://www.youtube.com/get_video_info";
static NSString * const kRefererURL = @"http://www.youtube.com/watch?v=%@";

@interface STVYouTubeExtractor () {
    AFHTTPClient *_httpClient;
    //an array of dictionaries, each contianing info for a given stream
    NSMutableArray *_streamMaps;
    NSString *_qualityString;
    //cpn is a randomimzed parameter sent with request to get video info
    NSArray *_cpnChars;
    BOOL _isCancelled;
}

@property (nonatomic, strong) NSString *videoID;
@property (nonatomic, strong) NSURL* extractedURL;
@property (nonatomic) STVYouTubeVideoQuality quality;

@property (nonatomic, strong) NSMutableArray *elValues;

@end

@implementation STVYouTubeExtractor

- (id)initWithID:(NSString *)videoID quality:(STVYouTubeVideoQuality)quality
{
    STVAssert(videoID, @"invalid to initialize without videoID");
    
    self = [super init];
    if (self) {
        _isCancelled = NO;
        _videoID = videoID;
        _quality = quality;
        switch (_quality) {
            case STVYouTubeVideoQualityHD1080:
                STVAssert(NO, @"HD1080 isn't returned reliably");
                _qualityString = @"hd1080";
                break;
            case STVYouTubeVideoQualityHD720:
                _qualityString = @"hd720";
                break;
            case STVYouTubeVideoQualityLarge:
                STVAssert(NO, @"Large isn't returned reliably");
                _qualityString = @"large";
                break;
            case STVYouTubeVideoQualityMedium:
                _qualityString = @"medium";
                break;
            case STVYouTubeVideoQualitySmall:
                _qualityString = @"small";
        }
        _streamMaps = [@[] mutableCopy];
        _httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kYouTubeRequestURL]];
        [_httpClient setDefaultHeader:@"referer" value:[NSString stringWithFormat:kRefererURL, _videoID]];
        
        //cycle these values to improve odds of extracing URL for different types of video
        _elValues = [@[@"embedded", @"detailpage", @"vevo", @""] mutableCopy];
    }
    return self;
}

- (void)startExtracting
{
    if ([self.elValues count] == 0) {
        //no more to try, fail
        if (_isCancelled) {
            return;
        }
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                              action:kAnalyticsIssueSTVExtractorFail
                                               label:@"Exhausted elValues; No valid streams."];
        [self.delegate stvYouTubeExtractor:self failedExtractingYouTubeURLWithError:nil];
    }
    
    //smaller set of params seems to work just as well
    //check blame on this line to go back in time and view more params
    NSDictionary *queryParams = @{@"video_id": _videoID,
                                  @"el": [self.elValues firstObject],
                                  @"ps": @"default",
                                  @"eurl": @"",
                                  @"gl": @"US",
                                  @"hl": @"en_US"};
    [self.elValues removeObjectAtIndex:0];
    
    NSURLRequest *req = [_httpClient requestWithMethod:@"GET"
                                                  path:nil
                                            parameters:queryParams];

    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (_isCancelled) {
            return;
        }
        NSString *rawString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];

        if (rawString && [self createStreamMapsFromResponse:rawString]) {
            NSArray *urlsFound = [self playbackURLsForCurrentSettings];
            if (urlsFound) {
                [self.delegate stvYouTubeExtractor:self didSuccessfullyExtractYouTubeURLs:urlsFound];
                
            } else if ([self.elValues count] > 0 && !_isCancelled) {
                [self startExtracting];
                
            } else {
                [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                      action:kAnalyticsIssueSTVExtractorFail
                                                       label:[NSString stringWithFormat:@"url not found, raw string: %@", rawString]];
                [self.delegate stvYouTubeExtractor:self failedExtractingYouTubeURLWithError:nil];
            }
            
        } else if ([self.elValues count] > 0 && !_isCancelled) {
            [self startExtracting];
            
        } else {
            [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                  action:kAnalyticsIssueSTVExtractorFail
                                                   label:[NSString stringWithFormat:@"bad raw string: %@", rawString]];
            [self.delegate stvYouTubeExtractor:self failedExtractingYouTubeURLWithError:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (_isCancelled) {
            return;
        }
        if ([self.elValues count] > 0) {
            [self startExtracting];
            
        } else {
            [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                  action:kAnalyticsIssueSTVExtractorFail
                                                   label:[NSString stringWithFormat:@"Network op fail, error: %@", error]];
            [self.delegate stvYouTubeExtractor:self failedExtractingYouTubeURLWithError:error];
        }
    }];
    [op start];
}

- (void)stopExtracting
{
    _isCancelled = YES;
}

#pragma mark - helpers

- (BOOL)createStreamMapsFromResponse:(NSString *)rawResponse
{
    //the response is query string formatted, we want the value of "stream_map"
    NSScanner *scanner = [NSScanner scannerWithString:rawResponse];
    [scanner scanUpToString:@"stream_map=" intoString:nil];
    [scanner scanString:@"stream_map=" intoString:nil];
    NSString *urlEncodedStreamMap = nil;
    [scanner scanUpToString:@"&" intoString:&urlEncodedStreamMap];

    if (!urlEncodedStreamMap) {
        return NO;
    }

    NSString *commaDelineatedStreamMap = [self urlDecode:urlEncodedStreamMap];
    //commaDelineatedStreamMap looks like "<video quality set 1>,<video quality set 2>,..."

    NSArray *rawStreamMaps = [commaDelineatedStreamMap componentsSeparatedByString:@","];
    //each rawStreamMap looks like a query string (ie. ampersand separated)

    for (NSString *streamMapQueryString in rawStreamMaps) {
        NSArray *streamMapElements = [streamMapQueryString componentsSeparatedByString:@"&"];
        //streamMapElements is essentially a dictionary, each elemenet has the form "<key>=<value>"...

        NSMutableDictionary *streamMapsDict = [@{} mutableCopy];
        for (NSString *streamMapElement in streamMapElements) {
            NSArray *dictEntry = [streamMapElement componentsSeparatedByString:@"="];
            if ([dictEntry count] == 2) {
                streamMapsDict[dictEntry[0]] = [self urlDecode:dictEntry[1]];
            }
        }

        [_streamMaps addObject:streamMapsDict];
    }

    [self normalizeStreamMaps];
    //_streamMaps is now an array of dictionaries with important keys like "quality", "type", "url" and "sig"

    return YES;
}

- (NSArray *)playbackURLsForCurrentSettings
{
    if (!_streamMaps) {
        return nil;
    }
    
    NSMutableArray *orderedURLs = [NSMutableArray new];

    for (NSDictionary *streamMap in _streamMaps) {
        BOOL isStereo3d = (streamMap[@"stereo3d"] && [streamMap[@"stereo3d"] isEqualToString:@"1"]);
        if (streamMap[@"url"] && streamMap[@"sig"] && streamMap[@"type"] && [AVURLAsset isPlayableExtendedMIMEType:streamMap[@"type"]] && !isStereo3d) {
            NSString *possibleUrl = [NSString stringWithFormat:@"%@&signature=%@", streamMap[@"url"], streamMap[@"sig"]];
            //we can play this back... put it at head of line if it's the right quality
            if (streamMap[@"quality"] && [streamMap[@"quality"] isEqualToString:_qualityString]) {
                [orderedURLs insertObject:[NSURL URLWithString:possibleUrl] atIndex:0];
            } else {
                [orderedURLs addObject:[NSURL URLWithString:possibleUrl]];
            }
        }
    }

    return orderedURLs;
}

- (NSString *)urlDecode:(NSString *)urlEncoded
{
    return [[urlEncoded stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)generateCPN
{
    //CPN is 16 random characters from a base 64 set
    if (!_cpnChars) {
        _cpnChars =  @[@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"-", @"_"];
    }
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)], _cpnChars[arc4random_uniform(64)]];
}

- (void)normalizeStreamMaps
{
    for (NSMutableDictionary *streamMap in _streamMaps) {
        //have seen stream map having key "s" instead of "sig"
        if (!streamMap[@"sig"] && streamMap[@"s"]) {
            streamMap[@"sig"] = streamMap[@"s"];
        }
    }
}

@end
