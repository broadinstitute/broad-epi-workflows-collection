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
    wc -l ~{prefix}.fragment.bed

    awk 'BEGIN{OFS="\t"} {print $1, $2+4, $2+5; print $1, $3-5, $3-4}' \
        ~{prefix}.fragment.bed > ~{prefix}.tn5.bed
    wc -l ~{prefix}.tn5.bed

    LC_COLLATE=C sort -k1,1 -k2,2n -S 2G -T . ~{prefix}.tn5.bed > ~{prefix}.tn5.sorted.bed
    LC_COLLATE=C sort -k1,1 -k2,2n ~{reference_tiled_bed} > reference.bed
    wc -l reference.bed

    bedtools intersect -c -sorted -a reference.bed -b ~{prefix}.tn5.sorted.bed > ~{prefix}.binned.raw.bed
    cut -f1,2,3,5 ~{prefix}.binned.raw.bed > ~{prefix}.binned.raw.counts.bed

    head ~{prefix}.binned.raw.counts.bed
    wc -l ~{prefix}.binned.raw.bed

    awk 'BEGIN{OFS="\t"} {bin=$3-$2; norm=$4/bin; print $1,$2,$3,norm}' \
        ~{prefix}.binned.raw.counts.bed > ~{prefix}.binned.norm.bed

  >>>

  output {
    File binned_bed = "~{prefix}.binned.norm.bed"
    #File bigwig     = "~{prefix}.bw"
  }

  runtime {
    docker: docker
    memory: "~{machine_mem_gb} GiB"
    disks: "local-disk ~{disk_gb} HDD"
  }
}
