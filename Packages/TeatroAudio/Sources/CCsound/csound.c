#include "csound.h"
#include <stdlib.h>

struct CSOUND { int dummy; };

CSOUND* csoundCreate(void* host) {
    (void)host;
    return malloc(sizeof(struct CSOUND));
}

void csoundSetOption(CSOUND* cs, const char* opt) {
    (void)cs;
    (void)opt;
}

int csoundCompileOrc(CSOUND* cs, const char* orc) {
    (void)cs;
    (void)orc;
    return 0;
}

int csoundStart(CSOUND* cs) {
    (void)cs;
    return 0;
}

int csoundPerformKsmps(CSOUND* cs) {
    (void)cs;
    return 1;
}

void csoundStop(CSOUND* cs) {
    (void)cs;
}

void csoundReset(CSOUND* cs) {
    (void)cs;
}

void csoundDestroy(CSOUND* cs) {
    free(cs);
}

void csoundInputMessage(CSOUND* cs, const char* msg) {
    (void)cs;
    (void)msg;
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
