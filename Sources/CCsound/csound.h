#ifndef CSOUND_H
#define CSOUND_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CSOUND CSOUND;

CSOUND* csoundCreate(void* host);
void csoundSetOption(CSOUND* cs, const char* opt);
int csoundCompileOrc(CSOUND* cs, const char* orc);
int csoundStart(CSOUND* cs);
int csoundPerformKsmps(CSOUND* cs);
void csoundStop(CSOUND* cs);
void csoundReset(CSOUND* cs);
void csoundDestroy(CSOUND* cs);
void csoundInputMessage(CSOUND* cs, const char* msg);

#ifdef __cplusplus
}
#endif

#endif // CSOUND_H

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
