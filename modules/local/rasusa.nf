// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process RASUSA {
    tag "$meta.id -> ${params.depth_cutoff}X"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? 'bioconda::rasusa=0.3.0' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container 'https://depot.galaxyproject.org/singularity/rasusa:0.3.0--h516909a_0'
    } else {
        container 'quay.io/biocontainers/rasusa:0.3.0--h516909a_0'
    }

    input:
    tuple val(meta), path(reads), val(genome_size)
    
    output:
    tuple val(meta), path('*X.fastq.gz'), emit: reads
    path '*.version.txt'               , emit: version

    script:
    // Added soft-links to original fastqs for consistent naming in MultiQC
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    if (meta.single_end) {
        """
        rasusa \\
            $options.args \\
            --coverage $params.depth_cutoff \\
            --genome-size $genome_size \\
            --input $reads \\
            --output ${prefix}.${params.depth_cutoff}X.fastq.gz
        
        echo \$(rasusa --version 2>&1) | sed -e "s/rasusa //g" > ${software}.version.txt
        """
    } else {
        """
        rasusa \\
            $options.args \\
            --coverage $params.depth_cutoff \\
            --genome-size $genome_size \\
            --input $reads \\
            --output ${prefix}_1.${params.depth_cutoff}X.fastq.gz ${prefix}_2.${params.depth_cutoff}X.fastq.gz

        echo \$(rasusa --version 2>&1) | sed -e "s/fastp //g" > ${software}.version.txt
        """
    }
}
