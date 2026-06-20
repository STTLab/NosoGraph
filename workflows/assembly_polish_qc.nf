nextflow.enable.dsl=2

include { ASSEMBLY_CANU } from '../modules/assembly/canu'
include { ASSEMBLY_FLYE } from '../modules/assembly/flye'
include { RACON_POLISH  } from '../modules/polish/racon'
include { PILON_POLISH  } from '../modules/polish/pilon'
include { CHECKM2       } from '../modules/qc/checkm2'

workflow ASSEMBLY_POLISH_QC {

    // --- Validate required params ---
    if (!params.long_reads) error "Missing required param: --long_reads"
    if (!params.assembler)  error "Missing required param: --assembler (canu | flye)"
    if (!params.tech)       error "Missing required param: --tech (nanopore | nanopore-hq | pacbio)"

    long_reads_ch = Channel.fromPath(params.long_reads, checkIfExists: false)

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
    if (pilon_iter > 0) {
        if (!params.read1 || !params.read2) error "Pilon requires --read1 and --read2"

        def read1_ch = channel.fromPath(params.read1, checkIfExists: false)
        def read2_ch = channel.fromPath(params.read2, checkIfExists: false)

        def final_ch = PILON_POLISH(polished_ch, read1_ch, read2_ch)

        CHECKM2(final_ch)
    }
}
