#!/bin/R

# for data analysis
library(tidyverse)
library(data.table)

# for bio data analysis
library(plyranges)
library(vcfR)

# load VCF
introgressed_variants_gnomAD_v3.1.2_AFs <- read.vcfR("../../results/2d-annotate_variants_gnomAD_AFs/introgressed_variants_lift38_chr_lift37_abbrev-gnomad.genomes.v3.1.2.sites.vcf.gz")

# split INFO
introgressed_variants_gnomAD_v3.1.2_AFs <- vcfR2tidy(introgressed_variants_gnomAD_v3.1.2_AFs, info_only=TRUE)$fix

# rename CHROM
introgressed_variants_gnomAD_v3.1.2_AFs <- introgressed_variants_gnomAD_v3.1.2_AFs %>% 
	mutate(CHROM = gsub("chr", "", CHROM)) 

# filter SNPs
introgressed_variants_gnomAD_v3.1.2_AFs <- introgressed_variants_gnomAD_v3.1.2_AFs %>% 
	filter(REF %in% c("A", "C", "G", "T"), ALT %in% c("A", "C", "G", "T"))

# save names
names(introgressed_variants_gnomAD_v3.1.2_AFs)[c(3,6:length(introgressed_variants_gnomAD_v3.1.2_AFs))] <- paste("gnomAD_v3.1.2_orig", names(introgressed_variants_gnomAD_v3.1.2_AFs)[c(3,6:length(introgressed_variants_gnomAD_v3.1.2_AFs))], sep="_")
introgressed_variants_gnomAD_v3.1.2_AFs_names <- names(introgressed_variants_gnomAD_v3.1.2_AFs)[c(3,6:length(introgressed_variants_gnomAD_v3.1.2_AFs))]

# add GRange and Variant cols
introgressed_variants_gnomAD_v3.1.2_AFs <- introgressed_variants_gnomAD_v3.1.2_AFs %>% 
	mutate(VariantCHROM = CHROM, VariantPOS = POS, VariantREF = REF, VariantALT = ALT) %>% 
	mutate(VariantID = paste(VariantCHROM, VariantPOS, VariantREF, VariantALT, sep="_")) %>% 
	mutate(seqnames=VariantCHROM, start=VariantPOS, end=VariantPOS, width=1, strand="*") %>% 
	dplyr::select(seqnames, start, end, width, strand, VariantID, VariantCHROM, VariantPOS, VariantREF, VariantALT, all_of(introgressed_variants_gnomAD_v3.1.2_AFs_names))

# save only summary cols
introgressed_variants_gnomAD_v3.1.2_AFs <- introgressed_variants_gnomAD_v3.1.2_AFs %>% 
	dplyr::select(seqnames, start, end, width, strand, VariantID, VariantCHROM, VariantPOS, VariantREF, VariantALT, all_of(paste("gnomAD_v3.1.2_orig", 
		c("AF", "AC", "AN", "AF_oth", "AC_oth", "AN_oth", "AF_ami", "AC_ami", "AN_ami", "AF_sas", "AC_sas", "AN_sas", "AF_fin", "AC_fin", "AN_fin", "AF_eas", "AC_eas", "AN_eas", "AF_amr", "AC_amr", "AN_amr", "AF_afr", "AC_afr", "AN_afr", "AF_mid", "AC_mid", "AN_mid", "AF_asj", "AC_asj", "AN_asj", "AF_nfe", "AC_nfe", "AN_nfe"), sep="_")))
names(introgressed_variants_gnomAD_v3.1.2_AFs) <- gsub("_orig_", "_summ_", names(introgressed_variants_gnomAD_v3.1.2_AFs))

# merge to full variants
introgressed_variants_tb <- as_tibble(fread("../../results/1a-preprocess_PIBv1_MPRA_final/introgressed_variants.txt.gz")) %>% 
	dplyr::select(seqnames, start, end, width, strand, VariantID, VariantCHROM, VariantPOS, VariantREF, VariantALT)
names_temp <- intersect(names(introgressed_variants_tb), names(introgressed_variants_gnomAD_v3.1.2_AFs))
introgressed_variants_gnomAD_v3.1.2_AFs <- introgressed_variants_tb %>% mutate_at(names_temp, as.character)%>% 
	left_join(introgressed_variants_gnomAD_v3.1.2_AFs %>% mutate_at(names_temp, as.character))

# save all variants
write_tsv(introgressed_variants_gnomAD_v3.1.2_AFs, gzfile("../../results/2d-annotate_variants_gnomAD_AFs/introgressed_variants_gnomAD_v3.1.2_AFs.txt.gz"))

# save summ variants
introgressed_variants_gnomAD_v3.1.2_AFs_summ <- introgressed_variants_gnomAD_v3.1.2_AFs %>% 
	dplyr::select(seqnames, start, end, width, strand, starts_with("Variant"), contains("_summ_"))
write_tsv(introgressed_variants_gnomAD_v3.1.2_AFs_summ, gzfile("../../results/2d-annotate_variants_gnomAD_AFs/introgressed_variants_gnomAD_v3.1.2_AFs_summ.txt.gz"))
