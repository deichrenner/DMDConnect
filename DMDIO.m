%DMDIO Abstract class definition for DMD input output
%
% Methods::
%  open         Open the connection to the DMD
%  close        Close the connection to the DMD
%  read         Read data from the DMD
%  write        Write data to the DMD
%
% Notes::
% - handle is the connection object
% - The read function should return a uint8 datatype
% - The write function should be given a uint8 datatype as a parameter
% 
% This toolbox is based on the hidapi implementation written by Peter Corke
% in the framework of his robotics toolbox. The original source code can be
% found on http://www.petercorke.com/Robotics_Toolbox.html.
% 
% Author: Klaus Hueck (e-mail: khueck (at) physik (dot) uni-hamburg (dot) de)
% Version: 0.0.1alpha
% Changes tracker:  28.01.2016  - First version
% License: GPL v3

classdef DMDIO
    properties (Abstract)
        % connection handle
        handle
    end
    
    methods (Abstract)
        % open the DMD connection
        open(DMDIO)
        % close the DMD connection
        close(DMDIO)
        % read data from the DMD
        read(DMDIO)
        % write data to the DMD
        write(DMDIO)
    end
end