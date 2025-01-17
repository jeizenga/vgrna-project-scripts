
# plot_mapping_stats.R

rm(list=ls())

library("tidyverse")
library("gridExtra")
library("wesanderson")
library("scales")

source("./utils.R")

# printHeader()

# data_dir <- read.csv(args[6], sep = " ", header = F)
# setwd(data_dir)

########


parse_file <- function(filename) {
  
  dir_split <- strsplit(dirname(filename), "/")[[1]]
  
  data <- read_table2(filename)
  data <- data %>%
    add_column(Type = dir_split[5]) %>%
    add_column(Reads = dir_split[7]) %>%
    add_column(Method = dir_split[8]) %>%
    add_column(Graph = dir_split[9])
  
  if (!grepl("mpmap", filename)) {
    
     data <- data %>%
       mutate(AllelicMapQ = MapQ)
  }
  
  return(data)
}

mapping_data <- map_dfr(list.files(path = "./methods", pattern=".*_exon_ovl_gc.*.txt", full.names = T, recursive = T), parse_file)


########


mapping_data <- mapping_data %>%
  filter(Type == "polya_rna")

mapping_data$Method <- recode_factor(mapping_data$Method, 
                                           "hisat2" = "HISAT2",
                                           "star" = "STAR",
                                           "map_fast" = "vg map", 
                                           "mpmap" = "vg mpmap")

mapping_data <- mapping_data %>%
  filter(Graph != "1kg_NA12878_gencode100") %>%
  filter(Graph != "1kg_NA12878_exons_gencode100")

mapping_data$Graph = recode_factor(mapping_data$Graph, 
                                         "gencode100" = "Spliced reference",
                                         "1kg_nonCEU_af001_gencode100" = "Spliced pangenome graph",
                                         "1kg_all_af001_gencode100" = "Spliced pangenome graph")


mapping_data_stats <- mapping_data %>%
  mutate(MapQ = ifelse(IsMapped, MapQ, -1)) %>% 
  mutate(MapQ1 = Count * (MapQ >= 1)) %>% 
  mutate(MapQ30 = Count * (MapQ >= 30)) %>% 
  group_by(Reads, Method, Graph) %>%
  summarise(count = sum(Count), MapQ1 = sum(MapQ1), MapQ30 = sum(MapQ30)) %>%
  mutate(MapQ1_frac = MapQ1 / count, MapQ30_frac = MapQ30 / count) %>%
  gather("MapQ1_frac", "MapQ30_frac", key = "Filter", value = "Frac")

for (reads in unique(mapping_data_stats$Reads)) {
  
  mapping_data_stats_reads <- mapping_data_stats %>%
    filter(Reads == reads)
  
  mapping_data_stats_reads <- mapping_data_stats_reads %>%
    ungroup() %>%
    add_row(Reads = reads, Method = "STAR", Graph = "Spliced pangenome graph", count = 0, MapQ1 = 0, MapQ30 = 0, Filter = "MapQ1_frac", Frac = 0) %>%
    add_row(Reads = reads, Method = "STAR", Graph = "Spliced pangenome graph", count = 0, MapQ1 = 0, MapQ30 = 0, Filter = "MapQ30_frac", Frac = 0)
  
  mapping_data_stats_reads$Graph = recode_factor(mapping_data_stats_reads$Graph, 
                                                 "Spliced reference" = "Spliced\nreference",
                                                 "Spliced pangenome graph" = "Spliced\npangenome\ngraph")
  
  mapping_data_stats_reads$Filter <- recode_factor(mapping_data_stats_reads$Filter, 
                                                         "MapQ1_frac" = "MapQ >= 1", 
                                                         "MapQ30_frac" = "MapQ >= 30")
  
  mapping_data_stats_reads$FacetCol <- "Real reads"
  mapping_data_stats_reads$FacetRow <- ""
  
  plotMappingStatsBenchmark(mapping_data_stats_reads, wes_cols, paste("plots/real_stats/real_r1_stats_bar_", reads, sep = ""))
}

########
