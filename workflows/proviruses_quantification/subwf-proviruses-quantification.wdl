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
        File proviruses_coordinates
        String prefix = "prefix"
    }

    Array[String] regions = read_lines(proviruses_coordinates)

    scatter(region in regions){
        call task_get_bam_slice.proviruses_quantification as bam_slice {
            input:
                gdc_bam_uuid = gdc_bam_uuid,
                gdc_token_file = gdc_token_file,
                region = region,
                prefix = prefix
        }

        call task_featurecount.feature_counts_rna as count {
            input:
                bam = bam_slice.sliced_bam,
                gtf = annotation_saf_file,
                prefix = prefix
        }
    }
    
    
    output {
        Array[File] proviruses_featurecount_summary = count.rna_featurecount_summary
        Array[File] proviruses_featurecount_counts = count.rna_featurecount_counts
    }
}

