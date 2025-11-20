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
    File? barcode_file  
    Boolean tn5_shift = true
    Boolean cutoff_analysis_flag = true
  }

  command <<<
    set -euo pipefail

  shifted_beds=()

  for bed in ~{sep=' ' bed_files}; do
      out="tn5_$(basename "$bed")"

      # auto-detect gzip
      if [[ "$bed" == *.gz ]]; then
          zcat "$bed" | \
            awk 'BEGIN{OFS="\t"}{$2=$2-4;$3=$3+4;print}' > "$out"
      else
          awk 'BEGIN{OFS="\t"}{$2=$2-4;$3=$3+4;print}' "$bed" > "$out"
      fi

      shifted_beds+=("$out")
  done

    macs3 callpeak \
      -f FRAG \
      -t "${shifted_beds[@]}" \
      -g ~{genome_size} \
      -q ~{qvalue} \
      ~{if cutoff_analysis_flag then "--cutoff-analysis" else ""} \
      ~{if defined(barcode_file) then "--barcodes " + barcode_file else ""} \
      -n ~{name_prefix}

    mkdir macs_output
    mv ~{name_prefix}* macs_output/
            
    wc -l macs_output/~{name_prefix}_peaks.narrowPeak | awk '{print $1}' > macs_output/peak_count.txt

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

task split_celltypes {
    input {
        File barcode_map   # TSV: barcode <tab> celltype
    }

    command <<<
        set -euo pipefail
        mkdir out

        # Extract unique cell types
        cut -f2 ~{barcode_map} | sort -u > out/celltypes.txt

        # Create barcode lists + mapping TSV
        echo -n "" > out/barcode_file_map.tsv

        while read CT; do
            outfile="out/${CT}_barcodes.txt"
            awk -v ct="$CT" '$2==ct{print $1}' ~{barcode_map} > "$outfile"
            echo -e "${CT}\t${outfile}" >> out/barcode_file_map.tsv
        done < out/celltypes.txt
    >>>

    output {
        Array[String] celltypes = read_lines("out/celltypes.txt")
        Map[String, File] barcode_lists = read_map("out/barcode_file_map.tsv")
    }

    runtime {
        docker: "ubuntu:22.04"
        cpu: 1
        memory: "1G"
    }
}
