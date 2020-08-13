//
//  ViewController.m
//  KVO
//
//  Created by Sumang on 2020/8/13.
//  Copyright © 2020 Sumang. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import <objc/runtime.h>
#import "NSObject+YJXKVO.h"

@interface ViewController ()
@property (nonatomic,strong) Person * person;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.person = [[Person alloc] init];
    NSKeyValueObservingOptions  options =  NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;
 //  [self.person addObserver:self forKeyPath:@"name" options:options context:NULL];
    [self.person SM_addObserver:self forKeyPath:@"name" options:options context:NULL];
      self.person.name = @"kobe";
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.person.name = [NSString stringWithFormat:@"+"];
    [self printClasses:[Person class]];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%@", change);
}


#pragma mark -遍历类以及子类
- (void)printClasses :(Class)cls {
    //注册类的总数
    int count = objc_getClassList(NULL, 0);
    //创建一个数组，其中包含给对象
    NSMutableArray * mArray = [NSMutableArray arrayWithObject:cls];
    //获取所有注册的类
    Class * classes = (Class*)malloc(sizeof(Class) * count);
    objc_getClassList(classes, count);
    for (int i = 0; i < count; i++) {
        if (cls == class_getSuperclass(classes[i])) {
            [mArray addObject:classes[i]];
        }
    }
    free(classes);
    NSLog(@"%@", mArray);
    
}


- (void)dealloc
{
    [self.person removeObserver:self forKeyPath:@"name"];
}

@end
