//
//  NSObject+YJXKVO.m
//  KVO
//
//  Created by Sumang on 2020/8/13.
//  Copyright © 2020 Sumang. All rights reserved.
//

#import "NSObject+YJXKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kSMKVOPrefix = @"SMKVONotifying_";
static NSString *const kSMKVOAssiociateKey = @"kSMKVO_AssiociateKey";

@implementation NSObject (YJXKVO)
- (void)SM_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    // 验证setter
    [self judgeSetterMethodFromKeyPath:keyPath];
    
    //动态生成子类
    Class newClass = [self creatChildClass:keyPath];
    object_setClass(self, newClass);
    
    // // 4: 观察存
       objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kSMKVOAssiociateKey), observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    
    
}

#pragma mark - 动态生成子类
- (Class)creatChildClass:(NSString *)keyPath{
    
    // 2:动态生成子类
    // SMKVO_Person - Person
    NSString *oldName = NSStringFromClass([self class]);
    NSString *newName = [NSString stringWithFormat:@"%@%@",kSMKVOPrefix,oldName];
    Class newClass    = objc_allocateClassPair([self class], newName.UTF8String, 0);
    objc_registerClassPair(newClass);
    
    // 2.1 子类添加一些方法 class setter
    // class
    SEL classSEL = NSSelectorFromString(@"class");
    Method classM= class_getInstanceMethod([self class], classSEL);
    const char *type = method_getTypeEncoding(classM);
    class_addMethod(newClass, classSEL, (IMP)SM_class, type);
    
    // setter setNickName
    SEL setterSEL = NSSelectorFromString(setterForGetter(keyPath));
    Method setterM= class_getInstanceMethod([self class], setterSEL);
    const char *setterType = method_getTypeEncoding(setterM);
    class_addMethod(newClass, setterSEL, (IMP)SM_setter, setterType);
    
    return newClass;
}


#pragma mark -验证是否存在setter方法
- (void)judgeSetterMethodFromKeyPath:(NSString *)keyPath{
    Class superClass    = object_getClass(self);
    SEL setterSeletor   = NSSelectorFromString(setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod(superClass, setterSeletor);
    if (!setterMethod) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"没有当前%@的setter",keyPath] userInfo:nil];
    }
}


#pragma mark - 函数部分

static void SM_setter(id self,SEL _cmd,id newValue){
    
    NSString *keyPath = getterForSetter(NSStringFromSelector(_cmd));

    // 消息发送  setName:
    [self willChangeValueForKey:keyPath];
    
    // newValue给谁  newClass LGperson
    // 给父类发送消息
    
    void (*SM_objc_msgSendSuper)(id,SEL,id,id,void *) = (void *)objc_msgSend;
    
    struct objc_super SM_objc_super = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self)),
    };
    objc_msgSendSuper(&SM_objc_super, _cmd, newValue);
    
    [self didChangeValueForKey:keyPath];
    
    // 响应回调
    // 属性 -- 关联存储
    id observer = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kSMKVOAssiociateKey));
    // 响应
    // sel
    SEL obserSEL = @selector(observeValueForKeyPath:ofObject:change:context:);
    
    SM_objc_msgSendSuper(observer, obserSEL,self,@{keyPath:newValue},NULL);
}




Class SM_class(id self,SEL _cmd){
    // LGPerson
    return class_getSuperclass([self class]); //
}



#pragma mark - 从get方法获取set方法的名称 key ===>>> setKey:
static NSString *setterForGetter(NSString *getter){
    
    if (getter.length <= 0) { return nil;}
    
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *leaveString = [getter substringFromIndex:1];
    
    return [NSString stringWithFormat:@"set%@%@:",firstString,leaveString];
}

#pragma mark - 从set方法获取getter方法的名称 set<Key>:===> key
static NSString *getterForSetter(NSString *setter){
    
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
        
    }
    
    NSRange range = NSMakeRange(3, setter.length-4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    return  [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
}



@end
