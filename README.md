# DMDConnect
This Matlab package provides a connection to the LightCrafter EVM6500 DLP evaluation platform. 
The code is based on the usb communication library hidapi and its Matlab implementation realized by Peter Corke. 
For a working progress bar you need to download the textprogressbar function from [FileExchange](http://www.mathworks.com/matlabcentral/fileexchange/28067-text-progress-bar). Copy the file to the helperFunctions folder. 

The most important functions are implemented Command.m and DMD.m. Have a look at the [DLP C900 Programmer's Guide](http://www.ti.com/lit/ug/dlpu018b/dlpu018b.pdf)
for a better reference of the individual commands implemented in this toolbox. 

## Cross Platform Compatibility
The hidapi implementation should work on Windows, OSX and Linux likewise. However, the communication has only been tested under Windows so far. 

## Known bugs
* There is still a better error handling needed.
* Some more comments in the code would make it better understandable. 

## Example
Make the DMDConnect package known to your Matlab installation by adding it to the path. 

Connect the EVM6500 board to your computer. 

Initialize a DMD object:
`d = DMD('debug', 1);`

Get the firmware version:
`d.fwversion % returns the actual firmware version of the board`

Set the mode of the DMD to the internal pattern mode.
`d.setMode(1) % Pre-stored pattern mode`

Activate a checkerboard testpattern.
`d.testPattern(7) % Activate a checkerboard testpattern`

Put the DMD to sleep. 
`d.sleep % Enter standby mode`

Wake it up again.
`d.wakeup % Wake up again after standby`

Put the DMD to idle mode in order to equalize the on/off state of single pixels.
`d.idle % Idle mode`

Put the DMD to active mode back again. 
`d.active % Back to active after idle`

Display some matrix I on the DMD
`I = [ones(500,500) zeros(500,500)];`
`d.display(I);`

## Scientific Usage
If you use this code for scientific purpose, please cite it as [![DOI](https://zenodo.org/badge/20887/deichrenner/DMDConnect.svg)](https://zenodo.org/badge/latestdoi/20887/deichrenner/DMDConnect)



## Licensing
This toolbox is based on the hidapi implementation written by Peter Corke
in the framework of his robotics toolbox. The original source code can be
found on http://www.petercorke.com/Robotics_Toolbox.html.

Author: Klaus Hueck (e-mail: khueck (at) physik (dot) uni-hamburg (dot) de)
Version: 0.0.1alpha
Changes tracker:  28.01.2016  - First version
License: GPL v3
