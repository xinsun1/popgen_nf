process GL_CHR {
    tag '$batch_id'
    label 'process_medium'
    // executor 'slurm'
    executor 'local'
    cpus 2
    time '24h'
    queue 'cpuqueue'
    memory '8 GB'
    // remember to set executor.perCpuMemAllocation = true in config file


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/angsd%3A0.940--hce60e53_2' :
        'angsd:0.940--hce60e53_2'}"

    publishDir(
        path: "${params.wdir}gl_chr",
        mode: 'move',
    )

    input:
    val batch
    path list_bam
    val region
    val param_gl

    output:
    path "*.beagle.gz", emit: beagle_gz
    path "*.arg", emit: arg
    path "*.mafs.gz", emit: maf_gz
    val true, emit: done

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    
    """
    angsd -remove_bads 1 -uniqueOnly 1 \\
        -out ${batch}.${region} \\
        ${param_gl} \\
        -nThreads 1 \\
        -bam ${list_bam} \\
        -r ${region}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(angsd))
    END_VERSIONS
    """
}

process GL_FILTER {
    tag '$batch_id'
    label 'process_low'
    // executor 'slurm'
    executor 'local'
    cpus 1
    time '1h'
    queue 'cpuqueue'
    memory '1 GB'

    // remember to set executor.perCpuMemAllocation = true in config file
    
    publishDir(
        path: "${params.wdir}gl_chr",
        mode: 'move',
    )

    input:
    val ready
    val batch
    val region
    val maf
    val n
    val mis

    output:
    path "${batch}.${region}.is_tv_maf${maf}_mis${mis}", emit: is_f
    path "${batch}.${region}.tv_maf${maf}_mis${mis}.beagle", emit: beagle_f
    path "${batch}.${region}.tv_maf${maf}_mis${mis}.mafs", emit: maf_f
    val "${batch}.${region}.tv_maf${maf}_mis${mis}.beagle", emit: beagle
    val "${batch}.${region}.tv_maf${maf}_mis${mis}.mafs", emit: maf
    val true, emit: done

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def maf_gz = file("${params.wdir}gl_chr/${batch}.${region}.mafs.gz")
    def beagle_gz = file("${params.wdir}gl_chr/${batch}.${region}.beagle.gz")
    """
    zcat ${maf_gz} | \\
        awk '{\\
            if(NR==1){print 1}\\
            else{if(\\
            (\$3=="A" && \$4=="G") || \\
            (\$3=="T" && \$4=="C") || \\
            (\$3=="C" && \$4=="T") || \\
            (\$3=="G" && \$4=="A") || \\
            \$5 < (${maf}/100) || \\
            \$5 > (1-(${maf}/100)) || \\
            \$6/${n} < (${mis}/100)\\
            ){print 0}\\
            else{print 1}\\
            }}' \\
            > ${batch}.${region}.is_tv_maf${maf}_mis${mis}
    zcat ${beagle_gz} | \\
        awk 'NR==FNR \\
            {a[FNR]=\$1} \\
            NR != FNR \\
            {if(a[FNR]==1){print \$0}}' \\
            ${batch}.${region}.is_tv_maf${maf}_mis${mis} \\
            - \\
            > ${batch}.${region}.tv_maf${maf}_mis${mis}.beagle
    zcat ${maf_gz} | \\
        awk 'NR==FNR {a[FNR]=\$1} \\
            NR != FNR \\
            {if(a[FNR]==1){print \$0}}' \\
            ${batch}.${region}.is_tv_maf${maf}_mis${mis} \\
            - \\
            > ${batch}.${region}.tv_maf${maf}_mis${mis}.mafs

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo bash))
    END_VERSIONS
    """
}

process GL_CLEAN {
    tag '$batch_id'
    label 'process_medium'
    executor 'local'
    cpus 1
    time '2h'
    // remember to set executor.perCpuMemAllocation = true in config file

    input:
    val ready_bg
    val ready_maf
    val name_bg
    val name_maf
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    rm -fr ${params.wdir}gl_chr/${name_bg}
    rm -fr ${params.wdir}gl_chr/${name_maf}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(bash -version))
    END_VERSIONS
    """
}


