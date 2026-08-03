#import "MHFoundation.h"

#include <mbgl/util/run_loop.hpp>

void MHInitializeRunLoop();

/* Using a compound statement (GNU Extension, supported by clang) */
#define MH_OBJC_DYNAMIC_CAST(object, type)                                       \
  ({                                                                              \
    __typeof__(object) temp##__LINE__ = (object);                                 \
    (type *)([temp##__LINE__ isKindOfClass:[type class]] ? temp##__LINE__ : nil); \
  })

#define MH_OBJC_DYNAMIC_CAST_AS_PROTOCOL(object, proto)                                      \
  ({                                                                                          \
    __typeof__(object) temp##__LINE__ = (object);                                             \
    (id<proto>)([temp##__LINE__ conformsToProtocol:@protocol(proto)] ? temp##__LINE__ : nil); \
  })
