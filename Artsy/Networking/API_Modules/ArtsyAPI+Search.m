#import "ARLogger.h"
#import "ArtsyAPI+Search.h"

#import "Artist.h"
#import "Gene.h"
#import "ARRouter.h"
#import "SearchResult.h"
#import "SearchSuggestion.h"

#import "MTLModel+JSON.h"
#import "AFHTTPRequestOperation+JSON.h"

static NSString *
EnsureQuery(NSString *query) {
    if (query) {
        NSString *trimmed = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            return trimmed;
        }
    }
    return nil;
}

@implementation ArtsyAPI (Search)

+ (AFHTTPRequestOperation *)searchWithQuery:(NSString *)query success:(void (^)(NSArray *results))success failure:(void (^)(NSError *error))failure
{
    return [self searchWithFairID:nil andQuery:query success:success failure:failure];
}

+ (AFHTTPRequestOperation *)searchWithFairID:(NSString *)fairID andQuery:(NSString *)query success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    NSString *_query = EnsureQuery(query);
    if (!_query) {
        return nil;
    }

    NSParameterAssert(success);

    NSURLRequest *request = fairID ? [ARRouter newSearchRequestWithFairID:fairID andQuery:_query] : [ARRouter newSearchRequestWithQuery:_query];
    AFHTTPRequestOperation *searchOperation = nil;
    searchOperation = [AFHTTPRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSArray *jsonDictionaries = JSON;
        NSMutableArray *returnArray = [NSMutableArray array];

        if (fairID) {
            // Old style obj -> objc class mapping for fair inline-search
            // This is so that when the new version of the FairVC from Emission deprecates the current version
            // we can just delete everything related to `SearchResult` safely, including this code.
            //
            for (NSDictionary *dictionary in jsonDictionaries) {
                if ([SearchResult searchResultIsSupported:dictionary]) {
                    NSError *error = nil;
                    SearchResult *result = [[SearchResult class] modelWithJSON:dictionary error:&error];
                    if (error) {
                        ARErrorLog(@"Error creating search result. Error: %@", error.localizedDescription);
                    } else {
                        [returnArray addObject:result];
                    }
                }
            }
        } else {
            // use "new" suggest API which has all data in response
            for (NSDictionary *dictionary in jsonDictionaries) {
                NSError *error = nil;
                if ([SearchSuggestion searchResultIsSupported:dictionary]) {

                    id result = [SearchSuggestion.class modelWithJSON:dictionary error:&error];

                    if (error) {
                        ARErrorLog(@"Error creating search result. Error: %@", error.localizedDescription);
                    } else {
                        [returnArray addObject:result];
                    }
                }
            }
        }

        success(returnArray);

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failure) {
            failure(error);
        }
    }];

    [searchOperation start];
    return searchOperation;
}

+ (AFHTTPRequestOperation *)artistSearchWithQuery:(NSString *)query excluding:(NSArray *)artistsToExclude success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    NSString *_query = EnsureQuery(query);
    if (!_query) {
        return nil;
    }
    
    NSParameterAssert(success);

    NSURLRequest *request = [ARRouter newArtistSearchRequestWithQuery:_query excluding:artistsToExclude];
    AFHTTPRequestOperation *searchOperation = nil;
    searchOperation = [AFHTTPRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSArray *jsonDictionaries = JSON;
        NSMutableArray *returnArray = [NSMutableArray array];

        for (NSDictionary *dictionary in jsonDictionaries) {
            NSError *error = nil;
            Artist *result = [Artist modelWithJSON:dictionary error:&error];
            if (error) {
                ARErrorLog(@"Error creating search result. Error: %@", error.localizedDescription);
            } else {
                [returnArray addObject:result];
            }
        }

        success(returnArray);

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failure) {
            failure(error);
        }
    }];

    [searchOperation start];
    return searchOperation;
}

+ (AFHTTPRequestOperation *)geneSearchWithQuery:(NSString *)query excluding:(NSArray *)genesToExclude success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    NSString *_query = EnsureQuery(query);
    if (!_query) {
        return nil;
    }

    NSParameterAssert(success);

    NSURLRequest *request = [ARRouter newGeneSearchRequestWithQuery:_query excluding:genesToExclude];
    AFHTTPRequestOperation *searchOperation = nil;
    searchOperation = [AFHTTPRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSArray *jsonDictionaries = JSON;
        NSMutableArray *returnArray = [NSMutableArray array];
        
        for (NSDictionary *dictionary in jsonDictionaries) {
            NSError *error = nil;
            Gene *result = [Gene modelWithJSON:dictionary error:&error];
            if (error) {
                ARErrorLog(@"Error creating search result. Error: %@", error.localizedDescription);
            } else {
                [returnArray addObject:result];
            }
        }
        
        success(returnArray);

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failure) {
            failure(error);
        }
    }];

    [searchOperation start];
    return searchOperation;
}

@end
