/*
 Copyright (c) 2017 Oliver Roehrdanz
 Copyright (c) 2017 Matteo Sassano
 Copyright (c) 2017 Christopher Voelker
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 */

#ifndef nativeDiag_h
#define nativeDiag_h

#include <stdio.h>
#include <mach/mach.h>
#include <mach/mach_host.h>
#include <assert.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    
    //
    // Basic memory diagnostic informations, suchs as the virtual memory
    // and the residental memory size
    //
    struct memory_diagnostic_info {
        unsigned long long vs;      // Virtual Memory Size
        unsigned long long rss;     // Residental Memory Size
    };
    typedef struct memory_diagnostic_info memory_diagnostic_info_t;
    typedef struct memory_diagnostic_info *p_memory_diagnostic_info_t;
    
    
    //
    // Extended memory information, including the virual as well as the residental
    // memory size as well but also including some more values regarding peak
    // memory behaviors
    //
    struct memory_extended_diagnostic_info {
        unsigned long long vs;
        unsigned long long rss;
        unsigned long long rss_peak;
    };
    typedef struct memory_extended_diagnostic_info memory_extended_diagnostic_info_t;
    typedef struct memory_extended_diagnostic_info *p_memory_extended_diagnostic_info_t;
    
    //
    // Structure to hold all native diagnostics that can possibly be retrieved
    //
    struct native_diagnostic_info {
        float cpuusage;
        union {
            memory_diagnostic_info_t memory_info;
            memory_extended_diagnostic_info_t memory_extended_info;
        } memory;
    };
    typedef struct native_diagnostic_info native_diagnostic_info_t;
    typedef struct native_diagnostic_info *p_native_diagnostic_info_t;
    
    /**
     * Get the CPU Usage for the executing task and all of the tasks threads
     * Each of the devices cores can reach 100% cpu usage, this function will
     * return the sum of the cpu usage of all the cores.
     *
     * @param usage cpu usage in percent
     * @return 0 iff successful, error value otherwise
     */
    int getCPULoad(float *usage);
    
    /**
     * Get the memory usage for the executing task (the running app itself)
     *
     * @param memory_diag_info pointer to structure to hold information about residental and virtual memory size
     * @return 0 iff requesting the used memory succeeded, error value otherwise
     */
    int getMemoryUsage(memory_diagnostic_info_t *memory_diag_info);
    
    
    /**
     * Get extended memory usage diagnostics    for the executing task (the running app itself)
     *
     * @param memory_diag_info pointer to structure to hold information about residental and virtual memory size and peak sizes
     * @return 0 iff requesting the used memory succeeded, error value otherwise
     */
    int getMemoryInformation(memory_extended_diagnostic_info_t *memory_diag_info);
    
    /**
     * Get the total bytes of residental memory usage on the device
     *
     * @return the resident memory usage in bytes, a negative value if an error occured
     */
    long long getResidentMemory();
    
	/**
	 * Get the free memory on the device
	 *
	 * @return the free memory in bytes, a negative value if an error occured
	 */
	long long getFreeMemory();

	/**
	 * Get the total used memory by all apps and the os on the device
	 *
	 * @return the total used memory in bytes, a negative value if an error occured
	 */
	long long getTotalUsedMemory();

	/**
	 * Get the active memory on the device
	 *
	 * @return the active memory in bytes, a negative value if an error occured
	 */
	long long getActiveMemory();

	/**
	 * Get the wired memory on the device
	 *
	 * @return the wired memory in bytes, a negative value if an error occured
	 */
	long long getWiredMemory();

	/**
	 * Get the inactive memory on the device 
	 *
	 * @return the inactive memory in bytes, a negative value if an error occured
	 */
	long long getInactiveMemory();
    
#ifdef __cplusplus
}
#endif


#endif /* nativeDiag_h */
