version 1.0

# TASK
# igvtools

task igvtools_count {
    meta {
        version: 'v0.1'
        author: 'Eugenio Mattei (emattei@broadinstitute.org) at Broad Institute of MIT and Harvard'
        description: 'Broad Institute of MIT and Harvard: Deeptools QC step'
    }

    input {
        # This task takes in input the bedgraphs for input and ctrl and call peaks.
        File sorted_bam  # Coordinates sorted
        File chrom_sizes

        Boolean? include_duplicates = false
        Boolean? paired = true
        Int? max_zoom = 1
        Int? window_size = 25
        Int? extend_factor = 150
        Int? minimum_mapping_quality = 0
        String? prefix
        String? genome_id = "hg38"

        # Compute Resources
        Int? cpus = 1
        Int? memory_gb = 16
        String docker_image = "docker.io/polumechanos/igvtools"
    }

    #Float input_file_size_gb = size(fastq_R1, "G")
    # This is almost fixed for either mouse or human genome
    Int mem_gb = memory_gb
    #Int disk_gb = round(20.0 + 4 * input_file_size_gb)
    Int disk_gb = 100


    command <<<
        set -e

        igvtools count \
        ~{true='--includeDuplicates ' false='' include_duplicates} \
        ~{true='--pairs ' false='' paired} \
        ~{"-z " + max_zoom} \
        ~{"-w " + window_size} \
        ~{"-e " + extend_factor} \
        ~{"--minMapQuality " + minimum_mapping_quality} \
        ~{sorted_bam} \
        ~{prefix}_igvtools.wig \
        ~{genome_id}

        wigToBigWig ~{prefix}_igvtools.wig ~{chrom_sizes} ~{prefix}_igvtools.bw

        igvtools count \
        ~{true='--includeDuplicates ' false='' include_duplicates} \
        ~{true='--pairs ' false='' paired} \
        ~{"-z " + max_zoom} \
        ~{"-w " + window_size} \
        ~{"-e " + extend_factor} \
        ~{"--minMapQuality " + minimum_mapping_quality} \
        ~{sorted_bam} \
        ~{prefix}_igvtools.tdf \
        ~{genome_id}


    >>>

    output {
        File igvtools_count_bw = "${prefix}_igvtools.bw"
        File igvtools_count_tdf = "${prefix}_igvtools.tdf"
    }

    runtime {
        cpu : cpus
        memory : mem_gb+'G'
        disks : 'local-disk ${disk_gb} SSD'
        docker : docker_image
    }

}
