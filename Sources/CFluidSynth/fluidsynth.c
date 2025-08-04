#include "fluidsynth.h"
#include <stdlib.h>

struct fluid_settings_t { int dummy; };
struct fluid_synth_t { int dummy; };
struct fluid_audio_driver_t { int dummy; };

fluid_settings_t* new_fluid_settings(void) {
    return malloc(sizeof(struct fluid_settings_t));
}

void delete_fluid_settings(fluid_settings_t* s) {
    free(s);
}

void fluid_settings_setstr(fluid_settings_t* s, const char* name, const char* val) {
    (void)s;
    (void)name;
    (void)val;
}

fluid_synth_t* new_fluid_synth(fluid_settings_t* s) {
    (void)s;
    return malloc(sizeof(struct fluid_synth_t));
}

int fluid_synth_sfload(fluid_synth_t* s, const char* path, int update) {
    (void)s;
    (void)path;
    (void)update;
    return 0;
}

void delete_fluid_synth(fluid_synth_t* s) {
    free(s);
}

fluid_audio_driver_t* new_fluid_audio_driver(fluid_settings_t* s, fluid_synth_t* syn) {
    (void)s;
    (void)syn;
    return malloc(sizeof(struct fluid_audio_driver_t));
}

void delete_fluid_audio_driver(fluid_audio_driver_t* d) {
    free(d);
}

void fluid_synth_noteon(fluid_synth_t* s, int chan, int key, int vel) {
    (void)s;
    (void)chan;
    (void)key;
    (void)vel;
}

void fluid_synth_noteoff(fluid_synth_t* s, int chan, int key) {
    (void)s;
    (void)chan;
    (void)key;
}

void fluid_synth_all_notes_off(fluid_synth_t* s, int chan) {
    (void)s;
    (void)chan;
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
