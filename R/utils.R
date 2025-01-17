
# utils.R

library("ggrepel")
library("scales")

########


set.seed(4321)

wes_cols <- c(rev(wes_palette("Rushmore1")[c(1,3,4,5)]), wes_palette("Darjeeling1")[c(5)], wes_palette("Royal2")[c(1,2)])

printHeader <- function() {

  args <- commandArgs()
  cript_dir <- dirname(sub("--file=", "", args[4]))
  print(script_dir)
  
  print(args)
  system(paste(c("git", "-C", script_dir, "rev-parse", "HEAD"), collapse = " "))
  system(paste(c("git", "-C", script_dir, "rev-parse", "--abbrev-ref", "HEAD"), collapse = " "))
}

plotRocCurveMapq <- function(data, cols) {
  
  data <- data %>%
    mutate(TP = Count * Correct) %>% 
    mutate(FP = Count * !Correct)
  
  data_roc <- data %>% 
    mutate(MapQ = ifelse(IsMapped, MapQ, -1)) %>% 
    group_by(Method, Graph, FacetRow, FacetCol, MapQ) %>%
    summarise(TP = sum(TP), FP = sum(FP)) %>% 
    arrange(desc(MapQ), .by_group = T) %>%
    mutate(TPcs = cumsum(TP), FPcs = cumsum(FP)) %>%
    mutate(N = max(TPcs) + max(FPcs)) %>% 
    ungroup() %>%
    mutate(N = max(N)) %>%
    mutate(Sensitivity = (FPcs + TPcs) / N, Precision = TPcs / (FPcs + TPcs)) %>%
    filter(MapQ > 0)
  
  min_lim_x <- min(data_roc$Sensitivity)
  
  #a <- annotation_logticks(sides = "l")
  #a$data <- data.frame(x = NA, FacetCol = c(as.character(data_roc$FacetCol[1])))
  
  p <- data_roc %>%
    ggplot(aes(y = -1 * log10(1 - Precision), x = Sensitivity, color = Method, linetype = Graph, shape = Graph, label = MapQ)) +
    #a +
    geom_line(size = 1) +
    geom_point(data = subset(data_roc, MapQ == 0 | MapQ == 1 | (MapQ == 42 & grepl("Bowtie2", Method)) | MapQ == 60 | MapQ == 255), size = 2, alpha = 1) +
    geom_text_repel(data = subset(data_roc, MapQ == 0 | MapQ == 1 | (MapQ == 42 & grepl("Bowtie2", Method)) | MapQ == 60| MapQ == 255), size = 3.5, fontface = 2, show.legend = FALSE) +
    scale_y_continuous(breaks = seq(1, 4), labels = c(0.9, 0.99, 0.999, 0.9999)) + 
    facet_grid(FacetRow ~ FacetCol) +
    scale_color_manual(values = cols) +
    xlim(c(min_lim_x, 1)) +
    xlab("Mapping sensitivity") +
    ylab("Mapping accuracy") +
    theme_bw() +
    theme(aspect.ratio = 1) +
    theme(strip.background = element_blank()) +
    theme(panel.spacing = unit(0.5, "cm")) +
    theme(legend.key.width = unit(1, "cm")) +
    theme(text = element_text(size = 13)) +
    theme(legend.text = element_text(size = 12))
  print(p)   
}

plotMapQCurve <- function(data, cols, ylab) {

  p <- data %>%
    ggplot(aes(y = Value, x = MapQ, color = Method, linetype = Graph, shape = Graph)) +
    geom_line(size = 1) +
    geom_point(size = 2) +
    facet_grid(FacetRow ~ FacetCol) +
    scale_color_manual(values = cols) +
    xlab("Mapping quality threshold") +
    ylab(ylab) +
    theme_bw() +
    theme(aspect.ratio = 1) +
    theme(strip.background = element_blank()) +
    theme(panel.spacing = unit(0.5, "cm")) +
    theme(legend.key.width = unit(1, "cm")) +
    theme(text = element_text(size = 13)) +
    theme(legend.text = element_text(size = 12))
  print(p)
}

plotErrorCurve <- function(data, cols) {
  
  data <- data %>%
    mutate(TP = Count * Correct) %>% 
    mutate(FP = Count * !Correct) %>%
    filter(MapQ > 0) %>%
    mutate(MapQ = ifelse(MapQ > 60, 60, MapQ)) %>%
    group_by(Method, Graph, FacetRow, FacetCol, MapQ) %>%
    summarise(Count = sum(Count), TP = sum(TP), FP = sum(FP)) %>% 
    mutate(Est_MapQ = -10 * log10(FP / (TP +FP)))
  
  p <- data %>%
    ggplot(aes(y = Est_MapQ, x = MapQ, color = Method, size = Count, linetype = Graph)) +
    geom_point() +
    geom_line(size = 1) +
    facet_grid(FacetRow ~ FacetCol) +
    scale_color_manual(values = cols) +
    scale_size(breaks = c(0.5*10^6, 10*10^6, 75*10^6), labels = comma) +
    xlab("Estimated mapping quality") +
    ylab("Empirical mapping quality") +
    xlim(c(0,60)) +
    ylim(c(0,60)) +
    theme_bw() +
    theme(aspect.ratio = 1) +
    theme(strip.background = element_blank()) +
    theme(panel.spacing = unit(0.5, "cm")) +
    theme(legend.key.width = unit(1, "cm")) +
    theme(text = element_text(size = 13)) +
    theme(legend.text = element_text(size = 12))
  print(p) 
}

plotLogBins <- function(data, cols, xlab, ylab) {
  
  data <- data %>%
    mutate(value_x_log = log10(value_x + 1)) %>%
    mutate(value_y_log = log10(value_y + 1))
  
  breaks <- c(1, 10, 100, 1000, 10000)
    
  p <- data %>%
    ggplot(aes(y = value_y_log, x = value_x_log)) +
    geom_bin2d() +
    facet_grid(FacetRow ~ FacetCol) +
    scale_fill_gradient(name = "Count", trans = "log10", breaks = breaks, labels = breaks) +
    xlab(xlab) +
    ylab(ylab) +
    theme_bw() +
    theme(aspect.ratio = 1) +
    theme(strip.background = element_blank()) +
    theme(panel.spacing = unit(0.5, "cm")) +
    theme(legend.key.width = unit(1, "cm")) +
    theme(text = element_text(size = 10)) +
    theme(legend.text = element_text(size = 9))
  print(p) 
}

plotBiasCurve <- function(data, cols, min_count) {
  
  data <- data %>%
    mutate(ref = (ref_up + ref_down) / 2) %>%
    mutate(alt = (alt_up + alt_down) / 2) %>%
    filter(ref + alt >= min_count) %>%
    mutate(frac = alt / (ref + alt)) %>%
    mutate(len = ifelse(len > 15, 16, len)) %>%
    mutate(len = ifelse(len < -15, -16, len)) %>%
    group_by(Method, Graph, FacetCol, FacetRow, var, len) %>%
    summarise(n = n(), ref_count = sum(ref), alt_count = sum(alt), frac_mean = mean(frac))  
  
  p <- data %>% 
    ggplot(aes(y = frac_mean, x = len, color = Method, linetype = Graph, shape = Graph, label = sprintf("%0.3f", round(frac_mean, digits = 3)))) +
    geom_line(size = 0.75) + 
    geom_point(data = subset(data, len == 0), size = 2) +  
    geom_text_repel(data = subset(data, len == 0), size = 3, fontface = 2, box.padding = 0.75, show.legend = FALSE) +  
    geom_hline(yintercept = 0.5, size = 0.5, linetype = 1, alpha = 0.75) + 
    facet_grid(FacetRow ~ FacetCol) +
    scale_color_manual(values = cols) +
    scale_x_continuous(breaks=c(-16, -10, -5, 0, 5, 10, 16), labels = c("<-15", "-10", "-5", "SNV", "5", "10", ">15")) +
    ylim(c(0.3, 0.7)) +
    xlab("Allele length") +
    ylab("Mean fraction of reads on alt allele") +
    guides(linetype = FALSE) +
    guides(shape = FALSE) +
    theme_bw() +
    theme(strip.background = element_blank()) +
    theme(panel.spacing = unit(0.3, "cm")) +
    theme(legend.key.width = unit(1, "cm")) +
    theme(text = element_text(size = 14)) +
    theme(legend.text = element_text(size = 13))
  print(p)
}

plotBiasBinom <- function(data, cols, min_count) {
  
  data <- data %>%
    ungroup() %>%
    mutate(ref = (ref_up + ref_down) / 2) %>%
    mutate(alt = (alt_up + alt_down) / 2) %>%
    filter(ref + alt >= min_count) %>%
    mutate(count = ref + alt) %>%
    rowwise() %>%
    mutate(binom_test = binom.test(x = c(round(ref), round(alt)), alternative = "two.sided")$p.value) %>%
    group_by(Method, Graph, FacetCol, FacetRow, var) %>%
    summarise(n = n(), n_binom = sum(binom_test <= 0.01))
  
  data %>% print(n = 100)
  
  p <- data %>% 
    ggplot(aes(y = n_binom / n, x = n, color = Method, shape = Graph)) +
    geom_point(size = 1.5) +
    scale_color_manual(values = cols) +
    facet_grid(FacetRow ~ FacetCol, scales="free_x") +
    xlab(paste("Number of variants (coverage >= ", min_count, ")", sep = "")) +
    ylab(expression(paste("Fraction of biased variants (", alpha, " = 0.01)", sep = ""))) +
    theme_bw() +
    theme(aspect.ratio = 1) +
    theme(strip.background = element_blank()) +
    theme(panel.spacing = unit(0.5, "cm")) +
    theme(legend.key.width = unit(1, "cm")) +
    theme(text = element_text(size = 10)) +
    theme(legend.text = element_text(size = 9))
  print(p)
}

plotStatsBarTwoLayer <- function(data, cols) {
  
  data_bar <- data
  min_frac <- data_bar %>% filter(Frac > 0) %>% summarise(frac = min(Frac))
  
  p <- ggplot() +
    geom_bar(data = data_bar[data_bar$Filter == "MapQ >= 30",], aes(Graph, y = Frac, fill = Method, alpha = Filter), stat = "identity", width = 0.5, position = position_dodge()) +
    geom_bar(data = data_bar[data_bar$Filter == "MapQ >= 1",], aes(Graph, y = Frac, fill = Method, alpha = Filter), stat = "identity", width = 0.5, position = position_dodge(), alpha = 0.5) +
    scale_fill_manual(values = cols) +
    scale_alpha_manual(name = "Filter", values = c(0.5, 1), labels = c("MapQ >= 1", "MapQ >= 30"), drop = F) + 
    scale_y_continuous(limits = c(floor(min_frac$frac * 10) / 10, 1), oob = rescale_none) +
    facet_grid(FacetRow ~ FacetCol) +
    xlab("") +
    ylab("Mapping rate") +
    theme_bw() +
    theme(strip.background = element_blank()) +
    theme(panel.spacing = unit(0.5, "cm")) +
    theme(text = element_text(size = 12)) +
    theme(legend.text = element_text(size = 11))
  print(p)
}

plotStatsBar <- function(data, cols, ylab) {
  
  min_frac <- data %>% filter(Frac > 0) %>% ungroup() %>% summarise(frac = min(Frac))
  
  p <- data %>% 
    ggplot(aes(Graph, y = Frac, fill = Method)) +
    geom_bar(stat = "identity", width = 0.5, position = position_dodge()) +
    scale_fill_manual(values = cols) +
    scale_y_continuous(limits = c(floor(min_frac$frac * 2) / 2, 1), oob = rescale_none) +
    facet_grid(FacetRow ~ FacetCol) +
    xlab("") +
    ylab(ylab) +
    theme_bw() +
    theme(strip.background = element_blank()) +
    theme(panel.spacing = unit(0.5, "cm")) +
    theme(text = element_text(size = 12)) +
    theme(legend.text = element_text(size = 11))
  print(p)
}

plotBar <- function(data, cols, ylab) {
  
  p <- data %>% 
    ggplot(aes(x = Graph, y = Value, fill = Method)) +
    geom_bar(stat = "identity", width = 0.5, position = position_dodge()) +
    scale_fill_manual(values = cols) +
    facet_grid(FacetRow ~ FacetCol) +
    xlab("") +
    ylab(ylab) +
    theme_bw() +
    theme(strip.background = element_blank()) +
    theme(panel.spacing = unit(0.5, "cm")) +
    theme(text = element_text(size = 12)) +
    theme(legend.text = element_text(size = 11))
  print(p)
}

plotRocBenchmarkMapQ <- function(data, cols, filename) {

  pdf(paste(filename, "_roc.pdf", sep = ""), height = 5, width = 7, pointsize = 12)
  plotRocCurveMapq(data, cols)
  dev.off() 
}

plotErrorBenchmark <- function(data, cols, filename) {
  
  pdf(paste(filename, "_error.pdf", sep = ""), height = 5, width = 7, pointsize = 12)
  plotErrorCurve(data, cols)
  dev.off() 
}

plotMappingBiasBenchmark <- function(data, cols, filename) {

  pdf(paste(filename, ".pdf", sep = ""), height = 4, width = 9, pointsize = 12)
  plotBiasCurve(data, cols, 20)
  dev.off() 
}

plotMappingBiasBinomBenchmark <- function(data, cols, filename) {
  
  pdf(paste(filename, ".pdf", sep = ""), height = 5, width = 9, pointsize = 12)
  plotBiasBinom(data, cols, 20)
  dev.off() 
}

plotMappingStatsBenchmark <- function(data, cols, filename) {

  pdf(paste(filename, ".pdf", sep = ""), height = 4, width = 4, pointsize = 12)
  plotStatsBarTwoLayer(data, cols)
  dev.off() 
}

plotIsoSeqCorrelationBenchmark <- function(data, cols, filename) {
  
  data <- data %>%
    rename(Value = Corr) 
  
  pdf(paste(filename, ".pdf", sep = ""), height = 5, width = 7, pointsize = 12)
  plotMapQCurve(data, cols, "Iso-Seq exon coverage correlation")
  dev.off() 
}

plotIsoSeqCoverageBenchmark <- function(data, cols, filename) {
  
  data <- data %>%
    rename(value_x = Coverage.est) %>%
    rename(value_y = Coverage.pb)
  
  pdf(paste(filename, ".pdf", sep = ""), height = 5, width = 7, pointsize = 12)
  plotLogBins(data, cols, "Estimated exon coverage (log10 + 1)", "Iso-Seq exon coverage (log10 + 1)")
  dev.off() 
}

plotMappingComputeBenchmark <- function(data, cols, filename) {
  
  data <- data %>%
    rename(Value = Time)
  
  pdf(paste(filename, ".pdf", sep = ""), height = 4, width = 4, pointsize = 12)
  plotBar(data, cols, "Read pairs mapped per second")
  dev.off() 
}

plotMappingMemoryBenchmark <- function(data, cols, filename) {
  
  data <- data %>%
    rename(Value = Mem)
  
  pdf(paste(filename, ".pdf", sep = ""), height = 4, width = 4, pointsize = 12)
  plotBar(data, cols, "Maximum memory usage (GiB)")
  dev.off() 
}
