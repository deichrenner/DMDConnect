%usbDMDIO USB interface between MATLAB and the dmd
%
% Methods::
%
%  usbDMDIO    Constructor, initialises and opens the usb connection
%  delete       Destructor, closes the usb connection
%
%  open         Open a usb connection to the dmd
%  close        Close the usb connection to the dmd
%  read         Read data from the dmd through usb
%  write        Write data to the dmd through usb
%
% Example::
%           usbdmd = usbDMDIO()
%
% Notes::
% - Uses the hid library implementation in hidapi.m
% 
% This toolbox is based on the hidapi implementation written by Peter Corke
% in the framework of his robotics toolbox. The original source code can be
% found on http://www.petercorke.com/Robotics_Toolbox.html.
% 
% Author: Klaus Hueck (e-mail: khueck (at) physik (dot) uni-hamburg (dot) de)
% Version: 0.0.1alpha
% Changes tracker:  28.01.2016  - First version
% License: GPL v3

classdef usbDMDIO < DMDIO
    properties
        % connection handle
        handle
        % debug input
        debug = 0;
        % vendor ID (C900 = 0x0451)
        vendorID = 1105;
        % product ID (C900 = 0xc900)
        productID = 51456;
        % read buffer size (needs to be one byte larger than the actual
        % buffer, as the hdiapi framework always adds one byte in front for
        % the report id)
        nReadBuffer = 65;
        % write buffer size equals the size of the read buffer
        nWriteBuffer = 65;
    end
    
    methods
        function dmdIO = usbDMDIO(varargin)
            %usbDMDIO.usbDMDIO Create a usbDMDIO object
            %
            % usbdmd = usbDMDIO(varargin) is an object which
            % initialises a usb connection between MATLAB and the dmd
            % using hidapi.m.
            % 
            % Notes::
            % - Can take one parameter debug which is a flag specifying
            % output printing (0 or 1).
            
            % make all hidapi relevant functions available to usbDMDIO.m
            libDir = strsplit(mfilename('fullpath'), filesep);
            % fix fullfile file separation for linux systems
            firstsep = '';
            if (isunix == 1)
                firstsep = '/';
            end
            addpath(fullfile(firstsep, libDir{1:end-1}, 'hidapi'));
            
            if nargin == 0
                dmdIO.debug = 0;
            end
            if nargin > 0
                dmdIO.debug = varargin{1}; 
            end
            if dmdIO.debug > 0
                fprintf('usbDMDIO init\n');
            end
            % create the usb handle 
            dmdIO.handle = hidapi(dmdIO.debug,dmdIO.vendorID,dmdIO.productID,dmdIO.nReadBuffer,dmdIO.nWriteBuffer);
            % open the dmdIO connection
            dmdIO.open;
        end
        
        function delete(dmdIO)
            %usbDMDIO.delete Delete the usbDMDIO object
            %
            % delete(dmdIO) closes the usb connection handle
            
            if dmdIO.debug > 0
                fprintf('usbDMDIO delete\n');
            end
            % delete the usb handle 
            delete(dmdIO.handle)
        end
        
        % open the dmd IO connection
        function open(dmdIO)
            %usbDMDIO.open Open the usbDMDIO object
            %
            % usbDMDIO.open() opens the usb handle through the hidapi
            % interface.
            
            if dmdIO.debug > 0
                fprintf('usbDMDIO open\n');
            end
            % open the usb handle
            dmdIO.handle.open;
%             % set the connection to nonblocking for read operations
%             dmdIO.handle.setNonBlocking(1);
        end
        
        function close(dmdIO)
            %usbDMDIO.close Close the usbDMDIO object
            %
            % usbDMDIO.close() closes the usb handle through the hidapi
            % interface.
            if dmdIO.debug > 0
                fprintf('usbDMDIO close\n');
            end 
            % close the usb handle
            dmdIO.handle.close;
        end
        
        function rmsg = read(dmdIO)
            %usbDMDIO.read Read data from the usbDMDIO object
            %
            % rmsg = usbDMDIO.read() reads data from the dmd through
            % usb and returns the data in uint8 format.
            %
            % Notes::
            % - This function is blocking with no time out in the current
            % implementation.
            
            if dmdIO.debug > 0
                fprintf('usbDMDIO read\n');
            end 
            % read from the usb handle
            rmsg = dmdIO.handle.read;
            % get the number of read bytes
            nLength = double(typecast(uint8(rmsg(3:4)),'uint16'));
            % format the read message (2 byte length plus message)
            rmsg = rmsg(1:nLength+4);
        end
        
        function write(dmdIO,wmsg)
            %usbDMDIO.write Write data to the usbDMDIO object
            %
            % usbDMDIO.write(wmsg) writes data to the dmd through usb.
            %
            % Notes::
            % - wmsg is the data to be written to the dmd via usb in  
            % uint8 format.
            
            if dmdIO.debug > 0
                fprintf('usbDMDIO write\n');
            end 
            % write to the usb handle using report ID 0
            dmdIO.handle.write(wmsg,0);
        end
    end 
end