#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { ASSEMBLY_POLISH_QC } from './workflows/assembly_polish_qc'
include { AUTO_AUTOCYCLER }    from './modules/vendor/autocycler/main.nf'

// Select the pipeline with --pipeline (Nextflow's strict parser drops -entry).
//   nextflow run main.nf --pipeline autocycler --long_reads <reads>
workflow {
    if (params.pipeline == 'autocycler') {
        AUTO_AUTOCYCLER()
    } else if (params.pipeline == 'assembly_polish_qc') {
        ASSEMBLY_POLISH_QC()
    } else {
        error "Unknown --pipeline '${params.pipeline}'. Use: assembly_polish_qc, autocycler"
    }
}
