version 1.0

import "../../tasks/task_get_tcga_bam_slice.wdl" as task_get_bam_slice
import "../../tasks/task_featurecount.wdl" as task_featurecount

workflow wf_proviruses_quantification{
    meta {
        version: 'v0.1'
        author: 'Eugenio Mattei'
        description: 'Broad Institute of MIT and Harvard: Proviruses quantification.'
    }
    
    input {
        String gdc_bam_uuid
        File gdc_token_file
        File annotation_saf_file
        String? prefix = "prefix"
    }

    call task_get_bam_slice as bam_slice {
        input:
            gdc_bam_uuid = gdc_bam_uuid
    }

    
    call task_featurecount.feature_counts_rna as count {
        input:
            bam = tcga_bam_uuid,
            binned_bed = binned_bed,
            A_compartments_bed = A_compartments_bed,
            B_compartments_bed = B_compartments_bed,
            prefix = prefix
    }
    
    output {
        File pbs_corrected_bed = pbs.pbs_corrected_bed
        File pbs_corrected_plot = pbs.pbs_corrected_plot
        File pbs_original_plot = pbs.pbs_original_plot
        File pbs_compartment_fit_plot = pbs.pbs_compartment_fit_plot
        File pbs_joint_plot = pbs.pbs_joint_plot
    }

    output {
        File rna_featurecount_count = count.rna_featurecount_counts
        File rna_featurecount_summary = count.rna_featurecount_summary
    }
}

