version 1.0

task fragment_to_binnedcounts {
  input {
    File fragments
    File reference_tiled_bed # bed file of the binned genome without blacklist regions, 4th column = numbered index
    File igv_genome_file
    File chrom_sizes
    String prefix = "prefix"
    Int binsize = 5000

    # runtime values
    String docker = "swekhande/sw-dockers:fragment_binning"
    Int disk_gb = 50
    Int machine_mem_gb = 4
  }

  command <<<
    set -euo pipefail

    #gunzip -c ~{fragments} > ~{prefix}.fragment.bed
    #bedtools genomecov -i ~{prefix}.fragment.bed -g ~{chrom_sizes} -bg > ~{prefix}.bedgraph
    #LC_COLLATE=C sort -k1,1 -k2,2n ~{prefix}.bedgraph > ~{prefix}.sorted.bedgraph  
    #rm ~{prefix}.bedgraph
    #bedGraphToBigWig ~{prefix}.sorted.bedgraph ~{chrom_sizes} ~{prefix}.bw
    #bigWigAverageOverBed ~{prefix}.bw ~{reference_tiled_bed} stdout | cut -f 5 > counts.txt
    #cut -f 1-3 ~{reference_tiled_bed} - | paste - counts.txt > ~{prefix}.binned.bed

    gunzip -c ~{fragments} > ~{prefix}.fragment.bed
    
    # add Tn5 insertion sites, two per fragment
    awk 'BEGIN{OFS="\t"} {print $1, $2+4, $2+5; print $1, $3-5, $3-4}' \
    ~{prefix}.fragment.bed > ~{prefix}.tn5.bed
    
    LC_COLLATE=C sort -k1,1 -k2,2n ~{prefix}.tn5.bed > ~{prefix}.tn5.sorted.bed

    # 4. Create genome-wide insertion track (bigWig)
    bedtools genomecov -i ~{prefix}.tn5.sorted.bed -g ~{chrom_sizes} -bg > ~{prefix}.tn5.bedgraph
    bedGraphToBigWig ~{prefix}.tn5.bedgraph ~{chrom_sizes} ~{prefix}.tn5.bw
    rm ~{prefix}.tn5.bedgraph

    bigWigAverageOverBed ~{prefix}.tn5.bw ~{reference_tiled_bed} stdout | cut -f 5 > counts.txt
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
