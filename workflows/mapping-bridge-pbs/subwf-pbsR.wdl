version 1.0

import "../../tasks/task_check_inputs.wdl" as task_check_inputs
import "../../tasks/task_bam_to_binnedcounts.wdl" as task_bam_to_binnedcounts
import "../../tasks/task_pbsr.wdl" as task_pbsr

workflow wf_pbsR{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Run PBS on mapping bridge samples'
    }
    
    input {
        String accession
        File igvf_credentials
        File reference_tiled_bed
        File igv_genome_file
        File chrom_sizes
        File mappability_bed
        String prefix
    }
    
    call task_check_inputs.check_inputs as check_inputs {
            input:
                path = accession,
                igvf_credentials = igvf_credentials
        }

    call task_bam_to_binnedcounts.bam_to_binnedcounts as bam_to_binnedcounts {
            input:
                bam = check_inputs.output_file,
                reference_tiled_bed = reference_tiled_bed,
                igv_genome_file = igv_genome_file,
                chrom_sizes = chrom_sizes,
                prefix = prefix
        }

    call task_pbsr.pbsr as pbsr {
        input:
            binned_bed = bam_to_binnedcounts.binned_bed,
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
        File bigwig = bam_to_binnedcounts.bigwig
    }
}