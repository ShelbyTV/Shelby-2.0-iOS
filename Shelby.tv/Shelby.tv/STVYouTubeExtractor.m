//
//  STVYouTubeExtractor.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "STVYouTubeExtractor.h"
#import "AFNetworking.h"
#import "ShelbyAnalyticsClient.h"

static NSString* const kUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3";

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
            case STVYouTubeVideoQualityHD720:
                STVAssert(NO, @"HD720 isn't returned reliably");
                _qualityString = @"hd720";
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
    }
    return self;
}

- (void)startExtracting
{
    //these are the query params YouTube mobile (iPhone) pages send as of 8/5/2013
    NSDictionary *queryParams = @{@"html5": @"1",
                                  @"video_id": _videoID,
                                  @"cpn": [self generateCPN],
                                  @"eurl": @"unknown",
                                  @"ps": @"native",
                                  @"el": @"embedded",
                                  @"hl": @"en_US",
                                  @"sts": @"15917",
                                  //this width and height seem to work okay... but...
                                  //we get back a bunch of medium/small quality videos
                                  //not sure how to get large yet :-/
                                  @"width": @"640", //iphone5: @"640", //phad: @"1536"
                                  @"height": @"959",//iphone5: @"1136", //ipad: @"2048"
                                  @"c": @"web",
                                  @"cver": @"html5"};
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
            NSURL *urlFound = [self playbackURLForCurrentSettings];
            if (urlFound) {
                [self.delegate stvYouTubeExtractor:self didSuccessfullyExtractYouTubeURL:urlFound];
            } else {
                [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                      action:kAnalyticsIssueSTVExtractorFail
                                                       label:[NSString stringWithFormat:@"url not found, raw string: %@", rawString]];
                [self.delegate stvYouTubeExtractor:self failedExtractingYouTubeURLWithError:nil];
            }
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
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                              action:kAnalyticsIssueSTVExtractorFail
                                               label:[NSString stringWithFormat:@"Network op fail, error: %@", error]];
        [self.delegate stvYouTubeExtractor:self failedExtractingYouTubeURLWithError:error];
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

- (NSURL *)playbackURLForCurrentSettings
{
    if (!_streamMaps) {
        return nil;
    }
    NSString *possibleUrl;

    for (NSDictionary *streamMap in _streamMaps) {
        if (streamMap[@"url"] && streamMap[@"sig"] && streamMap[@"type"] && [streamMap[@"type"] rangeOfString:@"mp4"].location != NSNotFound ) {
            possibleUrl = [NSString stringWithFormat:@"%@&signature=%@", streamMap[@"url"], streamMap[@"sig"]];
            //we can play this back... is it the right quality?
            if (streamMap[@"quality"] && [streamMap[@"quality"] isEqualToString:_qualityString]) {
                return [NSURL URLWithString:possibleUrl];
            }
        }
    }

    //we didn't return the quality we wanted, return a fallback
    if (possibleUrl) {
        return [NSURL URLWithString:possibleUrl];
    }
    return nil;
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
