//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#include <stdio.h>

void Apu_Initialize();
void Apu_Execute(unsigned int cpuCycles);
void Apu_HandleCpuWrite(unsigned short cpuAddress, unsigned char value);
unsigned char Apu_HandleCpuRead(unsigned short cpuAddress);
