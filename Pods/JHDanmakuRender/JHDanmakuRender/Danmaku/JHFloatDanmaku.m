//
//  JHFloatDanmaku.m
//  JHDanmakuRenderDemo
//
//  Created by JimHuang on 16/2/22.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "JHFloatDanmaku.h"
#import "JHDanmakuContainer.h"
#import "JHDanmakuEngine+Private.h"

@interface JHFloatDanmaku()
@property (assign, nonatomic) CGFloat during;
@property (assign, nonatomic) JHFloatDanmakuPosition position;
@end

@implementation JHFloatDanmaku
{
    NSInteger _currentChannel;
}

- (instancetype)initWithFontSize:(CGFloat)fontSize textColor:(JHColor *)textColor text:(NSString *)text shadowStyle:(JHDanmakuShadowStyle)shadowStyle font:(JHFont *)font during:(CGFloat)during direction:(JHFloatDanmakuDirection)direction {
    
    if (font == nil) {
        font = [JHFont systemFontOfSize:fontSize];
    }
    
    return [self initWithFont:font text:text textColor:textColor effectStyle:(JHDanmakuEffectStyle)shadowStyle during:direction position:(JHFloatDanmakuPosition)direction];
}

- (instancetype)initWithFont:(JHFont *)font
                        text:(NSString *)text
                   textColor:(JHColor *)textColor
                 effectStyle:(JHDanmakuEffectStyle)effectStyle
                      during:(CGFloat)during
                    position:(JHFloatDanmakuPosition)position {
    if (self = [super initWithFont:font text:text textColor:textColor effectStyle:effectStyle]) {
        _position = position;
        _during = during;
    }
    return self;
}

- (BOOL)updatePositonWithTime:(NSTimeInterval)time container:(JHDanmakuContainer *)container {
    return self.appearTime + _during >= time;
}

/**
 *  找出同方向的弹幕 按照所在轨道归类弹幕
 优先选择没有弹幕的轨道
 如果都有 选择弹幕最少的轨道
 *
 */
- (CGPoint)originalPositonWithEngine:(JHDanmakuEngine *)engine
                                rect:(CGRect)rect
                         danmakuSize:(CGSize)danmakuSize
                      timeDifference:(NSTimeInterval)timeDifference {
    NSMutableDictionary <NSNumber *, NSMutableArray <JHDanmakuContainer *>*>*dic = [NSMutableDictionary dictionary];
    
    NSInteger channelCount = (engine.channelCount == 0) ? [self channelCountWithContentRect:rect danmakuSize:danmakuSize] : engine.channelCount;
    
    //轨道高
    NSInteger channelHeight = [self channelHeightWithChannelCount:channelCount contentRect:rect];
    
    NSMutableArray <JHDanmakuContainer *>*activeContainer = engine.activeContainer;
    
    [activeContainer enumerateObjectsUsingBlock:^(JHDanmakuContainer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.danmaku isKindOfClass:[JHFloatDanmaku class]]) {
            //判断弹幕所在轨道
            NSInteger channel = obj.danmaku.currentChannel;
            
            if (!dic[@(channel)]) dic[@(channel)] = [NSMutableArray array];
            
            [dic[@(channel)] addObject:obj];
        }
    }];
    
    __block NSInteger channel = channelCount - 1;
    //每条轨道都有弹幕
    if (dic.count >= channelCount) {
        __block NSInteger minCount = dic[@(0)].count;
        [dic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray<JHDanmakuContainer *> * _Nonnull obj, BOOL * _Nonnull stop) {
            if (minCount >= obj.count) {
                minCount = obj.count;
                channel = key.intValue;
            }
        }];
    }
    //选择没有弹幕的轨道
    else {
        if (_position == JHFloatDanmakuPositionAtTop) {
            for (NSInteger i = 0; i < channelCount; ++i) {
                if (!dic[@(i)]) {
                    channel = i;
                    break;
                }
            }
        }
        else {
            for (NSInteger i = channelCount - 1; i >= 0; --i) {
                if (!dic[@(i)]) {
                    channel = i;
                    break;
                }
            }
        }
    }
    
    _currentChannel = channel;
    return CGPointMake((rect.size.width - danmakuSize.width) / 2, channelHeight * channel);
}


- (CGFloat)during {
    return _during;
}

- (JHFloatDanmakuDirection)direction {
    return (JHFloatDanmakuDirection)_position;
}

- (NSInteger)currentChannel {
    return _currentChannel;
}

#pragma mark - 私有方法
- (NSInteger)channelCountWithContentRect:(CGRect)contentRect danmakuSize:(CGSize)danmakuSize {
    NSInteger channelCount = contentRect.size.height / danmakuSize.height;
    return channelCount > 4 ? channelCount : 4;
}

- (NSInteger)channelHeightWithChannelCount:(NSInteger)channelCount contentRect:(CGRect)rect {
    return rect.size.height / channelCount;
}

@end

