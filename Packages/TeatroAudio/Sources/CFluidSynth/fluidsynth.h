#ifndef FLUIDSYNTH_H
#define FLUIDSYNTH_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct fluid_settings_t fluid_settings_t;
typedef struct fluid_synth_t fluid_synth_t;
typedef struct fluid_audio_driver_t fluid_audio_driver_t;

fluid_settings_t* new_fluid_settings(void);
void delete_fluid_settings(fluid_settings_t* s);
void fluid_settings_setstr(fluid_settings_t* s, const char* name, const char* val);

fluid_synth_t* new_fluid_synth(fluid_settings_t* s);
int fluid_synth_sfload(fluid_synth_t* s, const char* path, int update);
void delete_fluid_synth(fluid_synth_t* s);

fluid_audio_driver_t* new_fluid_audio_driver(fluid_settings_t* s, fluid_synth_t* syn);
void delete_fluid_audio_driver(fluid_audio_driver_t* d);

void fluid_synth_noteon(fluid_synth_t* s, int chan, int key, int vel);
void fluid_synth_noteoff(fluid_synth_t* s, int chan, int key);
void fluid_synth_all_notes_off(fluid_synth_t* s, int chan);

#define FLUID_FAILED (-1)

#ifdef __cplusplus
}
#endif

#endif /* FLUIDSYNTH_H */

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
