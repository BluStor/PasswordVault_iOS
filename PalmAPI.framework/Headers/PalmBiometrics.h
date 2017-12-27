// Copyright © 2017 RedRock Biometrics. All rights reserved.
#ifndef __PALM_BIOMETRICS_H__
#define __PALM_BIOMETRICS_H__

#include "PalmFrame.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct _PalmBiometricsHandle {
  void* impl;
} PalmBiometricsHandle;

/**
 * Set configuration parameters. A parameter is specified by two strings [name, value].
 * Call this function before calling PalmBiometrics_Create.
 *
 * @param name A pointer to parameter name string. The string is expected to end with '\0'.
 * @param value A pointer to parameter value string. The string is expected to end with '\0'.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_SetConfig(const char* name, const char* value);

/**
 * Get configuration parameters.
 *
 * @param name A pointer to parameter name string. The string is expected to end with '\0'.
 * @param value A pointer to hold the output parameter value string. The caller needs to allocate the memory.
 * @param value_size A pointer to an integer to hold the output parameter value string size. This parameter
 * is updated upon return with the actual number of bytes written to the value pointer.
 * @param null_terminate A boolean value on whether or not to include a null-termination character ('\0') at
 * the end of the value string (0 is no, otherwise yes).
 *
 * @note: If the size of the value buffer is insufficient to hold the entire value, this function will
 * return an ePalm_InsufficientMemory error, and the value_size parameter will be updated with the actual
 * size needed to store the results.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_GetConfig(const char* name, char* value, int32_t* value_size, int null_terminate);

/**
 * Create a new palm biometrics handle that is passed to most of the Palm biometrics
 * functions.
 *
 * @param handle A pointer to a palm biometrics handle.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_Create(PalmBiometricsHandle* handle);

/**
 * Destroy a palm biometrics handle.
 *
 * @param handle A palm biometrics handle.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_Destroy(PalmBiometricsHandle* handle);

/**
 * Current time in microseconds.
 *
 * @return The current time in microseconds. A negative value indicates failure.
 */
PALM_EXPORT int64_t PALM_CALL PalmBiometrics_Now(void);

/**
 * Provide a camera frame for processing.
 *
 * @param handle A palm biometrics handle.
 * @param frame The frame acquired through the Camera SDK or from an
 *              alternate image-capture interface.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_ProcessFrame(PalmBiometricsHandle handle, const PalmFrame* frame);

/**
 * Attempt to create a new palm model that will extracted from the frame sequence provided
 * by PalmBiometrics_ProcessFrame(). The new model will be returned as a PalmModelingResult.
 *
 * @param handle A palm biometrics handle.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_Model(PalmBiometricsHandle handle);

typedef struct _PalmModel {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * A flag to indicate if this palm model is valid or not
   */
  uint32_t valid;

  /**
   * A flag to indicate if palm model is for left or right (0 is left and 1 is right).
   */
  uint32_t sidedness;

  /**
   * Unique identifier for palm model
   */
  uint8_t id[20];
} PalmModelID;

/**
 * Attempt to load an existing palm model into SDK memory. If the input model data is valid this function outputs
 * a palm model ID which can be to specify the palm model in other function calls.
 *
 * @param handle A palm biometrics handle.
 * @param model_data A pointer to palm model data stream.
 * @param model_data_size The size of palm model data stream in bytes.
 * @param model_id A reference to hold the output palm model ID.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_LoadModel(PalmBiometricsHandle handle, const void* model_data, uint32_t model_data_size, PalmModelID* model_id);

/**
 * Attempt to unload a palm model from SDK memory. Only useful in local version. No operation will be performed in server version.
 *
 * @param handle A palm biometrics handle.
 * @param model_id A reference to hold the ID of the to-be-unloaded palm model.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_UnloadModel(PalmBiometricsHandle handle, const PalmModelID* model_id);

/**
 * Attempt to remove an existing palm model from disk. Used in server version to remove a model on this server. When
 * called in local version, this function only unloads model from memory, the same as PalmBiometrics_UnloadModel.
 *
 * @param handle A palm biometrics handle.
 * @param model_id Pointer to the id of the to-be-removed model.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_RemoveModel(PalmBiometricsHandle handle, const PalmModelID* model_id);

/**
 * Attempt to add a newly created palm model.
 *
 * @param handle A palm biometrics handle.
 * @param model_id A reference to hold the ID of the newly created palm model.
 *
 * @note Use this function only once for a newly created palm model. For existing palm models, use LoadModel.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_AddModel(PalmBiometricsHandle handle, const PalmModelID* model_id);

/**
 * Attempt to extract the segmented image mask of a palm model.
 *
 * @param handle A palm biometrics handle.
 * @param model_id Pointer to ID of the model. Use NULL for a newly created palm model that has not been saved.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_ExtractModelMask(PalmBiometricsHandle handle, const PalmModelID* model_id);

/**
 * Attempt to match a set of existing palm model(s) to a live palm that will be detected
 * from the frame sequence provided by PalmBiometrics_ProcessFrame(). The result(s)
 * will be returned as PalmMatchingResult(s).
 *
 * @param handle A palm biometrics handle.
 * @param model_ids A pointer to the IDs of models that will be matched to when a palm is detected.
 * @param num_models The number of models stored in models array.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_Match(PalmBiometricsHandle handle, const PalmModelID* model_ids, uint32_t num_models);

/**
 * Attempt to specify the palm detection orientation.
 *
 * @param handle A palm biometrics handle.
 * @param horv   A integer. Set horv to 0 or 1 to inform SDK that the camera is placed in landscape or portrait orientation and the user's
 *               palm will be placed with fingers pointing towards the up direction of the camera. SDK will then only detect palm in that
 *               particular orientation. Set horv to 2 to inform SDK that the camera orientation is unknown or the user's palm will be placed
 *               in arbitrary directions. SDK will then detect palm in all 360 degrees.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_SetCameraOrientation(PalmBiometricsHandle handle, int horv);

/**
 * A 2-D point.
 */
typedef struct _PalmPoint2D {
  float x;
  float y;
} PalmPoint2D;

/**
 * A 2-D quadrilateral described by four 2-D points.
 */
typedef struct _PalmQuad2D {
  PalmPoint2D a;
  PalmPoint2D b;
  PalmPoint2D c;
  PalmPoint2D d;
} PalmQuad2D;

typedef struct _PalmDetected {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * Palm identifier.
   */
  uint32_t palm_id;

  /**
   * Camera frame identifier with which this structure is associated.
   */
  int64_t frame_id;

  /**
   * A quadrilateral in image coordinates enclosing the palm.
   */
  PalmQuad2D quad;

  /**
   * Time stamp of when the palm was first detected in microseconds.
   */
  int64_t timestamp;

  /**
   * The readiness of the palm.
   */
  float readiness;

  /**
   * The quality of the palm.
   */
  float quality;

  /**
   * The brightness of the palm.
   */
  float brightness;

  /**
   * The centerness of the palm.
   */
  float centerness;

  /**
   * A scaler between 0 and 1 to indicate the likelihood of the detected palm being left or right (0 is definitely left and 1 is definitely right).
   */
  float sidedness;
} PalmDetected;

/**
 * The palms detected in the latest frame.
 */
typedef struct _PalmsDetected {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * The number of palms detected.
   */
  uint32_t num_palms;

  /**
   * An array of detected palms, consisting of num_detected palms.
   */
  PalmDetected* palms;
} PalmsDetected;

typedef enum _PalmMatchingStatus {
  /**
   * It could not be determined if the model matched the given user identifier.
   */
  PalmMatching_Undetermined = -1,

  /**
   * The palm matched the specified.
   */
  PalmMatching_Match = 0,

  /**
   * The palm did not match the specified user identifier.
   */
  PalmMatching_Mismatch = 1
} PalmMatchingStatus;

/**
 * The matching result.
 */
typedef struct _PalmMatchingResult {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * The matching status for the palm;
   */
  PalmMatchingStatus status;

  /**
   * The matching score;
   */
  float score;

  /**
   * The identifier of the detected palm that matches the result.
   */
  uint32_t palm_id;

  /**
   * The ID of the model for which the result was generated.
   */
  PalmModelID model_id;
} PalmMatchingResult;

/**
 * The modeling result.
 */
typedef struct _PalmModelingResult {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * The identifier of the detected palm that matches the result.
   */
  uint32_t palm_id;

  /**
   * The ID of the model for which the result was generated. This model ID will be invalid if modeling failed.
   */
  PalmModelID model_id;

  /**
   * The pointer to palm model data stream if the modeling was successful, or NULL if
   * the modeling failed.
   */
  const void* data;

  /**
   * The size of the palm model data stream in bytes.
   */
  uint32_t data_size;
} PalmModelingResult;

/**
 * The image shows the masked (segmented) palm model.
 */
typedef struct _PalmMaskedImage {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * The ID of the model from which the masked image was extracted.
   */
  PalmModelID model_id;

  /**
   * The masked palm image.
   */
  PalmImage image;
} PalmMaskedImage;

/**
 * The possible message types.
 */
typedef enum _ePalmMessageType {
  /**
   * No message was available.
   */
  MessageNone = 0,

  /**
   * The message corresponds to palms being detected.
   */
  MessagePalmsDetected = 1,

  /**
   * The message corresponds to palm matching result.
   */
  MessageMatchingResult = 2,

  /**
   * The message corresponds to palm modeling result.
   */
  MessageModelingResult = 3,

  /**
   * The message corresponds to palm matching started.
   */
  MessageMatchingStarted = 4,

  /**
   * The message corresponds to palm matching finished.
   */
  MessageMatchingFinished = 5,

  /**
   * The message corresponds to palm modeling started.
   */
  MessageModelingStarted = 6,

  /**
   * The message corresponds to palm modeling finished.
   */
  MessageModelingFinished = 7,

  /**
   * The message corresponds to masked palm image.
   */
  MessageMaskedPalmImage = 8,

  /**
   * The message corresponds to add palm model.
   */
  MessageAddModelResult = 9,

  /**
   * The message corresponds to remove palm model.
   */
  MessageRemoveModelResult = 10
} ePalmMessageType;

/**
 * The result of a request for update a palm model, such as add or remove.
 */
typedef struct _PalmModelUpdateResult {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * The ID of the to be updated model.
   */
  PalmModelID model_id;
} PalmModelUpdateResult;

typedef struct _PalmMessage {
  /**
   * Size of this structure in byte.
   */
  uint32_t size;

  /**
   * The message type of this message.
   */
  ePalmMessageType type;

  /**
   * The error status. If the value is not ePalm_Success, then an error occurs when the message is generated.
   */
  ePalmStatus status;

  /**
   * A pointer to the message corresponding to the message type.
   */
  union {
    const void* pointer;
    const PalmsDetected* palms_detected;
    const PalmMatchingResult* matching_result;
    const PalmModelingResult* modeling_result;
    const PalmModelUpdateResult* model_update_result;
    const PalmMaskedImage* masked_image;
  } message;
} PalmMessage;

/**
 * Wait for a message to become available. The function will wait until either
 * a message becomes available or the specified timeout duration elapses.
 * The messages are valid until the next call to PalmBiometrics_WaitMessage or
 * PalmBiometrics_Destroy.
 *
 * @param handle A palm biometrics handle.
 * @param message The message to be filled in.
 * @param timeout The maximum length of time, in milliseconds, to wait for a
 *                message to become available.
 */
PALM_EXPORT ePalmStatus PALM_CALL PalmBiometrics_WaitMessage(PalmBiometricsHandle handle, PalmMessage* message, int32_t timeout);

#ifdef __cplusplus
}
#endif

#endif /* __PALM_BIOMETRICS_H__ */
