
#import "GPUImageWaveFilter.h"

NSString *const kGPUImageWaveFragmentShaderString = SHADER_STRING
(
    precision highp float;
    varying highp vec2 textureCoordinate;
    uniform sampler2D inputImageTexture;

    uniform float centerX;
    uniform float centerY;

    uniform float normalizedPhase;
    uniform float texelWidth;
    uniform float texelHeight;

    float m_pi = 3.14159265358979323846;

    void main()
    {
        vec4 color;
        float x = textureCoordinate.x - centerX;
        float y = textureCoordinate.y - centerY;
        float dist = sqrt(x*x + y*y);
        float delt = 0.004 / dist * sin(dist * dist * m_pi / 0.06 + normalizedPhase * 2.0 * m_pi);
        gl_FragColor = texture2D(inputImageTexture, textureCoordinate + vec2(x / dist * delt, y / dist * delt));
    }
);

@implementation GPUImageWaveFilter

- (id)init
{
    if (self = [self initWithFragmentShaderFromString:kGPUImageWaveFragmentShaderString])
    {
        self.normalizedPhase = 0.f;
        
        self.centerX = -0.1;
        self.centerY = 0.5;
    }
    return self;
}

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString
{
    if (self = [super initWithFragmentShaderFromString:fragmentShaderString])
    {
        _normalizedPhaseUniform = [filterProgram uniformIndex:@"normalizedPhase"];
        
        _centerXUniform = [filterProgram uniformIndex:@"centerX"];
        _centerYUniform = [filterProgram uniformIndex:@"centerY"];
    }
    return self;
}

- (void)setNormalizedPhase:(CGFloat)normalizedPhase
{
    _normalizedPhase = normalizedPhase;
    [self setFloat:_normalizedPhase forUniform:_normalizedPhaseUniform program:filterProgram];
}

- (void)setCenterX:(CGFloat)centerX
{
    _centerX = centerX;
    [self setFloat:_centerX forUniform:_centerXUniform program:filterProgram];
}

- (void)setCenterY:(CGFloat)centerY
{
    _centerY = centerY;
    [self setFloat:_centerY forUniform:_centerYUniform program:filterProgram];
}

@end
