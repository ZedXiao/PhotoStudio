#pragma once
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef int (*PSCancelCallback)(void *context);
typedef struct {
    void *pixels;
    size_t byte_count;
    int width, height, channels, bits, encoded, orientation;
    char make[128], model[128];
    float iso, aperture, shutter, focal_length;
} PSRawImage;
// Pixels are owned by the caller after success; release with ps_raw_free.
int ps_raw_decode(const char *path, PSCancelCallback cancel, void *context,
                  PSRawImage *output, char *error, size_t error_capacity);
int ps_raw_thumbnail(const char *path, PSRawImage *output);
int ps_raw_orientation(const char *path);
void ps_raw_free(PSRawImage *image);
const char *ps_raw_version(void);
int ps_raw_camera_count(void);
const char *ps_raw_camera_at(int index);
#ifdef __cplusplus
}
#endif
