
#import "GPUImageFilter.h"

@interface GPUImageWaveFilter : GPUImageFilter
{
    GLint _normalizedPhaseUniform;
    
    GLint _centerXUniform;
    GLint _centerYUniform;
}

@property (nonatomic, assign) CGFloat normalizedPhase;

@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;

@end
