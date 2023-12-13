process MPILE_UP_CALL_REGION {
    tag '$batch_id'
    label 'process_medium'
    executor 'slurm'
    // executor 'local'
    cpus 1
    time '48h'
    queue 'cpuqueue'
    memory '16 GB'
    // remember to set executor.perCpuMemAllocation = true in config file


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools%3A1.18--h8b25389_0' :
        'bcftools:A1.18--h8b25389_0'}"

    publishDir(
        path: "${params.publishdir}gt_chr",
        mode: 'move',
    )

    input:
    val batch
    path ref
    path list_bam
    val param_mpileup
    val param_call
    val region

    // tuple val(meta_gt), val(region)

    output:
    path "*.vcf.gz", emit: vcf
    path "*.vcf.gz.csi", emit: vcf_index

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    bcftools mpileup \\
        -Ou -f ${ref} \\
        -a FORMAT/AD,FORMAT/DP \\
        -b ${list_bam} \\
        ${param_mpileup} \\
        -r ${region} | \\
        bcftools call \\
        ${param_call} \\
        -vmO z \\
        -o ${batch}.${region}.vcf.gz

    bcftools index ${batch}.${region}.vcf.gz
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(bcftools version))
    END_VERSIONS
    """
}
