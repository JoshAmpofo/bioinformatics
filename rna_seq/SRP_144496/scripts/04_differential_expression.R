#!/usr/bin/env Rscript

# ============================================================
# SRP144496 RNA-seq
# Stage 4: Differential Expression Analysis
#
# Comparisons:
#   1. HT55  : itraconazole vs control
#   2. SW948 : itraconazole vs control
#
# Outputs:
#   - PCA
#   - sample correlation heatmap
#   - dispersion plot
#   - normalized counts
#   - annotated DESeq2 results
#   - significant DEG tables
#   - upregulated / downregulated DEG tables
#   - MA plots
#   - volcano plots with gene labels
#   - cell-line-specific top-50 DEG heatmaps
# ============================================================


# ============================================================
# Load libraries
# ============================================================

suppressPackageStartupMessages({

    library(DESeq2)
    library(ggplot2)
    library(pheatmap)
    library(ggrepel)

})


# ============================================================
# Configuration
# ============================================================

COUNT_FILE <- paste0(
    "results/06_quantification/",
    "SRP144496_gene_counts.tsv"
)

META_FILE <- "metadata/samplesheet.csv"

GTF_FILE <- paste0(
    "reference_genome/gencode_v50/",
    "gencode.v50.primary_assembly.annotation.gtf"
)

OUTDIR <- "results/08_differential_expression"


# Differential-expression thresholds

PADJ_THRESHOLD <- 0.05

LFC_THRESHOLD <- 1


# Low-expression filtering

MIN_COUNT <- 10

MIN_SAMPLES <- 4


# Number of genes to show on heatmaps

TOP_HEATMAP_GENES <- 50


# Number of genes to label on volcano plots

TOP_VOLCANO_LABELS <- 10


dir.create(
    OUTDIR,
    recursive = TRUE,
    showWarnings = FALSE
)


# ============================================================
# Utility functions
# ============================================================

stop_with_message <- function(message) {

    stop(
        paste0(
            "\nERROR: ",
            message,
            "\n"
        ),
        call. = FALSE
    )

}


message("")
message("======================================================")
message(" SRP144496 Differential Expression Analysis")
message("======================================================")
message("")


# ============================================================
# 1. Check required files
# ============================================================

message("[1/11] Checking required files...")


if (!file.exists(COUNT_FILE)) {

    stop_with_message(
        paste(
            "Count matrix not found:",
            COUNT_FILE
        )
    )

}


if (!file.exists(META_FILE)) {

    stop_with_message(
        paste(
            "Metadata file not found:",
            META_FILE
        )
    )

}


if (!file.exists(GTF_FILE)) {

    stop_with_message(
        paste(
            "GENCODE GTF file not found:",
            GTF_FILE
        )
    )

}


if (Sys.which("awk") == "") {

    stop_with_message(
        "'awk' was not found. It is required for memory-efficient GTF parsing."
    )

}


message("Required files found.")
message("")


# ============================================================
# 2. Load count matrix
# ============================================================

message("[2/11] Loading count matrix...")


counts <- read.delim(

    COUNT_FILE,

    header = TRUE,

    row.names = 1,

    check.names = FALSE

)


message(
    "Genes loaded:   ",
    nrow(counts)
)

message(
    "Samples loaded: ",
    ncol(counts)
)


if (ncol(counts) != 16) {

    stop_with_message(

        paste(
            "Expected 16 samples but found",
            ncol(counts)
        )

    )

}


counts <- as.matrix(counts)


# DESeq2 requires integer counts

storage.mode(counts) <- "integer"


if (any(is.na(counts))) {

    stop_with_message(
        "NA values were detected in the count matrix."
    )

}


if (any(counts < 0)) {

    stop_with_message(
        "Negative count values were detected."
    )

}


message("Count matrix loaded successfully.")
message("")


# ============================================================
# 3. Load sample metadata
# ============================================================

message("[3/11] Loading sample metadata...")


meta <- read.csv(

    META_FILE,

    stringsAsFactors = FALSE,

    check.names = FALSE

)


required_columns <- c(

    "sample",

    "run",

    "cell_line",

    "condition",

    "replicate"

)


missing_columns <- setdiff(

    required_columns,

    colnames(meta)

)


if (length(missing_columns) > 0) {

    stop_with_message(

        paste(

            "Missing metadata columns:",

            paste(
                missing_columns,
                collapse = ", "
            )

        )

    )

}


# ------------------------------------------------------------
# Match metadata order to count matrix
# ------------------------------------------------------------

if (!all(colnames(counts) %in% meta$run)) {

    missing_runs <- setdiff(
        colnames(counts),
        meta$run
    )

    stop_with_message(

        paste(

            "Count-matrix run IDs absent from metadata:",

            paste(
                missing_runs,
                collapse = ", "
            )

        )

    )

}


meta <- meta[

    match(
        colnames(counts),
        meta$run
    ),

]


if (!all(meta$run == colnames(counts))) {

    stop_with_message(
        "Metadata and count-matrix sample order do not match."
    )

}


rownames(meta) <- meta$run


message("Metadata successfully matched to counts.")
message("")


# ============================================================
# 4. Load GENCODE gene annotations
# ============================================================

message("[4/11] Loading GENCODE gene annotation...")


# ------------------------------------------------------------
# Read ONLY gene rows from the GTF.
#
# This avoids loading the full GENCODE exon/transcript GTF
# into memory.
# ------------------------------------------------------------

awk_command <- sprintf(

    "awk -F '\\t' '$3 == \"gene\" {print}' %s",

    shQuote(GTF_FILE)

)


gene_lines <- system(

    awk_command,

    intern = TRUE

)


if (length(gene_lines) == 0) {

    stop_with_message(
        "No gene records were extracted from the GTF."
    )

}


gtf_genes <- read.delim(

    text = gene_lines,

    sep = "\t",

    header = FALSE,

    quote = "",

    comment.char = "",

    stringsAsFactors = FALSE

)


if (ncol(gtf_genes) != 9) {

    stop_with_message(
        "Unexpected GTF structure. Expected 9 columns."
    )

}


colnames(gtf_genes) <- c(

    "seqname",

    "source",

    "feature",

    "start",

    "end",

    "score",

    "strand",

    "frame",

    "attribute"

)


# ------------------------------------------------------------
# Function for extracting a GTF attribute
# ------------------------------------------------------------

extract_gtf_attribute <- function(x, attribute) {

    pattern <- paste0(

        ".*",

        attribute,

        ' "([^"]+)".*'

    )


    result <- sub(

        pattern,

        "\\1",

        x

    )


    # If the requested attribute was absent,
    # sub() returns the original string.
    # Convert these entries to NA.

    result[
        result == x
    ] <- NA


    return(result)

}


# ------------------------------------------------------------
# Construct annotation table
# ------------------------------------------------------------

gene_annotation <- data.frame(

    gene_id = extract_gtf_attribute(

        gtf_genes$attribute,

        "gene_id"

    ),

    gene_symbol = extract_gtf_attribute(

        gtf_genes$attribute,

        "gene_name"

    ),

    gene_type = extract_gtf_attribute(

        gtf_genes$attribute,

        "gene_type"

    ),

    stringsAsFactors = FALSE

)


# Stable Ensembl ID without version suffix

gene_annotation$ensembl_gene_id <- sub(

    "\\..*$",

    "",

    gene_annotation$gene_id

)


# Remove any unexpected duplicate gene IDs

gene_annotation <- gene_annotation[

    !duplicated(
        gene_annotation$gene_id
    ),

]


message(
    "GENCODE genes loaded: ",
    nrow(gene_annotation)
)


# Save annotation lookup table

write.table(

    gene_annotation,

    file.path(

        OUTDIR,

        "GENCODE_gene_annotation.tsv"

    ),

    sep = "\t",

    row.names = FALSE,

    quote = FALSE

)


message("GENCODE annotation loaded successfully.")
message("")


# ============================================================
# 5. Define experimental design
# ============================================================

message("[5/11] Constructing experimental groups...")


meta$cell_line <- factor(

    meta$cell_line,

    levels = c(

        "HT55",

        "SW948"

    )

)


meta$condition <- factor(

    meta$condition,

    levels = c(

        "control",

        "itraconazole"

    )

)


meta$group <- factor(

    paste(

        meta$cell_line,

        meta$condition,

        sep = "_"

    ),

    levels = c(

        "HT55_control",

        "HT55_itraconazole",

        "SW948_control",

        "SW948_itraconazole"

    )

)


message("")
message("Experimental design:")
message("")

print(

    table(

        meta$cell_line,

        meta$condition

    )

)

message("")


# ------------------------------------------------------------
# Check biological replication
# ------------------------------------------------------------

group_counts <- table(
    meta$group
)


if (any(group_counts < 2)) {

    stop_with_message(
        "One or more experimental groups have fewer than 2 replicates."
    )

}


# Save actual metadata used

write.csv(

    meta,

    file.path(

        OUTDIR,

        "sample_metadata_used.csv"

    ),

    row.names = TRUE

)


# ============================================================
# 6. Construct DESeq2 dataset + filter genes
# ============================================================

message("[6/11] Constructing DESeq2 dataset...")


dds <- DESeqDataSetFromMatrix(

    countData = counts,

    colData = meta,

    design = ~ group

)


genes_before <- nrow(dds)


# ------------------------------------------------------------
# Keep genes with at least 10 counts in at least 4 samples
# ------------------------------------------------------------

keep <- rowSums(

    counts(dds) >= MIN_COUNT

) >= MIN_SAMPLES


dds <- dds[
    keep,
]


genes_after <- nrow(dds)


message(
    "Genes before filtering: ",
    genes_before
)

message(
    "Genes after filtering:  ",
    genes_after
)

message(
    "Genes removed:          ",
    genes_before - genes_after
)

message("")


write.table(

    data.frame(

        genes_before = genes_before,

        genes_after = genes_after,

        genes_removed = genes_before - genes_after,

        minimum_count = MIN_COUNT,

        minimum_samples = MIN_SAMPLES

    ),

    file.path(

        OUTDIR,

        "filtering_summary.tsv"

    ),

    sep = "\t",

    row.names = FALSE,

    quote = FALSE

)


# ============================================================
# 7. Run DESeq2
# ============================================================

message("[7/11] Running DESeq2 model...")


dds <- DESeq(dds)


saveRDS(

    dds,

    file.path(

        OUTDIR,

        "SRP144496_DESeq2_object.rds"

    )

)


message("DESeq2 model completed.")
message("")


# ============================================================
# 8. Export annotated normalized counts
# ============================================================

message("[8/11] Exporting normalized counts...")


normalized_counts <- counts(

    dds,

    normalized = TRUE

)


normalized_annotation_index <- match(

    rownames(normalized_counts),

    gene_annotation$gene_id

)


normalized_output <- data.frame(

    gene_id = rownames(normalized_counts),

    ensembl_gene_id = sub(

        "\\..*$",

        "",

        rownames(normalized_counts)

    ),

    gene_symbol = gene_annotation$gene_symbol[
        normalized_annotation_index
    ],

    gene_type = gene_annotation$gene_type[
        normalized_annotation_index
    ],

    as.data.frame(
        normalized_counts,
        check.names = FALSE
    ),

    check.names = FALSE

)


write.table(

    normalized_output,

    file.path(

        OUTDIR,

        "normalized_counts.tsv"

    ),

    sep = "\t",

    row.names = FALSE,

    quote = FALSE

)


message("Normalized counts exported.")
message("")


# ============================================================
# 9. VST transformation + global sample QC
# ============================================================

message("[9/11] Creating sample-level QC plots...")


vsd <- vst(

    dds,

    blind = FALSE

)


saveRDS(

    vsd,

    file.path(

        OUTDIR,

        "SRP144496_VST_object.rds"

    )

)


# ============================================================
# PCA
# ============================================================

pca_data <- plotPCA(

    vsd,

    intgroup = c(

        "cell_line",

        "condition"

    ),

    returnData = TRUE

)


percent_var <- round(

    100 *

    attr(
        pca_data,
        "percentVar"
    )

)


pca_data$sample <- rownames(
    pca_data
)


pca_plot <- ggplot(

    pca_data,

    aes(

        x = PC1,

        y = PC2,

        colour = condition,

        shape = cell_line,

        label = sample

    )

) +

    geom_point(
        size = 4
    ) +

    geom_text_repel(

        size = 3,

        max.overlaps = Inf

    ) +

    xlab(

        paste0(

            "PC1: ",

            percent_var[1],

            "% variance"

        )

    ) +

    ylab(

        paste0(

            "PC2: ",

            percent_var[2],

            "% variance"

        )

    ) +

    ggtitle(
        "SRP144496 PCA"
    ) +

    theme_bw(
        base_size = 12
    )


ggsave(

    file.path(

        OUTDIR,

        "PCA_all_samples.png"

    ),

    pca_plot,

    width = 9,

    height = 7,

    dpi = 300

)


# ============================================================
# Sample correlation heatmap
# ============================================================

sample_cor <- cor(
    assay(vsd)
)


sample_annotation <- data.frame(

    Cell_line = meta$cell_line,

    Condition = meta$condition

)


rownames(sample_annotation) <- rownames(meta)


png(

    file.path(

        OUTDIR,

        "sample_correlation_heatmap.png"

    ),

    width = 2200,

    height = 2000,

    res = 250

)


pheatmap(

    sample_cor,

    annotation_col = sample_annotation,

    annotation_row = sample_annotation,

    main = "Sample correlation",

    border_color = NA

)


dev.off()


# ============================================================
# Dispersion plot
# ============================================================

png(

    file.path(

        OUTDIR,

        "DESeq2_dispersion_plot.png"

    ),

    width = 2000,

    height = 1600,

    res = 250

)


plotDispEsts(dds)


dev.off()


message("Global sample-level plots generated.")
message("")


# ============================================================
# 10. Differential-expression contrast function
# ============================================================

run_contrast <- function(

    cell_line,

    treated_group,

    control_group

) {


    message("")
    message("------------------------------------------------------")
    message(
        "Running contrast: ",
        treated_group,
        " vs ",
        control_group
    )
    message("------------------------------------------------------")


    comparison_name <- paste0(

        cell_line,

        "_itraconazole_vs_control"

    )


    contrast_dir <- file.path(

        OUTDIR,

        comparison_name

    )


    dir.create(

        contrast_dir,

        recursive = TRUE,

        showWarnings = FALSE

    )


    # ========================================================
    # DESeq2 results
    # ========================================================

    res <- results(

        dds,

        contrast = c(

            "group",

            treated_group,

            control_group

        ),

        alpha = PADJ_THRESHOLD

    )


    res <- res[

        order(
            res$padj
        ),

    ]


    df <- as.data.frame(res)


    df$gene_id <- rownames(df)


    df$ensembl_gene_id <- sub(

        "\\..*$",

        "",

        df$gene_id

    )


    # ========================================================
    # Add GENCODE gene annotation
    # ========================================================

    annotation_index <- match(

        df$gene_id,

        gene_annotation$gene_id

    )


    df$gene_symbol <- gene_annotation$gene_symbol[

        annotation_index

    ]


    df$gene_type <- gene_annotation$gene_type[

        annotation_index

    ]


    # ========================================================
    # Classify differential-expression status
    # ========================================================

    df$status <- "Not_significant"


    df$status[

        !is.na(df$padj) &

        df$padj < PADJ_THRESHOLD &

        df$log2FoldChange >= LFC_THRESHOLD

    ] <- "Upregulated"


    df$status[

        !is.na(df$padj) &

        df$padj < PADJ_THRESHOLD &

        df$log2FoldChange <= -LFC_THRESHOLD

    ] <- "Downregulated"


    # ========================================================
    # Rearrange columns
    # ========================================================

    df <- df[

        ,

        c(

            "gene_id",

            "ensembl_gene_id",

            "gene_symbol",

            "gene_type",

            "baseMean",

            "log2FoldChange",

            "lfcSE",

            "stat",

            "pvalue",

            "padj",

            "status"

        )

    ]


    # ========================================================
    # Export complete results
    # ========================================================

    write.csv(

        df,

        file.path(

            contrast_dir,

            "all_DESeq2_results.csv"

        ),

        row.names = FALSE

    )


    # ========================================================
    # Significant genes
    # ========================================================

    significant <- df[

        df$status != "Not_significant",

    ]


    upregulated <- df[

        df$status == "Upregulated",

    ]


    downregulated <- df[

        df$status == "Downregulated",

    ]


    write.csv(

        significant,

        file.path(

            contrast_dir,

            "significant_DEGs.csv"

        ),

        row.names = FALSE

    )


    write.csv(

        upregulated,

        file.path(

            contrast_dir,

            "upregulated_DEGs.csv"

        ),

        row.names = FALSE

    )


    write.csv(

        downregulated,

        file.path(

            contrast_dir,

            "downregulated_DEGs.csv"

        ),

        row.names = FALSE

    )


    # ========================================================
    # DEG summary
    # ========================================================

    summary_table <- data.frame(

        Comparison = comparison_name,

        Upregulated = nrow(upregulated),

        Downregulated = nrow(downregulated),

        Total_significant = nrow(significant),

        padj_threshold = PADJ_THRESHOLD,

        abs_log2FC_threshold = LFC_THRESHOLD

    )


    write.table(

        summary_table,

        file.path(

            contrast_dir,

            "DEG_summary.tsv"

        ),

        sep = "\t",

        row.names = FALSE,

        quote = FALSE

    )


    # ========================================================
    # MA plot
    # ========================================================

    png(

        file.path(

            contrast_dir,

            "MA_plot.png"

        ),

        width = 2000,

        height = 1600,

        res = 250

    )


    plotMA(

        res,

        alpha = PADJ_THRESHOLD,

        ylim = c(
            -6,
            6
        ),

        main = comparison_name

    )


    dev.off()


    # ========================================================
    # Volcano plot
    # ========================================================

    volcano <- df[

        !is.na(df$padj) &

        !is.na(df$log2FoldChange),

    ]


    volcano$minus_log10_padj <- -log10(

        pmax(

            volcano$padj,

            .Machine$double.xmin

        )

    )


    # --------------------------------------------------------
    # Generate plot labels
    # --------------------------------------------------------

    volcano$plot_label <- volcano$gene_symbol


    missing_volcano_labels <- (

        is.na(
            volcano$plot_label
        ) |

        volcano$plot_label == ""

    )


    volcano$plot_label[
        missing_volcano_labels
    ] <- volcano$ensembl_gene_id[
        missing_volcano_labels
    ]


    # --------------------------------------------------------
    # Select top significant genes for labels
    # --------------------------------------------------------

    top_label_genes <- volcano[

        volcano$status != "Not_significant",

    ]


    top_label_genes <- top_label_genes[

        order(
            top_label_genes$padj
        ),

    ]


    top_label_genes <- head(

        top_label_genes,

        TOP_VOLCANO_LABELS

    )


    # --------------------------------------------------------
    # Build volcano plot
    # --------------------------------------------------------

    volcano_plot <- ggplot(

        volcano,

        aes(

            x = log2FoldChange,

            y = minus_log10_padj,

            colour = status

        )

    ) +

        geom_point(

            alpha = 0.55,

            size = 1.3

        ) +

        geom_vline(

            xintercept = c(

                -LFC_THRESHOLD,

                LFC_THRESHOLD

            ),

            linetype = "dashed"

        ) +

        geom_hline(

            yintercept = -log10(
                PADJ_THRESHOLD
            ),

            linetype = "dashed"

        ) +

        geom_text_repel(

            data = top_label_genes,

            aes(
                label = plot_label
            ),

            size = 3,

            max.overlaps = Inf,

            show.legend = FALSE

        ) +

        xlab(
            "log2 fold change"
        ) +

        ylab(
            "-log10 adjusted p-value"
        ) +

        ggtitle(

            paste(

                cell_line,

                "Itraconazole vs Control"

            )

        ) +

        theme_bw(
            base_size = 12
        )


    ggsave(

        file.path(

            contrast_dir,

            "volcano_plot.png"

        ),

        volcano_plot,

        width = 8,

        height = 7,

        dpi = 300

    )


    # ========================================================
    # Top-50 DEG heatmap
    # ========================================================

    sig_ids <- rownames(res)[

        !is.na(res$padj) &

        res$padj < PADJ_THRESHOLD &

        abs(
            res$log2FoldChange
        ) >= LFC_THRESHOLD

    ]


    sig_ids <- sig_ids[

        order(

            res[
                sig_ids,
            ]$padj

        )

    ]


    if (length(sig_ids) > 0) {


        # ----------------------------------------------------
        # Select top DEGs
        # ----------------------------------------------------

        top_ids <- head(

            sig_ids,

            TOP_HEATMAP_GENES

        )


        # ----------------------------------------------------
        # Get gene symbols
        # ----------------------------------------------------

        top_annotation_index <- match(

            top_ids,

            gene_annotation$gene_id

        )


        heatmap_labels <- gene_annotation$gene_symbol[

            top_annotation_index

        ]


        # ----------------------------------------------------
        # If a gene symbol is unavailable,
        # display the stable Ensembl ID instead
        # ----------------------------------------------------

        missing_labels <- (

            is.na(
                heatmap_labels
            ) |

            heatmap_labels == ""

        )


        heatmap_labels[
            missing_labels
        ] <- sub(

            "\\..*$",

            "",

            top_ids[
                missing_labels
            ]

        )


        # ----------------------------------------------------
        # Select ONLY samples from the current cell line
        # ----------------------------------------------------

        selected_samples <- rownames(meta)[

            meta$cell_line == cell_line

        ]


        heatmap_matrix <- assay(vsd)[

            top_ids,

            selected_samples,

            drop = FALSE

        ]


        # ----------------------------------------------------
        # Heatmap sample annotation
        # ----------------------------------------------------

        heatmap_annotation <- data.frame(

            Condition = meta[

                selected_samples,

                "condition",

                drop = TRUE

            ]

        )


        rownames(
            heatmap_annotation
        ) <- selected_samples


        # ----------------------------------------------------
        # Draw heatmap
        # ----------------------------------------------------

        png(

            file.path(

                contrast_dir,

                "top50_DEG_heatmap.png"

            ),

            width = 2400,

            height = 2800,

            res = 250

        )


        pheatmap(

            heatmap_matrix,

            scale = "row",

            annotation_col = heatmap_annotation,

            labels_row = heatmap_labels,

            show_rownames = TRUE,

            fontsize_row = 7,

            border_color = NA,

            main = paste(

                "Top DEGs:",

                comparison_name

            )

        )


        dev.off()

    }


    # ========================================================
    # Console summary
    # ========================================================

    message("")

    message(
        "Significant DEGs: ",
        nrow(significant)
    )

    message(
        "  Upregulated:   ",
        nrow(upregulated)
    )

    message(
        "  Downregulated: ",
        nrow(downregulated)
    )


    return(
        summary_table
    )

}


# ============================================================
# 11. Run biological comparisons
# ============================================================

message("[10/11] Running differential-expression contrasts...")


ht55_summary <- run_contrast(

    cell_line = "HT55",

    treated_group = "HT55_itraconazole",

    control_group = "HT55_control"

)


sw948_summary <- run_contrast(

    cell_line = "SW948",

    treated_group = "SW948_itraconazole",

    control_group = "SW948_control"

)


combined_summary <- rbind(

    ht55_summary,

    sw948_summary

)


write.table(

    combined_summary,

    file.path(

        OUTDIR,

        "all_comparisons_summary.tsv"

    ),

    sep = "\t",

    row.names = FALSE,

    quote = FALSE

)


# ============================================================
# Final report
# ============================================================

message("")
message("[11/11] Analysis complete.")
message("")
message("======================================================")
message(" DIFFERENTIAL EXPRESSION COMPLETE")
message("======================================================")
message("")

message(
    "Genes entering DESeq2: ",
    genes_after
)

message("")

message(
    "Results directory:"
)

message(
    "  ",
    OUTDIR
)

message("")

print(
    combined_summary
)

message("")
message(
    "Finished: ",
    date()
)
message("")