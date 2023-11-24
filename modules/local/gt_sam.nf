process SMARTPCA_PAR {
    tag '$batch_id'
    label 'process_local'
    executor 'local'
    cpus 1

    input:
    // [row.batch_id, eigen_meta, para_meta]
    tuple val(batch_id), val(eigen_meta), val(para_meta)

    output:
    path "par.${batch_id}", emit: par_file
    val batch_id, emit: batch_id
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    // TODO nf-core: If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    // TODO nf-core: Please replace the example samtools command below with your module's command
    // TODO nf-core: Please indent the command appropriately (4 spaces!!) to help with readability ;)
    """
    
    """
}

process MPILE_UP_CALL_REGION {
    tag '$batch_id'
    label 'process_medium'
    executor 'slurm'
    cpus 1
    time '48h'
    queue 'cpuqueue'
    memory '16 GB'
    // remember to set executor.perCpuMemAllocation = true in config file


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools%3A1.18--h8b25389_0' :
        'bcftools:A1.18--h8b25389_0'}"

    input:
    val meta_gt
    val region

    output:
    path "*.vcf.gz", emit: vcf
    path "*.vcf.gz.csi", emit: vcf_index

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    bcftools mpileup \\
        -Ou -f ${meta_gt.ref} \\
        -a FORMAT/AD,FORMAT/DP \\
        -b ${meta_gt.list_bam} \\
        ${meta_gt.param_mpileup} \\
        -r ${region} | \\
        bcftools call \\
        ${meta_gt.param_call} \\
        -vmO z \\
        -o ${meta_gt.batch}.${region}.vcf.gz

    bcftools index ${meta_gt.batch}.${region}.vcf.gz
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(bcftools version))
    END_VERSIONS
    """
}