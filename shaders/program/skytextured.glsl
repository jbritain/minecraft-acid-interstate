#include "/lib/Syntax.glsl"

/***********************************************************************/
#if defined vsh

  out vec2 texcoord;
  out vec4 glcolor;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
  }

#endif
/***********************************************************************/



/***********************************************************************/
#if defined fsh
  uniform sampler2D gtexture;

  in vec2 texcoord;
  in vec4 glcolor;

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(gtexture, texcoord) * glcolor;
    if (color.a < 0.1) {
      discard;
    }
  }
#endif
/***********************************************************************/
