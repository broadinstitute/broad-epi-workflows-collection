version 1.0

task pbsr {
  input {
    File binned_bed
    File mappability_bed
    String prefix = "prefix"

    # runtime values
    String docker = "swekhande/sw-dockers:mapping-bridge-pbs"
    Int disk_gb = 8
    Int machine_mem_gb = 2
  }

  command <<<
    set -euo pipefail
    Rscript "~{pbsR_script}" "~{binned_bed}" "~{mappability_bed}" "~{prefix}"
  >>>

  output {
    File pbs_bed          = "~{prefix}.pbs.bed"
    File pbs_plot         = "~{prefix}.pbs_plot.png"
    File pbs_dist_plot    = "~{prefix}.pbs_distribution_plot.png"
    Float k               = read_float("~{prefix}_k.txt")
    Float beta            = read_float("~{prefix}_beta.txt")
    Float lambda          = read_float("~{prefix}_lambda.txt")
  }

  runtime {
    docker: docker
    memory: "~{machine_mem_gb} GiB"
    disks: "local-disk ~{disk_gb} HDD"
  }
}
