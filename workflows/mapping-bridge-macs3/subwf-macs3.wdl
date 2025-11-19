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
        File accession
        File igvf_credentials
        String prefix
    }
    
    if (sub(accession, "^gs:\/\/", "") == sub(accession, "", "")){
        call task_check_inputs.check_inputs as check_inputs {
                input:
                    path = accession,
                    igvf_credentials = igvf_credentials
            }
    }
    
    File fragment = select_first([ check_inputs.output_file, accession ])

    call task_macs3.task_macs3 as task_macs3 {
            input:
                bed_files = [fragment],
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