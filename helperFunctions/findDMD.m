function [ ind ] = findDMD( )
%FINDDMD tries to identify the dmd screen by its native resolution

ge = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment();
gds = ge.getScreenDevices();

for i = 1:numel(gds)
    height(i) = gds(i).getDisplayMode().getHeight();
    width(i) = gds(i).getDisplayMode().getWidth();
end

ind = find(width == 1920 & height == 1080);

end

