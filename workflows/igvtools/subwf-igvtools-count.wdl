version 1.0

import "../../tasks/task_igvtools_count.wdl" as task_igvtools

workflow wf_igvtools{
    meta {
        version: 'v0.1'
            author: 'Eugenio Mattei (emattei@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Deeptools.'
    }
    
    input {
        Array[File] input_bams
    }
    
    scatter(file in input_bams){
        call task_igvtools.igvtools_count as count{
            input:
                sorted_bam = file
        }    
    }

    output {
        Array[File] igvtools_count_bw = count.igvtools_count_bw
        Array[File] igvtools_count_tdf = count.igvtools_count_tdf
    }
}