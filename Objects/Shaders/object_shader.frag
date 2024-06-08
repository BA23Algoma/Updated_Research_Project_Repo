#version 330 core

out vec4 FragColor;

in vec2 TexCoord;
in vec3 FragPos;
in vec3 Normal;

uniform sampler2D colorTexture;
uniform sampler2D normalMap;

void main()
{
    vec3 texColor = texture(colorTexture, TexCoord).rgb;
    vec3 normalMap = texture(normalMap, TexCoord).rgb * 2.0 - 1.0;
    vec3 normalFinal = normalize(normalMap * Normal);

    // Simulated lighting calculation
    float ambientStrength = 0.3;
    vec3 ambient = ambientStrength * texColor;

    vec3 lightColor = vec3(1.0);
    vec3 lightDir = normalize(vec3(0.0, 1.0, 1.0));
    float diff = max(dot(normalFinal, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    vec3 result = (ambient + diffuse) * texColor;

    FragColor = vec4(result, 1.0);
}
