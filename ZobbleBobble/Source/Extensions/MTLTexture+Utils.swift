//
//  MTLTexture+Utils.swift
//  ZobbleBobble
//
//  Created by Rost on 11.08.2023.
//

import MetalKit

extension MTLTexture {
    func threadGroupCount(pipeline: MTLComputePipelineState) -> MTLSize {
        return MTLSizeMake(pipeline.threadExecutionWidth,
                           pipeline.maxTotalThreadsPerThreadgroup / pipeline.threadExecutionWidth,
                           1)
    }
    
    func threadGroups(pipeline: MTLComputePipelineState) -> MTLSize {
        let groupCount = threadGroupCount(pipeline: pipeline)
        return MTLSizeMake((self.width + groupCount.width - 1) / groupCount.width, (self.height + groupCount.height - 1) / groupCount.height, 1)
    }
}
