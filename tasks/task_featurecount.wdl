version 1.0

# TASK
# SHARE-rna-feature-count

task feature_counts_rna {
    meta {
        version: 'v0.1'
        author: 'Eugenio Mattei (emattei@broadinstitute.org) at Broad Institute of MIT and Harvard'
        description: 'Broad Institute of MIT and Harvard: assign features rna task'
    }

    input {
        # This function takes in input the bam file produced by the STAR
        # aligner run on a mixed index (e.g. mouse + human) and split
        # the reads into the two genomes

        Boolean multimapper
        Boolean intron
        Boolean paired
        Boolean primary
        Boolean counts_fragments
        File bam
        File gtf
        Int quality
        String feature_type = "exon"
        String format # SAF/GTF
        String gene_naming = "gene_name"
        String genome_name
        String? prefix
        String docker_image = "us.gcr.io/buenrostro-share-seq/share_task_count_rna"
        Int cpus = 6
        Int? disk_gb = 300
    }

    #Float input_file_size_gb = size(input[0], "G")
    Int mem_gb = 64
    
    #Int disk_gb = round(20.0 + 4 * input_file_size_gb)

    String featurecount_log = "${default="share-seq" prefix}.rna.featurecounts.alignment.wdup.${if multimapper then "multi" else "unique"}.${if intron then "intron" else "exon"}.${genome_name}.featurecount.log"
    String featurecount_out = "${default="share-seq" prefix}.rna.featurecounts.alignment.wdup.${if multimapper then "multi" else "unique"}.${if intron then "intron" else "exon"}.${genome_name}.featurecount.out.txt"


    command {
        set -e

        ln -s ${bam} temp_input.bam

        # Count reads in exons
        featureCounts -T ${cpus} \
            -Q ${quality} \
            ${if multimapper then "-M " else ""} \
            ${"-a " + gtf} \
            ${"-t " + feature_type} \
            ${"-g " + gene_naming} \
            ${"-F " + format} \
            -o ${featurecount_out} \
            -R BAM \
            ${true='--primary ' false=' ' primary} \
            ${if paired then "-p " else ""} \
            ${true='--countReadPairs ' false=' ' counts_fragments} \
            temp_input.bam >> ${featurecount_log}

            mv ${featurecount_out}.summary ${featurecount_out}.summary.txt

    }

    output {
        File rna_featurecount_summary = "${featurecount_out}.summary.txt"
        File rna_featurecount_counts = "${featurecount_out}"
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
        bam: {
                description: 'Alignment bam file',
                help: 'Aligned reads in bam format.',
                example: 'hg38.aligned.bam'
            }
        gtf: {
                description: 'GTF file',
                help: 'Genes definitions in GTF format.',
                example: 'hg38.refseq.gtf'
            }
        multimapper: {
                description: 'Multimappers flag',
                help: 'Flag to set if you want to keep the multimapping reads.',
                default: false,
                example: [true, false]
            }
        intron: {
                description: 'Introns flag',
                help: 'Flag to set if you want to include reads overlapping introns.',
                default: false,
                example: [true, false]
            }
        genome_name: {
                description: 'Reference name',
                help: 'The name genome reference used to align.',
                examples: ['hg38', 'mm10', 'hg19', 'mm9'],
            }
        gene_naming: {
                description: 'Gene nomenclature',
                help: 'Choose if you want to use the official gene symbols (gene_name) or ensemble gene names (gene_id).',
                default: 'gene_name',
                examples: ['gene_name', 'gene_id']
            }
        prefix: {
                description: 'Prefix for output files',
                help: 'Prefix that will be used to name the output files',
                example: 'MyExperiment'
            }
        cpus: {
                description: 'Number of cpus',
                help: 'Set the number of cpus useb by bowtie2',
                example: '4'
            }
        docker_image: {
                description: 'Docker image.',
                help: 'Docker image for preprocessing step. Dependencies: samtools',
                example: ['put link to gcr or dockerhub']
            }
    }
}
