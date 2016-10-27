% DMD interface to the TI 6500 EVM DLP evaluation module
%
% Methods:
% DMD               Constructor, establishes communications
% delete            Destructor, closes connection
% send              Send data to the DMD
% receive           Receive data from the DMD
% setMode
% definePattern
% numOfImages
% initPatternLoad
% uploadPattern
% patternControl
% getCount
% testPattern
% idle
% active
% reset
% sleep             Puts the DMD to sleep
% wakeup            Wakes up the DMD after a standby operation
% fwversion         Returns the firmware version of the DMD
%
% Example::
%           d = DMD('debug', 1)
%
% This toolbox is based on the hidapi implementation written by Peter Corke
% in the framework of his robotics toolbox. The original source code can be
% found on http://www.petercorke.com/Robotics_Toolbox.html.
%
% Author: Klaus Hueck (e-mail: khueck (at) physik (dot) uni-hamburg (dot) de)
% Version: 0.0.1alpha
% Changes tracker:  28.01.2016  - First version
% License: GPL v3

classdef DMD < handle
    
    properties
        % connection handle
        conn;
        % debug input
        debug;
        % sequence counter, initialize to 1
        count = 1;
        % power status of the dmd, wide awake at init
        sleeping = 0;
        % DMD in idle mode? Is not idle at init
        isidle = 0;
        % is a pattern running?
        isrunning = 1;
        % display mode
        displayMode = 3;
        % contains the java frame for displaying images in fullscreen on
        % the dmd
        frame = '';
    end
    
    methods
        function dmd = DMD(varargin)
            % DMD.DMD Create a DMD object
            %
            % d = DMD(OPTIONS) is an object that represents a connection
            % interface to a TI 6500 EVM DMD module.
            %
            % Options:
            %  'debug',D       Debug level, show communications packet
            
            % make all helper functions known to DMD()
            libDir = strsplit(mfilename('fullpath'), filesep);
            % fix fullfile file separation for linux systems
            firstsep = '';
            if (isunix == 1)
                firstsep = '/';
            end
            addpath(fullfile(firstsep, libDir{1:end-1}, 'helperFunctions'));
            
            % init the properties
            opt.debug = 0;
            % read in the options
            opt = tb_optparse(opt, varargin);
            
            % connect via usb
            dmd.debug = opt.debug;
            if dmd.debug <= 1
                dmd.conn = usbDMDIO;
            elseif dmd.debug == 2
                dmd.conn = usbDMDIO(dmd.debug);
            elseif dmd.debug == 3
                disp('Dummy mode. Didn''t connect to DMD!');
            end
            connect = 1;
            
            % error
            if(~connect)
                fprintf('Add error handling here!\n');
            end
        end
        
        function delete(dmd)
            % DMD.delete Delete the DMD object
            %
            % delete(b) closes the connection to the dmd
            
            % wake it up before closing if it was asleep
            if dmd.sleeping
                dmd.wakeup;
            end
            
            % check if display mode is normal video mode. if so, shut down
            % the it6535 receiver
            if dmd.displayMode == 0                
                % shut down it6535 receiver &0x1A01
                cmd = Command();
                cmd.Mode = 'w';                     % set to write mode
                cmd.Reply = true;                  % we want no reply
                cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
                data = dec2bin(0, 8);                  % usb payload
                cmd.addCommand({'0x1A', '0x01'}, data);   % set the usb command
                dmd.send(cmd)
                dmd.receive;
            end
            dmd.conn.close();
        end
        
        function send(dmd, cmd)
            % DMD.send Send data to the dmd
            %
            % DMD.send(cmd) sends a command to the dmd through the
            % connection handle.
            %
            % Notes::
            % - cmd is a command object.
            %
            % Example::
            %           d.send(cmd)
            
            % make chunks of 64 byte and send via loop
            if ~(dmd.debug == 3)
                chunkSize = 64;
                numOfTransfers = ceil(length(cmd.msg)/chunkSize);
                for i = 1:numOfTransfers
                    % add data to packet
                    if i == numOfTransfers
                        data = cmd.msg((i-1)*chunkSize+1:end);
                    else
                        data = cmd.msg((i-1)*chunkSize+1:i*chunkSize);
                    end
                    % send the message through the DMDIO write function
                    dmd.conn.write(data);
                end
            end
            
            if dmd.debug > 0
                fprintf('sent:    [ ');
                for ii=1:length(cmd.msg)
                    fprintf('%s ',dec2hex(cmd.msg(ii)))
                end
                fprintf(']\n');
            end
        end
        
        function display(dmd,I)
            %DMD.display supermethod to prepare, upload and show a matlab
            %matrix
            %
            % display prepares the matrix I for upload, uploads it and
            % finally displays it on the dmd
            %
            % Note:
            % - I is the input matrix (max size 1920x1080x1)
            %
            % Example::
            %           d.display(ones(1920,1080))
            
            
            % check which display mode the dmd is in
            if dmd.displayMode == 0
                
                % check if source is locked
                [~, stat] = dmd.status;
                if stat(4)
                    % show full screen image on dmd
                    ind = findDMD();
                    if ~isempty(ind)
                        fullscreen(I,ind);
                    else
                        warndlg(['There is no screen with the native DMD resolution available. ' ...
                            'Please connect the DMD, and select the proper display mode.']);
                    end
                else
                    disp('Video source not locked');
                end
            elseif dmd.displayMode == 1
                disp('Displaying images via pre-stored pattern mode is not implemented yet');
            elseif dmd.displayMode == 2
                
                disp('Displaying images via video pattern mode is not implemented yet');
                
            elseif dmd.displayMode == 3
                % pattern on the fly mode -> use usb connection to transfer
                % images
                if dmd.debug
                    disp('Display image in pattern on-the-fly mode');
                end
                % prepare matrix for upload
                BMP = prepBMP(I);
                % set the mode to pattern display mode
                dmd.setMode
                % stop the running pattern
                dmd.patternControl(0)
                % define the pattern to be uploaded
                dmd.definePattern % FIXME: allow for better pattern definition
                % set the number of images to be uploaded to one
                dmd.numOfImages
                % initialize the pattern upload
                dmd.initPatternLoad(0,size(BMP,1));
                % do the upload
                dmd.uploadPattern(BMP)
                % set the dmd state to play
                dmd.patternControl(2)
            end
        end
        
        function setMode(dmd,m) % 0x1A1B
            %DMD.setMode Sets DMD to the selected mode
            %
            % setMode puts the dmd to the selected mode. Possible modes m
            % are:
            %   0 = Normal video mode
            %   1 = Pre-stored pattern mode (Images from flash)
            %   2 = Video pattern mode
            %   3 = Pattern On-The-Fly mode (Images loaded through USB)
            %
            % Note:
            % - m is the mode. The default mode is 3.
            %
            % Example::
            %           d.setMode(2)
            
            if nargin == 1
                m = 3;
                if dmd.debug
                    disp('setMode: Use default mode 3');
                end
            elseif nargin > 2
                disp(['setMode: Please only specify the dmd to work on and ' ...
                    'the required operation mode']);
            end
            
            if any(m > 3) || any(m < 0)
                disp('setMode: Only modes [0-3] are allowed, use default mode 3.');
                m = 3;
            end
            
            % make new display mode known the dmd object
            dmd.displayMode = m;
            
            cmd = Command();
            cmd.Mode = 'w';                     % set to write mode
            cmd.Reply = true;                  % we want no reply
            cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
            data = dec2bin(m, 8);                  % usb payload
            cmd.addCommand({'0x1A', '0x1B'}, data);   % set the usb command
            dmd.send(cmd)
            dmd.receive;
            
            % set additional parameters depending on the chosen display
            % mode
            if dmd.displayMode == 0 || dmd.displayMode == 2
                % set it6535 receiver to display port &0x1A01
                cmd = Command();
                cmd.Mode = 'w';                     % set to write mode
                cmd.Reply = true;                  % we want no reply
                cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
                data = dec2bin(2, 8);                  % usb payload
                cmd.addCommand({'0x1A', '0x01'}, data);   % set the usb command
                dmd.send(cmd)
                dmd.receive;
                dmd.display(zeros(1080,1920));
            end
        end
        
        function definePattern(dmd) % 0x1A34
            %DMD.definePattern Defines the LUT entry for a pattern
            %
            %
            
            idx             = 0;    % pattern index
            exposureTime    = 500000;  % exposure time in �s
            clearAfter      = 1;    % clear pattern after exposure
            bitDepth        = 1;    % desired bit depth (1 corresponds to bitdepth of 1)
            leds            = 1;    % select which color to use
            triggerIn       = 0;    % wait for trigger or cuntinue
            darkTime        = 0;    % dark time after exposure in �s
            triggerOut      = 0;    % use trigger2 as output
            patternIdx      = 0;    % image pattern index
            bitPosition     = 0;    % bit position in image pattern
            
            % define commandstring bytewise as per the C900 Programmer's
            % guide
            data = char;
            data(1:2,:) = dec2bin(typecast(uint16(idx), 'uint8'),8);
            data(3:6,:) = dec2bin(typecast(uint32(exposureTime), 'uint8'),8); % needs to override byte 5 as there is no such thing as uint24 :-(
            data(6,:)   = [dec2bin(triggerIn), dec2bin(leds,3), ...
                dec2bin(bitDepth-1,3), dec2bin(clearAfter)];
            data(7:10,:) = dec2bin(typecast(uint32(darkTime), 'uint8'),8); % needs to override byte 9 as there is no such thing as uint24 :-(
            data(10,:)   = dec2bin(typecast(uint8(triggerOut), 'uint8'),8);
            byte11_10 = [dec2bin(patternIdx,11) dec2bin(bitPosition,5)];
            data(11:12,:) = [byte11_10(1:8); byte11_10(9:16)];
            
            cmd = Command();
            cmd.Mode = 'w';                     % set to write mode
            cmd.Reply = true;                   % we want a reply!
            cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
            cmd.addCommand({'0x1A', '0x34'}, data);   % set the usb command
            dmd.send(cmd)
            dmd.receive;
        end
        
        function numOfImages(dmd, n, m) % 0x1A31
            %DMD.numOfImages Sets the number of images in a pattern
            %
            % Note:
            % - n is the number if images in the pattern
            % - m is the number of times the pattern should be repeated
            
            if nargin == 1
                n = 1;
                m = 100;
            end
            
            data = '';
            data(1:2,:) = dec2bin(typecast(uint16(n), 'uint8'),8);
            data(3:6,:) = dec2bin(typecast(uint32(m), 'uint8'),8);
            
            cmd = Command();
            cmd.Mode = 'w';                     % set to write mode
            cmd.Reply = true;                   % we want a reply!
            cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
            cmd.addCommand({'0x1A', '0x31'}, data);   % set the usb command
            dmd.send(cmd)
            dmd.receive;
            
        end
        
        function initPatternLoad(dmd, idx, imgSize) % 0x1A2A
            %DMD.initPattern Initializes the BMP pattern load
            %
            
            data = '';
            data(1:2,:) = dec2bin(typecast(uint16(idx), 'uint8'),8);
            data(3:6,:) = dec2bin(typecast(uint32(imgSize), 'uint8'),8);
            
            cmd = Command();
            cmd.Mode = 'w';                     % set to write mode
            cmd.Reply = true;                   % we want a reply!
            cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
            cmd.addCommand({'0x1A', '0x2A'}, data);   % set the usb command
            dmd.send(cmd)
            dmd.receive;
        end
        
        function uploadPattern(dmd, BMP) % 0x1A2B
            %DMD.uploadPattern Uploads the prepared BMP to the dmd
            %
            
            % The C900 input buffer is 512 byte large. The HID buffer is 64
            % byte large and the command header of the first transmission
            % of each 512 byte chunk is 8 byte long.
            % Thus we need to split the data in chunks of 1x 55 byte plus
            % nx 64 byte until all 512 bytes of the input buffer are
            % filled. Then, we need to issue a new transmission with the
            % full 8 byte header.
            chunkSize = 54;
            numOfTransfers = ceil(size(BMP,1)/chunkSize);
            textprogressbar('Upload Image: ');
            for i = 1:numOfTransfers
                % add data to packet
                if i == numOfTransfers
                    data = BMP((i-1)*chunkSize+1:end,:);
                else
                    data = BMP((i-1)*chunkSize+1:i*chunkSize,:);
                end
                % get size of packet to be transfered
                numOfBytes = dec2bin(typecast(uint16(size(data,1)),'uint8'),8);
                data = [numOfBytes; dec2bin(hex2dec(data),8)]; %#ok<AGROW>
                cmd = Command();
                cmd.Mode = 'w';                     % set to write mode
                cmd.Reply = true;                   % we want a reply!
                cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
                cmd.addCommand({'0x1A', '0x2B'}, data);   % set the usb command
                dmd.send(cmd);
                rmsg = dmd.receive;
                if ~(cmd.msg(2) == rmsg(2))
                    error('Transmission error sent and received message do not correspond!')
                end
                textprogressbar(100*i/numOfTransfers);
            end
            textprogressbar(' Done...');
        end
        
        function patternControl(dmd, c) % 0x1A24
            %DMD.patternControl Starts, stops or pauses the actual pattern
            %
            % patternControl starts, stops or pauses the actual pattern. A
            % stop will cause the pattern to stop. The next start command
            % will restart the sequence from the beginning. A pause command
            % will stop the pattern while the next start command restarts
            % the sequence by re-displaying the current pattern in the
            % sequence.
            %
            % Note:
            % - c is the command and can be
            %       0 = Stop
            %       1 = Pause
            %       2 = Start
            %
            % Example::
            %           d.patternControl()
            
            cmd = Command();
            cmd.Mode = 'w';                     % set to write mode
            cmd.Reply = true;                   % we want a reply!
            cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
            data = dec2bin(c,8);                  % usb payload
            cmd.addCommand({'0x1A', '0x24'}, data);   % set the usb command
            dmd.send(cmd);
            dmd.receive;
        end
        
        function c = getCount(dmd)
            % DMD.getCount Gets the actual value of the counter
            %
            % c = DMD.getCount(dmd) gets the actual value of the internal
            % counter for the sequence byte and increases it by one. If
            % dmd.count > 255 dmd.count will be reset to 1
            %
            % Example::
            %           c = d.getCount();
            c = dmd.count;
            dmd.count = dmd.count + 1;
            dmd.count(dmd.count > 255) = 1;
        end
        
        function rmsg = receive(dmd)
            % DMD.receive Receive data from the dmd
            %
            % rmsg = DMD.receive() receives data from the dmd through
            % the connection handle.
            %
            % Example::
            %           rmsg = d.receive()
            
            % read the message through the DMDIO read function
            if ~(dmd.debug == 3)
                rmsg = dmd.conn.read();
                if dmd.debug > 0
                    fprintf('received:    [ ');
                    for ii=1:length(rmsg)
                        fprintf('%d ',rmsg(ii))
                    end
                    fprintf(']\n');
                end
            else
                rmsg = zeros(20);
            end
        end
        
        function testPattern(dmd, p)
            % DMD.testpattern Show test pattern
            %
            % testpattern sets the input source of the dmd to the internal
            % test pattern generator and shows the selected test pattern
            %
            % Pattern Adresses:
            %   0 = Solid field
            %   1 = Horizontal ramp
            %   2 = Vertical ramp
            %   3 = Horizontal lines
            %   4 = Diagonal lines
            %   5 = Vertical lines
            %   6 = Grid
            %   7 = Checkerboard
            %   8 = RGB ramp
            %   9 = Color bars
            %   10 = Step bars
            %
            % Note:
            % - p is the adress of the pattern
            %
            % Example::
            %       d.testpattern(1)
            
            if ~dmd.sleeping
                cmd = Command();
                cmd.Mode = 'w';                     % set to write mode
                cmd.Reply = false;                  % we want a reply!
                cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
                data = '00000001';                  % usb payload
                cmd.addCommand({'0x1A', '0x00'}, data);   % set the usb command
                dmd.send(cmd)
                
                if p <= 10
                    cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
                    data = dec2bin(p,8);                  % usb payload
                    cmd.addCommand({'0x12', '0x03'}, data);   % set the usb command
                    dmd.send(cmd)
                else
                    disp(['The selected pattern does not exist. ' ...
                        'Valid pattern addresses are [0-10]']);
                end
            else
                if dmd.debug
                    disp('The DMD is asleep! Do not disturb!');
                end
            end
            
        end
        
        function idle(dmd)
            %DMD.idle Puts the DMD in idle mode
            %
            % idle puts the dmd to idle mode.
            %
            % Example::
            %           d.idle()
            
            if ~dmd.isidle
                cmd = Command();
                cmd.Mode = 'w';                     % set to write mode
                cmd.Reply = true;                   % we want a reply!
                cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
                data = '00000001';                  % usb payload
                cmd.addCommand({'0x02', '0x01'}, data);   % set the usb command
                dmd.send(cmd);
                dmd.receive;
                dmd.isidle = 1;
            else
                if dmd.debug
                    disp('DMD is already in idle mode!');
                end
            end
        end
        
        function active(dmd)
            %DMD.active Puts the DMD from idle back to active mode
            %
            % active puts the dmd back to active mode.
            %
            % Example::
            %           d.active()
            
            if dmd.isidle
                cmd = Command();
                cmd.Mode = 'w';                     % set to write mode
                cmd.Reply = true;                   % we want a reply!
                cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
                data = '00000000';                  % usb payload
                cmd.addCommand({'0x02', '0x01'}, data);   % set the usb command
                dmd.send(cmd)
                dmd.receive;
                dmd.isidle = 0;
            else
                if dmd.debug
                    disp('DMD was already active!');
                end
            end
        end
        
        function sleep(dmd)
            % DMD.sleep Put DMD to sleep
            %
            % sleep puts the dmd to stand by mode.
            %
            % Example::
            %           d.sleep()
            
            if ~dmd.sleeping
                cmd = Command();
                cmd.Mode = 'w';                     % set to write mode
                cmd.Reply = false;                   % we want a reply!
                cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
                data = '00000001';                  % usb payload
                cmd.addCommand({'0x02', '0x00'}, data);   % set the usb command
                dmd.send(cmd)
                dmd.sleeping = 1;
            else
                if dmd.debug
                    disp('DMD is already sleeping! Sleeps now even deeper...');
                end
            end
        end
        
        function reset(dmd)
            % DMD.reset Do a software reset
            %
            % reset does a software reset on the dmd.
            %
            % Example::
            %           d.reset()
            
            cmd = Command();
            cmd.Mode = 'w';                     % set to write mode
            cmd.Reply = false;                   % we want a reply!
            cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
            data = '00000010';                  % usb payload
            cmd.addCommand({'0x02', '0x00'}, data);   % set the usb command
            dmd.send(cmd)
        end
        
        function wakeup(dmd)
            % DMD.wakeup Wakeup DMD after sleep
            %
            % wakeup puts the dmd back to normal operation mode.
            %
            % Example::
            %           d.wakeup()
            
            if dmd.sleeping
                cmd = Command();
                cmd.Mode = 'w';                     % set to write mode
                cmd.Reply = false;                   % we want a reply!
                cmd.Sequence = dmd.getCount;        % set the rolling counter of the sequence byte
                data = '00000000';                  % usb payload
                cmd.addCommand({'0x02', '0x00'}, data);   % set the usb command
                dmd.send(cmd)
                dmd.sleeping = 0;
            else
                if dmd.debug
                    disp('DMD was not sleeping! Did''t wake it up...');
                end
            end
        end
        
        function fwVersion(dmd)
            % DMD.fwversion Return firmware version
            %
            % fwversion returns firmware version.
            %
            % Example::
            %           d.fwversion()
            
            cmd = Command();
            cmd.Mode = 'r';         % set to read mode
            cmd.Reply = true;       % we want a reply!
            cmd.Sequence = dmd.getCount;     % set the rolling counter of the sequence byte
            cmd.addCommand({'0x02', '0x05'}, '');
            dmd.send(cmd);
            
            % receive the command
            msg = dmd.receive()';
            
            % parse firmware version
            rpatch = typecast(uint8(msg(5:6)),'uint16');
            rminor = uint8(msg(7));
            rmajor = uint8(msg(8));
            APIpatch = typecast(uint8(msg(9:10)),'uint16');
            APIminor = uint8(msg(11));
            APImajor = uint8(msg(12));
            v = [num2str(rmajor) '.' num2str(rminor) '.' num2str(rpatch)];
            
            % display the result
            disp(['I am a ' deblank(dmd.conn.handle.getProductString) ...
                '. My personal details are:']);
            disp([blanks(5) 'Application Software Version: v' v]);
            disp([blanks(5) 'API Software Version: ' num2str(APImajor) '.' ...
                num2str(APIminor) '.' num2str(APIpatch)]);
            disp(['If I don''t work complain to my manufacturer ' ...
                dmd.conn.handle.getManufacturersString]);
        end
        
        
        function hwstat = hwstatus(dmd) % 0x1A0A
            % DMD.hwstatus Returns the hardware status of the DMD
            %
            % hwstatus returns the hardware status of the dmd as described
            % in the DLPC900 programmers guide on page 15.
            % Meaning of the different bits see manual.
            %
            % Example::
            %           d.hwstatus()
            
            cmd = Command();
            cmd.Mode = 'r';         % set to read mode
            cmd.Reply = true;       % we want a reply!
            cmd.Sequence = dmd.getCount;     % set the rolling counter of the sequence byte
            cmd.addCommand({'0x1A', '0x0A'}, '');
            dmd.send(cmd);
            
            % receive the command
            msg = dmd.receive()';
            
            % parse hardware status
            hwstat = dec2bin(msg(5),8);
        end
        
        function [stat, statbin] = status(dmd) % 0x1A0C
            % DMD.status Returns the main status of the DMD
            %
            % status returns the main status of the dmd as described
            % in the DLPC900 programmers guide on page 16.
            % The first output returns a cell array with a human readable
            % status message. The second one just returns the bits as
            % listed in the developer manual.
            %
            % Example::
            %           d.status()
            
            cmd = Command();
            cmd.Mode = 'r';         % set to read mode
            cmd.Reply = true;       % we want a reply!
            cmd.Sequence = dmd.getCount;     % set the rolling counter of the sequence byte
            cmd.addCommand({'0x1A', '0x0C'}, '');
            dmd.send(cmd);
            
            % receive the command
            msg = dmd.receive()';
            
            % parse hardware status
            statbin = dec2bin(msg(5),8);
            statbin = str2num(fliplr(statbin(3:end))');
            
            % 0 status
            stat0 = {'Mirrors not parked | '; ...
                'Sequencer stopped | '; ...
                'Video is running | '; ...
                'External source not locked | '; ...
                'Port 1 sync not valid | '; ...
                'Port 2 sync not valid';};
            % 1 status
            stat1 = {'Mirrors parked | '; ...
                'Sequencer running | '; ...
                'Video is frozen | '; ...
                'External source locked | '; ...
                'Port 1 sync valid | '; ...
                'Port 2 sync valid';};
            stat = stat0;
            stat(statbin == 1) = stat1(statbin == 1);
        end
    end
end
