version 1.0

import "../../tasks/task_get_tcga_bam.wdl" as task_get_bam
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
        String prefix = "prefix"
    }

    call task_get_bam.proviruses_quantification as get_bam {
        input:
            gdc_bam_uuid = gdc_bam_uuid,
            gdc_token_file = gdc_token_file,
            prefix = prefix
    }

    call task_featurecount.feature_counts_rna as count {
        input:
            bam = get_bam.gdc_tcga_bam,
            gtf = annotation_saf_file,
            prefix = prefix
    }
    
    
    output {
        File proviruses_featurecount_summary = count.rna_featurecount_summary
        File proviruses_featurecount_counts = count.rna_featurecount_counts
    }
}

