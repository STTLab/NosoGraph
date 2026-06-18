nextflow.enable.dsl=2

include { ASSEMBLY_CANU } from '../modules/assembly/canu'
include { ASSEMBLY_FLYE } from '../modules/assembly/flye'
include { RACON_ITER    } from '../modules/polish/racon'
include { PILON_ITER    } from '../modules/polish/pilon'
include { CHECKM2       } from '../modules/qc/checkm2'

workflow ASSEMBLY_POLISH_QC {

    // --- Validate required params ---
    if (!params.long_reads) error "Missing required param: --long_reads"
    if (!params.assembler)  error "Missing required param: --assembler (canu | flye)"
    if (!params.tech)       error "Missing required param: --tech (nanopore | nanopore-hq | pacbio)"

    long_reads_ch = Channel.fromPath(params.long_reads, checkIfExists: true)

    // --- Assembly ---
    def assembly_ch
    if (params.assembler == 'canu') {
        assembly_ch = ASSEMBLY_CANU(long_reads_ch)
    } else if (params.assembler == 'flye') {
        assembly_ch = ASSEMBLY_FLYE(long_reads_ch)
    } else {
        error "Unknown assembler '${params.assembler}'. Use: canu, flye"
    }

    // --- Racon polishing ---
    // Each iteration is a separate resumable process; output of iter N feeds iter N+1.
    def polished_ch = (params.racon_iter > 0)
        ? (1..params.racon_iter).inject(assembly_ch) { prev_ch, iter ->
              RACON_ITER(prev_ch, long_reads_ch, iter)
          }
        : assembly_ch

    // --- Pilon polishing + CheckM2 ---
    if (params.pilon_iter > 0) {
        if (!params.read1 || !params.read2) error "Pilon requires --read1 and --read2"

        def read1_ch = Channel.fromPath(params.read1, checkIfExists: true)
        def read2_ch = Channel.fromPath(params.read2, checkIfExists: true)

        def final_ch = (1..params.pilon_iter).inject(polished_ch) { prev_ch, iter ->
            PILON_ITER(prev_ch, read1_ch, read2_ch, iter)
        }

        CHECKM2(final_ch)
    }
}
