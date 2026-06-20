process AUTOCYCLER_ASSEMBLE {
    // One assembly per (assembler, subsample) combination, via `autocycler helper`.
    label 'autocycler_assembly'
    conda "${moduleDir}/../conda/autocycler.yaml"
    publishDir "${params.outdir}/01_assembly/assemblies", mode: 'copy'

    input:
    tuple val(assembler), path(sample), val(genome_size)

    output:
    path "${assembler}_${id}.fasta"

    script:
    id = sample.baseName.replaceAll(/^sample_/, '')
    """
    autocycler helper ${assembler} \\
        --reads ${sample} \\
        --out_prefix ${assembler}_${id} \\
        --genome_size ${genome_size} \\
        --threads ${params.threads}
    """

    stub:
    id = sample.baseName.replaceAll(/^sample_/, '')
    """
    touch ${assembler}_${id}.fasta
    """
}

process AUTOCYCLER_COMPRESS {
    // Compress all input assemblies into a unitig graph.
    label 'autocycler'
    conda "${moduleDir}/../conda/autocycler.yaml"

    input:
    path 'assemblies/*'

    output:
    path 'autocycler_out'

    script:
    """
    autocycler compress -i assemblies -a autocycler_out
    """

    stub:
    """
    mkdir -p autocycler_out
    touch autocycler_out/input_assemblies.gfa
    """
}

process AUTOCYCLER_CLUSTER {
    // Cluster the contigs into putative genomic units (qc_pass clusters).
    label 'autocycler'
    conda "${moduleDir}/../conda/autocycler.yaml"

    input:
    path autocycler_out

    output:
    path 'autocycler_out', emit: dir
    path 'autocycler_out/clustering/qc_pass/cluster_*', emit: clusters

    script:
    """
    autocycler cluster -a autocycler_out
    """

    stub:
    """
    mkdir -p autocycler_out/clustering/qc_pass/cluster_001
    mkdir -p autocycler_out/clustering/qc_pass/cluster_002
    """
}

process AUTOCYCLER_TRIM_RESOLVE {
    // Trim and resolve a single cluster; emit its final GFA renamed to the cluster id
    // so the collected GFAs don't collide on staging.
    label 'autocycler'
    conda "${moduleDir}/../conda/autocycler.yaml"

    input:
    path cluster

    output:
    path "${cluster}.gfa"

    script:
    """
    autocycler trim -c ${cluster}
    autocycler resolve -c ${cluster}
    cp ${cluster}/5_final.gfa ${cluster}.gfa
    """

    stub:
    """
    touch ${cluster}.gfa
    """
}

process AUTOCYCLER_COMBINE {
    // Combine the resolved clusters into the final consensus assembly.
    label 'autocycler'
    conda "${moduleDir}/../conda/autocycler.yaml"
    publishDir "${params.outdir}/01_assembly", mode: 'copy'

    input:
    path autocycler_out
    path final_gfas

    output:
    path "${autocycler_out}/consensus_assembly.fasta", emit: fasta
    path "${autocycler_out}/consensus_assembly.gfa",   emit: gfa

    script:
    """
    autocycler combine -a ${autocycler_out} -i ${final_gfas}
    """

    stub:
    """
    touch ${autocycler_out}/consensus_assembly.fasta
    touch ${autocycler_out}/consensus_assembly.gfa
    """
}
