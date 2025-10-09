version 1.0

import "../../tasks/task_check_inputs.wdl" as task_check_inputs

workflow wf_check_inputs{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Download IGVF accession'
    }
    
    input {
        File accession
        File igvf_credentials
        String prefix
    }

    call task_check_inputs.check_inputs as check_inputs {
            input:
                path = accession,
                igvf_credentials = igvf_credentials
        }

    output {
        File downloaded_file = check_inputs.output_file
    }
}