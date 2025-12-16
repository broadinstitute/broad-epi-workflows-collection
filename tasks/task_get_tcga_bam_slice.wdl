version 1.0

task feature_counts_rna {
    meta {
        version: 'v0.1'
        author: 'Eugenio Mattei'
        description: 'Broad Institute of MIT and Harvard: assign features rna task'
    }

    input {
        # This function takes in input a gdc uuid accession and
        # using the gdc-client tool, downloads all the reads overlapping
        # provisuses annotations. The definition of the proviruses comes from 
        # Fridman et al (2026).

        # Inputs
        String bam_gdc_uuid
        File gdc_token_file
        String prefix

        # Runtime parameters
        String docker="polumechanos/gdc-client:latest"

    }

    #Float input_file_size_gb = size(input[0], "G")
    Int mem_gb = 64
    
    #Int disk_gb = round(20.0 + 4 * input_file_size_gb)


    command {
        set -e

        ln -s ${gdc_token_file} gdc-token-text-file.txt

        token=$(<gdc-token-text-file.txt)
        
        curl --header "X-Auth-Token: $token" 'https://api.gdc.cancer.gov/slicing/view/2912e314-f6a7-4f4a-94ac-20db2c8f793b?region=chr1&region=chr2:10000&region=chr3:10000-20000' --output ${prefix}_regions_slice.bam

    }

    output {
        File sliced_bam = "${prefix}_regions_slice.bam"
    }

    runtime {
        cpu : cpus
        memory : mem_gb+'G'
        disks : 'local-disk ${disk_gb} SSD'
        maxRetries : 0
        docker: docker_image
        monitoring_script: "gs://fc-a30e1a42-4d9b-4dc9-b343-aab547e1ee09/cromwell_monitoring_script2.sh"
    }

    parameter_meta {
        bam_gdc_uuid: {
                description: 'BAM UUID',
                help: 'UUID of the aligned reads from GDC.',
                example: 'adsads-dadsa-dsa'
            }
        gdc_token_file: {
                description: 'GDC acecssion token',
                help: 'Accession token obtained from GDC.',
                example: 'token.txt'
            }
        prefix: {
                description: 'Prefix for output files',
                help: 'Prefix that will be used to name the output files',
                example: 'MyExperiment'
            }
        docker_image: {
                description: 'Docker image.',
                help: 'Docker image for preprocessing step. Dependencies: samtools',
                example: ['put link to gcr or dockerhub']
            }
    }
}
