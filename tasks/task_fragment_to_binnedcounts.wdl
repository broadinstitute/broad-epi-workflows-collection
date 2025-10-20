version 1.0

task fragment_to_binnedcounts {
  input {
    File fragments                          
    File reference_tiled_bed                
    File chrom_sizes                        
    String prefix = "prefix"
    Int binsize = 5000
    Boolean tn5_count = false               # if true TN5 counting, else bigWigAverageOverBed

    String docker = "swekhande/sw-dockers:fragment_binning"
    Int disk_gb = 50
    Int machine_mem_gb = 4
  }

  command <<<
    set -euo pipefail

    gunzip -c "~{fragments}" > "~{prefix}.fragment.bed"
    wc -l "~{prefix}.fragment.bed"

    if [ "~{tn5_count}" = "true" ]; then
      echo "Running TN5 counting pipeline..."
      awk 'BEGIN{OFS="\t"} {print $1, $2+4, $2+5; print $1, $3-5, $3-4}' \
          "~{prefix}.fragment.bed" > "~{prefix}.tn5.bed"
      LC_COLLATE=C sort -k1,1 -k2,2n -S 2G -T . "~{prefix}.tn5.bed" > "~{prefix}.tn5.sorted.bed"
      LC_COLLATE=C sort -k1,1 -k2,2n "~{reference_tiled_bed}" > reference.sorted.bed
      bedtools intersect -c -sorted -a reference.sorted.bed -b "~{prefix}.tn5.sorted.bed" > "~{prefix}.binned.raw.bed"
      cut -f1,2,3,5 "~{prefix}.binned.raw.bed" > "~{prefix}.binned.raw.counts.bed"
      awk 'BEGIN{OFS="\t"} {bin=$3-$2; norm=($4/bin); print $1,$2,$3,norm}' \
          "~{prefix}.binned.raw.counts.bed" > "~{prefix}.binned.bed"

    else
      echo "Running BigWig average coverage pipeline..."
      bedtools genomecov -i "~{prefix}.fragment.bed" -g "~{chrom_sizes}" -bg > "~{prefix}.bedgraph"
      LC_COLLATE=C sort -k1,1 -k2,2n "~{prefix}.bedgraph" > "~{prefix}.sorted.bedgraph"
      bedGraphToBigWig "~{prefix}.sorted.bedgraph" "~{chrom_sizes}" "~{prefix}.bw"
      LC_COLLATE=C sort -k1,1 -k2,2n "~{reference_tiled_bed}" > reference.sorted.bed
      bigWigAverageOverBed "~{prefix}.bw" reference.sorted.bed stdout | cut -f5 > counts.txt
      paste <(cut -f1-3 reference.sorted.bed) counts.txt > "~{prefix}.binned.bed"
    fi

    echo "Done."
  >>>

  output {
    File binned_bed = "~{prefix}.binned.bed"
    #File bigwig = "~{prefix}.bw"
  }

  runtime {
    docker: docker
    memory: "~{machine_mem_gb} GiB"
    disks: "local-disk ~{disk_gb} HDD"
  }
}
