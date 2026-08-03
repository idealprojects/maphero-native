#import "MHFoundation_Private.h"

/// Initializes the run loop shim that lives on the main thread.
void MHInitializeRunLoop() {
    static mbgl::util::RunLoop runLoop;
}
