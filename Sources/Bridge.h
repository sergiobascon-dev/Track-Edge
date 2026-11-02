#include <stdbool.h>
typedef void (*EBTouchCallback)(int count, int identifier, double x, double y, double time);
bool EBStart(EBTouchCallback callback);
void EBStop(void);
int EBDeviceCount(void);
bool EBHaptic(int strength);

const char *EBDeviceInfo(void);
