process GL_CHR {
    tag '$batch_id'
    label 'process_medium'
    executor 'slurm'
    cpus 2
    time '1h'
    queue 'cpuqueue'
    memory '4 GB'
    // remember to set executor.perCpuMemAllocation = true in config file


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/angsd%3A0.940--hce60e53_2' :
        'angsd:0.940--hce60e53_2'}"

    publishDir(
        path: "${params.wdir}gl_chr",
        mode: 'move',
    )

    input:
    tuple val(meta_gl), val(region)

    output:
    path "*.beagle.gz", emit: beagle
    path "*.arg", emit: arg
    path "*.mafs.gz", emit: maf
    val true, emit: done

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // angsd -remove_bads 1 -uniqueOnly 1 \\
    //     -out ${meta_gl.batch}.${region} \\
    //     ${meta_gl.param_gl} \\
    //     -nThreads 2 \\
    //     -bam ${meta_gl.list_bam} \\
    //     -r ${region}
    
    """
    echo "a" >> ${meta_gl.batch}.${region}.beagle.gz
    echo "a" >> ${meta_gl.batch}.${region}.arg
    echo "a" >> ${meta_gl.batch}.${region}.mafs.gz
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(angsd))
    END_VERSIONS
    """
}

process GL_CLEAN {
    tag '$batch_id'
    label 'process_low'
    executor 'slurm'
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
    tuple val(meta_gl), val(region)

    output:
    path "${meta_gl.batch}.${region}.is_tv_maf${meta_gl.maf}_mis${meta_gl.mis}", emit: is_f
    path "${meta_gl.batch}.${region}.tv_maf${meta_gl.maf}_mis${meta_gl.mis}.beagle", emit: beagle
    path "${meta_gl.batch}.${region}.tv_maf${meta_gl.maf}_mis${meta_gl.mis}.mafs", emit: maf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // zcat ${meta_gl.batch}.${region}.mafs.gz | \\
    //     awk '{\\
    //         if(NR==1){print 1}\\
    //         else{if(\\
    //         (\$3=="A" && \$4=="G") || \\
    //         (\$3=="T" && \$4=="C") || \\
    //         (\$3=="C" && \$4=="T") || \\
    //         (\$3=="G" && \$4=="A") || \\
    //         \$5 < (${meta_gl.maf}/100) || \\
    //         \$5 > ((1-${meta_gl.maf})/100) || \\
    //         \$7/${meta_gl.n} < (${meta_gl.mis}/100)\\
    //         ){print 0}\\
    //         else{print 1}\\
    //         }}' \\
    //         > ${meta_gl.batch}.${region}.is_tv_maf${meta_gl.maf}_mis${meta_gl.mis}
    // zcat ${meta_gl.batch}.${region}.beagle.gz | \\
    //     awk 'NR==FNR \\
    //         {a[FNR]=\$1} \\
    //         NR != FNR \\
    //         {if(a[FNR]==1){print \$0}}' \\
    //         ${meta_gl.batch}.${region}.is_tv_maf${meta_gl.maf}_mis${meta_gl.mis} \\
    //         - \\
    //         > ${meta_gl.batch}.${region}.tv_maf${meta_gl.maf}_mis${meta_gl.mis}.beagle
    // zcat ${meta_gl.batch}.${region}.mafs.gz | \\
    //     awk 'NR==FNR {a[FNR]=\$1} \\
    //         NR != FNR \\
    //         {if(a[FNR]==1){print \$0}}' \\
    //         ${meta_gl.batch}.${region}.is_tv_maf${meta_gl.maf}_mis${meta_gl.mis} \\
    //         - \\
    //         > ${meta_gl.batch}.${region}.tv_maf${meta_gl.maf}_mis${meta_gl.mis}.mafs
    
    """
    echo "a" > ${meta_gl.batch}.${region}.is_tv_maf${meta_gl.maf}_mis${meta_gl.mis}
    echo "b" > ${meta_gl.batch}.${region}.tv_maf${meta_gl.maf}_mis${meta_gl.mis}.beagle
    echo "c" > ${meta_gl.batch}.${region}.tv_maf${meta_gl.maf}_mis${meta_gl.mis}.mafs

    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo bash))
    END_VERSIONS
    """
}

process GL_MERGE {
    tag '$batch_id'
    label 'process_medium'
    executor 'slurm'
    cpus 2
    time '48h'
    queue 'cpuqueue'
    memory '4 GB'
    // remember to set executor.perCpuMemAllocation = true in config file


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/angsd%3A0.940--hce60e53_2' :
        'angsd:0.940--hce60e53_2'}"

    publishDir(
        path: "${params.wdir}gl_chr",
        mode: 'move',
    )

    input:
    tuple val(meta_gl), val(region)

    output:
    path "*.beagle.gz", emit: beagle
    path "*.arg", emit: arg
    path "*.mafs.gz", emit: maf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    cat gl_chr1_tv_maf05_mis50.beagle >> $WDIR/gl_tv_maf05_mis50.beagle
    cat gl_chr1_tv_maf05_mis50.mafs >> $WDIR/gl_tv_maf05_mis50.mafs
    for i in {2..38}
    do
            tail -n +2 gl_chr${i}_tv_maf05_mis50.beagle >> $WDIR/gl_tv_maf05_mis50.beagle
            tail -n +2 gl_chr${i}_tv_maf05_mis50.mafs >> $WDIR/gl_tv_maf05_mis50.mafs
    done

    gzip $WDIR/gl_tv_maf05_mis50.beagle &
    gzip $WDIR/gl_tv_maf05_mis50.mafs &
    wait
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(angsd))
    END_VERSIONS
    """
}


