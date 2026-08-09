#!/usr/bin/env Rscript

# ============================================================
# SRP144496 RNA-seq
# Stage 5: Shared and Cell-Line-Specific DEG Analysis
#
# Compares:
#   HT55 itraconazole vs control
#   SW948 itraconazole vs control
#
# IMPORTANT:
# "HT55-only" and "SW948-only" here mean significant in one
# contrast but not the other. This is descriptive and is not
# equivalent to a formal interaction test.
# ============================================================


suppressPackageStartupMessages({

    library(ggplot2)
    library(ggrepel)

})


# ============================================================
# Configuration
# ============================================================

HT55_DIR <- paste0(
    "results/08_differential_expression/",
    "HT55_itraconazole_vs_control"
)

SW948_DIR <- paste0(
    "results/08_differential_expression/",
    "SW948_itraconazole_vs_control"
)


HT55_ALL <- file.path(
    HT55_DIR,
    "all_DESeq2_results.csv"
)

SW948_ALL <- file.path(
    SW948_DIR,
    "all_DESeq2_results.csv"
)


HT55_SIG <- file.path(
    HT55_DIR,
    "significant_DEGs.csv"
)

SW948_SIG <- file.path(
    SW948_DIR,
    "significant_DEGs.csv"
)


OUTDIR <- "results/09_shared_specific_DEGs"


dir.create(
    OUTDIR,
    recursive = TRUE,
    showWarnings = FALSE
)


PADJ_THRESHOLD <- 0.05
LFC_THRESHOLD <- 1

TOP_LABELS <- 12


# ============================================================
# Utility function
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
message(" Shared and Cell-Line-Specific DEG Analysis")
message("======================================================")
message("")


# ============================================================
# 1. Check files
# ============================================================

message("[1/8] Checking input files...")


required_files <- c(

    HT55_ALL,
    SW948_ALL,
    HT55_SIG,
    SW948_SIG

)


missing_files <- required_files[
    !file.exists(required_files)
]


if (length(missing_files) > 0) {

    stop_with_message(

        paste(
            "Missing files:",
            paste(
                missing_files,
                collapse = ", "
            )
        )

    )

}


message("All required files found.")
message("")


# ============================================================
# 2. Load DEG results
# ============================================================

message("[2/8] Loading differential-expression results...")


ht55_all <- read.csv(
    HT55_ALL,
    stringsAsFactors = FALSE,
    check.names = FALSE
)


sw948_all <- read.csv(
    SW948_ALL,
    stringsAsFactors = FALSE,
    check.names = FALSE
)


ht55_sig <- read.csv(
    HT55_SIG,
    stringsAsFactors = FALSE,
    check.names = FALSE
)


sw948_sig <- read.csv(
    SW948_SIG,
    stringsAsFactors = FALSE,
    check.names = FALSE
)


required_columns <- c(

    "gene_id",
    "ensembl_gene_id",
    "gene_symbol",
    "gene_type",
    "log2FoldChange",
    "padj",
    "status"

)


for (column in required_columns) {

    if (!column %in% colnames(ht55_all)) {

        stop_with_message(
            paste(
                "HT55 results are missing column:",
                column
            )
        )

    }


    if (!column %in% colnames(sw948_all)) {

        stop_with_message(
            paste(
                "SW948 results are missing column:",
                column
            )
        )

    }

}


message(
    "HT55 significant DEGs:  ",
    nrow(ht55_sig)
)

message(
    "SW948 significant DEGs: ",
    nrow(sw948_sig)
)

message("")


# ============================================================
# 3. Determine shared and unique DEG sets
# ============================================================

message("[3/8] Identifying DEG overlap...")


ht55_genes <- unique(
    ht55_sig$gene_id
)


sw948_genes <- unique(
    sw948_sig$gene_id
)


shared_genes <- intersect(

    ht55_genes,

    sw948_genes

)


ht55_only_genes <- setdiff(

    ht55_genes,

    sw948_genes

)


sw948_only_genes <- setdiff(

    sw948_genes,

    ht55_genes

)


message(
    "Shared DEGs:      ",
    length(shared_genes)
)

message(
    "HT55-only DEGs:   ",
    length(ht55_only_genes)
)

message(
    "SW948-only DEGs:  ",
    length(sw948_only_genes)
)

message("")


# ============================================================
# 4. Export HT55-only and SW948-only DEG tables
# ============================================================

message("[4/8] Exporting shared and unique DEG tables...")


ht55_only <- ht55_sig[

    ht55_sig$gene_id %in%
        ht55_only_genes,

]


sw948_only <- sw948_sig[

    sw948_sig$gene_id %in%
        sw948_only_genes,

]


write.csv(

    ht55_only,

    file.path(
        OUTDIR,
        "HT55_only_DEGs.csv"
    ),

    row.names = FALSE

)


write.csv(

    sw948_only,

    file.path(
        OUTDIR,
        "SW948_only_DEGs.csv"
    ),

    row.names = FALSE

)


# ============================================================
# Construct detailed shared-DEG table
# ============================================================

shared_ht55 <- ht55_sig[

    ht55_sig$gene_id %in%
        shared_genes,

    c(
        "gene_id",
        "ensembl_gene_id",
        "gene_symbol",
        "gene_type",
        "baseMean",
        "log2FoldChange",
        "pvalue",
        "padj",
        "status"
    )

]


shared_sw948 <- sw948_sig[

    sw948_sig$gene_id %in%
        shared_genes,

    c(
        "gene_id",
        "baseMean",
        "log2FoldChange",
        "pvalue",
        "padj",
        "status"
    )

]


colnames(shared_ht55)[
    5:9
] <- c(

    "HT55_baseMean",
    "HT55_log2FC",
    "HT55_pvalue",
    "HT55_padj",
    "HT55_status"

)


colnames(shared_sw948)[
    2:6
] <- c(

    "SW948_baseMean",
    "SW948_log2FC",
    "SW948_pvalue",
    "SW948_padj",
    "SW948_status"

)


shared <- merge(

    shared_ht55,

    shared_sw948,

    by = "gene_id",

    all = FALSE

)


# ============================================================
# Classify direction of shared responses
# ============================================================

shared$shared_response <- "Discordant_direction"


shared$shared_response[

    shared$HT55_log2FC > 0 &
    shared$SW948_log2FC > 0

] <- "Shared_upregulated"


shared$shared_response[

    shared$HT55_log2FC < 0 &
    shared$SW948_log2FC < 0

] <- "Shared_downregulated"


# ------------------------------------------------------------
# Rank genes by significance in BOTH cell lines.
#
# pmax() gives the less significant padj of the two,
# so highly ranked genes must perform well in both contrasts.
# ------------------------------------------------------------

shared$joint_padj <- pmax(

    shared$HT55_padj,

    shared$SW948_padj,

    na.rm = TRUE

)


shared <- shared[

    order(
        shared$joint_padj
    ),

]


write.csv(

    shared,

    file.path(
        OUTDIR,
        "shared_DEGs_detailed.csv"
    ),

    row.names = FALSE

)


# Separate biologically useful subsets

shared_up <- shared[

    shared$shared_response ==
        "Shared_upregulated",

]


shared_down <- shared[

    shared$shared_response ==
        "Shared_downregulated",

]


discordant <- shared[

    shared$shared_response ==
        "Discordant_direction",

]


write.csv(

    shared_up,

    file.path(
        OUTDIR,
        "shared_upregulated_DEGs.csv"
    ),

    row.names = FALSE

)


write.csv(

    shared_down,

    file.path(
        OUTDIR,
        "shared_downregulated_DEGs.csv"
    ),

    row.names = FALSE

)


write.csv(

    discordant,

    file.path(
        OUTDIR,
        "shared_discordant_DEGs.csv"
    ),

    row.names = FALSE

)


message(
    "Shared upregulated:   ",
    nrow(shared_up)
)

message(
    "Shared downregulated: ",
    nrow(shared_down)
)

message(
    "Discordant direction: ",
    nrow(discordant)
)

message("")


# ============================================================
# 5. Create overall overlap summary
# ============================================================

message("[5/8] Creating overlap summaries...")


overlap_summary <- data.frame(

    Category = c(

        "HT55_only",

        "Shared",

        "SW948_only"

    ),

    Genes = c(

        length(
            ht55_only_genes
        ),

        length(
            shared_genes
        ),

        length(
            sw948_only_genes
        )

    )

)


write.table(

    overlap_summary,

    file.path(
        OUTDIR,
        "DEG_overlap_summary.tsv"
    ),

    sep = "\t",

    row.names = FALSE,

    quote = FALSE

)


direction_summary <- data.frame(

    Category = c(

        "Shared_upregulated",

        "Shared_downregulated",

        "Discordant_direction"

    ),

    Genes = c(

        nrow(shared_up),

        nrow(shared_down),

        nrow(discordant)

    )

)


write.table(

    direction_summary,

    file.path(
        OUTDIR,
        "shared_direction_summary.tsv"
    ),

    sep = "\t",

    row.names = FALSE,

    quote = FALSE

)


# ============================================================
# 6. Overlap visualizations
# ============================================================

message("[6/8] Generating overlap plots...")


# ------------------------------------------------------------
# Bar plot
# ------------------------------------------------------------

overlap_summary$Category <- factor(

    overlap_summary$Category,

    levels = c(

        "HT55_only",

        "Shared",

        "SW948_only"

    )

)


overlap_plot <- ggplot(

    overlap_summary,

    aes(
        x = Category,
        y = Genes
    )

) +

    geom_col(
        width = 0.65
    ) +

    geom_text(

        aes(
            label = Genes
        ),

        vjust = -0.4,

        size = 4

    ) +

    xlab(NULL) +

    ylab(
        "Number of significant DEGs"
    ) +

    ggtitle(
        "Itraconazole-responsive DEG overlap"
    ) +

    theme_bw(
        base_size = 12
    )


ggsave(

    file.path(
        OUTDIR,
        "DEG_overlap_barplot.png"
    ),

    overlap_plot,

    width = 7,

    height = 6,

    dpi = 300

)


# ------------------------------------------------------------
# Simple two-set Venn-style diagram
#
# No additional R package is needed.
# The circles are schematic, while the displayed counts
# are exact.
# ------------------------------------------------------------

png(

    file.path(
        OUTDIR,
        "DEG_overlap_venn.png"
    ),

    width = 2000,

    height = 1600,

    res = 250

)


par(
    mar = c(
        1,
        1,
        4,
        1
    )
)


plot(

    NA,

    xlim = c(
        0,
        10
    ),

    ylim = c(
        0,
        8
    ),

    axes = FALSE,

    xlab = "",

    ylab = "",

    main = "Significant DEG overlap"

)


symbols(

    x = c(
        4,
        6
    ),

    y = c(
        4,
        4
    ),

    circles = c(
        2.5,
        2.5
    ),

    inches = FALSE,

    add = TRUE,

    fg = c(
        "black",
        "black"
    )

)


text(

    2.9,
    4,

    labels = length(
        ht55_only_genes
    ),

    cex = 1.4

)


text(

    5,
    4,

    labels = length(
        shared_genes
    ),

    cex = 1.4

)


text(

    7.1,
    4,

    labels = length(
        sw948_only_genes
    ),

    cex = 1.4

)


text(

    3,
    6.8,

    labels = paste0(
        "HT55\n(n = ",
        length(ht55_genes),
        ")"
    ),

    cex = 1.1

)


text(

    7,
    6.8,

    labels = paste0(
        "SW948\n(n = ",
        length(sw948_genes),
        ")"
    ),

    cex = 1.1

)


dev.off()


# ============================================================
# 7. Compare log2 fold changes across ALL genes
# ============================================================

message("[7/8] Comparing treatment effect sizes...")


ht55_compare <- ht55_all[

    ,

    c(

        "gene_id",

        "ensembl_gene_id",

        "gene_symbol",

        "gene_type",

        "log2FoldChange",

        "padj",

        "status"

    )

]


sw948_compare <- sw948_all[

    ,

    c(

        "gene_id",

        "log2FoldChange",

        "padj",

        "status"

    )

]


colnames(ht55_compare)[
    5:7
] <- c(

    "HT55_log2FC",

    "HT55_padj",

    "HT55_status"

)


colnames(sw948_compare)[
    2:4
] <- c(

    "SW948_log2FC",

    "SW948_padj",

    "SW948_status"

)


comparison <- merge(

    ht55_compare,

    sw948_compare,

    by = "gene_id",

    all = FALSE

)


# ------------------------------------------------------------
# Classify every tested gene
# ------------------------------------------------------------

comparison$significance_group <- "Neither"


comparison$significance_group[

    comparison$HT55_status !=
        "Not_significant" &

    comparison$SW948_status ==
        "Not_significant"

] <- "HT55_only"


comparison$significance_group[

    comparison$HT55_status ==
        "Not_significant" &

    comparison$SW948_status !=
        "Not_significant"

] <- "SW948_only"


comparison$significance_group[

    comparison$HT55_status !=
        "Not_significant" &

    comparison$SW948_status !=
        "Not_significant"

] <- "Significant_both"


write.csv(

    comparison,

    file.path(
        OUTDIR,
        "all_genes_HT55_SW948_comparison.csv"
    ),

    row.names = FALSE

)


# ------------------------------------------------------------
# Calculate fold-change correlation
# ------------------------------------------------------------

complete <- comparison[

    is.finite(
        comparison$HT55_log2FC
    ) &

    is.finite(
        comparison$SW948_log2FC
    ),

]


pearson_r <- cor(

    complete$HT55_log2FC,

    complete$SW948_log2FC,

    method = "pearson"

)


spearman_rho <- cor(

    complete$HT55_log2FC,

    complete$SW948_log2FC,

    method = "spearman"

)


correlation_summary <- data.frame(

    Metric = c(

        "Pearson_r",

        "Spearman_rho"

    ),

    Value = c(

        pearson_r,

        spearman_rho

    )

)


write.table(

    correlation_summary,

    file.path(
        OUTDIR,
        "log2FC_correlation.tsv"
    ),

    sep = "\t",

    row.names = FALSE,

    quote = FALSE

)


# ------------------------------------------------------------
# Select top shared genes for labelling
# ------------------------------------------------------------

label_data <- shared


label_data$plot_label <- label_data$gene_symbol


missing_labels <- (

    is.na(
        label_data$plot_label
    ) |

    label_data$plot_label == ""

)


label_data$plot_label[
    missing_labels
] <- label_data$ensembl_gene_id[
    missing_labels
]


label_data <- head(

    label_data,

    TOP_LABELS

)


# ------------------------------------------------------------
# Treatment-effect scatter plot
# ------------------------------------------------------------

fc_plot <- ggplot(

    comparison,

    aes(

        x = HT55_log2FC,

        y = SW948_log2FC,

        colour = significance_group

    )

) +

    geom_hline(

        yintercept = 0,

        linetype = "dashed"

    ) +

    geom_vline(

        xintercept = 0,

        linetype = "dashed"

    ) +

    geom_abline(

        slope = 1,

        intercept = 0,

        linetype = "dotted"

    ) +

    geom_point(

        alpha = 0.45,

        size = 1.4

    ) +

    geom_text_repel(

        data = label_data,

        aes(

            x = HT55_log2FC,

            y = SW948_log2FC,

            label = plot_label

        ),

        inherit.aes = FALSE,

        size = 3,

        max.overlaps = Inf

    ) +

    xlab(
        "HT55 log2 fold change"
    ) +

    ylab(
        "SW948 log2 fold change"
    ) +

    ggtitle(

        paste0(

            "Itraconazole treatment effects\n",

            "Pearson r = ",

            round(
                pearson_r,
                3
            )

        )

    ) +

    theme_bw(
        base_size = 12
    )


ggsave(

    file.path(
        OUTDIR,
        "HT55_vs_SW948_log2FC_scatter.png"
    ),

    fc_plot,

    width = 8,

    height = 7,

    dpi = 300

)


# ============================================================
# 8. Final summary
# ============================================================

message("[8/8] Analysis complete.")
message("")

message("======================================================")
message(" DEG OVERLAP SUMMARY")
message("======================================================")
message("")

message(
    "HT55 significant DEGs:      ",
    length(ht55_genes)
)

message(
    "SW948 significant DEGs:     ",
    length(sw948_genes)
)

message(
    "Shared significant DEGs:    ",
    length(shared_genes)
)

message(
    "HT55-only significant DEGs: ",
    length(ht55_only_genes)
)

message(
    "SW948-only significant DEGs:",
    length(sw948_only_genes)
)

message("")

message(
    "Shared upregulated:         ",
    nrow(shared_up)
)

message(
    "Shared downregulated:       ",
    nrow(shared_down)
)

message(
    "Discordant shared DEGs:     ",
    nrow(discordant)
)

message("")

message(
    "Pearson log2FC correlation: ",
    round(
        pearson_r,
        4
    )
)

message(
    "Spearman correlation:       ",
    round(
        spearman_rho,
        4
    )
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
message(
    "Finished: ",
    date()
)
message("")