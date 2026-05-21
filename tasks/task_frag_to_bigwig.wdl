version 1.0

task task_frag_to_bigwig {

    meta {
        version: 'v0.1'
        author: 'Siddarth Wekhande (swekhand@broadinstitute.org) at Broad Institute of MIT and Harvard'
        description: 'Broad Institute of MIT and Harvard: Create bigwigs using scatac_fragment_tools'
    }

  input {
    Array[File] fragments
    String output_prefix
    File chrom_sizes
    File? barcode_file  
    Boolean tn5_shift = true

    Boolean normalize = false
    Float scaling = 1.0
    Boolean cut_sites = false
    Boolean chrom_prefix = false
    String sort_memory = "4G"
    Int cpu = 8
  }

  command <<<
  set -euo pipefail

  log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
  }

  merged_fragments="~{output_prefix}.merged.fragments.tsv.gz"
  out_bw="~{output_prefix}.bw"

  log "Starting fragment processing"
  log "Output merged fragments: ${merged_fragments}"
  log "Output bigWig: ${out_bw}"
  log "Tn5 shift enabled: ~{tn5_shift}"

  mkdir -p sort_tmp

  log "Streaming gzipped fragments, applying optional Tn5 shift, sorting, and compressing"

  {
    for bed in ~{sep=' ' fragments}; do
      log "Processing input: ${bed}"

      if ~{tn5_shift}; then
        gzip -dc "${bed}" | awk 'BEGIN{OFS="\t"}{
          $2=$2-4;
          if ($2 < 0) $2=0;
          $3=$3+4;
          print
        }'
      else
        gzip -dc "${bed}"
      fi
    done
  } | sort \
        -T sort_tmp \
        -S ~{sort_memory} \
        --parallel ~{cpu} \
        -k1,1 -k2,2n | \
      gzip -c > "${merged_fragments}"

  log "Finished merge/sort/compression"
  log "Merged fragments size:"
  ls -lh "${merged_fragments}" >&2

  log "Running scatac_fragment_tools bigwig"

  scatac_fragment_tools bigwig \
    -i "${merged_fragments}" \
    -c "~{chrom_sizes}" \
    -o "${out_bw}" \
    ~{if normalize then "-n" else ""} \
    -s ~{scaling} \
    ~{if cut_sites then "-x" else ""} \
    ~{if chrom_prefix then "--chrom-prefix" else ""}

  log "Finished bigWig generation"
  log "bigWig size:"
  ls -lh "${out_bw}" >&2

>>>

  output {
    File bigwig = "${output_prefix}.bw"
    #File merged_fragments = "${output_prefix}.merged.fragments.tsv.gz"
  }

  runtime {
    docker: "swekhande/shareseq-prod:scatac-fragment-tools-v2"
    cpu: 8
    memory: "128G"
    disks: "local-disk 500 SSD"
  }
}
