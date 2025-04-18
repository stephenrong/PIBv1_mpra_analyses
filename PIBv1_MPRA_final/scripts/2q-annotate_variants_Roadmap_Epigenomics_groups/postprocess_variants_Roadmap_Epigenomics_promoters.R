#!/bin/R

# for data analysis
library(tidyverse)
library(data.table)

# for bio data analysis
library(plyranges)
library(rtracklayer)
source("../shared_functions/seqinfo_fix_change.R")

# load variants
introgressed_variants_tb <- as_tibble(readRDS("../../results/1a-preprocess_PIBv1_MPRA_final/introgressed_variants.rds"))[,1:10]

# load Roadmap_Epigenomics_promoters
Roadmap_Epigenomics_promoters_tb <- as_tibble(fread(paste0("../../../Datasets/gene_regulation_element_catalogs/Roadmap_Epigenomics_elements/data_cleanup/GRCh37_merged/Roadmap_Epigenomics_promoters2_groups.txt.gz")))

# rename group
Roadmap_Epigenomics_promoters_tb <- Roadmap_Epigenomics_promoters_tb %>% 
	mutate(group = gsub(" ", "_", group)) %>% 
	mutate(group = gsub("\\.", "", group)) %>% 
	mutate(group = gsub("&", "and", group))

# Roadmap_Epigenomics_promoters names
names(Roadmap_Epigenomics_promoters_tb)[6:length(Roadmap_Epigenomics_promoters_tb)] <- paste("Roadmap_Epigenomics_promoters_orig", names(Roadmap_Epigenomics_promoters_tb)[6:length(Roadmap_Epigenomics_promoters_tb)], sep="_")
introgressed_variants_Roadmap_Epigenomics_promoters_names <- names(Roadmap_Epigenomics_promoters_tb)[6:length(Roadmap_Epigenomics_promoters_tb)]

# overlap variants and Roadmap_Epigenomics_promoters
introgressed_variants_Roadmap_Epigenomics_promoters <- as_tibble(find_overlaps(GRanges(introgressed_variants_tb), GRanges(Roadmap_Epigenomics_promoters_tb)))

# Roadmap_Epigenomics_promoters names
introgressed_variants_Roadmap_Epigenomics_promoters_names <- names(introgressed_variants_Roadmap_Epigenomics_promoters)[11:length(introgressed_variants_Roadmap_Epigenomics_promoters)]

# collapse by group
introgressed_variants_Roadmap_Epigenomics_promoters_collapse <- introgressed_variants_Roadmap_Epigenomics_promoters %>% 
	group_by(seqnames, start, end, width, strand, VariantID, VariantCHROM, VariantPOS, VariantREF, VariantALT) %>% 
	dplyr::summarise_at(introgressed_variants_Roadmap_Epigenomics_promoters_names, function(x) {paste(x, collapse=",")}) %>% 
	ungroup() %>% 
	mutate(Roadmap_Epigenomics_promoters_summ_Group = Roadmap_Epigenomics_promoters_orig_group) %>% 
	mutate(Roadmap_Epigenomics_promoters_summ_Summary = "Roadmap_Epigenomics_promoters_overlap") %>% 
	dplyr::select(seqnames, start, end, width, strand, VariantID, VariantCHROM, VariantPOS, VariantREF, VariantALT, 
		starts_with("Roadmap_Epigenomics_promoters_orig"), Roadmap_Epigenomics_promoters_summ_Summary, Roadmap_Epigenomics_promoters_summ_Group)

# pivot by group
introgressed_variants_Roadmap_Epigenomics_promoters_pivot <- introgressed_variants_Roadmap_Epigenomics_promoters %>% 
	mutate(Roadmap_Epigenomics_promoters_orig_group_temp = Roadmap_Epigenomics_promoters_orig_group) %>% 
	pivot_wider(names_from=Roadmap_Epigenomics_promoters_orig_group, names_sep="-", names_prefix="Roadmap_Epigenomics_promoters_summ_Group-", values_from=Roadmap_Epigenomics_promoters_orig_group_temp)

# join together
introgressed_variants_Roadmap_Epigenomics_promoters <- full_join(introgressed_variants_Roadmap_Epigenomics_promoters_collapse, introgressed_variants_Roadmap_Epigenomics_promoters_pivot)

# merge to full variants
introgressed_variants_tb <- as_tibble(fread("../../results/1a-preprocess_PIBv1_MPRA_final/introgressed_variants.txt.gz")) %>% 
	dplyr::select(seqnames, start, end, width, strand, VariantID, VariantCHROM, VariantPOS, VariantREF, VariantALT)
names_temp <- intersect(names(introgressed_variants_tb), names(introgressed_variants_Roadmap_Epigenomics_promoters))
introgressed_variants_Roadmap_Epigenomics_promoters <- introgressed_variants_tb %>% mutate_at(names_temp, as.character)%>% 
	left_join(introgressed_variants_Roadmap_Epigenomics_promoters %>% mutate_at(names_temp, as.character))

# save all variants
write_tsv(introgressed_variants_Roadmap_Epigenomics_promoters, gzfile("../../results/2q-annotate_variants_Roadmap_Epigenomics_groups/introgressed_variants_Roadmap_Epigenomics_promoters.txt.gz"))

# save summ variants
introgressed_variants_Roadmap_Epigenomics_promoters_summ <- introgressed_variants_Roadmap_Epigenomics_promoters %>% 
	dplyr::select(seqnames, start, end, width, strand, starts_with("Variant"), contains("_summ_"))
write_tsv(introgressed_variants_Roadmap_Epigenomics_promoters_summ, gzfile("../../results/2q-annotate_variants_Roadmap_Epigenomics_groups/introgressed_variants_Roadmap_Epigenomics_promoters_summ.txt.gz"))
sort(table(introgressed_variants_Roadmap_Epigenomics_promoters_summ$Roadmap_Epigenomics_promoters_summ_Summary))
