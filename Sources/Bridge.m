#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <stdatomic.h>
#import "Bridge.h"
// ABI of macOS MultitouchSupport, loaded at runtime; no third-party dependencies.
typedef struct { float x,y; } EBPoint;
typedef struct { EBPoint position,velocity; } Vector;
typedef struct {
 int frame; double timestamp; int path,state,finger,hand;
 Vector normalized; float quality; int reserved; float angle,major,minor;
 Vector absolute; int reserved2,reserved3; float density;
} Contact;
typedef void (*FrameCallback)(void *, Contact *, size_t, double, size_t);
static void *library;
static char deviceInfo[256]="Not started";
const char *EBDeviceInfo(void) { return deviceInfo; }
static CFArrayRef devices;
static _Atomic(EBTouchCallback) receiver;
static void stopHaptics(void);
static void (*unregisterFrame)(void *,FrameCallback);
static int (*stopDevice)(void *);
static void frame(void *device, Contact *contacts,size_t count,double timestamp,size_t number) {
 EBTouchCallback callback=atomic_load(&receiver);
 if (!callback) return;
 int active=0; Contact *single=NULL;
 for(size_t i=0;i<count;i++) if(contacts[i].state==3 || contacts[i].state==4) { active++; single=&contacts[i]; }
 callback(active,single ? single->path : 0,single ? single->normalized.position.x : 0,single ? single->normalized.position.y : 0,timestamp);
}
bool EBStart(EBTouchCallback callback) {
 EBStop();
 if(!library) library=dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport",RTLD_NOW);
 if(!library) return false;
 CFArrayRef (*create)(void)=dlsym(library,"MTDeviceCreateList");
 void (*registerFrame)(void *,FrameCallback)=dlsym(library,"MTRegisterContactFrameCallback");
 int (*start)(void *,int)=dlsym(library,"MTDeviceStart");
 unregisterFrame=dlsym(library,"MTUnregisterContactFrameCallback");
 stopDevice=dlsym(library,"MTDeviceStop");
 bool (*opaque)(void *)=dlsym(library,"MTDeviceIsOpaqueSurface");
 if(!create||!registerFrame||!start||!stopDevice||!unregisterFrame) return false;
 CFArrayRef all=create(); if(!all) { snprintf(deviceInfo,sizeof(deviceInfo),"Device list unavailable"); return false; }
 snprintf(deviceInfo,sizeof(deviceInfo),"Raw devices: %ld",CFArrayGetCount(all));
 NSMutableArray *usable=[NSMutableArray array];
 // OpaqueSurface is not a trackpad predicate (false on modern built-in devices).
 // Prefer the built-in device below.
 for(id dev in (__bridge NSArray *)all) {
  bool isOpaque=opaque ? opaque((__bridge void *)dev) : false;
  char detail[48]; snprintf(detail,sizeof(detail),"; opaque=%d",isOpaque); strlcat(deviceInfo,detail,sizeof(deviceInfo));
  [usable addObject:dev];
 }
 bool (*builtIn)(void *)=dlsym(library,"MTDeviceIsBuiltIn");
 if(builtIn) for(id dev in usable) if(builtIn((__bridge void *)dev)) { usable=[NSMutableArray arrayWithObject:dev]; break; }
 if(usable.count>1) usable=[NSMutableArray arrayWithObject:usable.firstObject];
 devices=CFBridgingRetain(usable); CFRelease(all); receiver=callback;
 for(id dev in (__bridge NSArray *)devices) { registerFrame((__bridge void *)dev,frame); start((__bridge void *)dev,0); }
 return CFArrayGetCount(devices)>0;
}
void EBStop(void) {
 atomic_store(&receiver,NULL);
 stopHaptics();
 if(devices) { for(id dev in (__bridge NSArray *)devices) { stopDevice((__bridge void *)dev); unregisterFrame((__bridge void *)dev,frame); } CFRelease(devices); devices=NULL; }
}
int EBDeviceCount(void) { return devices ? (int)CFArrayGetCount(devices) : 0; }

// Discover the actuator through IOKit properties rather than assuming a model ID.
#import <IOKit/IOKitLib.h>
static CFTypeRef actuator;
static int (*actuate)(CFTypeRef,int,unsigned int,float,float);
static int (*closeActuator)(CFTypeRef);
bool EBHaptic(int strength) {
 if(!library) return false;
 if(!actuator) {
  CFTypeRef (*create)(uint64_t)=dlsym(library,"MTActuatorCreateFromDeviceID");
  int (*openActuator)(CFTypeRef)=dlsym(library,"MTActuatorOpen");
  actuate=dlsym(library,"MTActuatorActuate"); closeActuator=dlsym(library,"MTActuatorClose");
  if(!create||!openActuator||!actuate||!closeActuator) return false;
  const char *classes[]={"AppleMultitouchDevice","AppleMultitouchTrackpadHIDEventDriver"};
  for(int i=0;i<2 && !actuator;i++) {
   io_iterator_t iterator=0;
   if(IOServiceGetMatchingServices(kIOMainPortDefault,IOServiceMatching(classes[i]),&iterator)!=KERN_SUCCESS) continue;
   io_service_t service;
   while((service=IOIteratorNext(iterator))) {
    CFTypeRef property=IORegistryEntryCreateCFProperty(service,i==0 ? CFSTR("Multitouch ID") : CFSTR("mt-device-id"),kCFAllocatorDefault,0);
    if(property && CFGetTypeID(property)==CFNumberGetTypeID()) {
     int64_t identifier=0; CFNumberGetValue(property,kCFNumberSInt64Type,&identifier);
     CFTypeRef candidate=create((uint64_t)identifier);
     if(candidate) { if(openActuator(candidate)==0) actuator=candidate; else CFRelease(candidate); }
    }
    if(property) CFRelease(property); IOObjectRelease(service);
    if(actuator) break;
   }
   IOObjectRelease(iterator);
  }
 }
 return actuator && actuate(actuator,strength==0 ? 3 : (strength==2 ? 6 : 4),0,0,0)==0;
}

static void stopHaptics(void) { if(actuator) { if(closeActuator) closeActuator(actuator); CFRelease(actuator); actuator=NULL; } }
