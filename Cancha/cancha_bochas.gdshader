shader_type spatial;

uniform vec4 top_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);

void fragment()
{
    float z = NORMAL.y;

    z = z * 0.5 + 0.5;

    ALBEDO = mix(bottom_color.rgb, top_color.rgb, z);
}