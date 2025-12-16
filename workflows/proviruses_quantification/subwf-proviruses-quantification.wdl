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

    call task_get_bam_slice.proviruses_quantification as bam_slice {
        input:
            gdc_bam_uuid = gdc_bam_uuid,
            gdc_token_file = gdc_token_file
    }

    
    call task_featurecount.feature_counts_rna as count {
        input:
            bam = bam_slice.sliced_bam,
            gtf = annotation_saf_file,
            prefix = annotation_saf_file
    }
    
    output {
        File proviruses_featurecount_summary = count.rna_featurecount_summary
        File proviruses_featurecount_counts = count.rna_featurecount_counts
    }
}

