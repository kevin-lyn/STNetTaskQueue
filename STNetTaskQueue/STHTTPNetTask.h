//
//  STHTTPNetTask.h
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTask.h"

// Error domains
FOUNDATION_EXPORT NSString *const STHTTPNetTaskServerError;
FOUNDATION_EXPORT NSString *const STHTTPNetTaskResponseParsedError;

// Error "userInfo" key
FOUNDATION_EXPORT NSString *const STHTTPNetTaskErrorStatusCodeUserInfoKey;
FOUNDATION_EXPORT NSString *const STHTTPNetTaskErrorResponseDataUserInfoKey;

FOUNDATION_EXPORT NSString *STHTTPNetTaskRequestObjectDefaultSeparator;

typedef NS_ENUM(NSUInteger, STHTTPNetTaskMethod) {
    STHTTPNetTaskGet,
    STHTTPNetTaskPost,
    STHTTPNetTaskPut,
    STHTTPNetTaskDelete,
    STHTTPNetTaskHead,
    STHTTPNetTaskPatch
};

typedef NS_ENUM(NSUInteger, STHTTPNetTaskRequestType) {
    STHTTPNetTaskRequestJSON,
    STHTTPNetTaskRequestKeyValueString,
    STHTTPNetTaskRequestFormData
};

typedef NS_ENUM(NSUInteger, STHTTPNetTaskResponseType) {
    STHTTPNetTaskResponseJSON,
    STHTTPNetTaskResponseString,
    STHTTPNetTaskResponseRawData
};

/*
 If a class conforms to this protocol, it means the instance of this class will be converted to a dictionary and passed as parameter in a HTTP request.
 */
@protocol STHTTPNetTaskRequestObject <NSObject>

/* 
 Properties which should be ignored when packing parameters for reqeust.
 
 @return NSArray An array of strings representing the name of properties to be ignored.
 */
- (NSArray *)ignoredProperties;

@optional

/*
 Separator string which should be used when packing parameters.
 E.g. property schoolName will be converted to school_name.
 Default: @"_"
 
 @return NSString
 */
- (NSString *)parameterNameSeparator;

@end

/*
 Net task which is designed for HTTP protocol.
 */
@interface STHTTPNetTask : STNetTask<STHTTPNetTaskRequestObject>

/*
 HTTP method which should be used for the HTTP net task.
 
 @return STHTTPNetTaskMethod
 */
- (STHTTPNetTaskMethod)method;

/*
 Request parameters format. E.g JSON, key-value string(form param).
 
 @return STHTTPNetTaskRequestType
 */
- (STHTTPNetTaskRequestType)requestType;

/*
 Response data format. E.g JSON, String, Raw data.
 
 @return STHTTPNetTaskResponseType
 */
- (STHTTPNetTaskResponseType)responseType;

/*
 Custom headers which will be added into HTTP request headers.
 
 @return NSDictionary<NSString, NSString> Custom headers, e.g. @{ @"User-Agent": @"STNetTaskQueue Client" }
 */
- (NSDictionary *)headers;

/*
 Additional parameters which will be added as HTTP request parameters.
 
 @return NSDictionary<NSString, id>
 */
- (NSDictionary *)parameters;

/*
 NSDatas which will be added into multi-part form data body,
 requestType should be STHTTPNetTaskRequestFormData if you are going to return datas.
 
 @return NSDictionary<NSString, NSData>
 */
- (NSDictionary *)datas;

/*
 This method will be called if the response object is a dictionary.
 
 @param dictionary NSDictionary
 */
- (void)didResponseDictionary:(NSDictionary *)dictionary;

/*
 This method will be called if the response object is an array.
 
 @param array NSArray
 */
- (void)didResponseArray:(NSArray *)array;

/*
 This method will be called if the response obejct is a string.
 
 @param string NSString
 */
- (void)didResponseString:(NSString *)string;

/*
 This method will be called if the response object is NSData
 
 @param data NSData
 */
- (void)didResponseData:(NSData *)data;

@end
