# Take user input
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: pbsR_script.R <binned_bed> <map_df_file> <output_prefix>")
}

pkgload::load_all("pbs-analysis/pbsR")
library(foreach)
library(magrittr)

binned_bed <- args[1]
map_file <- args[2]
prefix <- args[3]

# Read mappability file
map_df <- read.csv(map_file, sep = "\t", header = FALSE)
colnames(map_df) = c("chr","start","end","mappability_score")

# Read input bed file
t1 <- read.csv(binned_bed, sep = "\t", header = FALSE)
colnames(t1) = c("chr","start","end","counts")
t2 = pbsR:::rescaleMappability(t1, map_df = map_df)
t3 = pbsR:::rescaleXY(t2)
t4 = PBS(t3)

# Write outputs
write.table(pbsR::getPBS(t4), paste0(prefix, ".pbs.bed"),
            quote = FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

write.table(t4$pbs_obj$beta, paste0(prefix, "_beta.txt"),
            quote = FALSE, sep = "\t", row.names = FALSE, col.names = FALSE)

write.table(t4$pbs_obj$k, paste0(prefix, "_k.txt"),
            quote = FALSE, sep = "\t", row.names = FALSE, col.names = FALSE)

write.table(t4$pbs_obj$lambda, paste0(prefix, "_lambda.txt"),
            quote = FALSE, sep = "\t", row.names = FALSE, col.names = FALSE)

# Save plot
ggplot2::ggsave(filename = paste0(prefix, ".pbs_plot.png"),
       plot = pbsR::getPBSPlot(t4, title_str = prefix))

ggplot2::ggsave(filename = paste0(prefix, ".pbs_distribution_plot.png"),
                plot = ggplot(data = t4$pbs_obj$bin_df) + geom_histogram(aes(x = pbs)) + xlab(paste0(prefix + ": PBS scores"))
                )