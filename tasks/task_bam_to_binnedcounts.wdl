version 1.0

task bam_to_binnedcounts {
  input {
    File bam
    File reference_tiled_bed # bed file of the binned genome without blacklist regions, 4th column = numbered index
    File igv_genome_file
    File chrom_sizes
    String prefix = "prefix"
    Int binsize = 5000

    # runtime values
    String docker = "quay.io/kdong2395/pbs:kdong-dev"
    Int disk_gb = 50
    Int machine_mem_gb = 4
  }

  command <<<
    set -e
    
    igvtools count -w ~{binsize} --minMapQuality 1 --pairs ~{bam} ~{prefix}.wig ~{igv_genome_file}
    wigToBigWig ~{prefix}.wig ~{chrom_sizes} ~{prefix}.bw
    bigWigAverageOverBed ~{prefix}.bw ~{reference_tiled_bed} stdout | cut -f 5 > counts.txt
    cut -f 1-3 ~{reference_tiled_bed} - | paste - counts.txt > ~{prefix}.binned.bed
  >>>

  output {
    File binned_bed = "~{prefix}.binned.bed"
    File bigwig     = "~{prefix}.bw"
  }

  runtime {
    docker: docker
    memory: "~{machine_mem_gb} GiB"
    disks: "local-disk ~{disk_gb} HDD"
  }
}
