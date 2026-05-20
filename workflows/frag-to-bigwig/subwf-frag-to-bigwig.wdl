version 1.0

import "../../tasks/task_check_inputs.wdl" as task_check_inputs
import "../../tasks/task_frag_to_bigwig.wdl" as task_frag_to_bigwig

workflow wf_macs3{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Run scatac tools fragment to bigwig'
    }
    
    input {
        Array[File] accessions
        File igvf_credentials
        File chrom_sizes
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

    call task_frag_to_bigwig.task_frag_to_bigwig as task_frag_to_bigwig {
    input:
      fragments = fragments,
      chrom_sizes = chrom_sizes,
      output_prefix = prefix,
  }

    
    output {
         File bigwig = task_frag_to_bigwig.bigwig
    }
}