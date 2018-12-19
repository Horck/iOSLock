//
//  ViewController.m
//  IosLock
//  作者：Inlight先森
//  链接：https://www.jianshu.com/p/bd25479b7cd1
//  來源：简书
//  Created by 华融 on 2018/12/18.
//  Copyright © 2018年 Huarong Comsumer Finance. All rights reserved.
//

#import "ViewController.h"

#import <pthread.h>

#import <libkern/OSAtomic.h>

#import <os/lock.h>


@interface ViewController ()
@property(atomic,copy)NSString *atomicTest;
@property(nonatomic, copy) NSString *name;
// 火车票数量
@property(assign, nonatomic) NSInteger count;
@property(strong, nonatomic) NSLock *lock;
@end

@implementation ViewController
/* 线程中8大锁
@synchronized

NSLock 对象锁

NSRecursiveLock 递归锁

NSConditionLock 条件锁

pthread_mutex 互斥锁（C语言）

dispatch_semaphore 信号量实现加锁（GCD）

OSSpinLock 自旋锁
 
os_unfair_lock 
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


/*
 nonatomic 不会对生成的 getter、setter 方法加同步锁（非原子性）
 atomic 会对生成的 getter 、setter 加同步锁（原子性）
 setter / getter 被 atomic 修饰的属性时，该属性是读写安全的。然而读写安全并不代表线程安全
 // 结果中会出现 AT1-----> AT2 或者 AT2-----> AT1 的打印
 */
- (IBAction)atomicTest:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i =0; i<1000; i++) {
            self.atomicTest = @"AT1";
            NSLog(@"AT1-----> %@", self.atomicTest);

        }
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i =0; i<1000; i++) {
            self.atomicTest = @"AT2";
            NSLog(@"AT2-----> %@", self.atomicTest);
            
        }
    });
}

/* 1 同步锁 @sychronized
 @synchronized(self) 指令使用的 self 为该锁的唯一标识，只有当标识相同时，才为满足互斥，如果线程2中的 self 改成其它对象，线程2就不会被阻塞。
 @synchronized 指令实现锁的优点就是我们不需要在代码中显式的创建锁对象，便可以实现锁的机制，但作为一种预防措施，@synchronized 块会隐式的添加一个异常处理来保护代码，该处理会在异常抛出的时候自动的释放互斥锁。所以如果不想让隐式的异常处理例程带来额外的开销，你可以考虑使用锁对象。

*/
- (IBAction)sychronizedAction:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {
            self.name = @"线程1";
            sleep(3);
            NSLog(@"sychronized  线程结束值是---->%@",self.name);
        }
    });
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {
            self.name = @"线程2";
            NSLog(@"sychronized 线程2结束值是---->%@",self.name);
        }
        
    });
}
/*
 NSLock 简单的互斥锁过 NSLocking 协议定义了 lock 和 unlock 方法。
 
 */
-(IBAction) nsLockAction:(id)sender
{
    // 初始化6张票
    self.count = 6;
    self.lock = [[NSLock alloc] init];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self saleAction];
    });
    
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [self saleAction];
    });

}

- (void)saleAction
{
    while (1) {
        sleep(1);
        // 锁上
        [self.lock lock];
        // 开始卖票
        if (self.count >=1) {
            self.count --;
            NSLog(@"nsLock  开始买票了剩余票数 ---->%ld  当前线程-->%@",self.count,[NSThread currentThread]);
        }else
        {
            NSLog(@"nsLock 票卖没了  当前线程-->%@",[NSThread currentThread]);
            break;
        }
        [self.lock unlock];
        
    }
    
}
/*
 NSRecursiveLock 递归锁 NSLock在递归中反复执行锁会造成死锁
 
 使用递归锁可以在一个线程中反复获取锁而不造成死锁，这个过程中会记录获取锁和释放锁的次数，只有最后两者平衡锁才被最终释放。
 
 */
- (IBAction)recursiveLockAction:(id)sender
{
    NSRecursiveLock *recursiveLock = [[NSRecursiveLock alloc] init];
    
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
       
        static void (^testMethod)(int);
        
        testMethod = ^(int value)
        {
            [recursiveLock lock];
            if (value > 0) {
                [NSThread sleepForTimeInterval:1];
                value--;
                NSLog(@" recursiveLock  value值是----> %d",value);
                testMethod(value);
            }
            [recursiveLock unlock];
            
        };
        
        testMethod(5);
        NSLog(@"  recursiveLock  结束了--------");
    });
}

/*
 NSCoditionLock 做多线程之间的任务等待调用，而且是线程安全的。
 NSConditionLock 也跟其它的锁一样，是需要 lock 与 unlock 对应的，只是 lock , lockWhenCondition: 与 unlock ，unlockWithCondition: 是可以随意组合的，当然这是与需求相关的。
 */
- (IBAction)conditionLockAction:(id)sender
{
    NSInteger HAS_DATA = 1;
    NSInteger NO_DATA = 0;
    
    NSConditionLock *_conditionLock = [[NSConditionLock alloc] initWithCondition:NO_DATA];
    NSMutableArray *products = [NSMutableArray array];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            [_conditionLock lockWhenCondition:NO_DATA];
            [products addObject:[[NSObject alloc] init]];
            NSLog(@"conditionLock  生产");
            [_conditionLock unlockWithCondition:HAS_DATA];
            sleep(5);
        }
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            NSLog(@"conditionLock 等待");
            [_conditionLock lockWhenCondition:HAS_DATA];
            [products removeObjectAtIndex:0];
            NSLog(@"conditionLock 售卖");
            [_conditionLock unlockWithCondition:NO_DATA];
        }
    });
    
}

/*
 POSIX(pthread_mutex)
 C语言定义下多线程加锁方式。 pthread_mutex 和 dispatch_semaphore_t 很像，但是完全不同。pthread_mutex 是Unix/Linux平台上提供的一套条件互斥锁的API。
 新建一个简单的 pthread_mutex 互斥锁，引入头文件 #import <pthread.h> 声明并初始化一个 pthread_mutex_t 的结构。使用 pthread_mutex_lock 和 pthread_mutex_unlock 函数。调用 pthread_mutex_destroy 来释放该锁的数据结构。
 
 */
-(IBAction)posixAction:(id)sender
{
    __block pthread_mutex_t theLock;
    pthread_mutex_init(&theLock, NULL);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        pthread_mutex_lock(&theLock);
        NSLog(@"pthread_mutex 第一个线程同步操作开始");
        sleep(3);
        NSLog(@"pthread_mutex 第一个线程同步操作结束");
        pthread_mutex_unlock(&theLock);
        
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);
        pthread_mutex_lock(&theLock);
        NSLog(@"pthread_mutex 第二个线程同步操作");
        pthread_mutex_unlock(&theLock);
        
    });
    
    // pthread_mutex 还可以创建条件锁，提供了和 NSCondition 一样的条件控制，初始化互斥锁同时使用 pthread_cond_init 来初始化条件数据结构.
    /*
     // 初始化
     int pthread_cond_init (pthread_cond_t *cond, pthread_condattr_t *attr);
     // 等待（会阻塞）
     int pthread_cond_wait (pthread_cond_t *cond, pthread_mutex_t *mut);
     // 定时等待
     int pthread_cond_timedwait (pthread_cond_t *cond, pthread_mutex_t *mut, const struct timespec *abstime);
     // 唤醒
     int pthread_cond_signal (pthread_cond_t *cond);
     // 广播唤醒
     int pthread_cond_broadcast (pthread_cond_t *cond);
     // 销毁
     int pthread_cond_destroy (pthread_cond_t *cond);

     */

    // pthread_mutex 还提供了很多函数，有一套完整的API，包含 Pthreads 线程的创建控制等等，非常底层，可以手动处理线程的各个状态的转换即管理生命周期，甚至可以实现一套自己的多线程，感兴趣的可以继续深入了解。
}



/*
 dispatch_semaphore_t GCD中信号量，也可以解决资源抢占问题,支持信号通知和信号等待。每当发送一个信号通知，则信号量 +1；每当发送一个等待信号时信号量 -1,；如果信号量为 0 则信号会处于等待状态，直到信号量大于 0 开始执行。

 * @param value
 *信号量的起始值，当传入的值小于零时返回NULL
 * @result
 * 成功返回一个新的信号量，失败返回NULL
 
dispatch_semaphore_t dispatch_semaphore_create(long value)


 * @discussion
 * 信号量减1，如果结果小于0，那么等待队列中信号增量到来直到timeout
 * @param dsema
 * 信号量
 * @param timeout
 * 等待时间
 * 类型为dispatch_time_t，这里有两个宏DISPATCH_TIME_NOW、DISPATCH_TIME_FOREVER
 * @result
 * 若等待成功返回0，timeout返回非0
 
long dispatch_semaphore_wait(dispatch_semaphore_t dsema, dispatch_time_t timeout);


 * @discussion
 * 信号量加1，如果之前的信号量小于0，将唤醒一条等待线程
 * @param dsema
 * 信号量
 * @result
 * 唤醒一条线程返回非0，否则返回0

long dispatch_semaphore_signal(dispatch_semaphore_t dsema)

 */



- (IBAction)dispatch_semaphoreAction:(id)sender
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    // 线程1
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        // 等待
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@" dispatch_semaphore  任务1");
        sleep(10);
        // 发信号
        dispatch_semaphore_signal(semaphore);
        
    });
    
    // 线程1
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        // 等待
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"dispatch_semaphore 任务2");
        sleep(10);
        // 发信号
        dispatch_semaphore_signal(semaphore);
        
    });
    
}
/*
 OSSpinLock 自旋锁
 OSSpinLock 自旋锁，性能最高的锁。它的缺点是当等待时会消耗大量 CPU 资源，不太适用于较长时间的任务。 YY大神在博客 不再安全的 OSSpinLock 中说明了OSSpinLock已经不再安全，暂不建议使用。  https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/
 
 iOS 10 之后，苹果给出了解决方案，就是用 os_unfair_lock 代替 OSSpinLock。
 

 */
- (IBAction)osspinLockAction:(id)sender
{
    /*
     // 会报警告 'OSSpinLockLock' is deprecated: first deprecated in iOS 10.0 - Use os_unfair_lock_lock() from <os/lock.h> instead

     __block OSSpinLock theLock = OS_SPINLOCK_INIT;
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
     OSSpinLockLock(&theLock);
     NSLog(@"sspinLock 第一个线程同步操作开始");
     sleep(3);
     NSLog(@"sspinLock 第一个线程同步操作结束");
     OSSpinLockUnlock(&theLock);
     });
     
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
     OSSpinLockLock(&theLock);
     sleep(1);
     NSLog(@"第二个线程同步操作");
     OSSpinLockUnlock(&theLock);
     });
     */
    __block os_unfair_lock  lock = OS_UNFAIR_LOCK_INIT;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        os_unfair_lock_lock(&lock);
        NSLog(@"os_unfair_lock 第一个线程同步操作开始");
        sleep(8);
        NSLog(@"os_unfair_lock 第一个线程同步操作结束");
        os_unfair_lock_unlock(&lock);
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);
        os_unfair_lock_lock(&lock);
        NSLog(@"os_unfair_lock 第二个线程同步操作开始");
        os_unfair_lock_unlock(&lock);
    });
}

/* 总结
 @synchronized：适用线程不多，任务量不大的多线程加锁
 NSLock：性能不算差，但感觉用的人不多。
 dispatch_semaphore_t：使用信号来做加锁，性能很高和 OSSpinLock 差不多。
 NSConditionLock：多线程处理不同任务的通信建议时用， 只加锁的话性能很低。
 NSRecursiveLock：性能不错，使用场景限制于递归。
 POSIX(pthread_mutex)：C语言的底层api，复杂的多线程处理建议使用，也可以封装自己的多线程。
 OSSpinLock：性能非常高，可惜不安全了，使用 os_unfair_lock 来代替。

 */
@end
