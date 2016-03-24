%Get the Experiment Control status. Might throw an exception.
function [diff, len, reply] = cSync(handles)
%@return:   The reply from Experiment Control
%Queries Experiment Control's status. Might throw an exception when
%Experiment Control is not running, so the use of a
%try/catch-construct is highly recommended when using this method.

%I dont check for an error here, because giving the error to the
%caller function enables a better handling for this event.

import java.net.*;
import java.io.*;
%Establish connection
socket = Socket(handles.Host, handles.Port);
out = socket.getOutputStream;
in = socket.getInputStream;
out.write(int8(['GETSTATUS' 10]));
%Waiting for messages from Server
while ~(in.available)
end
n = in.available;
%Buffer size = 300 characters
reply = zeros(1,300);
for i = 1:n
    reply(i) = in.read();
end
close(socket);

b = reply;

%Get the current time and the ending time; if the
%difference is positive a new measurement gets started.
linebreaks = find(b==10);
tStart = b((linebreaks(2)+12:linebreaks(2)+23))-48;
tNow = b((linebreaks(3)+12:linebreaks(3)+23))-48;
tEnd = b((linebreaks(4)+12:linebreaks(4)+23))-48;
%Convert to DateVectors. I ignore milliseconds.
startVec = [1990, 6, 28, tStart(1)*10+tStart(2), ...
    tStart(4)*10+tStart(5), ...
    tStart(7)*10+tStart(8)+tStart(10)/10+tStart(11)/100];
nowVec = [1990, 6, 28, tNow(1)*10+tNow(2), ...
    tNow(4)*10+tNow(5), ...
    tNow(7)*10+tNow(8)+tNow(10)/10+tNow(11)/100];
endVec = [1990, 6, 28, tEnd(1)*10+tEnd(2), ...
    tEnd(4)*10+tEnd(5), ...
    tEnd(7)*10+tEnd(8)+tEnd(10)/10+tEnd(11)/100];

diff = etime(endVec, nowVec);
len = etime(endVec, startVec);
%Check if the macine is stopped (if so, the fist seven
%letters are 'Stopped'. In this case, it might be that the
%difference is positive, because i ignored the date before.
if isequal(b(1:7), [83 116 111 112 112 101 100])
    diff = -100;
end;