//
//  DDFileSendAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-9.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDFileSendAPI.h"
#import "DDFileEntity.h"
@implementation DDFileSendAPI
/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutTimeInterval
{
    return 10;
}

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID
{
    return MODULE_ID_FILETRANSFER;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_FILETRANSFER;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_FILE_REQUEST;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_FILE_RESPONSE;
}

/**
 *  解析数据的block
 *
 *  @return 解析数据的block
 */
- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSData* data)
    {
        DataInputStream *inputData = [DataInputStream dataInputStreamWithData:data];
        int result = [inputData readInt];
        NSDictionary* info = nil;
        if (result == 0)
        {
            NSString* fromUserID = [inputData readUTF];
            NSString* toUserID = [inputData readUTF];
            NSString* fileName = [inputData readUTF];
            NSString* taskID = [inputData readUTF];
            NSString* ip = [inputData readUTF];
            uint16 port = [inputData readShort];
            info = @{@"fromUserID":fromUserID,
                       @"toUserID":toUserID,
                       @"fileName":fileName,
                         @"taskID":taskID,
                             @"ip":ip,
                           @"port":@(port)};
            return info;
        }
        return info;
    };
    return analysis;
}

/**
 *  打包数据的block
 *
 *  @return 打包数据的block
 */
- (Package)packageRequestObject
{
    Package package = (id)^(id object,uint16_t seqNo)
    {
        
        NSArray* array = (NSArray*)object;
        NSString* fromUserId = array[0];
        NSString* toUserId = array[1];
        NSString* fileName = array[2];
        uint32_t fileSize = [array[3] intValue];
        
        
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = IM_PDU_HEADER_LEN + 4 * 4 +
        strLen(fromUserId) + strLen(toUserId) + strLen(fileName);
        
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_FILETRANSFER cId:CMD_FILE_REQUEST seqNo:seqNo];
        [dataout writeUTF:fromUserId];
        [dataout writeUTF:toUserId];
        [dataout writeUTF:fileName];
        [dataout writeInt:fileSize];
        log4CInfo(@"serviceID:%i cmdID:%i --> get file request from user:%@ to user:%@ fileName:%@ fileSize:%i",MODULE_ID_FILETRANSFER,CMD_FILE_REQUEST,fromUserId,toUserId,fileName,fileSize);
        return [dataout toByteArray];
    };
    return package;
}
@end
