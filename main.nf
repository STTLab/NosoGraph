#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { AUTO_BACTERIAL_ASSEMBLY } from './modules/vendor/bacterial-assembly/main.nf'
include { AUTO_AUTOCYCLER }         from './modules/vendor/autocycler/main.nf'

// Select the pipeline with --pipeline (Nextflow's strict parser drops -entry).
//   nextflow run main.nf --pipeline autocycler --long_reads <reads>
workflow {
    if (params.pipeline == 'autocycler') {
        AUTO_AUTOCYCLER()
    } else if (params.pipeline == 'bacterial-assembly') {
        AUTO_BACTERIAL_ASSEMBLY()
    } else {
        error "Unknown --pipeline '${params.pipeline}'. Use: bacterial-assembly, autocycler"
    }
}
