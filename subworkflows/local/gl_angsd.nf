//
// Call genotype likelihoods with ANGSD
//

nextflow.enable.dsl = 2

include { GL_CHR; GL_CLEAN; } from '../../modules/local/angsd_gl.nf'

workflow ANGSD_GL {
    take:
    list_region
    
    main:
    
    // run gl per region
    ch_region = Channel.fromPath(list_region)
      .splitText()
      .map{it -> it.trim()}
    

    // filter gl per region

    // merge output

    // ch_gl = GL_CHR (ch_meta_region)
    // GL_CLEAN (ch_gl.done, ch_meta_region)

    meta_gl_first = meta_gl.first().value
    
    ch_region 
    | map {it ->
            "${params.wdir}gl_chr/${meta_gl_first.batch}.${it}.tv_maf${meta_gl_first.maf}_mis${meta_gl_first.mis}.beagle"}
    | view()

//     | collectFile("${meta_gl_first.batch}.tv_maf${meta_gl_first.maf}_mis${meta_gl_first.mis}.beagle",
//             storeDir: params.wdir,
//             keepHeader: true,
//             skip: 1,
//             sort: false)
// 


    
    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

workflow {
    ANGSD_GL ( params.list_region )
}
