version 1.0

# TASK
# bedGraphToBigWig

task bedGraphToBigWig {
    meta {
        version: 'v0.1'
        author: 'Eugenio Mattei (emattei@broadinstitute.org) at Broad Institute of MIT and Harvard'
        description: 'Broad Institute of MIT and Harvard: Deeptools QC step'
    }

    input {
        # This task takes in input the bedgraphs for input and ctrl and call peaks.
        File bedGraph
        File chrom_sizes

        String? prefix

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
        gzip -dc ~{bedGraph} | LC_ALL=C sort -k1,1 -k2,2n > sorted
        bedGraphToBigWig sorted ~{chrom_sizes} ~{prefix}.bw
    >>>

    output {
        File converted_bw = "${prefix}.bw"
    }

    runtime {
        cpu : cpus
        memory : mem_gb+'G'
        disks : 'local-disk ${disk_gb} SSD'
        docker : docker_image
    }

}
