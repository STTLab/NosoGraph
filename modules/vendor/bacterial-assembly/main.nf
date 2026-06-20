nextflow.enable.dsl=2

include { ASSEMBLY_CANU } from './assembly/canu.nf'
include { ASSEMBLY_FLYE } from './assembly/flye.nf'
include { RACON_POLISH  } from './polish/racon.nf'
include { PILON_POLISH  } from './polish/pilon.nf'
include { CHECKM2       } from './qc/checkm2.nf'

// Composable core: single-assembler long-read assembly -> racon -> pilon -> CheckM2.
// Steps after assembly are gated by params (racon_iter, pilon_iter).
workflow BACTERIAL_ASSEMBLY {
    take:
        long_reads_ch
        read1_ch
        read2_ch

    main:
        // --- Assembly ---
        def assembly_ch
        if (params.assembler == 'canu') {
            assembly_ch = ASSEMBLY_CANU(long_reads_ch)
        } else if (params.assembler == 'flye') {
            assembly_ch = ASSEMBLY_FLYE(long_reads_ch)
        } else {
            error "Unknown assembler '${params.assembler}'. Use: canu, flye"
        }

        def racon_iter = params.racon_iter as int
        def pilon_iter = params.pilon_iter as int

        // --- Racon polishing (all iterations in one process) ---
        def polished_ch = (racon_iter > 0)
            ? RACON_POLISH(assembly_ch, long_reads_ch)
            : assembly_ch

        // --- Pilon polishing + CheckM2 (all iterations in one process) ---
        def final_ch = polished_ch
        def qc_ch     = channel.empty()
        if (pilon_iter > 0) {
            final_ch = PILON_POLISH(polished_ch, read1_ch, read2_ch)
            qc_ch    = CHECKM2(final_ch)
        }

    emit:
        assembly = final_ch
        qc       = qc_ch
}

// Entry wrapper: reads params, validates, builds channels, runs the core.
workflow AUTO_BACTERIAL_ASSEMBLY {
    if (!params.long_reads) error "Missing required param: --long_reads"
    if (!params.assembler)  error "Missing required param: --assembler (canu | flye)"
    if (!params.tech)       error "Missing required param: --tech (nanopore | nanopore-hq | pacbio)"

    if ((params.pilon_iter as int) > 0 && (!params.read1 || !params.read2))
        error "Pilon polishing (pilon_iter > 0) requires --read1 and --read2"

    long_reads_ch = channel.fromPath(params.long_reads, checkIfExists: false)
    read1_ch = params.read1 ? channel.fromPath(params.read1, checkIfExists: false) : channel.empty()
    read2_ch = params.read2 ? channel.fromPath(params.read2, checkIfExists: false) : channel.empty()

    BACTERIAL_ASSEMBLY(long_reads_ch, read1_ch, read2_ch)
}

// Default entry so the module runs standalone:
//   nextflow run modules/bacterial-assembly --long_reads <reads> --assembler flye --tech nanopore
workflow {
    AUTO_BACTERIAL_ASSEMBLY()
}
