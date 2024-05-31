# Aseprite Color Shading v4.0
This is an Aseprite Script that opens a dynamic palette picker window with relevant color shading options.

Based on v1.0-2.0 by Dominick John and David Capello, https://github.com/dominickjohn/aseprite/tree/master,  
v3.0 by yashar98, https://github.com/yashar98/aseprite/tree/main,  
v3.1 by Daeyangae, https://github.com/Daeyangae/aseprite,  
v4.0 by Manuel Hoelzl, https://github.com/hoelzlmanuel/aseprite-color-shading.

## Instructions:
   Place this file into the Aseprite scripts folder (File -> Scripts -> Open Scripts Folder).  
   Run the "Color Shading" script (File -> Scripts -> Color Shading v4.0) to open the palette window.
## Usage:
- Base: Clicking on either base color will switch the shading palette to that saved color base.
- "Get" Button: Updates base colors using the current foreground and background color and regenerates shading.
- Left click: Set clicked color as foreground color.
- Right click: Set clicked color as background color.
- Middle click: Set clicked color as fore- or background color, depending on which one was set last (if auto pick is on) and regenerate all shades based on this new color.
- The temperature sliders influence the temperature of the dark and light shade swatches, respectively
- Intensity adds a saturation gradient to the shade swatches
- Peak adds a lightness gradient to the shade swatches
- Sway sets the actual influence of the temperatures set
- Slots changes the number of color swatches

<img width="363" alt="Color Shading v4 0" src="https://github.com/hoelzlmanuel/aseprite-color-shading/assets/26813147/28987f67-af23-441b-91e4-72f0c2f9d212">
