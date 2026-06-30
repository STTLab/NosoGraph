#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { BACTERIAL_ASSEMBLY } from './modules/vendor/bacterial-assembly/main.nf'
include { AUTO_AUTOCYCLER }    from './modules/vendor/autocycler/main.nf'
include { KRAKEN2_CLASSIFY }   from './modules/vendor/kraken2-classify/main.nf'
include { ASSEMBLY_QC_IDEN }   from './modules/vendor/assembly-qc-iden/main.nf'
include { KG_EXPORT }          from './modules/local/kg_export.nf'
include { META_KG_EXPORT }     from './modules/local/meta_kg_export.nf'

// One sample per invocation (STTLab monolithic model). Select the pipeline with
// --pipeline; the bacterial-assembly and metagenomics paths additionally export a
// per-sample knowledge graph to <outdir>/<sample_id>/kg/.
//   nextflow run main.nf --pipeline bacterial-assembly --sample_id S01 \
//       --long_reads reads.fastq.gz --assembler flye --tech nanopore ...
//   nextflow run main.nf --pipeline autocycler --long_reads <reads>
//   nextflow run main.nf --pipeline metagenomics --sample_id S01 \
//       --long_reads reads.fastq.gz --kraken2_db <kraken2 DB dir>
workflow {
    if (params.pipeline == 'autocycler') {
        AUTO_AUTOCYCLER()

    } else if (params.pipeline == 'bacterial-assembly') {
        // --- Validate (mirrors the vendored AUTO_BACTERIAL_ASSEMBLY wrapper) ---
        if (!params.sample_id)  error "Missing required param: --sample_id"
        if (!params.long_reads) error "Missing required param: --long_reads"
        if (!params.assembler)  error "Missing required param: --assembler (canu | flye)"
        if (!params.tech)       error "Missing required param: --tech (nanopore | nanopore-hq | pacbio)"
        if ((params.pilon_iter as int) > 0 && (!params.read1 || !params.read2))
            error "Pilon polishing (pilon_iter > 0) requires --read1 and --read2"

        long_reads_ch = channel.fromPath(params.long_reads, checkIfExists: false)
        read1_ch = params.read1 ? channel.fromPath(params.read1, checkIfExists: false) : channel.empty()
        read2_ch = params.read2 ? channel.fromPath(params.read2, checkIfExists: false) : channel.empty()

        // --- Assembly -> polish -> QC (vendored, untouched) ---
        BACTERIAL_ASSEMBLY(long_reads_ch, read1_ch, read2_ch)

        // --- Knowledge-graph export (NosoGraph-owned) ---
        // The vendored core does not surface Flye's assembly_info.txt through its emits,
        // so source it from its publishDir once the assembly has completed (Flye only;
        // a NO_FILE sentinel otherwise). CheckM2 is optional (only runs when pilon_iter>0).
        // Distinct sentinels so the optional inputs never collide on a shared filename.
        no_flye_info  = file("${projectDir}/assets/NO_FLYE_INFO")
        no_checkm2    = file("${projectDir}/assets/NO_CHECKM2")
        no_blast_iden = file("${projectDir}/assets/NO_BLAST_IDEN")

        assembly_v  = BACTERIAL_ASSEMBLY.out.assembly.first()
        flye_info_v = assembly_v.map { fa ->
            def info = file("${params.outdir}/01_assembly/assembly_info.txt")
            info.exists() ? info : no_flye_info
        }

        // --- QC + identification enrichment (assembly-qc-iden, vendored & untouched) ---
        // Active when --blast_db is set (its presence is the toggle, so plain assembly runs
        // are never forced to ship a 100GB+ BLAST DB). Runs QUAST/CheckM2/BLAST on the final
        // assembly; this CheckM2 supersedes the bacterial-assembly QC, and BLAST adds a
        // per-contig best-hit accession to the KG (Contig.accession). QUAST uses the same
        // long reads for mapping stats; --reference is optional.
        if (params.blast_db) {
            if (!params.checkm2_db)
                error "QC+identification enrichment (--blast_db) also requires --checkm2_db"
            qc_iden_nofile = file("${projectDir}/modules/vendor/assembly-qc-iden/assets/NO_FILE")
            qc_reads_ch = channel.fromPath(params.long_reads, checkIfExists: false)
            qc_ref_ch   = channel.fromPath(params.reference ?: qc_iden_nofile, checkIfExists: false)

            ASSEMBLY_QC_IDEN(assembly_v, qc_reads_ch, qc_ref_ch)
            checkm2_v    = ASSEMBLY_QC_IDEN.out.checkm2
            blast_iden_v = ASSEMBLY_QC_IDEN.out.blast
        } else {
            checkm2_v    = BACTERIAL_ASSEMBLY.out.qc.ifEmpty(no_checkm2).first()
            blast_iden_v = channel.value(no_blast_iden)
        }

        KG_EXPORT(assembly_v, flye_info_v, checkm2_v, blast_iden_v)

    } else if (params.pipeline == 'metagenomics') {
        // Single-step model: the vendored kraken2-classify module classifies the reads
        // against a pre-built Kraken2 DB, then this exports a high-level pathogen-ID
        // knowledge graph (NosoGraph-owned) from the Kraken2 report. Bracken refinement is
        // a future seam (see report/meta_kg_export.py).
        if (!params.sample_id)  error "Missing required param: --sample_id"
        if (!params.long_reads) error "Missing required param: --long_reads"
        if (!params.kraken2_db) error "Missing required param: --kraken2_db (Kraken2 DB dir with hash.k2d/opts.k2d/taxo.k2d)"

        KRAKEN2_CLASSIFY(channel.fromPath(params.long_reads, checkIfExists: false))
        META_KG_EXPORT(KRAKEN2_CLASSIFY.out.report)

    } else {
        error "Unknown --pipeline '${params.pipeline}'. Use: bacterial-assembly, autocycler, metagenomics"
    }
}
