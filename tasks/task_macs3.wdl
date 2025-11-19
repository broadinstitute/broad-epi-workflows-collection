version 1.0

task task_macs3 {

    meta {
        version: 'v0.1'
        author: 'Siddarth Wekhande (swekhand@broadinstitute.org) at Broad Institute of MIT and Harvard'
        description: 'Broad Institute of MIT and Harvard: Call peaks using MACS3'
    }

  input {
    Array[File] bed_files
    String name_prefix
    Float genome_size
    Float qvalue
  }

  command <<<
    set -euo pipefail

    echo "[$(date)] ===== RESOURCE USAGE REPORT (START) =====" >&2
    free -m >&2
    df -h >&2
    echo "[$(date)] =========================================" >&2

    macs3 callpeak \
      -f FRAG \
      -t ~{sep=' ' bed_files} \
      -g ~{genome_size} \
      -q ~{qvalue} \
      --cutoff-analysis \
      -n ~{name_prefix}

    mkdir macs_output
    mv ~{name_prefix}* macs_output/
            
    wc -l macs_output/~{name_prefix}_peaks.narrowPeak | awk '{print $1}' > macs_output/peak_count.txt


    echo "[$(date)] ===== RESOURCE USAGE REPORT (END) =====" >&2
    free -m >&2
    df -h >&2
    echo "[$(date)] =======================================" >&2
  >>>

  output {
    File narrow_peaks = "macs_output/~{name_prefix}_peaks.narrowPeak"
    File summit_bed = "macs_output/~{name_prefix}_summits.bed"
    File cutoff_analysis = "macs_output/~{name_prefix}_cutoff_analysis.txt"
    Float peak_count = read_float("macs_output/peak_count.txt")
  }

  runtime {
    docker: "jespina/chtc-macs3:1.0"
    cpu: 4
    memory: "32G"
    disks: "local-disk 100 SSD"
  }
}