#version 330
// The Emacs frames (picom.conf): their top bar less see-through than the
// rest of the frame, whose transparency (alpha-background, SPC t t) is all
// Emacs knows.  BAR is the bar's height in pixels: the font's line (19),
// and twice anthe/window-bar-padding (anthe-windows.el).
#define BAR 19.0
// The share of the frame's transparency the bar keeps
#define KEEP 0.3

in vec2 texcoord;
uniform sampler2D tex;

vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    vec2 texsize = textureSize(tex, 0);
    vec4 c = texture2D(tex, texcoord / texsize, 0);
    if (texcoord.y < BAR && c.a > 0.0 && c.a < 1.0) {
        // Premultiplied: the colour at its new alpha
        float a = 1.0 - (1.0 - c.a) * KEEP;
        c = vec4(c.rgb / c.a * a, a);
    }
    return default_post_processing(c);
}
