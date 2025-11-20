version 1.0

import "../../tasks/task_check_inputs.wdl" as task_check_inputs
import "../../tasks/task_macs3.wdl" as task_macs3

workflow wf_macs3{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Run PBS on mapping bridge samples'
    }
    
    input {
        Array[File] accessions
        File igvf_credentials
        String prefix
    }
    
    scatter (acc in accessions) {
        Boolean is_local = sub(acc, "^gs://", "") == sub(acc, "", "")
        if (is_local) {
            call task_check_inputs.check_inputs as check_inputs {
                input:
                    path = acc,
                    igvf_credentials = igvf_credentials
            }
        }
        File resolved_fragment = select_first([check_inputs.output_file, acc])
    }
    
    Array[File] fragments = resolved_fragment

    call task_macs3.task_macs3 as task_macs3 {
            input:
                bed_files = fragments,
                name_prefix = prefix,
                genome_size = 2654621783.0, 
                qvalue = 0.01
        }
    
    output {
         File narrow_peaks    = task_macs3.narrow_peaks
         File cutoff_analysis = task_macs3.cutoff_analysis
         File summit_bed      = task_macs3.summit_bed
         Float peak_count     = task_macs3.peak_count
    }
}