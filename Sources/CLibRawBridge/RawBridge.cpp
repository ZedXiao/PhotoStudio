#include "RawBridge.h"
#include <libraw/libraw.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <memory>

struct Cancellation { PSCancelCallback callback; void *context; };
static int exif_orientation(int flip) {
    static const int orientations[] = {1, 2, 4, 3, 5, 8, 6, 7};
    return flip >= 0 && flip < 8 ? orientations[flip] : 0;
}
static int progress(void *opaque, LibRaw_progress, int, int) {
    auto *c = static_cast<Cancellation *>(opaque);
    return c->callback ? c->callback(c->context) : 0;
}
int ps_raw_decode(const char *path, PSCancelCallback cancel, void *context,
                  PSRawImage *out, char *error, size_t capacity) {
    if (!out || !path) return -1;
    std::memset(out, 0, sizeof(*out));
    auto fail = [&](int code, const char *message) {
        if (error && capacity) std::snprintf(error, capacity, "%s", message);
        return code == 0 ? -1 : code;
    };
    try {
        // LibRaw is larger than a macOS dispatch worker's default 512 KiB stack.
        // Keep it on the heap in every bridge entry point, including metadata reads.
        auto storage = std::make_unique<LibRaw>();
        LibRaw &raw = *storage;
        Cancellation cancellation{cancel, context};
        raw.set_progress_handler(progress, &cancellation);
        raw.imgdata.rawparams.max_raw_memory_mb = 1536;
        raw.imgdata.params.use_camera_wb = 1;
        raw.imgdata.params.output_bps = 16;
        raw.imgdata.params.output_color = 1; // tagged sRGB in the Swift bridge
        raw.imgdata.params.no_auto_bright = 1;
        raw.imgdata.params.user_qual = 3;
        raw.imgdata.params.half_size = 0;
        if (cancel && cancel(context)) return fail(-100, "Cancelled");
        int code = raw.open_file(path);
        if (code) return fail(code, libraw_strerror(code));
        std::snprintf(out->make, sizeof(out->make), "%s", raw.imgdata.idata.make);
        std::snprintf(out->model, sizeof(out->model), "%s", raw.imgdata.idata.model);
        out->iso = raw.imgdata.other.iso_speed;
        out->aperture = raw.imgdata.other.aperture;
        out->shutter = raw.imgdata.other.shutter;
        out->focal_length = raw.imgdata.other.focal_len;
        code = raw.unpack();
        if (code) return fail(code, libraw_strerror(code));
        code = raw.dcraw_process();
        if (code) return fail(code, libraw_strerror(code));
        libraw_processed_image_t *image = raw.dcraw_make_mem_image(&code);
        if (!image) return fail(code, libraw_strerror(code));
        if (image->type != LIBRAW_IMAGE_BITMAP || image->colors != 3 || image->bits != 16) {
            LibRaw::dcraw_clear_mem(image);
            return fail(-2, "Unsupported output layout");
        }
        out->byte_count = image->data_size;
        out->pixels = std::malloc(out->byte_count);
        if (!out->pixels) { LibRaw::dcraw_clear_mem(image); return fail(-3, "Insufficient memory"); }
        std::memcpy(out->pixels, image->data, out->byte_count);
        out->width = image->width; out->height = image->height;
        out->channels = image->colors; out->bits = image->bits;
        LibRaw::dcraw_clear_mem(image);
        return 0;
    } catch (const std::exception &e) { return fail(-4, e.what()); }
      catch (...) { return fail(-5, "RAW decoder error"); }
}
void ps_raw_free(PSRawImage *image) {
    if (image) { std::free(image->pixels); image->pixels = nullptr; }
}
int ps_raw_thumbnail(const char *path, PSRawImage *out) {
    std::memset(out, 0, sizeof(*out));
    try {
        auto storage = std::make_unique<LibRaw>();
        LibRaw &raw = *storage;
        int code = raw.open_file(path);
        if (code) return code;
        code = raw.unpack_thumb();
        if (code) return code;
        libraw_processed_image_t *image = raw.dcraw_make_mem_thumb(&code);
        if (!image) return code ? code : -1;
        out->byte_count = image->data_size;
        out->pixels = std::malloc(out->byte_count);
        if (!out->pixels) { LibRaw::dcraw_clear_mem(image); return -3; }
        std::memcpy(out->pixels, image->data, out->byte_count);
        out->encoded = image->type == LIBRAW_IMAGE_JPEG;
        out->width = image->width; out->height = image->height;
        out->bits = image->bits; out->channels = image->colors;
        out->orientation = exif_orientation(raw.imgdata.sizes.flip);
        LibRaw::dcraw_clear_mem(image);
        return 0;
    } catch (...) { return -5; }
}
int ps_raw_orientation(const char *path) {
    try {
        auto storage = std::make_unique<LibRaw>();
        LibRaw &raw = *storage;
        if (raw.open_file(path)) return 0;
        return exif_orientation(raw.imgdata.sizes.flip);
    } catch (...) { return 0; }
}
const char *ps_raw_version(void) { return LibRaw::version(); }
int ps_raw_camera_count(void) { return LibRaw::cameraCount(); }
const char *ps_raw_camera_at(int index) {
    return index >= 0 && index < LibRaw::cameraCount() ? LibRaw::cameraList()[index] : "";
}
