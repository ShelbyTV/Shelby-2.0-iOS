//
//  STVVimeoExtractor.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 10/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "STVVimeoExtractor.h"
#import "AFNetworking.h"
#import "ShelbyAnalyticsClient.h"

static NSString* const kUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3";

static NSString * const kBaseVimeoURL = @"http://vimeo.com";
static NSString * const kVimeoPath = @"/m/%@";
static NSString * const kRefererURL = @"http://vimeo.com/m/%@";

@interface STVVimeoExtractor () {
    AFHTTPClient *_httpClient;
    //dictionaries containing info for a given stream quality
    NSMutableDictionary *_streamMaps;
    NSString *_qualityString;
    BOOL _isCancelled;
}

@property (nonatomic, strong) NSString *videoID;
@property (nonatomic, strong) NSURL* extractedURL;
@property (nonatomic) STVVimeoVideoQuality quality;

@end


@implementation STVVimeoExtractor

- (id)initWithID:(NSString *)videoID quality:(STVVimeoVideoQuality)quality
{
    STVAssert(videoID, @"invalid to initialize without videoID");

    self = [super init];
    if (self) {
        _isCancelled = NO;
        _videoID = videoID;
        _quality = quality;
        _httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kBaseVimeoURL]];
        [_httpClient setDefaultHeader:@"referer" value:[NSString stringWithFormat:kRefererURL, _videoID]];
    }
    return self;
}

- (void)startExtracting
{
    NSURLRequest *req = [_httpClient requestWithMethod:@"GET"
                                                  path:[NSString stringWithFormat:kVimeoPath, _videoID]
                                            parameters:nil];

    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (_isCancelled) {
            return;
        }
        NSString *rawString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];

        NSString *dataConfigURLString = [self scrapeDataConfigURLFromHTML:rawString];
        if (!dataConfigURLString) {
            [self failWithError:nil label:@"Could not scrape data-config-url"];
            return;
        }

        [self processDataConfigURL:dataConfigURLString];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (_isCancelled) {
            return;
        }
        [self failWithError:error label:[NSString stringWithFormat:@"Network op fail, error: %@", error]];
    }];
    [op start];
}

- (void)stopExtracting
{
    _isCancelled = YES;
}

#pragma mark - helpers

- (NSString *)scrapeDataConfigURLFromHTML:(NSString *)rawHTML
{
    if (!rawHTML || rawHTML.length == 0) {
        return nil;
    }

    //the response is a webpage with a tag that contains an HTML5 data parameter "data-config-url"
    NSScanner *scanner = [NSScanner scannerWithString:rawHTML];
    [scanner scanUpToString:@"data-config-url=\"" intoString:nil];
    [scanner scanString:@"data-config-url=\"" intoString:nil];
    NSString *dataConfigURLString = nil;
    [scanner scanUpToString:@"\"" intoString:&dataConfigURLString];

    if (!dataConfigURLString) {
        return nil;
    }

    //turn &amp; into &
    dataConfigURLString = [dataConfigURLString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];

    return dataConfigURLString;
}

- (void)processDataConfigURL:(NSString *)dataConfigURLString
{
    NSURLRequest *req = [self requestForDataConfig:dataConfigURLString];
    if (!req) {
        [self failWithError:nil label:[NSString stringWithFormat:@"could not parse dataConfigURL: %@", dataConfigURLString]];
        return;
    }

    AFJSONRequestOperation *jsonOp = [[AFJSONRequestOperation alloc] initWithRequest:req];
    [jsonOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (_isCancelled) {
            return;
        }
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]] && [self createStreamMapsFromResponse:(NSDictionary *)responseObject]) {
            NSURL *urlFound = [self playbackURLForCurrentSettings];
            if (urlFound) {
                [self.delegate stvVimeoExtractor:self didSuccessfullyExtractVimeoURL:urlFound];
            } else {
                [self failWithError:nil label:[NSString stringWithFormat:@"url not found, raw response: %@", responseObject]];
            }
        } else {
            [self failWithError:nil label:[NSString stringWithFormat:@"bad raw response: %@", responseObject]];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (_isCancelled) {
            return;
        }
        [self failWithError:error label:[NSString stringWithFormat:@"Network op(2) fail, error: %@", error]];
    }];
    [jsonOp start];
}

- (BOOL)createStreamMapsFromResponse:(NSDictionary *)JSONDict
{
    NSDictionary *requestDict = JSONDict[@"request"];
    if (!requestDict) {
        return nil;
    }
    NSDictionary *filesDict = requestDict[@"files"];
    if (!filesDict) {
        return nil;
    }
    NSDictionary *h264Dict = filesDict[@"h264"];
    if (!h264Dict) {
        return nil;
    }
    _streamMaps = [NSMutableDictionary dictionaryWithDictionary:h264Dict];

    NSDictionary *hlsDict = filesDict[@"hls"];
    if (hlsDict) {
        _streamMaps[@"hls"] = @{@"url":hlsDict[@"all"]};
    }

    return YES;
}

- (NSURL *)playbackURLForCurrentSettings
{
    if ([_streamMaps count] == 0) {
        return nil;
    }

    NSDictionary *playbackDict;
    switch (_quality) {
        case STVVimeoVideoQualitySD:
            playbackDict = _streamMaps[@"sd"];
            break;
        case STVVimeoVideoQualityMobile:
            playbackDict = _streamMaps[@"mobile"];
            break;
        case STVVimeoVideoQualityHD:
            playbackDict = _streamMaps[@"hd"];
            break;
        case STVVimeoVideoQualityHLS:
            playbackDict = _streamMaps[@"hls"];
            break;
    }

    if (!playbackDict) {
        //fallback first to mobile, for our purposes
        playbackDict = _streamMaps[@"mobile"];
        //then just fallback to anything
        if (!playbackDict) {
            playbackDict = [_streamMaps valueForKey:[[_streamMaps allKeys] firstObject]];
        }
    }

    return [NSURL URLWithString:playbackDict[@"url"]];
}

- (NSURLRequest *)requestForDataConfig:(NSString *)dataConfigURLString
{
    //dataConfigURLString looks something like "http://player.vimeo.com/v2/video/67076984/config?byline=0&bypass_privacy=1..."
    //Vimeo will not accept requests with a trailing "/" after the path (ie. "...config/?byline=...")
    NSArray *urlComponents = [dataConfigURLString componentsSeparatedByString:@"?"];
    if ([urlComponents count] != 2) {
        return nil;
    }
    NSURL *baseURL = [NSURL URLWithString:((NSString *)urlComponents[0])];
    baseURL = [baseURL URLByDeletingLastPathComponent];
    NSString *path = [((NSString *)urlComponents[0]) lastPathComponent];
    NSString *pathWithParams = [NSString stringWithFormat:@"%@?%@", path, urlComponents[1]];

    _httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [_httpClient setDefaultHeader:@"referer" value:[NSString stringWithFormat:kRefererURL, _videoID]];
    NSURLRequest *req = [_httpClient requestWithMethod:@"GET"
                                                  path:pathWithParams
                                            parameters:nil];
    return req;
}

- (void)failWithError:(NSError *)error label:(NSString *)label
{
    DLog(@"Vimeo Extraction fail; error: %@; label: %@;", error, label);
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                          action:kAnalyticsIssueSTVVimeoExtractorFail
                                           label:label];
    [self.delegate stvVimeoExtractor:self failedExtractingVimeoURLWithError:error];
}

@end
