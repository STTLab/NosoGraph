#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { ASSEMBLY_POLISH_QC } from './workflows/assembly_polish_qc'

// Default entry — runs when no -entry flag is given
workflow {
    ASSEMBLY_POLISH_QC()
}
