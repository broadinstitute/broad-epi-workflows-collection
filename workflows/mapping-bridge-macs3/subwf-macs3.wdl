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
        File? barcode_map
    }
    
    if (sub(accession, "^gs:\/\/", "") == sub(accession, "", "")){
        call task_check_inputs.check_inputs as check_inputs {
                input:
                    path = accession,
                    igvf_credentials = igvf_credentials
            }
    }
    
    File fragment = select_first([ check_inputs.output_file, accession ])

    if (defined(barcode_map)) {
            call task_macs3.split_celltypes as split_celltypes {
                input:
                    barcode_map = select_first([barcode_map])
            }

            scatter (ct in split_celltypes.celltypes) {
                call task_macs3.task_macs3 as macs3_ct {
                    input:
                        bed_files    = [fragment],
                        name_prefix  = prefix + "_" + ct,
                        genome_size  = 2654621783.0,
                        qvalue       = 0.01,
                        barcode_file = split_celltypes.barcode_lists[ct]
                }
            }
        }

        if (!defined(barcode_map)) {
            call task_macs3.task_macs3 as macs3_single {
                input:
                    bed_files   = [fragment],
                    name_prefix = prefix,
                    genome_size = 2654621783.0,
                    qvalue      = 0.01
            }
        }

    output {
        #Array[String]  celltypes         = select_first([split_celltypes.celltypes, ["None"]])
        Array[File]  narrow_peaks    = select_first([macs3_ct.narrow_peaks, macs3_single.narrow_peaks])
        Array[File]  summit_bed      = select_first([macs3_ct.summit_bed, macs3_single.summit_bed])
        Array[File]  cutoff_analysis = select_first([macs3_ct.cutoff_analysis, macs3_single.cutoff_analysis])
        Array[Float]  peak_count     = select_first([macs3_ct.peak_count, macs3_single.peak_count])
    }

}