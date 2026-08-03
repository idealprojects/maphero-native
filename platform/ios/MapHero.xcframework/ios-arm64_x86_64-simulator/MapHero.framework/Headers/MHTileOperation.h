#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MHTileOperation) {
  MHTileOperationRequestedFromCache,    ///< A read request from the cache
  MHTileOperationRequestedFromNetwork,  ///< A read request from the online source
  MHTileOperationLoadFromNetwork,       ///< Tile data from the network has been retrieved
  MHTileOperationLoadFromCache,         ///< Tile data from the cache has been retrieved
  MHTileOperationStartParse,            ///< Background processing of tile data has been initiated
  MHTileOperationEndParse,              ///< Background processing of tile data has been completed
  MHTileOperationError,                 ///< An error occurred while loading the tile
  MHTileOperationCancelled,             ///< Loading of a tile was cancelled
  MHTileOperationNullOp,                ///< No operation has taken place
};
