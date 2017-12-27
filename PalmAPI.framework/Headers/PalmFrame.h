// Copyright © 2017 RedRock Biometrics. All rights reserved.
#ifndef __PALM_FRAME_H__
#define __PALM_FRAME_H__

#ifndef PALM_EXPORT
#ifdef _MSC_VER
#define PALM_EXPORT __declspec(dllexport)
#else
#define PALM_EXPORT __attribute__((visibility("default")))
#endif
#endif

#ifndef PALM_CALL
#ifdef _MSC_VER
#define PALM_CALL __stdcall
#else
#define PALM_CALL
#endif
#endif

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Possible return values from the various API functions.
 */
typedef enum _ePalmStatus {
  /**
   * The desired operation completed successfully.
   */
  ePalm_Success = 0,

  /**
   * The function timed-out before completing the desired operation.
   */
  ePalm_Timeout = 1,

  /**
   * There was an error completing the desired operation, but for an unknown
   * reasons.
   */
  ePalm_UnknownError = 0x8000,

  /**
   * An operation was requested when it was not expected.
   */
  ePalm_InvalidHandle = 0x8001,

  /**
   * One of the provided arguments was invalid or incomplete.
   */
  ePalm_InvalidArgument = 0x8002,

  /**
   * Insufficient memory in buffer.
   */
  ePalm_OutOfMemory = 0x8003,

  /**
   * An operation was requested when it was not expected.
   */
  ePalm_UnexpectedRequest = 0x8004,

  /**
   * The license id used was invalid.
   */
  ePalm_InvalidLicense = 0x8005,

  /**
   * The model does not exist or is invalid.
   */
  ePalm_InvalidModel = 0x8006,

  /**
   * Error connecting to API server.
   */
  ePalm_ServerConnectionError = 0x8007,

  /**
  * Error in data serialization.
  */
  ePalm_SerializationError = 0x8008
} ePalmStatus;

typedef struct _PalmImage {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * Pointer to the raw image data.
   */
  uint8_t* data;

  /**
   * Width of image in pixels.
   */
  uint32_t width;

  /**
   * Height of image in pixels.
   */
  uint32_t height;

  /**
   * Size of a row of pixels in bytes, including any padding at end.
   */
  uint32_t stride;

  /**
   * Number of color planes.
   */
  uint32_t planes;

  /**
   * Color depth of image in bits.
   */
  uint32_t depth;

  /**
   * Number of bytes offset from the beginning of data to the start of image.
   */
  uint32_t offset;
} PalmImage;

/**
 * Camera settings of the device used to acquire the image frame.
 */
typedef struct _CameraSettings {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * The camera gain setting.
   */
  int32_t gain;

  /**
   * The camera shutter setting.
   */
  int32_t shutter;

  /**
  * The camera brightness setting.
  */
  int32_t brightness;

  /**
   * The camera focus setting.
   */
  int32_t focus;
} CameraSettings;

/**
 * A camera device frame.
 */
typedef struct _PalmFrame {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * Unique frame identifier for this frame.
   */
  int64_t frame_id;

  /**
   * The time at which the frame was captured in microseconds.
   */
  int64_t timestamp;

  /**
   * Camera settings of the device used to capture this frame.
   */
  CameraSettings camera_settings;

  /**
   * The image associated with this frame.
   */
  PalmImage image;
} PalmFrame;

/**
* Allocate memory for image data buffer inside Palm API. This function also set
* the width, height and depth parameter of the image.
*
* @param image  An image whose pixel contents will be allocated inside Palm API.
*        width  Image width
*        height Image height
*        depth  Image depth which equals 8 * (number of channels). For instance, RGB is 24.
*
*/
PALM_EXPORT void PALM_CALL PalmImage_Create(PalmImage* image, uint32_t width, uint32_t height, uint32_t depth);

/**
* Free image data allocated using one of the Palm API functions.
*
* @param image An image whose pixel contents were allocated using one of the
*              Palm API functions.
*/
PALM_EXPORT void PALM_CALL PalmImage_Free(PalmImage* image);

#ifdef __cplusplus
}
#endif

#endif /* __PALM_FRAME_H__ */
