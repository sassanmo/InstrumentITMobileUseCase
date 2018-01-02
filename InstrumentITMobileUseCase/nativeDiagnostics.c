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

#include "nativeDiagnostics.h"


#ifdef __cplusplus
extern "C" {
#endif
    
    /**
      * Get the number of cpu cores of the device
      *
      * @return number of cpu cores
      */
    static int getNumCores() {
        static int num_cores = -1;
        if(num_cores == -1) {
            host_basic_info_data_t hostInfo;
            mach_msg_type_number_t infoCount;
            
            infoCount = HOST_BASIC_INFO_COUNT;
            host_info( mach_host_self(), HOST_BASIC_INFO, (host_info_t)&hostInfo, &infoCount ) ;
            num_cores = hostInfo.max_cpus;
        }
        return num_cores;
    }
    
    /**
     * Get the memory usage for the executing task (the running app itself)
     *
     * @param memory_diag_info pointer to structure to hold information about residental and virtual memory size
     * @return 0 iff requesting the used memory succeeded, error value otherwise
     */
    int getMemoryUsage(memory_diagnostic_info_t *memory_diag_info) {
        mach_task_basic_info_data_t task_basic_info;
        mach_msg_type_number_t task_info_count;
        
        task_info_count = MACH_TASK_BASIC_INFO_COUNT;
        if(task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&task_basic_info, &task_info_count) != KERN_SUCCESS)
            return -1;
        memory_diag_info->rss = task_basic_info.resident_size;
        memory_diag_info->vs = task_basic_info.virtual_size;
        
        return 0;
    }
    
    /**
     * Get the memory usage for the executing task (the running app itself)
     *
     * @param memory_diag_info pointer to structure to hold information about residental and virtual memory size
     * @return 0 iff requesting the used memory succeeded, error value otherwise
     */
    int getMemoryInformation(memory_extended_diagnostic_info_t *memory_diag_info) {
        task_vm_info_data_t task_vm_info;
        mach_msg_type_number_t task_info_count;
        if(task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&task_vm_info, &task_info_count) != KERN_SUCCESS)
            return -1;
        
        memory_diag_info->rss = task_vm_info.resident_size;
        memory_diag_info->vs = task_vm_info.virtual_size;
        memory_diag_info->rss_peak = task_vm_info.resident_size_peak;
        
        return 0;
    }
    
    
    /**
     * Get the CPU Usage for the executing task and all of the tasks threads
     * Each of the devices cores can reach 100% cpu usage, this function will
     * return the sum of the cpu usage of all the cores.
     *
     * @param usage cpu usage in percent
     * @return 0 iff successful, error value otherwise
     */
    int getCPULoad(float *usage) {
        thread_act_array_t threads;
        mach_msg_type_number_t thread_count;
        mach_msg_type_number_t thread_info_count;
        thread_info_data_t thread_info_data;
        thread_basic_info_t p_thread_basic_info;
        unsigned int i;
        unsigned int error;
        float cpu_tot;
        long tot_sec;
        long tot_usec;
        
        if(task_threads(mach_task_self(), &threads, &thread_count) != KERN_SUCCESS)
            return -2;
        
        error = 0;
        cpu_tot = 0.0f;
        tot_sec = 0;
        tot_usec = 0;
        
        //
        // Iterate over threads adding their cpu load
        //
        for(i = 0; i < thread_count; ++i) {
            thread_info_count = MACH_TASK_BASIC_INFO_COUNT;
            if(thread_info(threads[i], THREAD_BASIC_INFO, (thread_info_t)thread_info_data, &thread_info_count) != KERN_SUCCESS) {
                error = 3;
                break;
            }
            
            p_thread_basic_info = (thread_basic_info_t)thread_info_data;
            
            if(!(p_thread_basic_info->flags & TH_FLAGS_IDLE)) {
                cpu_tot += p_thread_basic_info->cpu_usage / (float)TH_USAGE_SCALE;
            }
        }
        
        if(!error) {
            *usage = cpu_tot / getNumCores();
        }
        if(vm_deallocate(mach_task_self(), (vm_offset_t)threads, thread_count * sizeof(thread_act_t)) != KERN_SUCCESS)
            return 4;
        return error;
    }

    /**
     * Get the total bytes of residental memory usage on the device
     *
     * @return the resident memory usage in bytes, a negative value if an error occured
     */
    long long getResidentMemory() {
        struct task_basic_info info;
        mach_msg_type_number_t sz = sizeof(info);
        if(task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &sz) != KERN_SUCCESS)
            return -1;
        return info.resident_size;
    }
    
    /**
     * Get the memory usage for the executing task (the running app itself)
     *
     * @param memory_diag_info pointer to structure to hold information about residental and virtual memory size
     * @return 0 iff requesting the used memory succeeded, error value otherwise
     */
	long long getFreeMemory()
	{
		vm_statistics_data_t vm_stats;
		mach_msg_type_number_t info_count = HOST_VM_INFO_COUNT;
		if(host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stats, &info_count) != KERN_SUCCESS) {
			return -1;
		}
		return vm_page_size * vm_stats.free_count;
	}

	/**
	 * Get the total used memory by all apps and the os on the device
	 *
	 * @return the total used memory in bytes, a negative value if an error occured
	 */
	long long getTotalUsedMemory()
	{
		vm_statistics_data_t vm_stats;
		mach_msg_type_number_t info_count = HOST_VM_INFO_COUNT;
		if(host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stats, &info_count) != KERN_SUCCESS) {
			return -1;
		}
		return vm_stats.active_count + vm_stats.inactive_count + vm_stats.wire_count;
	}

	/**
	 * Get the active memory on the device
	 *
	 * @return the active memory in bytes, a negative value if an error occured
	 */
	long long getActiveMemory()
	{
		vm_statistics_data_t vm_stats;
		mach_msg_type_number_t info_count = HOST_VM_INFO_COUNT;
		if(host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stats, &info_count) != KERN_SUCCESS) {
			return -1;
		}
		return vm_stats.active_count;
	}

	/**
	 * Get the wired memory on the device
	 *
	 * @return the wired memory in bytes, a negative value if an error occured
	 */
	long long getWiredMemory()
	{
		vm_statistics_data_t vm_stats;
		mach_msg_type_number_t info_count = HOST_VM_INFO_COUNT;
		if(host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stats, &info_count) != KERN_SUCCESS) {
			return -1;
		}
		return vm_stats.wire_count;
	}

	/**
	 * Get the inactive memory on the device 
	 *
	 * @return the inactive memory in bytes, a negative value if an error occured
	 */
	long long getInactiveMemory()
	{
		vm_statistics_data_t vm_stats;
		mach_msg_type_number_t info_count = HOST_VM_INFO_COUNT;
		if(host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stats, &info_count) != KERN_SUCCESS) {
			return -1;
		}
		return vm_stats.inactive_count;
	}
    
    
#ifdef __cplusplus
}
#endif
