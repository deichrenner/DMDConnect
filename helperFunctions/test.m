test = hidapi(0, 1105, 51456, 65, 65)
test.open
test.debug = 1
test.setNonBlocking(1)
buffer = [192, 255, 2, 0, 5, 2];
test.write(buffer, 0); test.read

test.close
delete(test)