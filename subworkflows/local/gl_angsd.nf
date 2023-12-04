//
// Call genotype likelihoods with ANGSD
//

nextflow.enable.dsl = 2

include { GL_CHR; GL_CLEAN; GL_FILTER; } from '../../modules/local/angsd_gl.nf'

workflow ANGSD_GL {
    take:
    list_region
    
    main:
    
    // run gl per region
    ch_region = Channel.fromPath(list_region)
      .splitText()
      .map{it -> it.trim()}
    
    ch_gl_chr = GL_CHR (
        params.batch,
        file(params.list_bam),
        ch_region,
        params.gl_param
        )

    // filter gl per region
    ch_gl_clean = GL_FILTER (
        ch_gl_chr.done,         // val ready
        params.batch,           // val batch
        ch_region,              // val region
        params.maf,             // val maf
        params.n,               // val n
        params.mis,             // val mis
    )
    // merge output, unsorted
    ch_gl_collect_bg = ch_gl_clean.beagle
        .map {it -> file("${params.wdir}gl_chr/${it}") }
        .collectFile(
            name: "${params.batch}.tv_maf${params.maf}_mis${params.mis}.beagle",
            storeDir: params.wdir,
            keepHeader: true,
            skip: 1,
        )
    ch_gl_collect_maf = ch_gl_clean.maf
        .map {it -> file("${params.wdir}gl_chr/${it}") }
        .collectFile(
            name: "${params.batch}.tv_maf${params.maf}_mis${params.mis}.mafs",
            storeDir: params.wdir,
            keepHeader: true,
            skip: 1,
        )
    ch_gl_collect_bg
        .view{ it }

    
    // clean directory
    // ch_clean_gl = GL_CLEAN (
    //     ch_gl_collect_bg,
    //     ch_gl_collect_maf,
    //     ch_gl_clean.beagle,
    //     ch_gl_clean.maf
    // )

    
    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

workflow {
    ANGSD_GL ( params.list_region )
}
