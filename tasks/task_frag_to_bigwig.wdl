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
  }

  command <<<
        set -euo pipefail

        merged_fragments="~{output_prefix}.merged.fragments.tsv.gz"
        out_bw="~{output_prefix}.bw"

        processed_beds=()

        for bed in ~{sep=' ' fragments}; do
            base="$(basename "$bed")"
            base="${base%.gz}"

            if ~{tn5_shift}; then
                out="tn5_shifted_${base}"

                if [[ "$bed" == *.gz ]]; then
                    gzip -dc "$bed" | \
                    awk 'BEGIN{OFS="\t"}{
                        $2=$2-4;
                        if ($2 < 0) $2=0;
                        $3=$3+4;
                        print
                    }' > "$out"
                else
                    awk 'BEGIN{OFS="\t"}{
                    $2=$2-4;
                    if ($2 < 0) $2=0;
                    $3=$3+4;
                    print
                    }' "$bed" > "$out"
                fi
            else
                out="unshifted_${base}"

                if [[ "$bed" == *.gz ]]; then
                    gzip -dc "$bed" > "$out"
                else
                    cat "$bed" > "$out"
                fi
            fi

            processed_beds+=("$out")
        done

        cat "${processed_beds[@]}" | sort -k1,1 -k2,2n | gzip -c > "$merged_fragments"

        scatac_fragment_tools bigwig \
        -i "$merged_fragments" \
        -c "~{chrom_sizes}" \
        -o "$out_bw" \
        ~{if normalize then "-n" else ""} \
        -s ~{scaling} \
        ~{if cut_sites then "-x" else ""} \
        ~{if chrom_prefix then "--chrom-prefix" else ""}
>>>

  output {
    File bigwig = "${output_prefix}.bw"
    #File merged_fragments = "${output_prefix}.merged.fragments.tsv.gz"
  }

  runtime {
    docker: "swekhande/shareseq-prod:scatac-fragment-tools-v2"
    cpu: 4
    memory: "32G"
    disks: "local-disk 100 SSD"
  }
}
