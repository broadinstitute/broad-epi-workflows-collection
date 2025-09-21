version 1.0

import "../../tasks/task_check_inputs.wdl" as task_check_inputs
import "../../tasks/task_fragment_to_binnedcounts.wdl" as task_fragment_to_binnedcounts
import "../../tasks/task_pbsr.wdl" as task_pbsr

workflow wf_pbsR{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Run PBS on mapping bridge samples'
    }
    
    input {
        File accession
        File igvf_credentials
        File reference_tiled_bed
        File igv_genome_file
        File chrom_sizes
        File mappability_bed
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

    call task_fragment_to_binnedcounts.fragment_to_binnedcounts as fragment_to_binnedcounts {
            input:
                fragments = fragment,
                reference_tiled_bed = reference_tiled_bed,
                igv_genome_file = igv_genome_file,
                chrom_sizes = chrom_sizes,
                prefix = prefix
        }

    call task_pbsr.pbsr as pbsr {
        input:
            binned_bed = fragment_to_binnedcounts.binned_bed,
            mappability_bed = mappability_bed,
            prefix = prefix
    }
    
    output {
        File pbs_bed = pbsr.pbs_bed
        File pbs_plot = pbsr.pbs_plot
        File pbs_dist_plot = pbsr.pbs_dist_plot
        Float k = pbsr.k
        Float beta = pbsr.beta
        Float lambda = pbsr.lambda
        #File bigwig = fragment_to_binnedcounts.bigwig
    }
}